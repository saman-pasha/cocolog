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
%%
%%     cocolog -s test/store-lock.pl        from the checkout root

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    (   embedded(D)
    ->  writers(D), holder(D), reader(D), gone(D), damaged(D)
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
