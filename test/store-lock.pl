%% An embedded store is one process's at a time (cocolog 3.0.3).
%%
%% Each process maps an embedded store's two files and keeps a picture of
%% them of its own, read at the open and written at every commit, and every
%% transaction it begins allocates a record in them. Two processes over one
%% store wrote over each other: cicilang's builds (cicilang 0.240, cocolog
%% 2.14.1) lost commits and rows with no error, hung, and left stores that
%% no later process could open. The open takes DIR/lock now, flock(2) held
%% to the process's last close, and a second process waits its turn
%% (embed/embed.cicili, `ce_store_lock').
%%
%% What it checks:
%%   - FOUR WRITERS AT ONCE, cicilang's own reproduction: each writes 40
%%     rows of 3 500 characters into a predicate of its own and reads them
%%     back, and a fifth process finds all 160. Through 3.0.2 a run of three
%%     lost a commit (`sequence has no row') and the reader after it could
%%     not read the store.
%%   - THE HOLDER IS NAMED: while a process holds the store, its process id
%%     is in DIR/lock, COCOLOG_STORE_WAIT=0 is refused at once naming it,
%%     and COCOLOG_STORE_WAIT=1 the same after its second.
%%   - A WAITER WAITS ITS TURN, says once, past two seconds, whom it waits
%%     for, and runs when the holder is done.
%%   - A HOLDER THAT READS ITS OWN LOCK KEEPS IT: the lock is flock(2)'s,
%%     the open file description's, where the first cut's record lock was
%%     the process's and went at any close of the file in the holder.
%%   - NO LOCK OUTLIVES ITS HOLDER: one killed with SIGKILL holds nothing,
%%     and nor does a child it spawned and left running.
%%   - A DAMAGED STORE SAYS SO, cicilang's third request: a store whose data
%%     file was cut short, emptied, or left without its hexmap is refused
%%     at the open, `the store in DIR is damaged: ...' -- through 3.0.2
%%     each opened without a word, and a read then hung until it was killed
%%     (the data file cut) or found every predicate gone, print_message/2
%%     among them (the other two). And a store whose hexmap was cut opens,
%%     as it must (below), and says so at the first torn read, in a consulted
%%     `dynamic' directive, where cicilang's later processes said `dynamic:
%%     out of memory', and in dynamic/1 as a goal, which raised
%%     representation_error(max_arity).
%%   - A STORE UNDER AN ADDRESS-SPACE LIMIT IS READ OR REFUSED, NEVER READ
%%     EMPTY (3.62.6, ZiguratIP 1.0.3; Ambitious's finding 41). `ulimit -v'
%%     counts what a mapping reserves, and through 3.62.5 each of a store's
%%     files reserved a gigabyte -- two for the canonical pair and two more
%%     for each thread's private reader -- and a mapping the limit refused
%%     was read as an empty file: under 4 GB a store of a megabyte read as
%%     empty (`Unknown procedure'), under 2 GB a write said it was damaged,
%%     under 1 GB the open did. Under 1.5 GB a small store reads and takes a
%%     write; a store whose data file cannot be mapped is refused at its
%%     open, saying so; one whose private reader cannot be mapped reads
%%     through its canonical pair; and across the limits near cocolog's
%%     floor, and those where a store of 256 MB loses its mappings one by
%%     one, no read finds the store empty or damaged, no refusal is silent,
%%     no process ends by a signal, and the store holds exactly the writes
%%     that said they were made. A read 800 brackets deep near the floor
%%     ends by no signal -- the first thread's stack is reserved under the
%%     limit as main() begins -- and one 30 000 deep raises
%%     resource_error(c_stack). A write that grows the store is kept whole
%%     or refused whole, saying so; a run_isolated/2 whose write through its
%%     own connection is refused raises it in assertz/1, keeps nothing and
%%     says so as its status; and the rows one run wrote read back whole in
%%     the next run on the thread, or it says of each why, in memory's words.
%%   - A ROW WHOSE READ IS REFUSED ITS MEMORY IS SAID AS MEMORY (3.62.6):
%%     each request of a fetch refused in turn (test/refuse.c), the answer is
%%     the row, resource_error(memory) or the host out of memory -- never
%%     `the row at ordinal 0 does not read as a clause' -- and a query that
%%     wrote nothing keeps its commit. A green task's write on a worker that
%%     is not the connection's owner, its write-through refused, raises in
%%     assertz/1, and the worker's next write is made; and the host's note of
%%     a changed predicate refused raises in memory's words.
%%   - A WRITE REFUSED ANY REQUEST ENDS WITH NO SIGNAL (3.62.7, ZiguratIP
%%     1.0.4): each request of any size a write makes, refused in turn, once
%%     and up to four times in a row, and the run answers, says memory or
%%     ends as a host out of memory ends -- no hang under the engine's locks,
%%     no abort at a commit or a begin, no SIGSEGV in a page walk -- and its
%%     store reads back. A REPL whose walks were refused their memory commits
%%     its next query's write, a B-tree hint refused is no write refused, and
%%     a commit refused a request after its intention is a commit made.
%%   - A GREEN TASK'S ASSERTZ IS ITS OWN ROW, AND NO TASK WAITS ON ITS HOST
%%     (3.63.1; the Ambitious session's finding 4). Four tasks' 1 000 assertz
%%     grow a fresh store as 1 000 rows do -- through 3.63.0 each rewrote
%%     its whole predicate, 21 to 27 s and 105 to 118 MB at 100 % of a
%%     core, the store's lock held -- and a second process reads each
%%     task's rows back in its order. A task that retracts from a predicate its host has written this
%%     turn, after the first call of a predicate not read yet or a
%%     current_predicate/1 had the host write the turn's changes into its
%%     open transaction, waits on no lock of the host's: through 3.63.0 it
%%     waited ten seconds and its retract was lost. And rows a program's own
%%     zigurat_call/2 took away are written again at the next assertz.
%%
%%     cocolog -s test/store-lock.pl        from the checkout root

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    (   embedded(D)
    ->  writers(D), holder(D), reader(D), gone(D), damaged(D), limited(D),
        refused_read(D), tasks_write(D)
    ;   skip('(this build carries no embedded store: make EMBED=0)')
    ),
    shl(['rm -rf ', D]),
    checks_done.

%% whether this binary opens a store at all
embedded(D) :-
    format(atom(Args), '--embed ~w/probe query true >/dev/null 2>&1', [D]),
    cocolog_run(Args, _, 0).

%% cicilang's writer and a reader of what each writer left
w_file(D, F) :-
    atom_concat(D, '/w.pl', F),
    fixture(F, ['w(Tag, K) :- atom_concat(''$ccl_ir:w_'', Tag, P), dynamic(P/2),',
                '    length(Cs, 3500), maplist(=(0''x), Cs), atom_codes(C0, Cs),',
                '    forall(between(1, K, I), (atom_concat(C0, I, C), T =.. [P, I, C], assertz(T))),',
                '    findall(I, (between(1, K, I), T2 =.. [P, I, _], call(T2)), Is), length(Is, N),',
                '    format("writer ~w: ~d of ~d rows back~n", [Tag, N, K]).',
                'r(J) :- forall(between(1, J, Tag),',
                '    ( atom_concat(''$ccl_ir:w_'', Tag, P), T =.. [P, _, _],',
                '      catch(( findall(x, T, Xs), length(Xs, N) ), _, N = none),',
                '      format("writer ~w has ~w rows~n", [Tag, N]) )).']).

writers(D) :-
    section('four writers at once over one fresh store'),
    w_file(D, F),
    cocolog(C),
    atom_concat(D, '/kb', KB),
    findall(Cmd,
            ( between(1, 4, I),
              format(atom(Cmd), '( ~w --embed ~w query "ensure_loaded(''~w''), w(~w, 40)" > ~w/w~w.out 2>&1; echo "exit $?" >> ~w/w~w.out ) &',
                     [C, KB, F, I, D, I, D, I]) ),
            Cmds),
    atomic_list_concat(Cmds, ' ', All),
    atom_concat(All, ' wait', Sh),
    shell(Sh, _, _, 300000),
    forall(between(1, 4, I),
           ( format(atom(Out), '~w/w~w.out', [D, I]),
             read_file_to_codes(Out, Cs), atom_codes(Text, Cs),
             format(atom(L1), 'writer ~w reads its 40 rows back', [I]),
             format(atom(N1), 'writer ~w: 40 of 40 rows back', [I]),
             has(L1, N1, Text),
             format(atom(L2), '...and exits 0 (writer ~w)', [I]),
             has(L2, 'exit 0', Text) )),
    format(atom(RArgs), '--embed ~w query "ensure_loaded(''~w''), r(4)" 2>&1', [KB, F]),
    cocolog_run(RArgs, RText, _),
    forall(between(1, 4, I),
           ( format(atom(L3), 'a fifth process finds writer ~w''s 40 rows', [I]),
             format(atom(N3), 'writer ~w has 40 rows', [I]),
             has(L3, N3, RText) )).

%% a process that holds KB for Ms milliseconds, and its pid once its goal
%% runs -- the store opened, which KB.ready says: its process id is in the
%% lock from the lock's taking, before the store's files are. PRE is the
%% text of goals it runs first, each followed by its comma
hold(KB, Ms, Pid) :- hold(KB, '', Ms, Pid).

hold(KB, Pre, Ms, Pid) :-
    cocolog(C),
    atom_concat(KB, '.ready', Ready),
    format(atom(Hold), '~w --embed ~w query "use_module(library(process)), ~wwrite_file_from_codes(''~w'', [114]), proc_sleep(~w)" >/dev/null 2>&1',
           [C, KB, Pre, Ready, Ms]),
    spawn(Hold, Pid),
    ( proc_until(exists_file(Ready), 20000, 50) -> true ; true ).

%% DIR/lock names Pid as its holder
lock_names(Lock, Pid) :-
    catch(read_file_to_codes(Lock, Cs), _, fail),
    append(Ds, [10], Cs),
    catch(number_codes(Pid, Ds), _, fail).

holder(D) :-
    section('the holder named, and a waiter in its turn'),
    atom_concat(D, '/kb2', KB),
    atom_concat(KB, '/lock', Lock),
    hold(KB, 8000, Pid),
    ( lock_names(Lock, Pid) -> Named0 = yes ; Named0 = no ),
    check('the holder writes its process id into DIR/lock', Named0, yes),
    cocolog(C),
    format(atom(Named), 'the store is in use by process ~w', [Pid]),
    format(atom(Now), 'COCOLOG_STORE_WAIT=0 ~w --embed ~w query true 2>&1', [C, KB]),
    shell(Now, NowText, NowExit),
    check('COCOLOG_STORE_WAIT=0 refuses at once', NowExit, 1),
    has('...naming the holder', Named, NowText),
    format(atom(One), 'COCOLOG_STORE_WAIT=1 ~w --embed ~w query true 2>&1', [C, KB]),
    get_time(T0), shell(One, OneText, OneExit), get_time(T1),
    check('COCOLOG_STORE_WAIT=1 refuses too', OneExit, 1),
    has('...naming the holder', Named, OneText),
    ( T1 - T0 >= 0.9 -> Waited = yes ; Waited is T1 - T0 ),
    check('...once it has waited its second', Waited, yes),
    format(atom(Wait), '~w --embed ~w query "write(ran), nl" 2>&1', [C, KB]),
    shell(Wait, WaitText, WaitExit),
    check('a waiter with no limit runs when the holder is done', WaitExit, 0),
    has('...and answers', ran, WaitText),
    format(atom(Note), 'cocolog: the store in ~w is in use by process ~w; waiting for it', [KB, Pid]),
    has('...having said whom it waited for', Note, WaitText),
    atomic_list_concat(Parts, 'waiting for it', WaitText), length(Parts, NP),
    check('...once', NP, 2),
    ( proc_wait(Pid, 10000, _) -> true ; proc_stop(Pid) ).

%% A HOLDER THAT READS ITS OWN LOCK KEEPS IT. The first cut's record lock
%% (fcntl) was the process's, and any close of the file in the holder gave
%% it back: a program that read its store's files -- a backup, a copy of
%% the directory made in-process -- let a second process in with no word
reader(D) :-
    section('a holder that reads its own lock keeps it'),
    atom_concat(D, '/kb5', KB),
    atom_concat(KB, '/lock', Lock),
    format(atom(Pre), 'read_file_to_codes(''~w'', _), ', [Lock]),
    hold(KB, Pre, 3000, Pid),
    cocolog(C),
    format(atom(Now), 'COCOLOG_STORE_WAIT=0 ~w --embed ~w query true 2>&1', [C, KB]),
    shell(Now, Text, Exit),
    check('a second process is still refused', Exit, 1),
    format(atom(Named), 'the store is in use by process ~w', [Pid]),
    has('...naming the holder', Named, Text),
    ( proc_wait(Pid, 10000, _) -> true ; proc_stop(Pid) ).

gone(D) :-
    section('no lock outlives its holder'),
    atom_concat(D, '/kb3', KB),
    cocolog(C),
    hold(KB, 60000, Pid),
    proc_kill(Pid, 9),
    ( proc_wait(Pid, 10000, _) -> true ; true ),
    format(atom(Now), 'COCOLOG_STORE_WAIT=0 ~w --embed ~w query true >/dev/null 2>&1', [C, KB]),
    shell(Now, _, KilledExit),
    check('a holder killed with SIGKILL holds no lock', KilledExit, 0),
    %% the child's output goes elsewhere, or it holds this shell's pipe open
    %% and shell/3 waits out its sleep
    format(atom(Spawner), '~w --embed ~w query "use_module(library(process)), proc_spawn(''exec sleep 30 >/dev/null 2>&1'', P), format(\\"child(~~w)~~n\\", [P])" 2>&1',
           [C, KB]),
    shell(Spawner, SText, _),
    shell(Now, _, ChildExit),
    check('a child its holder left running holds none', ChildExit, 0),
    (   atomic_list_concat([_, R|_], 'child(', SText), atomic_list_concat([P0|_], ')', R),
        atom_number(P0, Child)
    ->  catch(proc_kill(Child, 9), _, true)
    ;   true
    ).

damaged(D) :-
    section('a damaged store says so'),
    w_file(D, F),
    atom_concat(D, '/kb4', KB),
    format(atom(W), '--embed ~w query "ensure_loaded(''~w''), w(1, 40)" >/dev/null 2>&1', [KB, F]),
    cocolog_run(W, _, WExit),
    check('a store is made, one writer''s 40 rows in it', WExit, 0),
    atom_concat(KB, '/data.bin', Data),
    size_file(Data, Size),
    Half is Size // 2,
    damage(KB, cut, Half, ['its hexmap describes'], 'a data file cut to half its length'),
    damage(KB, emptied, 0, ['its hexmap describes'], 'a data file emptied'),
    damage(KB, gone, 0, ['its data file holds', 'and its hexmap is gone'], 'a data file whose hexmap is gone'),
    torn(D, KB, F).

%% a copy of the store in KB damaged as HOW says, opened: refused (exit 1)
%% and said to be damaged in the words SAYS, the first right after the
%% name, the rest after it
damage(KB, How, N, [Says|More], Label) :-
    copy_store(KB, How, Copy),
    (   How == cut
    ->  format(atom(Do), 'head -c ~w ~w/data.bin > ~w/cut && mv ~w/cut ~w/data.bin', [N, Copy, Copy, Copy, Copy])
    ;   How == emptied
    ->  format(atom(Do), ': > ~w/data.bin', [Copy])
    ;   format(atom(Do), 'rm -f ~w/hexmap.bin', [Copy])
    ),
    shl([Do]),
    cocolog(C),
    format(atom(Open), '~w --embed ~w query true 2>&1', [C, Copy]),
    shell(Open, Text, Exit, 60000),
    check(Label, Exit, 1),
    format(atom(Named), 'the store in ~w is damaged: ~w', [Copy, Says]),
    has('...is refused at its open, said to be damaged', Named, Text),
    forall(member(M, More), has('...in so many words', M, Text)).

copy_store(KB, How, Copy) :-
    atomic_list_concat([KB, '_', How], Copy),
    format(atom(Cp), 'rm -rf ~w; cp -R ~w ~w', [Copy, KB, Copy]),
    shl([Cp]).

%% A HEXMAP CUT TO HALF ITS LENGTH. The engine frees the pages its hexmap no
%% longer covers, as it frees what a first commit killed left behind, so the
%% open goes through and the first read of a row past the cut meets a
%% record the hexmap calls free -- where cicilang's later processes said
%% `dynamic: out of memory' (a consult's directive, made here), and
%% dynamic/1 as a goal raised representation_error(max_arity)
torn(D, KB, F) :-
    copy_store(KB, torn, Copy),
    atom_concat(Copy, '/hexmap.bin', Hex),
    size_file(Hex, HSize),
    HHalf is HSize // 2,
    format(atom(Cut), 'head -c ~w ~w > ~w.cut && mv ~w.cut ~w', [HHalf, Hex, Hex, Hex, Hex]),
    shl([Cut]),
    format(atom(Named), 'the store in ~w is damaged: ', [Copy]),
    cocolog(C),
    format(atom(Read), '~w --embed ~w query "ensure_loaded(''~w''), r(1)" 2>&1', [C, Copy, F]),
    shell(Read, RText, _, 60000),
    has('a hexmap cut to half: a read past the cut says the store is damaged', Named, RText),
    atom_concat(D, '/dyn.pl', Dyn),
    fixture(Dyn, [':- dynamic(zz/3).', 'main.']),
    format(atom(Run), '~w --embed ~w run ~w main 2>&1', [C, Copy, Dyn]),
    shell(Run, DText, _, 60000),
    atom_concat('dynamic: declare_dynamic: ', Named, DNamed),
    has('...a consulted `dynamic'' directive says so, not `out of memory''', DNamed, DText),
    format(atom(Goal), '~w --embed ~w query "catch(dynamic(zz/3), error(E, context(P, W)), true), ( E == resource_error(knowledge_base), P == system:(dynamic)/1 -> write(W) ; write(E-P) ), nl" 2>&1',
           [C, Copy]),
    shell(Goal, GText, _, 60000),
    has('...and dynamic/1 as a goal raises resource_error(knowledge_base), naming dynamic/1 and why', Named, GText).

%% A STORE UNDER AN ADDRESS-SPACE LIMIT (3.62.6, ZiguratIP 1.0.3). Each
%% check names the layer whose arm makes it red: the reservation that asks
%% for what it needs (mapbuf::reserve, `C'), the private reader that falls
%% back when it cannot be mapped (reader_ensure, `B'), the store refused at
%% its open when a file cannot be mapped or loaded (ce_map_open and the
%% open's catch, `A'), and the rollback whose fill asks for no memory
%% (mapstream::fill_n: on 1.0.2's, which made a vector of 64 KB, a query
%% that ran out of memory near the floor aborted at its rollback); and past
%% the floor the growth refused whole (`G', lim_grow) and the writes and
%% reads of a connection of a run's own (`W', `T', `R', `S', `C4',
%% lim_isolated). macOS enforces no `ulimit -v'
limited(D) :-
    section('a store under an address-space limit'),
    shell('uname -s', Sys, _),
    (   Sys == 'Darwin'
    ->  format("   SKIP (macOS does not enforce ulimit -v)~n", [])
    ;   cocolog(C),
        atom_concat(D, '/kb6', KB),
        format(atom(Make), '~w --embed ~w query "assertz(foo(1))" >/dev/null 2>&1', [C, KB]),
        shl([Make]),
        lim_run(1536000, KB, 'foo(X)', T1, E1),
        check('under ulimit -v 1536000 a store of a megabyte reads (C)', E1, 0),
        has('...what it holds', 'foo(1)', T1),
        lim_run(1536000, KB, 'assertz(bar(wide))', _, E2),
        check('...and takes a write (C)', E2, 0),
        %% A MAPPING ASKS FOR WHAT IT NEEDS UNDER A LIMIT, never the
        %% gigabyte it reserves without one: under 1100000 the data file's
        %% gigabyte left the program some 70 MB, and four million list cells
        %% were out of memory (the list is made under \+ \+, or `query'
        %% writes its four million cells back)
        lim_run(1100000, KB, '\\+ \\+ (length(_, 4000000), write(room), nl)', T3, E3),
        ( lim_answered(E3, T3) -> Room = room ; Room = T3 ),
        check('...and under 1100000 its mappings leave the program its memory: four million cells (C)', Room, room),
        lim_floor(KB, 8192, 1536000, lim_reads, F),
        Lo is max(8192, F - 8192), Hi is F + 8192, Fine is F - 2048,
        findall(V, ( between(0, 64, I), V is Lo + I * 1024, V =< Hi ), Coarse),
        findall(V, ( between(0, 15, I), V is Fine + I * 128 ), Fines),
        append(Coarse, Fines, Vs0), msort(Vs0, Vs),
        lim_sweep(KB, Vs, write, ['Unknown procedure', damaged], Bad, Written, _),
        check('near cocolog''s floor no read finds the store empty or damaged, none is silent, no process ends by a signal (A, fill_n)',
              Bad, []),
        lim_holds(KB, [wide|Written], 'the store holds foo(1) and exactly the writes that answered'),
        lim_deep(KB, F),
        lim_grow(D, KB, F),
        lim_isolated(D, KB, F),
        lim_big(D, KB, F, [wide|Written])
    ).

%% THE FIRST THREAD'S STACK, RESERVED UNDER THE LIMIT (3.62.6): RLIMIT_AS
%% counts the stack as the kernel grows it, and a growth the limit refuses
%% is a SIGSEGV. Through 3.62.5 a read of 800 brackets -- `((...(a)...))',
%% some 360 KB of C stack and next to no heap -- just under the floor, where
%% the heap had the last pages, ended so across 192 KB of limits, one of 30
%% 000 across every limit past it, and a load's own stack now and then (14
%% runs in 100 of one build at one limit: the stack's start is drawn at
%% random, and the load's peak is a page past what exec maps). The thread
%% grows its stack's mapping as main() begins now, a sixteenth of the limit
%% (`coco_cstack_reserve', `stack'), and the reserve is the stack a read or
%% a write may use: a read too deep for it raises resource_error(c_stack),
%% where past it the kernel could refuse the page (`bounds')
lim_deep(KB, F) :-
    findall(V, ( between(0, 64, I), V is F - 1024 + I * 32 ), Vs),
    lim_deep_sweep(KB, Vs, 800, B1, S1),
    check('a read 800 brackets deep across the limits around the floor ends by no signal, and says what stopped it (stack)',
          B1, []),
    ( member(T, S1), sub_atom(T, _, _, _, 'deep(ok)') -> R1 = read ; R1 = none ),
    check('...and reads where the limit leaves it room (stack)', R1, read),
    findall(V, ( between(0, 16, I), V is F + I * 128 ), Ws),
    lim_deep_sweep(KB, Ws, 30000, B2, S2),
    check('a read 30 000 brackets deep across the limits past the floor ends by no signal (stack, bounds)', B2, []),
    (   member(T2, S2), sub_atom(T2, _, _, _, 'deep(error(resource_error(c_stack)')
    ->  R2 = raised
    ;   R2 = none
    ),
    check('...and raises resource_error(c_stack) where it is read (bounds)', R2, raised).

lim_deep_sweep(_, [], _, [], []).
lim_deep_sweep(KB, [V|Vs], N, Bad, [Text|Said]) :-
    format(atom(G), 'format(atom(A), ''~~*ca~~*c'', [~w, 0''(, ~w, 0'')]), catch(( term_to_atom(T, A), T == a, R = ok ), E, R = E), write(deep(R)), nl',
           [N, N]),
    lim_run(V, KB, G, Text, Exit),
    findall(Why, lim_deep_bad(V, N, Text, Exit, Why), B0),
    lim_deep_sweep(KB, Vs, N, B1, Said),
    append(B0, B1, Bad).

lim_deep_bad(V, N, _, Exit, signal(V, N, Exit)) :- Exit >= 128.
lim_deep_bad(V, N, '', Exit, silent(V, N)) :- Exit =\= 0.
lim_deep_bad(V, N, Text, 0, unread(V, N)) :- \+ sub_atom(Text, _, _, _, 'deep(').

%% A WRITE THROUGH A CONNECTION OF ITS OWN, run_isolated/2's (3.62.6): its
%% store writes each clause through as it is asserted, where a query's
%% writes its predicates at the end. Under the limits past the floor where
%% the growth is refused, a write the knowledge base refused raises
%% resource_error(knowledge_base) in assertz/1, saying why (`W'), its clause
%% is not in the run's own store (`T'), and a run that caught it and went on
%% keeps nothing and says so as its status: the store holds the commit of a
%% thread a call was refused in (`R'), and the run's close answers the
%% refusal (`S'). Through 3.62.5 the assert succeeded, and the run answered
%% true and kept what it wrote after the refusal alone. And under the
%% limits where the writes fit and the thread's private reader, mapped when
%% the store was small, cannot widen for them, what lies past its mapping
%% is read by pread (mapbuf::read_at, `C4')
lim_isolated(D, KB, F) :-
    atom_concat(D, '/iso.pl', Fx),
    fixture(Fx, [':- use_module(library(thread)).',
                 'row(A) :- format(atom(A), ''~*c'', [60000, 120]).',
                 'fill(N, K, W) :- row(A), fill(1, N, A, K, W).',
                 'fill(I, N, _, 0, none) :- I > N, !.',
                 'fill(I, N, A, K, W) :- atom_concat(big, I, P), T =.. [P, A], catch(( assertz(T), R = ok ), E, R = E), ( R == ok -> I1 is I + 1, fill(I1, N, A, K, W) ; K = I, W = R ).',
                 'held(0, none) :- !.',
                 'held(K, H) :- atom_concat(big, K, P), ( catch(call(P, _), _, fail) -> H = present ; H = absent ).',
                 'said(none, none) :- !.',
                 'said(error(resource_error(knowledge_base), context(system:assertz/1, Why)), kb(Why)) :- !.',
                 'said(E, other(E)).',
                 'writes :- run_isolated(( assertz(small(1)), fill(400, K, W), held(K, H), said(W, Y), assertz(small(2)), format("iso(~q,~q,~q)~n", [K, H, Y]) ), S), format("status(~q)~n", [S]).',
                 'bigs(N) :- aggregate_all(count, ( between(1, 400, I), atom_concat(big, I, P), catch(call(P, X), _, fail), atom_length(X, 60000) ), N).',
                 'why(I, W) :- atom_concat(big, I, P), catch(( call(P, X), atom_length(X, L), W = len(L) ), E, W = E).',
                 'whys :- forall(between(1, 40, I), ( why(I, W), ( W == len(60000) -> true ; format("row(~w, ~q)~n", [I, W]) ) )).',
                 'reads :- foo(_), run_isolated(( row(A), forall(between(1, 40, I), ( atom_concat(big, I, P), T =.. [P, A], assertz(T) )) ), S1), run_isolated(( bigs(N), format("read(~q)~n", [N]), whys ), S2), format("status(~q, ~q)~n", [S1, S2]).',
                 'back :- catch(findall(X, small(X), Ss), error(existence_error(_, _), _), Ss = []), bigs(N), write(back(Ss, N)), nl.']),
    atom_concat(D, '/kb9', G),
    findall(V, ( member(M, [2048, 4096, 8192, 16384, 32768]), V is F + M ), Vs),
    lim_iso_writes(KB, G, Fx, Vs, Bad, Refused),
    check('a run_isolated/2 whose write is refused near the floor raises it, keeps nothing and says so, and a run that is not refused keeps it all (W, T, R, S)',
          Bad, []),
    (   Refused = [_|_] -> Seen = refused ; Seen = none ),
    check('...and a write through it was refused its growth, saying why (W)', Seen, refused),
    lim_floor_iso(KB, G, Fx, F, W),
    findall(V, ( between(0, 16, I), V is W + I * 256 ), Rs),
    lim_iso_reads(KB, G, Fx, Rs, RBad),
    check('across the limits past where forty rows fit, the rows a run wrote read back whole in the next run on the thread, or the run says why not (C4)',
          RBad, []).

%% the fixture's goal Goal, in a query over a fresh copy of KB in G under V
lim_iso_run(KB, G, Fx, V, Goal, Text, Exit) :-
    format(atom(Cp), 'rm -rf ~w; cp -R ~w ~w', [G, KB, G]),
    shl([Cp]),
    format(atom(Q), 'use_module(''~w''), ~w', [Fx, Goal]),
    lim_run(V, G, Q, Text, Exit).

%% the store in G read back with no limit
lim_iso_back(G, Fx, Text) :-
    cocolog(C),
    format(atom(Cmd), '~w --embed ~w query "use_module(''~w''), back" 2>&1', [C, G, Fx]),
    shell(Cmd, Text, _).

lim_iso_writes(_, _, _, [], [], []).
lim_iso_writes(KB, G, Fx, [V|Vs], Bad, Refused) :-
    lim_iso_run(KB, G, Fx, V, writes, Text, Exit),
    lim_iso_back(G, Fx, Back),
    findall(Why, lim_iso_bad(V, Text, Exit, Back, Why), B0),
    ( sub_atom(Text, _, _, _, 'could not grow') -> Refused = [V|Refused1] ; Refused = Refused1 ),
    lim_iso_writes(KB, G, Fx, Vs, B1, Refused1),
    append(B0, B1, Bad).

lim_iso_bad(V, _, Exit, _, signal(V, Exit)) :- Exit >= 128.
lim_iso_bad(V, Text, _, Back, said(V, Word)) :-
    member(Word, ['does not read as a clause', damaged]),
    once(( sub_atom(Text, _, _, _, Word) ; sub_atom(Back, _, _, _, Word) )).
%% not refused: the run answered true, and its 402 rows are there
lim_iso_bad(V, Text, _, Back, kept(V, Text, Back)) :-
    sub_atom(Text, _, _, _, 'iso(0,none,none)'),
    \+ ( sub_atom(Text, _, _, _, 'status(true)'), sub_atom(Back, _, _, _, 'back([1,2],400)') ).
%% refused: in assertz/1's context, saying why -- the growth refused, or an
%% allocation the engine's call was refused (W) -- the clause not in the
%% run's store (T), the run's status the commit's refusal and nothing of it
%% kept (R, S)
lim_iso_bad(V, Text, _, Back, refused(V, Text, Back)) :-
    sub_atom(Text, B, _, _, 'iso('), \+ sub_atom(Text, _, _, _, 'iso(0,none,none)'),
    sub_atom(Text, B, _, 0, Rest),
    \+ ( sub_atom(Rest, _, _, _, ',absent,kb('),
         once(( sub_atom(Rest, _, _, _, 'could not grow') ; sub_atom(Rest, _, _, _, 'out of memory') )),
         sub_atom(Text, _, _, _, 'status(''the knowledge base refused the commit: '),
         sub_atom(Back, _, _, _, 'back([],0)') ).
%% neither: the run answered nothing of itself, nor said why
lim_iso_bad(V, Text, Exit, _, nothing(V, Exit, Text)) :-
    \+ sub_atom(Text, _, _, _, 'iso('),
    \+ sub_atom(Text, _, _, _, 'out of memory'),
    \+ sub_atom(Text, _, _, _, 'could not grow').

%% the least limit, to 256 KB, past F under which the run's forty rows are
%% written (`status(true,'), the first status of `reads')
lim_floor_iso(KB, G, Fx, F, W) :-
    Hi is F + 65536,
    lim_floor_iso(KB, G, Fx, F, Hi, W).
lim_floor_iso(KB, G, Fx, Lo, Hi, W) :-
    (   Hi - Lo =< 256
    ->  W = Hi
    ;   Mid is (Lo + Hi) // 2 // 256 * 256,
        lim_iso_run(KB, G, Fx, Mid, reads, Text, _),
        (   sub_atom(Text, _, _, _, 'status(true,')
        ->  lim_floor_iso(KB, G, Fx, Lo, Mid, W)
        ;   lim_floor_iso(KB, G, Fx, Mid, Hi, W)
        )
    ).

lim_iso_reads(_, _, _, [], []).
lim_iso_reads(KB, G, Fx, [V|Vs], Bad) :-
    lim_iso_run(KB, G, Fx, V, reads, Text, Exit),
    findall(Why, lim_iso_read_bad(V, Text, Exit, Why), B0),
    lim_iso_reads(KB, G, Fx, Vs, B1),
    append(B0, B1, Bad).

lim_iso_read_bad(V, _, Exit, signal(V, Exit)) :- Exit >= 128.
lim_iso_read_bad(V, Text, _, said(V, Word)) :-
    member(Word, ['does not read as a clause', damaged]),
    sub_atom(Text, _, _, _, Word).
%% the rows were written: the next run read all forty of them, or said of
%% each it did not why, in memory's words (`row(I, Error)')
lim_iso_read_bad(V, Text, _, read(V, Line)) :-
    sub_atom(Text, _, _, _, 'status(true,'),
    \+ sub_atom(Text, _, _, _, 'read(40)'),
    split_string(Text, '\n', '', Lines),
    member(L, Lines), sub_string(L, 0, _, _, 'row('),
    \+ sub_string(L, _, _, _, 'resource_error(memory)'),
    \+ sub_string(L, _, _, _, 'out of memory'),
    atom_string(Line, L).
%% and never found a row missing without a word: a row past where the
%% reader's mapping could widen read as no row at all, its predicate's call
%% failed and the run answered false (`C4': through 1.0.2 a reader read
%% only what its mapping covered, 15 rows of the 40 under the least limits)
lim_iso_read_bad(V, Text, _, silent(V, Text)) :-
    sub_atom(Text, _, _, _, 'status(true, false)').

%% A WRITE THAT GROWS THE STORE, under the limits just past the floor where
%% the mapping cannot widen for the growth: forty rows of 60 000
%% characters, 37 fresh pages. The engine's first write of a fresh page is
%% the one that grows the files, and a grow the address space refused was a
%% write of nothing that the engine never saw -- the writer exited 0 and the
%% next process read `the row at ordinal 33 does not read as a clause'. The
%% room is asked for first now, of both files, for the whole page
%% (allocate_new_page's make_room, `G'). Each write starts from a copy of
%% the same store: one that answers holds its forty rows, one that does not
%% holds none of them and says why, and every one holds foo(1)
lim_grow(D, KB, F) :-
    atom_concat(D, '/kb8', G),
    findall(V, ( between(0, 16, I), V is F + I * 256 ), Vs),
    lim_grow_sweep(KB, G, Vs, Bad, Said),
    check('a write that grows the store near the floor is kept whole or refused whole, saying so, and never damages it (G)',
          Bad, []),
    (   member(S, Said), sub_atom(S, _, _, _, 'could not grow') -> Grew = refused ; Grew = none ),
    check('...and a growth the address space refused is said (G)', Grew, refused).

lim_grow_sweep(_, _, [], [], []).
lim_grow_sweep(KB, G, [V|Vs], Bad, [WText|Said]) :-
    cocolog(C),
    format(atom(Cp), 'rm -rf ~w; cp -R ~w ~w', [G, KB, G]),
    shl([Cp]),
    lim_run(V, G, 'format(atom(A), \'~*c\', [60000, 120]), forall(between(1, 40, I), assertz(big(I, A)))',
            WText, WExit),
    format(atom(Back), '~w --embed ~w query "catch(aggregate_all(count, (big(_, A), atom_length(A, 60000)), N), error(existence_error(_, _), _), N = 0), findall(X, foo(X), Fs), write(back(N, Fs)), nl" 2>&1',
           [C, G]),
    shell(Back, BText, _),
    ( lim_answered(WExit, WText) -> Want = 'back(40,[1])' ; Want = 'back(0,[1])' ),
    findall(Why, lim_grow_bad(V, WText, WExit, BText, Want, Why), B0),
    lim_grow_sweep(KB, G, Vs, B1, Said),
    append(B0, B1, Bad).

lim_grow_bad(V, _, WExit, _, _, signal(V, write, WExit)) :- WExit >= 128.
lim_grow_bad(V, '', WExit, _, _, silent(V, write)) :- WExit =\= 0.
lim_grow_bad(V, WText, _, BText, _, said(V, Word)) :-
    member(Word, ['does not read as a clause', damaged]),
    once(( sub_atom(WText, _, _, _, Word) ; sub_atom(BText, _, _, _, Word) )).
lim_grow_bad(V, _, WExit, BText, Want, held(V, WExit, Want)) :- \+ sub_atom(BText, _, _, _, Want).

%% `cocolog --embed KB query GOAL' under `ulimit -v V' (kilobytes): its
%% output and its exit status
lim_run(V, KB, Goal, Text, Exit) :-
    cocolog(C),
    format(atom(Cmd), 'ulimit -v ~w; ~w --embed ~w query "~w" 2>&1', [V, C, KB, Goal]),
    shell(Cmd, Text, Exit, 60000).

%% the store in KB reads, under V
lim_reads(KB, V) :-
    lim_run(V, KB, 'foo(X)', Text, 0),
    sub_atom(Text, _, _, _, 'foo(1)').

%% the store's files are mapped, under V: whatever happens after
lim_maps(KB, V) :-
    lim_run(V, KB, 'foo(X)', Text, _),
    \+ sub_atom(Text, _, _, _, 'could not be mapped').

%% the least limit, to a megabyte, under which Holds holds of the store in
%% KB, between Lo, under which it does not, and Hi, under which it does, both
%% multiples of 1024
lim_floor(KB, Lo, Hi, Holds, F) :-
    (   Hi - Lo =< 1024
    ->  F = Hi
    ;   Mid is (Lo + Hi) // 2 // 1024 * 1024,
        (   call(Holds, KB, Mid) -> lim_floor(KB, Lo, Mid, Holds, F) ; lim_floor(KB, Mid, Hi, Holds, F) )
    ).

%% a read and, where How is `write', a write `assertz(bar(V))' of KB under
%% each limit V of Vs. Bad: what went wrong, a word of Not said among it;
%% Written: the limits whose writes answered (lim_answered); Said: every read's text
lim_sweep(_, [], _, _, [], [], []).
lim_sweep(KB, [V|Vs], How, Not, Bad, Written, [RText|Said]) :-
    lim_run(V, KB, 'foo(X)', RText, RExit),
    (   How == write
    ->  format(atom(W), 'assertz(bar(~w))', [V]),
        lim_run(V, KB, W, WText, WExit)
    ;   WText = none, WExit = none
    ),
    findall(Why, lim_bad(V, Not, RText, RExit, WText, WExit, Why), B0),
    ( lim_answered(WExit, WText) -> Written = [V|Written1] ; Written = Written1 ),
    lim_sweep(KB, Vs, How, Not, B1, Written1, Said),
    append(B0, B1, Bad).

%% a write said it was made: its query answered and exited 0. Exit 0 alone
%% is not that -- a query that answers `false.' exits 0 too, by `query''s
%% contract (test/argv.pl), and under a limit that broke the preload one
%% answered so having written nothing
lim_answered(0, Text) :- sub_atom(Text, _, _, _, '1 answer(s).').

lim_bad(V, _, _, RExit, _, _, signal(V, read, RExit)) :- RExit >= 128.
lim_bad(V, _, _, _, _, WExit, signal(V, write, WExit)) :- integer(WExit), WExit >= 128.
lim_bad(V, Not, RText, _, WText, _, said(V, Word)) :-
    member(Word, Not),
    once(( sub_atom(RText, _, _, _, Word) ; WText \== none, sub_atom(WText, _, _, _, Word) )).
lim_bad(V, _, RText, 0, _, _, read_wrong(V)) :- \+ sub_atom(RText, _, _, _, 'foo(1)').
lim_bad(V, _, '', RExit, _, _, silent(V, read)) :- RExit =\= 0.
lim_bad(V, _, _, _, '', WExit, silent(V, write)) :- WExit =\= 0.

%% KB, read with no limit, holds foo(1) and the facts bar(B) for B of Bs, in
%% that order, and no other
lim_holds(KB, Bs, Label) :-
    cocolog(C),
    format(atom(Back), '~w --embed ~w query "findall(X, foo(X), Fs), findall(Y, bar(Y), Bs), write(back(Fs/Bs)), nl" 2>&1',
           [C, KB]),
    shell(Back, Text, _),
    format(atom(Want), 'back(~w)', [[1]/Bs]),
    has(Label, Want, Text).

%% THE SAME STORE GROWN TO 256 MB, its data file extended by truncate(1)
%% and opened once with no limit, which makes its hexmap cover the pages
%% (16 MB): a mapping of it is then near the size of a limit cocolog runs
%% under, and the limits a megabyte past the floor take the store's
%% mappings away one by one -- the canonical pair's data file first, then
%% the private reader's
lim_big(D, KB, F, Before) :-
    cocolog(C),
    atom_concat(D, '/kb7', Big),
    format(atom(Cp), 'rm -rf ~w; cp -R ~w ~w && truncate -s 268435456 ~w/data.bin', [Big, KB, Big, Big]),
    shl([Cp]),
    format(atom(Open), '~w --embed ~w query true >/dev/null 2>&1', [C, Big]),
    shell(Open, _, OE),
    check('a store of 256 MB opens with no limit', OE, 0),
    V1 is F + 131072,
    lim_run(V1, Big, 'foo(X)', T1, E1),
    check('under the floor and 128 MB its data file cannot be mapped, and the store is refused (A)', E1, 1),
    has('...saying so', 'its data.bin of 268435456 bytes could not be mapped', T1),
    has('...and why', 'under an address-space limit of', T1),
    V2 is F + 409600,
    lim_run(V2, Big, 'foo(X)', T2, E2),
    check('under the floor and 400 MB its canonical pair maps and its private reader does not: it reads (B, C)', E2, 0),
    has('...what it holds', 'foo(1)', T2),
    findall(V, ( between(0, 10, I), V is F + 65536 + I * 65536 ), Vs),
    lim_sweep(Big, Vs, write, ['Unknown procedure', damaged], Bad, Written, _),
    check('across the limits where its mappings are refused no read finds it empty or damaged, none is silent, no process ends by a signal (A, B)',
          Bad, []),
    append(Before, Written, All),
    lim_holds(Big, All, '...and it holds foo(1) and exactly the writes that answered'),
    %% AND JUST PAST WHERE ITS FILES FIRST MAP the open's own allocations
    %% are refused: the engine's open threw std::bad_alloc, which nothing
    %% caught through 3.62.5 -- the process aborted
    lim_floor(Big, F, V2, lim_maps, M),
    findall(V, ( between(0, 16, I), V is M + I * 256 ), Ms),
    lim_sweep(Big, Ms, read, ['Unknown procedure', damaged], MBad, _, Said),
    check('just past where its files map no read finds it empty or damaged, none is silent, no process ends by a signal (A)',
          MBad, []),
    (   member(S, Said), sub_atom(S, _, _, _, ': out of memory, under an address-space limit of')
    ->  Loaded = refused
    ;   Loaded = none
    ),
    check('...and a store the open could not load for want of memory is refused, saying so (A)', Loaded, refused).

%% A ROW'S READ REFUSED ITS MEMORY IS SAID AS MEMORY, AND A QUERY THAT WROTE
%% NOTHING KEEPS ITS COMMIT (3.62.6). test/refuse.c refuses each request
%% the fetch of a row of 60 000 characters makes, in turn -- each of a page
%% or more, then each of any size, once and twice in a row (a growth
%% refused outright) -- and every run reads the row whole, or says memory
%% (resource_error(memory) for a catch to take, or the knowledge base's
%% refusal in memory's words), or ends as a host out of memory ends. Never
%% `the row at ordinal 0 does not read as a clause', which a fetch said of a
%% row the reader stopped on for want of memory (`coco_row_into_store',
%% `P': under `ulimit -v' the second run_isolated/2 on a thread, above, at
%% the limits where its fetch fell short), and never `commit failed', which
%% the query's end said for a read refused in a transaction that had
%% written nothing (`ce_wrote', `Q')
refused_read(D) :-
    section('a row whose read is refused its memory'),
    shell('uname -s', Sys, _),
    shell('getconf GNU_LIBC_VERSION 2>/dev/null', Libc, _),
    (   ( Sys == 'Darwin' ; \+ sub_atom(Libc, 0, _, _, glibc) )
    ->  format("   SKIP (test/refuse.c interposes glibc's allocator)~n", [])
    ;   atom_concat(D, '/refuse.so', Shim),
        ( exists_file('tools/cc/cc') -> Cc = 'tools/cc/cc' ; Cc = clang ),
        format(atom(Build), '~w -shared -fPIC -O3 -o ~w test/refuse.c 2>&1', [Cc, Shim]),
        shell(Build, Why, CcExit),
        check('test/refuse.c compiles', CcExit-Why, 0-''),
        (   CcExit =:= 0
        ->  rr_rows(D, Shim), rr_green(D, Shim), rr_dirty(D, Shim), rr_any(D, Shim),
            rr_cursor(D, Shim), rr_hint(D, Shim), rr_tail(D, Shim), rr_commit(D, Shim),
            rr_retract(D, Shim)
        ;   true
        )
    ).

rr_rows(D, Shim) :-
    cocolog(C),
    atom_concat(D, '/rr.pl', Fx),
    fixture(Fx, ['rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
                 'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
                 'mk :- format(atom(A), ''~*c'', [60000, 120]), assertz(big1(A)).',
                 'main :- rf_mark(''REFUSE_ON''), catch(( big1(X), atom_length(X, L), R = len(L) ), E, R = E), rf_off, format("rr(~q)~n", [R]).']),
    atom_concat(D, '/kbr', KB),
    format(atom(Mk), '~w --embed ~w query "use_module(''~w''), mk" >/dev/null 2>&1', [C, KB, Fx]),
    shl([Mk]),
    rr_envs(Shim, C, KB, Fx, '', 'REFUSE_MIN=4096', E4),
    rr_envs(Shim, C, KB, Fx, '', '', E0),
    append(E4, E0, Envs),
    rr_runs(Shim, C, KB, same, Fx, Envs, 0, Runs),
    findall(Why, ( member(run(Env, Text, Exit), Runs), rr_bad(rr, Env, Text, Exit, Why) ), Bad),
    check('each request of a row''s fetch refused in turn: the row read whole, memory said, or the host out of memory; never a row that does not read, never a commit refused (P, Q)',
          Bad, []),
    rr_said(Runs, 'rr(error(resource_error(memory)', Mem),
    check('...and a fetch refused its memory raises resource_error(memory) for a catch to take', Mem, said).

%% A GREEN TASK'S WRITE ON A WORKER THAT IS NOT THE CONNECTION'S OWNER, ITS
%% WRITE-THROUGH REFUSED, RAISES, AND THE NEXT WRITE ON THAT WORKER GOES
%% THROUGH (3.62.6): such a worker commits each write where it is made, and
%% a call the embedded store refused leaves the session's transaction
%% rolled back under it, which the store's commit refuses until the session
%% says so (`coco_zg_fail's rollback, `N'). Each request of a page or more
%% the task's two writes make is refused in turn, once and twice in a row;
%% the first write (60 000 characters) is refused or made, and the second
%% (gw2(1), after the refusals) is made every time. Refusals of any size
%% are `rr_any''s, below
rr_green(D, Shim) :-
    cocolog(C),
    atom_concat(D, '/rw.pl', Fx),
    rr_rw_fixture(Fx),
    atom_concat(D, '/kbw', KB),
    atom_concat(KB, '_count', KBc),
    rr_envs(Shim, C, KBc, Fx, 'COCOLOG_GREEN_WORKERS=2', 'REFUSE_MIN=4096', Envs),
    rr_runs(Shim, C, KB, fresh, Fx, Envs, 0, Runs),
    findall(Why, ( member(run(Env, Text, Exit), Runs), rr_bad(rw, Env, Text, Exit, Why) ), Bad),
    check('each request of a page or more a green non-owner''s writes make, refused in turn: the first write made or raised, the second made, no signal (N)',
          Bad, []),
    rr_said(Runs, 'rw(resource_error(knowledge_base), ok)', Raised),
    check('...and a write-through refused there raises resource_error(knowledge_base) in assertz/1', Raised, said).

%% the green task's two writes, the first 60 000 characters inside the
%% shim's stretch, the second after it
rr_rw_fixture(Fx) :-
    fixture(Fx, ['rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
                 'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
                 'w :- format(atom(A), ''~*c'', [60000, 120]), rf_mark(''REFUSE_ON''), catch(( assertz(gw1(A)), R1 = ok ), E1, R1 = E1), rf_off, catch(( assertz(gw2(1)), R2 = ok ), E2, R2 = E2), ( R1 == ok -> S1 = ok ; R1 = error(F, _) -> S1 = F ; S1 = R1 ), format("rw(~q, ~q)~n", [S1, R2]).',
                 'main :- async_run(( go(w, T), await(T) )).']).

%% THE OWNER'S NOTE OF A CHANGED PREDICATE REFUSED IS SAID IN MEMORY'S WORDS
%% (3.62.6, `coco_zg_mark_dirty', `D'): the host batches its writes, and
%% the list it notes them on grows by realloc(3); each request of 128 bytes
%% an assert makes is refused in turn, and an assert it refuses raises
%% resource_error(knowledge_base) saying memory -- through 3.62.5 the
%% assert succeeded over a clause the batch never held, and with the
%% refusal raised and no words of its own the reason was the connection's
%% last error, which had nothing to do with it
rr_dirty(D, Shim) :-
    cocolog(C),
    atom_concat(D, '/rd.pl', Fx),
    rr_rd_fixture(Fx),
    atom_concat(D, '/kbd', KB),
    atom_concat(KB, '_count', KBc),
    rr_envs(Shim, C, KBc, Fx, '', 'REFUSE_SIZE=128', Envs),
    rr_runs(Shim, C, KB, fresh, Fx, Envs, 0, Runs),
    findall(Why, ( member(run(Env, Text, Exit), Runs), rr_bad(rd, Env, Text, Exit, Why) ), Bad),
    check('each request of 128 bytes an owner''s assert makes, refused in turn: the assert made, or refused in memory''s words, no signal (D)',
          Bad, []),
    rr_said(Runs, 'rd(error(resource_error(knowledge_base)', Raised),
    check('...and the assert whose note is refused raises resource_error(knowledge_base)', Raised, said),
    %% A CONSULTED CLAUSE THE KNOWLEDGE BASE REFUSED IS SAID AS ITS REFUSAL
    %% AND TAKEN BACK (3.62.6, the consult's report and
    %% `coco_assert_take_back', `K', `T'): consult/1 as a goal writes through,
    %% and a clause whose note the owner could not make was `not a clause'
    %% through 3.62.5, and stayed in this process with no row behind it
    atom_concat(D, '/rc.pl', Fc),
    atom_concat(D, '/gc.pl', Gc),
    fixture(Gc, ['gc(1).']),
    format(atom(Main), 'main :- rf_mark(''REFUSE_ON''), catch(consult(''~w''), _, true), rf_off, ( catch(gc(X), _, fail) -> format("rc(~~q)~~n", [X]) ; format("rc(none)~~n", []) ).', [Gc]),
    fixture(Fc, ['rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
                 'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
                 Main]),
    atom_concat(D, '/kbc', KC),
    atom_concat(KC, '_count', KCc),
    rr_envs(Shim, C, KCc, Fc, '', 'REFUSE_SIZE=128', CEnvs),
    rr_runs(Shim, C, KC, fresh, Fc, CEnvs, 0, CRuns),
    findall(Why, ( member(run(Env, Text, Exit), CRuns), rr_bad(rc, Env, Text, Exit, Why) ), CBad),
    check('each request of 128 bytes a consulted clause''s write makes, refused in turn: the clause made, or refused in the knowledge base''s words and gone, no signal (K, T)',
          CBad, []),
    rr_said(CRuns, 'the knowledge base refused the clause: ', CSaid),
    check('...and the consult says the clause it could not write', CSaid, said).

%% the owner's assert inside the shim's stretch
rr_rd_fixture(Fx) :-
    fixture(Fx, ['rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
                 'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
                 'main :- rf_mark(''REFUSE_ON''), catch(( assertz(gd(1)), R = ok ), E, R = E), rf_off, format("rd(~q)~n", [R]).']).

%% A WRITE REFUSED ANY REQUEST, UNDER THE ENGINE'S LOCKS OR NOT, ENDS WITH NO
%% SIGNAL AND LEAVES A STORE THAT READS (3.62.7, ZiguratIP 1.0.4). Each
%% request of any size the green non-owner's two writes make (rw.pl, from
%% `rr_green') and the owner's assert (rd.pl, from `rr_dirty') is refused in
%% turn, once and two, three and four times in a row, each run over a store
%% of its own, which a second process then reads: it answers, says memory,
%% or ends as a host out of memory ends, and the store reads back. Through
%% 3.62.6, on ZiguratIP 1.0.3, 16 of rw.pl's 93 requests refused once hung:
%% a `new' refused under the page list's and the free list's locks left both
%% held, and the rollback after it waited for ever on them. 14 aborted, a
%% refusal in the commit's index entries a bad_alloc nothing caught; and 6
%% were a SIGSEGV, cursor_walk writing its page snapshot through the null a
%% calloc answered. Four in a row reach a begin refused after a rollback
%% (`ce_begin'): bare, its bad_alloc aborted 11 of rw.pl's runs
rr_any(D, Shim) :-
    cocolog(C),
    atom_concat(D, '/rwa.pl', Fw),
    rr_rw_fixture(Fw),
    atom_concat(D, '/rda.pl', Fd),
    rr_rd_fixture(Fd),
    atom_concat(D, '/kba', KA),
    atom_concat(KA, '_count', KAc),
    rr_envs(Shim, C, KAc, Fw, 'COCOLOG_GREEN_WORKERS=2', '', [1, 2, 3, 4], EnvsW),
    rr_back_runs(Shim, C, KA, Fw, EnvsW, 0, RunsW),
    findall(Why, ( member(run(Env, Text, Exit, Back), RunsW), rr_any_bad(rw, Env, Text, Exit, Back, Why) ), BadW),
    check('each request of any size a green non-owner''s writes make, refused in turn: no hang, no signal, an answer or memory said, and the store reads back',
          BadW, []),
    atom_concat(D, '/kbo', KO),
    atom_concat(KO, '_count', KOc),
    rr_envs(Shim, C, KOc, Fd, '', '', [1, 2, 3, 4], EnvsD),
    rr_back_runs(Shim, C, KO, Fd, EnvsD, 0, RunsD),
    findall(Why, ( member(run(Env, Text, Exit, Back), RunsD), rr_any_bad(rd, Env, Text, Exit, Back, Why) ), BadD),
    check('...and each of any size the owner''s assert makes: the same',
          BadD, []).

%% A PAGE WALK REFUSED ITS SNAPSHOT GIVES ITS CURSOR BACK (3.62.7, ZiguratIP
%% 1.0.4, `CursorCount'): a thread holds sixteen cursors at most, and a walk
%% that threw kept the one it took, so after sixteen refused walks every
%% walk on the thread was refused, `maximum cursor count', with memory to
%% spare. Every request of 16 bytes -- a walk's page snapshot over a store
%% this small -- is refused while the first query of a REPL asserts twenty
%% new predicates, which leaves its transaction refused; the second query's
%% write, made after the refusals, is committed and read back by a second
%% process. THE QUERY WRITES FIRST, by a procedure call of its own: a
%% transaction that has written nothing holds no commit (3.62.6), and since
%% 3.63.1 a fetch writes nothing of the turn's (`coco_zg_fetch') -- through
%% 3.63.0 each fetch wrote the asserts before it, and the walks after them
%% found a transaction that had written
rr_cursor(D, Shim) :-
    cocolog(C),
    atom_concat(D, '/rcw.pl', Fx),
    fixture(Fx, ['rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
                 'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
                 'wr(I) :- atom_concat(q, I, P), T =.. [P, I], catch(assertz(T), _, true).',
                 'main :- zigurat_call(''cocolog::forget_clauses'', [main, rs, 1]), rf_mark(''REFUSE_ON''), forall(between(1, 20, I), wr(I)), rf_off.']),
    atom_concat(D, '/kbcw', KB),
    format(atom(Cmd), 'printf ''%s\\n'' "use_module(''~w''), main." "assertz(zc(1))." | env LD_PRELOAD=~w REFUSE_SIZE=16 REFUSE_N=1 REFUSE_RUN=0 ~w --embed ~w 2>&1',
           [Fx, Shim, C, KB]),
    shell(Cmd, Text, _, 60000),
    ( sub_atom(Text, _, _, _, 'commit failed') -> Refused = refused ; Refused = Text ),
    check('a REPL query whose walks were refused their memory is refused its commit', Refused, refused),
    format(atom(Rd), '~w --embed ~w query "findall(X, catch(zc(X), _, fail), L), write(L), nl" 2>&1', [C, KB]),
    shell(Rd, Back, _, 15000),
    ( sub_atom(Back, 0, _, _, '[1]') -> Kept = kept ; Kept = Text-Back ),
    check('...and the next query''s write, its memory back, is committed: no walk is refused the cursor a refused walk took',
          Kept, kept).

%% A B-TREE'S APPEND HINT THERE IS NO MEMORY FOR IS NO HINT (3.62.7,
%% ZiguratIP 1.0.4, `bt_tail_put'): the hint is a cache, and its refusal
%% threw out of the map of an entry already in the tree, which refused the
%% write. Its first two growths, of 56 and 112 bytes, are the only requests
%% of those sizes the writes make; each refused, the writes are made and
%% read back
rr_hint(D, Shim) :-
    cocolog(C),
    atom_concat(D, '/rwh.pl', Fw),
    rr_rw_fixture(Fw),
    atom_concat(D, '/rdh.pl', Fd),
    rr_rd_fixture(Fd),
    findall(Why, ( member(Kind-Fx-World-Want, [rw-Fw-'COCOLOG_GREEN_WORKERS=2'-'rows(2)', rd-Fd-''-'rows(1)']),
                   member(Size, [56, 112]),
                   rr_size_bad(C, Shim, D, Kind, Fx, World, Size, Want, Why) ), Bad),
    check('each of a B-tree hint''s two requests refused, the writes are made and read back', Bad, []).

%% A COMMIT'S TAIL THERE IS NO MEMORY FOR REFUSES NO COMMIT (3.62.7,
%% ZiguratIP 1.0.4, `log_after_sync'): once a commit's intention is on disk
%% nothing throws, and the list of the store's log indexes it makes there is
%% the one request of 8 bytes and the one of 16 that a green task's second
%% write to a predicate makes; each refused, the write is made and reads
%% back. Unguarded, its throw came after the intention: the commit was
%% refused and rolled back, and through 3.62.6, which caught nothing at a
%% commit, the process aborted
rr_tail(D, Shim) :-
    cocolog(C),
    atom_concat(D, '/rwt.pl', Ft),
    fixture(Ft, ['rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
                 'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
                 'w :- assertz(gw1(0)), rf_mark(''REFUSE_ON''), catch(( assertz(gw1(1)), R = ok ), E, R = E), rf_off, format("rt(~q)~n", [R]).',
                 'main :- async_run(( go(w, T), await(T) )).']),
    findall(Why, ( member(Size, [8, 16]),
                   rr_size_bad(C, Shim, D, rt, Ft, 'COCOLOG_GREEN_WORKERS=2', Size, 'rows(2)', Why) ), Bad),
    check('each of a commit tail''s two requests refused after its intention, the write is made and read back', Bad, []).

%% A COMMIT THE STORE REFUSED IS NO SUCCESS (3.64.6). test/refuse.c refuses
%% each request a `-s' script's writes and the commit after them make, in
%% turn, once and twice in a row -- the stretch begins at the program's
%% mark and runs to the process's end, the commit inside it -- each run
%% over a store of its own, which a second process reads: a run that exits
%% 0 left all twelve of its clauses whole, and none left part of them.
%% Through 3.64.5 a commit refused after `main' proved said `commit failed'
%% and exited 0, its store holding none of the twelve (`-s''s status was
%% main's answer, `S'). And `start' and `drop', each request of the whole
%% process refused in turn (REFUSE_ALL: they run no program to mark a
%% stretch with): a `start' that exits 0 left its machine listed, a `drop'
%% that exits 0 left it gone, and none ends by a signal. Through 3.64.5
%% each printed its word and exited 0 whatever its commit said (`T', `U'),
%% and a host whose machine's table of atoms was refused probed a table
%% that was not there, a SIGSEGV (`coco_machine_init', `V'). A refusal
%% before main -- the C++ runtime's, ZiguratIP's static initialisers -- is
%% an abort that says std::bad_alloc, which nothing of cocolog's can see.
rr_commit(D, Shim) :-
    cocolog(C),
    atom_concat(D, '/rcm', Dir),
    shl(['mkdir -p ', Dir]),
    atom_concat(Dir, '/rcm.pl', Fx),
    fixture(Fx, ['rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
                 'rcm_long(I, A) :- N is 200 + I * 37, length(Cs, N), maplist(=(0\'a), Cs), atom_codes(A, Cs).',
                 'main :- findall(I-A, ( between(1, 12, I), rcm_long(I, A) ), Ps), rf_mark(\'REFUSE_ON\'), forall(member(I-A, Ps), assertz(rcm(I, A))).']),
    atom_concat(Dir, '/rcm.sh', Sweep), rcm_sweep(Sweep),
    sh_join(['sh ', Sweep, ' ', C, ' ', Shim, ' ', Fx, ' ', Dir], Cmd),
    shell(Cmd, Out, _, 600000),
    check('each request of a script''s writes and its commit refused in turn: exit 0 only with its twelve clauses kept, never part of them, no signal (S, X)',
          Out, clean),
    atom_concat(Dir, '/rst.sh', Machines), rst_sweep(Machines),
    forall(member(Verb-Title,
                  [start-'each request of a `start'' refused in turn: exit 0 only with its machine listed, no signal (T, V, W, Y)',
                   drop-'each request of a `drop'' refused in turn: exit 0 only with its machine gone, no signal (U)']),
           ( sh_join(['sh ', Machines, ' ', C, ' ', Shim, ' ', Dir, ' ', Verb], MCmd),
             shell(MCmd, MOut, _, 600000),
             check(Title, MOut, clean) )),
    atom_concat(Dir, '/stp.sh', Steps), stp_sweep(Steps),
    forall(member(Filter-Title,
                  ['REFUSE_SIZE=2048'-'each request of a `step'' the size of a machine''s first table refused in turn: exit 0 only with its machine gone, a refused turn LOST with its machine there to step again, no signal (R, P, O, M)',
                   'REFUSE_MIN=4096'-'each request of 4096 bytes or more of a `step'' refused in turn: the same (O, M)',
                   'REFUSE_MIN=4096 big'-'and of a `step'' that thaws a blob of many kilobytes and suspends again: exit 2 only with its machine there, a refused turn LOST saying memory (P, Q, N, L, O, M)']),
           ( sh_join(['sh ', Steps, ' ', C, ' ', Shim, ' ', Dir, ' ', Filter], SCmd),
             shell(SCmd, SOut, _, 600000),
             check(Title, SOut, clean) )).

%% A RETRACT THE KNOWLEDGE BASE REFUSED TO WRITE RAISES, AND ITS CLAUSE
%% STAYS (3.64.7), as an assertz's refused write raises (3.62.6): through
%% 3.64.6 the retract went on over the refusal, its clause gone from the
%% program and still in the database, where a second process read it.
%% Eight shapes stand in the stretch the shim refuses in, the first four a
%% predicate each: a retract with no call open (`coco_retract_at''s plain
%% path, `R1'), one under an open call (its clause dead in place, `R2'),
%% retractall/1 where a death waits (the sweep, told before it, `R3', and
%% raised in retractall/1's context, `C'), retractall/1 of every clause of
%% a fourth predicate (3.78.11, `coco_retractall_walk': each match dead in
%% place and the database told once, every one given back where the write
%% is refused, `R4'), retract/1's walk and its retry
%% (`coco_db_walk', `coco_db_retry': `W1', `W2'), a single-sided rule
%% asserted over the rules a fetch read back (`F': through 3.64.6 every rule
%% read back put another last clause after it, and the rule stood behind
%% one; `A1': one write, where 3.64.6's three -- the rule, the old last
%% clause retracted, a new one -- were refused apart), and a predicate's
%% first rule by assertz and by asserta (`coco_ssu_add''s shapes 3 and 4,
%% one write with the last clause: `A3'). Each shape says it was done and
%% was, or says resource_error(knowledge_base) in its predicate's context
%% -- or the context of the fetch an assert reads first -- and was not, or
%% says memory; what the program holds after is what a second process
%% reads (its lists alone where the run said memory: a growth given less
%% than it asked is raised at the next step, or at the store's next put,
%% which may be a goal of `left/1''s); and no rule ever stands without its
%% last clause, which a goal no rule matches fails through. The host
%% batches (each request of 128 bytes, its dirty list's, refused in turn); a
%% green task, on a worker that is not the connection's owner, writes where
%% it is (each of a page or more); the first rules' writes there, and the
%% retract that retries -- its first two answers taken and failed past, the
%% third its answer -- each of any size. The open-call shape of a rule's
%% assert (`A2') is test/files/ssu_assert.pl's, held to swipl
rr_retract(D, Shim) :-
    cocolog(C),
    atom_concat(D, '/rrt', Dir),
    shl(['mkdir -p ', Dir]),
    atom_concat(Dir, '/rt.pl', Fx), rt_fixture(Fx),
    atom_concat(Dir, '/rrt.sh', Sweep), rrt_sweep(Sweep),
    forall(member(Goal-Filter-World-Title,
                  [hmain-'REFUSE_SIZE=128'-'X=1'-'each request of 128 bytes the host''s retracts and asserts make refused in turn: done and said, or refused and said in its context, the program''s view a second process''s (R1, R4, W1, F)',
                   gmain-'REFUSE_MIN=4096'-'COCOLOG_GREEN_WORKERS=2'-'...a green task''s writes, each request of a page or more: the same, never a rule without its last clause (R1, R2, R3, R4, C, W1, F, A1)',
                   gfirst-'X=2'-'COCOLOG_GREEN_WORKERS=2'-'...and its first rules, by assertz and by asserta, each request of any size (A3)',
                   gretry-'X=3'-'COCOLOG_GREEN_WORKERS=2'-'...and its retract/1 that retries, each request of any size: an answer the store refused raises, never an answer (W2)']),
           ( sh_join(['sh ', Sweep, ' ', C, ' ', Shim, ' ', Fx, ' ', Dir, ' ', Goal, ' ', Filter, ' ', World], Cmd),
             shell(Cmd, Out, _, 600000),
             ( sub_atom(Out, 0, _, _, 'clean of ') -> Got = clean ; Got = Out ),
             check(Title, Got, clean) )).

%% the seven shapes, a status each recorded in the stretch and its fact
%% read after it, where no request is refused (`said/1'); the lists, the
%% rule and the first rules as a program sees them (`left/1': `store' is a
%% second process's read). `open(G)' is a rule a goal no rule matches G
%% through -- it failed or succeeded where it should raise
%% existence_error(matching_rule, _)
rt_fixture(Fx) :-
    fixture(Fx,
            [ 'rf_mark(N) :- catch(( getenv(N, _) -> true ; true ), _, true).',
              'rf_off :- rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF''), rf_mark(''REFUSE_OFF'').',
              'rt_word(ok, ok) :- !.',
              'rt_word(error(resource_error(K), C), resource_error(K)-P) :- nonvar(C), C = context(P, _), nonvar(P), !.',
              'rt_word(error(F, _), F) :- !.',
              'rt_word(R, R).',
              'rt_do(G, W, W-S) :- catch(( once(G), R = ok ), E, R = E), rt_word(R, S).',
              'rt_rule(G, S) :- catch(( G -> S = ok ; S = fail ), E, ( E = error(existence_error(T, _), _) -> S = T ; E = error(F, _) -> S = F ; S = E )).',
              'rt_state(P, S) :- A =.. [P, big(1)], B =.. [P, small], rt_rule(A, SA), rt_rule(B, SB), ( SA \\== ok -> S = none ; SB == matching_rule -> S = ok ; ( SB == ok ; SB == fail ) -> S = open(SB) ; S = SB ).',
              'rt_has(G, F) :- ( catch(G, _, fail) -> F = not_done ; F = done ).',
              'rt_fact(plain, F) :- rt_has(ga(1), F).',
              'rt_fact(tomb, F) :- rt_has(gb(2), F).',
              'rt_fact(sweep, F) :- rt_has(gb(3), F).',
              'rt_fact(retry, F) :- rt_has(gc(5), F).',
              'rt_fact(many, F) :- rt_has(gd(2), F).',
              'rt_fact(rule, F) :- rt_rule(gr(small), S), ( S == ok -> F = done ; F = not_done(S) ).',
              'rt_fact(first, F) :- rt_state(gn, S), ( S == ok -> F = done ; S == none -> F = not_done ; F = S ).',
              'rt_fact(firsta, F) :- rt_state(gm, S), ( S == ok -> F = done ; S == none -> F = not_done ; F = S ).',
              'said(Rs) :- forall(member(W-S, Rs), ( rt_fact(W, F), format("~w(~q, ~q)~n", [W, S, F]) )).',
              'rt_list(G, L) :- findall(X, ( catch(call(G, Y), _, fail), ( Y = big(_) -> X = big ; X = Y ) ), L).',
              'left(W) :- rt_list(ga, A), rt_list(gb, B), rt_list(gc, C), rt_list(gd, Dd), rt_rule(gr(small), R), rt_state(gn, N), rt_state(gm, M), format("~w(~q, ~q, ~q, ~q, ~q, ~q, ~q)~n", [W, A, B, C, Dd, R, N, M]).',
              'shapes([P, T, Sw, Ma, Re, Ru|Fs]) :- rt_do(retract(ga(1)), plain, P), rt_do(forall(gb(X), ( X == 2 -> retract(gb(2)) ; true )), tomb, T), rt_do(retractall(gb(3)), sweep, Sw), rt_do(retractall(gd(_)), many, Ma), rt_do(( retract(gc(Y)), integer(Y), Y >= 5 ), retry, Re), rt_do(assertz((gr(small) => true)), rule, Ru), firsts(Fs).',
              'firsts([Fi, Fa]) :- rt_do(assertz((gn(big(_)) => true)), first, Fi), rt_do(asserta((gm(big(_)) => true)), firsta, Fa).',
              'retries([Re]) :- rt_do(( retract(gc(Y)), integer(Y), Y >= 5 ), retry, Re).',
              'seed :- format(atom(A), ''~*c'', [60000, 120]), forall(member(G-L, [ga-[1], gb-[1, 2, 3], gc-[4, 5, 6], gd-[1, 2, 3]]), forall(member(X, [big(A)|L]), ( T =.. [G, X], assertz(T) ))), assertz((gr(big(A)) => true)).',
              'warm :- once(ga(_)), once(gb(_)), once(gc(_)), once(gd(_)).',
              'w(G) :- warm, rf_mark(''REFUSE_ON''), call(G, Rs), rf_off, said(Rs), left(left).',
              'hmain :- warm, rf_mark(''REFUSE_ON''), shapes(Rs), rf_off, said(Rs), left(host).',
              'gmain :- catch(async_run(( go(w(shapes), T), await(T) )), _, true), left(host).',
              'gfirst :- catch(async_run(( go(w(firsts), T), await(T) )), _, true), left(host).',
              'gretry :- catch(async_run(( go(w(retries), T), await(T) )), _, true), left(host).' ]).

%% rrt.sh COCOLOG SHIM FILE DIR GOAL FILTER WORLD: GOAL of FILE over a copy of
%% a store FILE's seed/0 made, once for each request in its stretch FILTER
%% names, that one and then that one and the next refused, and the copy
%% read by a process with no shim. Prints `clean of N' when no run was
%% wrong and one write was refused and said so
rrt_sweep(Path) :-
    fixture(Path,
            [ 'c=$1; shim=$2; f=$3; d=$4; g=$5; flt=$6; world=$7',
              'rm -rf $d/t0; $c --embed $d/t0 query "use_module(\'$f\'), seed" > /dev/null 2>&1',
              'rm -rf $d/tc; cp -r $d/t0 $d/tc',
              'n=$( env $world $flt REFUSE_REPORT=1 LD_PRELOAD=$shim $c --embed $d/tc query "use_module(\'$f\'), $g" 2>&1 >/dev/null | sed -n \'s/^REFUSE count //p\' )',
              '[ -n "$n" ] && [ "$n" -gt 0 ] || { echo nocount; exit 0; }',
              'bad=""; refused=0',
              'for run in 1 2; do',
              '  i=1',
              '  while [ $i -le $n ]; do',
              '    kb=$d/t_$i; rm -rf $kb; cp -r $d/t0 $kb',
              '    timeout 60 env $world $flt REFUSE_N=$i REFUSE_RUN=$run LD_PRELOAD=$shim $c --embed $kb query "use_module(\'$f\'), $g" > $kb.out 2>&1; x=$?',
              '    s=$( timeout 30 $c --embed $kb query "use_module(\'$f\'), left(store)" 2>&1 | sed -n \'s/^store//p\' )',
              '    p=$( sed -n \'s/^host//p\' $kb.out ); [ -z "$p" ] && p=$( sed -n \'s/^left//p\' $kb.out )',
              '    mem=""; grep -q -e \'out of memory\' -e \'Not enough resources: memory\' -e \'resource_error(memory)\' $kb.out && mem=1',
              '    grep -E \'^(plain|tomb|sweep|many|retry|rule|first|firsta)\\(\' $kb.out > $kb.said',
              '    while read -r l; do',
              '      case "$l" in',
              '        *"(ok, done)") ;;',
              '        "plain(resource_error(knowledge_base)-(system:retract/1), not_done)"|"tomb(resource_error(knowledge_base)-(system:retract/1), not_done)"|"retry(resource_error(knowledge_base)-(system:retract/1), not_done)"|"sweep(resource_error(knowledge_base)-(system:retractall/1), not_done)"|"many(resource_error(knowledge_base)-(system:retractall/1), not_done)") refused=1 ;;',
              '        "rule(resource_error(knowledge_base)-(system:assertz/1), not_done(matching_rule))"|"first(resource_error(knowledge_base)-(system:assertz/1), not_done)"|"firsta(resource_error(knowledge_base)-(system:asserta/1), not_done)") refused=1 ;;',
              '        "rule(resource_error(knowledge_base)-gr/1, not_done(matching_rule))"|"first(resource_error(knowledge_base)-gn/1, not_done)"|"firsta(resource_error(knowledge_base)-gm/1, not_done)") ;;',
              '        *"(resource_error(memory)"*) case "$l" in *open*) bad="$bad #$run.$i:$l";; esac ;;',
              '        *) [ -n "$mem" ] && case "$l" in *open*) false;; *"(ok, "*|*"(resource_error("*) true;; *) false;; esac || bad="$bad #$run.$i:$l" ;;',
              '      esac',
              '    done < $kb.said',
              '    if [ $x -ge 124 ]; then bad="$bad #$run.$i:exit$x"',
              '    elif [ -n "$p" ]; then',
              '      case "$p$s" in *open*) bad="$bad #$run.$i:open$p$s";; esac',
              '      if [ -n "$mem" ]; then [ "${p%], *}" = "${s%], *}" ] || bad="$bad #$run.$i:$p$s"',
              '      else [ "$p" = "$s" ] || bad="$bad #$run.$i:$p$s"; fi',
              '    elif [ $x != 2 ] && [ -z "$mem" ]; then bad="$bad #$run.$i:none:$x"; fi',
              '    rm -rf $kb $kb.out $kb.said',
              '    i=$((i + 1))',
              '  done',
              'done',
              'if [ -n "$bad" ]; then echo "wrong of $n:$bad" | cut -c1-600',
              'elif [ $refused = 1 ]; then echo "clean of $n"',
              'else echo "none refused of $n"; fi' ]).

%% stp.sh COCOLOG SHIM DIR FILTER [big]: `step' of a machine started in a
%% store of its own, once for each request the whole process makes that
%% FILTER names -- REFUSE_SIZE=N, REFUSE_MIN=N: a step's are some sixteen
%% thousand, the preload's among them -- that one and then that one and the
%% next refused, and the store read by a process with no shim: its `list',
%% and a second `step' of a machine the first did not finish. A turn refused
%% is LOST (3), saying memory's words, and exit 1 is the store's open
%% refused before the turn began, which says so. A step finishes the
%% machine (0); BIG seeds one
%% suspended part way with a list and an atom of 3000 on its heap, which a
%% step thaws from a blob of many kilobytes and suspends again (2). Prints
%% clean when no run was wrong and one turn was LOST
stp_sweep(Path) :-
    fixture(Path,
            [ 'c=$1; shim=$2; d=$3; flt=$4; big=$5',
              'if [ -n "$big" ]; then',
              '  g="length(L, 3000), maplist(=(97), L), atom_codes(A, L), between(1, 100000, I), I >= 100000"; want=2; on=1',
              'else',
              '  g="X = f(aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, [b, c, d]), atom(a)"; want=0; on=0',
              'fi',
              'rm -rf $d/sseed; $c --embed $d/sseed start rsm "$g" > /dev/null 2>&1',
              'if [ -n "$big" ]; then $c --embed $d/sseed --steps 20000 step rsm > /dev/null 2>&1; fi',
              'rm -rf $d/s0; cp -r $d/sseed $d/s0',
              'n=$( env $flt REFUSE_ALL=1 REFUSE_REPORT=1 LD_PRELOAD=$shim $c --embed $d/s0 step rsm 2>&1 >/dev/null | sed -n \'s/^REFUSE count //p\' )',
              '[ -n "$n" ] && [ "$n" -gt 0 ] || { echo nocount; exit 0; }',
              'bad=""; lost=0',
              'for run in 1 2; do',
              '  i=1',
              '  while [ $i -le $n ]; do',
              '    kb=$d/s_$i; rm -rf $kb; cp -r $d/sseed $kb',
              '    timeout 30 env $flt REFUSE_ALL=1 REFUSE_N=$i REFUSE_RUN=$run LD_PRELOAD=$shim $c --embed $kb step rsm > $kb.out 2>&1; x=$?',
              '    l=$( timeout 30 $c --embed $kb list 2>/dev/null | grep -c " rsm " )',
              '    case "$x" in',
              '      0|2) if [ $x != $want ] || [ "$l" != $on ]; then bad="$bad #$run.$i:$x:$l"; fi ;;',
              '      1|3) [ $x = 3 ] && lost=1',
              '         if [ $x = 1 ] && ! grep -q "cannot open the embedded store" $kb.out; then bad="$bad #$run.$i:1:$(grep -v \'^REFUSE\' $kb.out | head -c 60 | tr \'\\n\' \' \')";',
              '         elif [ $x = 3 ] && ! grep -q "memory" $kb.out; then bad="$bad #$run.$i:3:unsaid:$(grep -v \'^REFUSE\' $kb.out | head -c 40 | tr \'\\n\' \' \')";',
              '         elif [ "$l" != 1 ]; then bad="$bad #$run.$i:$x:$l";',
              '         else timeout 30 $c --embed $kb step rsm > $kb.step 2>&1; y=$?',
              '           [ $y = $want ] || bad="$bad #$run.$i:again:$y:$(head -c 60 $kb.step | tr \'\\n\' \' \')"; fi ;;',
              '      134) grep -q "std::bad_alloc" $kb.out || bad="$bad #$run.$i:134" ;;',
              '      *) bad="$bad #$run.$i:$x:$l" ;;',
              '    esac',
              '    rm -rf $kb $kb.out $kb.step',
              '    i=$((i + 1))',
              '  done',
              'done',
              'if [ -n "$bad" ]; then echo "wrong of $n:$bad" | cut -c1-400',
              'elif [ $lost = 1 ]; then echo clean',
              'else echo "none lost of $n"; fi' ]).

%% rcm.sh COCOLOG SHIM FILE DIR: the script FILE over a store of its own,
%% once for each request from its mark to its end, that one and then that
%% one and the next refused, and the store read back by a process with no
%% shim. Prints clean when no run was wrong and one said `commit failed'
rcm_sweep(Path) :-
    fixture(Path,
            [ 'c=$1; shim=$2; f=$3; d=$4',
              'rm -rf $d/kb0',
              'n=$( REFUSE_REPORT=1 LD_PRELOAD=$shim $c --embed $d/kb0 -s $f 2>&1 >/dev/null | sed -n \'s/^REFUSE count //p\' )',
              '[ -n "$n" ] && [ "$n" -gt 0 ] || { echo nocount; exit 0; }',
              'bad=""; refused=0',
              'for run in 1 2; do',
              '  i=1',
              '  while [ $i -le $n ]; do',
              '    kb=$d/kb_$i; rm -rf $kb',
              '    timeout 30 env REFUSE_N=$i REFUSE_RUN=$run LD_PRELOAD=$shim $c --embed $kb -s $f > $kb.out 2>&1; x=$?',
              '    r=$( timeout 30 $c --embed $kb query "catch(( aggregate_all(count, ( rcm(I, A), atom_length(A, L), L =:= 200 + I * 37 ), W), aggregate_all(count, rcm(_, _), T) ), _, ( W = 0, T = 0 )), format(\'kept(~w,~w)~n\', [W, T])" 2>/dev/null | grep -o \'kept([0-9]*,[0-9]*)\' )',
              '    case "$x $r" in',
              '      "0 kept(12,12)") ;;',
              '      [12]" kept(0,0)") if grep -q "commit failed" $kb.out; then refused=1; fi ;;',
              '      [12]" kept(12,12)") ;;',
              '      *) bad="$bad #$run.$i:$x:$r" ;;',
              '    esac',
              '    rm -rf $kb $kb.out',
              '    i=$((i + 1))',
              '  done',
              'done',
              'if [ -n "$bad" ]; then echo "wrong of $n:$bad" | cut -c1-400',
              'elif [ $refused = 1 ]; then echo clean',
              'else echo "no commit refused of $n"; fi' ]).

%% rst.sh COCOLOG SHIM DIR VERB: `start' or `drop' of a machine over a
%% store of its own (for a drop, a copy of one the machine was started in),
%% once for each request the whole process makes, that one and then that
%% one and the next refused, and the store read by a process with no shim:
%% its `list', and a started machine's `step', which must thaw it. Prints
%% clean when no run was wrong and one was refused
rst_sweep(Path) :-
    fixture(Path,
            [ 'c=$1; shim=$2; d=$3; verb=$4',
              'g="X = f(aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, [b, c, d]), atom(a)"',
              'if [ $verb = start ]; then want=1; else want=0; fi',
              'go() { k=$1; shift; if [ $verb = start ]; then timeout 30 env "$@" $c --embed $k start rsm "$g"; else timeout 30 env "$@" $c --embed $k drop rsm; fi; }',
              'seed() { rm -rf $1; if [ $verb = drop ]; then cp -r $d/seed $1; fi; }',
              'rm -rf $d/seed; $c --embed $d/seed start rsm "$g" > /dev/null 2>&1',
              'seed $d/m0',
              'n=$( go $d/m0 REFUSE_ALL=1 REFUSE_REPORT=1 LD_PRELOAD=$shim 2>&1 >/dev/null | sed -n \'s/^REFUSE count //p\' )',
              '[ -n "$n" ] && [ "$n" -gt 0 ] || { echo nocount; exit 0; }',
              'bad=""; refused=0',
              'for run in 1 2; do',
              '  i=1',
              '  while [ $i -le $n ]; do',
              '    kb=$d/m_$i; seed $kb',
              '    go $kb REFUSE_ALL=1 REFUSE_N=$i REFUSE_RUN=$run LD_PRELOAD=$shim > $kb.out 2>&1; x=$?',
              '    l=$( timeout 30 $c --embed $kb list 2>/dev/null | grep -c " rsm " )',
              '    case "$x" in',
              '      0) if [ "$l" != $want ]; then bad="$bad #$run.$i:0:$l";',
              '         elif [ $verb = start ] && ! timeout 30 $c --embed $kb step rsm > $kb.step 2>&1; then bad="$bad #$run.$i:step:$(head -c 60 $kb.step | tr \'\\n\' \' \')"; fi ;;',
              '      1) refused=1 ;;',
              '      134) grep -q "std::bad_alloc" $kb.out || bad="$bad #$run.$i:134" ;;',
              '      *) bad="$bad #$run.$i:$x" ;;',
              '    esac',
              '    rm -rf $kb $kb.out $kb.step',
              '    i=$((i + 1))',
              '  done',
              'done',
              'if [ -n "$bad" ]; then echo "wrong of $n:$bad" | cut -c1-400',
              'elif [ $refused = 1 ]; then echo clean',
              'else echo "none refused of $n"; fi' ]).

%% the run of fixture FX with every request of SIZE bytes refused, when its
%% store does not read back WANT
rr_size_bad(C, Shim, D, Kind, Fx, World, Size, Want, sized(Kind, Size, Text, Back)) :-
    format(atom(KB), '~w/kbh_~w_~w', [D, Kind, Size]),
    format(atom(Cmd), 'env ~w LD_PRELOAD=~w REFUSE_SIZE=~w REFUSE_N=1 REFUSE_RUN=1 ~w --embed ~w query "use_module(''~w''), main" 2>&1',
           [World, Shim, Size, C, KB, Fx]),
    shell(Cmd, Text, _, 15000),
    format(atom(Rd), '~w --embed ~w query "findall(P, ( member(P, [gw1(_), gw2(_), gd(_)]), catch(P, _, fail) ), L), length(L, N), write(rows(N)), nl" 2>&1',
           [C, KB]),
    shell(Rd, Back, _, 15000),
    \+ sub_atom(Back, 0, _, _, Want).

%% each ENV of ENVS run over the fixture FX in a store of its own, and that
%% store read by a second process after: the run's text, its exit status and
%% the reader's text
rr_back_runs(_, _, _, _, [], _, []).
rr_back_runs(Shim, C, KB0, Fx, [Env|Envs], I, [run(Env, Text, Exit, Back)|Runs]) :-
    format(atom(KB), '~w_~w', [KB0, I]),
    format(atom(Cmd), 'env ~w LD_PRELOAD=~w ~w --embed ~w query "use_module(''~w''), main" 2>&1',
           [Env, Shim, C, KB, Fx]),
    shell(Cmd, Text, Exit, 15000),
    format(atom(Rd), '~w --embed ~w query "findall(P, ( member(P, [gw1(_), gw2(_), gd(_)]), catch(P, _, fail) ), L), length(L, N), write(rows(N)), nl" 2>&1',
           [C, KB]),
    shell(Rd, Back, _, 15000),
    I1 is I + 1,
    rr_back_runs(Shim, C, KB0, Fx, Envs, I1, Runs).

%% what is wrong with a run of `rr_any': a hang or a signal, a run that
%% neither answers nor says memory -- an uncaught resource_error(memory) is
%% `Not enough resources: memory' -- an owner's refusal not said as memory,
%% a store its reader cannot read. Not the second write's answer: a growth
%% given less than it asked stops the engine at its next step, which can be
%% that write's (1.10.28's rule), the row there all the same
rr_any_bad(_, Env, _, Exit, _, signal(Env, Exit)) :- Exit >= 124.
rr_any_bad(Kind, Env, Text, Exit, _, unsaid(Env, Exit, Text)) :-
    Exit < 124,
    rr_answer(Kind, Answer),
    \+ sub_atom(Text, _, _, _, Answer),
    \+ ( member(Word, ['resource_error(memory)', 'out of memory', 'Not enough resources: memory']),
         sub_atom(Text, _, _, _, Word) ).
rr_any_bad(rd, Env, Text, Exit, _, not_memory(Env, Text)) :-
    Exit < 124,
    sub_atom(Text, _, _, _, 'rd(error(resource_error(knowledge_base)'),
    \+ sub_atom(Text, _, _, _, 'out of memory').
rr_any_bad(_, Env, _, Exit, Back, unread(Env, Back)) :-
    Exit < 124,
    \+ sub_atom(Back, _, _, _, 'rows(').

%% the ENV of each run of a sweep: each request the fixture FX makes under
%% the shim's SHIM_ENV, refused in turn, once and twice in a row, the
%% fixture's own WORLD before each (`REFUSE count' of a run over the store
%% KB says how many)
rr_envs(Shim, C, KB, Fx, World, ShimEnv, Envs) :-
    rr_envs(Shim, C, KB, Fx, World, ShimEnv, [1, 2], Envs).

%% ...each refused RUNS (a list of lengths) in a row
rr_envs(Shim, C, KB, Fx, World, ShimEnv, Runs, Envs) :-
    format(atom(Cmd), 'env ~w ~w REFUSE_REPORT=1 LD_PRELOAD=~w ~w --embed ~w query "use_module(''~w''), main" 2>&1 >/dev/null',
           [World, ShimEnv, Shim, C, KB, Fx]),
    shell(Cmd, Text, _),
    (   sub_atom(Text, B, _, _, 'REFUSE count '), B1 is B + 13, sub_atom(Text, B1, _, 0, Rest),
        split_string(Rest, '\n', ' ', [S|_]), number_string(N0, S)
    ->  N = N0
    ;   N = 0
    ),
    findall(Env, ( member(Run, Runs), between(1, N, K),
                   format(atom(Env), '~w ~w REFUSE_N=~w REFUSE_RUN=~w', [World, ShimEnv, K, Run]) ), Envs).

%% each ENV of ENVS run over the fixture FX, in the store KB0 (SAME) or in
%% one of its own made empty at the run (FRESH): its text and exit status
rr_runs(_, _, _, _, _, [], _, []).
rr_runs(Shim, C, KB0, Fresh, Fx, [Env|Envs], I, [run(Env, Text, Exit)|Runs]) :-
    ( Fresh == fresh -> format(atom(KB), '~w_~w', [KB0, I]) ; KB = KB0 ),
    format(atom(Cmd), 'env ~w LD_PRELOAD=~w ~w --embed ~w query "use_module(''~w''), main" 2>&1',
           [Env, Shim, C, KB, Fx]),
    shell(Cmd, Text, Exit, 30000),
    I1 is I + 1,
    rr_runs(Shim, C, KB0, Fresh, Fx, Envs, I1, Runs).

%% whether some run's text holds WORD
rr_said(Runs, Word, Said) :-
    ( member(run(_, T, _), Runs), sub_atom(T, _, _, _, Word) -> Said = said ; Said = none ).

%% what is wrong with a run of the sweep of fixture KIND
rr_bad(_, Env, _, Exit, signal(Env, Exit)) :- Exit >= 124.
rr_bad(rr, Env, Text, _, said(Env, Word)) :-
    member(Word, ['does not read as a clause', damaged, 'commit failed']),
    sub_atom(Text, _, _, _, Word).
rr_bad(rw, Env, Text, _, second_refused(Env, Text)) :-
    sub_atom(Text, _, _, _, 'rw('),
    \+ sub_atom(Text, _, _, _, ', ok)').
rr_bad(rd, Env, Text, _, not_memory(Env, Text)) :-
    sub_atom(Text, _, _, _, 'rd(error(resource_error(knowledge_base)'),
    \+ sub_atom(Text, _, _, _, 'out of memory').
rr_bad(rc, Env, Text, _, said(Env, Text)) :-
    sub_atom(Text, _, _, _, 'not a clause').
rr_bad(rc, Env, Text, _, kept(Env, Text)) :-
    sub_atom(Text, _, _, _, 'the knowledge base refused the clause: '),
    \+ sub_atom(Text, _, _, _, 'rc(none)').
rr_bad(Kind, Env, Text, Exit, unsaid(Env, Exit, Text)) :-
    rr_answer(Kind, Answer),
    \+ sub_atom(Text, _, _, _, Answer),
    \+ sub_atom(Text, _, _, _, 'resource_error(memory)'),
    \+ sub_atom(Text, _, _, _, 'out of memory').

%% the text a run of fixture KIND prints when it answers
rr_answer(rr, 'rr(len(60000))').
rr_answer(rw, 'rw(').
rr_answer(rd, 'rd(').
rr_answer(rc, 'rc(').

%% ---- a green task's writes (3.63.1) ----------------------------------------
%%
%% A TASK ON A WORKER THAT IS NOT THE CONNECTION'S OWNER WRITES WHERE EACH
%% WRITE IS MADE (it has no turn to batch them over), and through 3.63.0 each
%% assertz rewrote its whole predicate: N asserts were N rewrites of up to N
%% rows, each leaving the last one's rows dead (lib/zigurat-kb.cicili's
%% `coco_zg_sync_pred'). And a fetch -- the first call of any predicate not
%% read yet: a library's, async_run/2's -- or current_predicate/1 wrote every
%% predicate the host's turn had changed into the host's open transaction,
%% whose deleted rows stayed locked to its commit: a task that then rewrote
%% one of them waited for a lock its host, awaiting the task, never gave
%% (`coco_zg_flush_one', `coco_zg_warm').
tasks_write(D) :-
    section('a green task''s writes'),
    tw_growth(D), tw_fetch(D), tw_current(D), tw_call(D).

tw_cmd(C, KB, F, Cmd) :-
    sh_join(['COCOLOG_GREEN_WORKERS=4 ', C, ' --embed ', KB, ' -s ', F, ' 2>&1'], Cmd).

tw_read(C, KB, Goal, Out) :-
    sh_join([C, ' --embed ', KB, ' query "', Goal, '" 2>&1'], Cmd),
    shell(Cmd, Out, _).

%% four tasks' 250 assertz each, on workers the connection is not
tw_growth(D) :-
    cocolog(C),
    atom_concat(D, '/tw.pl', F),
    fixture(F, [':- dynamic tw/2.',
                'tw_fill(W) :- forall(between(1, 250, I), assertz(tw(W, I))).',
                'main :- async_run(( findall(T, ( between(1, 4, W), go(tw_fill(W), T) ), Ts), await_all(Ts) ), _), aggregate_all(count, tw(_, _), N), format("tw(~w)~n", [N]).']),
    atom_concat(D, '/kbtw', KB),
    tw_cmd(C, KB, F, Cmd),
    shell(Cmd, Out, Exit, 600000),
    check('four green tasks'' 1 000 assertz into a fresh embedded store', Out-Exit, 'tw(1000)'-0),
    atom_concat(KB, '/data.bin', Data),
    size_file(Data, Size),
    ( Size < 16777216 -> Grew = rows ; Grew = Size ),
    check('...grow it as 1 000 rows do, not 1 000 rewrites of the predicate (over 100 MB through 3.63.0)', Grew, rows),
    tw_read(C, KB, 'forall(between(1, 4, W), ( findall(I, tw(W, I), Is), numlist(1, 250, Is) -> write(ok) ; write(bad(W)) )), nl', ROut),
    has('...and a second process reads each task''s 250 rows back in its order', okokokok, ROut).

%% THE FETCH: the host's assertz(tl(3)) waits in its turn's batch, and the
%% first call of async_run/2 fetches it -- which through 3.63.0 wrote tl/1
%% into the host's transaction, deleting the committed rows of tl(1) and
%% tl(2) under locks the task's rewrite for its retract then waited on
tw_fetch(D) :-
    cocolog(C),
    atom_concat(D, '/kbtl', KB),
    tw_read(C, KB, 'assertz(tl(1)), assertz(tl(2))', _),
    atom_concat(D, '/tl.pl', F),
    fixture(F, ['tl_rt :- retract(tl(1)).',
                'main :- assertz(tl(3)), async_run(( go(tl_rt, T), await(T) ), _), findall(X, tl(X), L), format("tl(~w)~n", [L]).']),
    tw_cmd(C, KB, F, Cmd),
    shell(Cmd, Out, Exit, 120000),
    check('a task retracts from a predicate its host wrote this turn, after a first call fetched',
          Out-Exit, 'tl([2,3])'-0),
    tw_read(C, KB, 'findall(X, tl(X), L), write(L), nl', ROut),
    has('...and its retract is kept: a second process reads [2,3] (through 3.63.0 the task waited ten seconds for the host''s lock, and [1,2,3])',
        '[2,3]', ROut).

%% CURRENT_PREDICATE/1 asks the knowledge base what predicates it holds
%% (`warm'), which through 3.63.0 wrote the turn's changes first, as the
%% fetch did; async_run/2 is called once before anything is written, so its
%% own fetch has nothing to write
tw_current(D) :-
    cocolog(C),
    atom_concat(D, '/kbtc', KB),
    tw_read(C, KB, 'assertz(tc(1)), assertz(tc(2))', _),
    atom_concat(D, '/tc.pl', F),
    fixture(F, ['tc_rt :- retract(tc(1)).',
                'main :- async_run(true, _), assertz(tc(3)), ( current_predicate(tc_none/0) -> true ; true ), async_run(( go(tc_rt, T), await(T) ), _), findall(X, tc(X), L), format("tc(~w)~n", [L]).']),
    tw_cmd(C, KB, F, Cmd),
    shell(Cmd, Out, Exit, 120000),
    check('a task retracts from a predicate its host wrote this turn, after a current_predicate/1',
          Out-Exit, 'tc([2,3])'-0),
    tw_read(C, KB, 'findall(X, tc(X), L), write(L), nl', ROut),
    has('...and a second process reads [2,3]', '[2,3]', ROut).

%% A PROGRAM'S OWN CALL OF A PROCEDURE MAY CHANGE ANY ROW (`zg_unsettle'):
%% the task's first assertz is a row of its own, its zigurat_call/2 takes the
%% predicate's rows away, and its second assertz writes the whole predicate
%% again -- a row of its own there would have left zc(1) in this process and
%% in no row
tw_call(D) :-
    cocolog(C),
    atom_concat(D, '/kbzc', KB),
    atom_concat(D, '/zc.pl', F),
    fixture(F, [':- dynamic zc/1.',
                'zc_t :- assertz(zc(1)), zigurat_call(''cocolog::forget_clauses'', [main, zc, 1]), assertz(zc(2)).',
                'main :- async_run(( go(zc_t, T), await(T) ), _), findall(X, zc(X), L), format("zc(~w)~n", [L]).']),
    tw_cmd(C, KB, F, Cmd),
    shell(Cmd, Out, Exit, 120000),
    check('a task''s zigurat_call/2 takes its predicate''s rows away between two assertz', Out-Exit, 'zc([1,2])'-0),
    tw_read(C, KB, 'findall(X, zc(X), L), write(L), nl', ROut),
    has('...and the second writes them again: a second process reads [1,2]', '[1,2]', ROut).
