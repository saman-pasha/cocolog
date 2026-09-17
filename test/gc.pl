%% What the store reclaims now, and what has to survive it.
%%
%% THE STORE NEVER SHRANK. Every write copied a whole term into its cell
%% array -- a clause, a global's new value, a ball, each solution a findall
%% kept -- and nothing took one out: a retract orphaned the cells, and a
%% global written again just pointed elsewhere. Measured on cicili-lang's
%% driver, which keeps its symbol tables in globals and writes them back
%% after every step: 103 192 overwrites put 1 073 MB into a store whose
%% live contents came to 20 MB. Since 1.2.13 the store compacts itself --
%% `coco_store_compact' in lib/kb.cicili says when and how -- and
%% `garbage_collect/0' asks for one now.
%%
%%     cocolog -s test/gc.pl        from the checkout root
%%
%% * a store written and written again stays the size of what it HOLDS,
%%   not of everything it was ever told;
%% * everything reachable survives a compaction as it was: clauses and
%%   the index over them, a global's value, a shared variable, a float, a
%%   string, and a retract that had already happened;
%% * the two callers that keep cell indices of their own -- a findall's
%%   solutions, a consult's initialization goals -- are moved with the
%%   rest, because a `forall/2' IS a findall and a script's whole life
%%   runs inside its `initialization(main)';
%% * under `--embed' what was written through reads back from a second
%%   process after one, and so does a retract; the same on the wire, when
%%   there is a server;
%% * a writing process REWRITES the whole predicate it touches, so an
%%   unvacuumed store grows with every one of them and a vacuumed one does
%%   not grow at all -- and the compaction above is this process's array
%%   and not the store on disk, which is the distinction that cost
%%   cicili-lang a cache;
%% * the write itself WAS quadratic in the rows one process writes, and is
%%   linear since ZiguratIP f5d6dd2, so the two timed checks are CEILINGS:
%%   only a regression past quadratic fails them, and the fix only made the
%%   numbers smaller -- which is exactly what they were written for;
%% * `statistics/2' answers the keys a program can act on and refuses the
%%   rest by name.

:- use_module('test/prelude.pl').

:- dynamic gc_f/3, gc_g/1, gc_s/1, gc_h/4, gc_r/2.

main :-
    bounded,
    survives,
    holders,
    embedded,
    wire,
    writes,
    keys,
    checks_done.

%% ---- the store stays the size of what it holds ------------------------

%% 4 000 integers is 16 000 cells a copy, 128 KB; 2 000 copies would be
%% 256 MB with nothing reclaimed. The trigger is four million cells of
%% growth (32 MB) past what was live at the last compaction, so the
%% store's high-water mark is that plus one copy -- pinned at twice it.
bounded :-
    section('a store written again and again stays the size of what it holds'),
    numlist(1, 4000, L),
    answer(( forall(between(1, 2000, _), nb_setval(gc_k, L)),
             statistics(store_used, B1),
             ( B1 < 67108864 -> Size1 = under_64mb ; Size1 = over(B1) ) ), Size1, X1),
    check('2 000 overwrites of a 128 KB global leave the store under 64 MB', X1, under_64mb),
    answer(( nb_getval(gc_k, V2), length(V2, N2), last(V2, La2) ), N2-La2, X2),
    check('and the global reads back whole', X2, 4000-4000),
    answer(( garbage_collect, statistics(store_used, B3),
             ( B3 < 8388608 -> Size3 = under_8mb ; Size3 = over(B3) ) ), Size3, X3),
    check('garbage_collect/0 brings it down to what is live', X3, under_8mb),
    %% a findall keeps each solution in the store until the search is over
    answer(( forall(between(1, 400, _), findall(X, member(X, L), _)),
             garbage_collect, statistics(store_used, B4),
             ( B4 < 8388608 -> Size4 = under_8mb ; Size4 = over(B4) ) ), Size4, X4),
    check('400 findalls over the list leave nothing behind either', X4, under_8mb),
    %% the pattern the growth trigger alone missed: everything asserted was
    %% live when the mark was set, and a retract never lowered it. (It also
    %% found retract/1 copying every candidate before looking at its head:
    %% 153 s for these two loops until retract skipped by first-argument key.)
    numlist(1, 2000, L5),
    answer(( forall(between(1, 3000, I5), asserta(gc_r(I5, L5))),
             forall(between(1, 2999, I5), retract(gc_r(I5, _))),
             gc_r(3000, V5), length(V5, N5), statistics(store_used, B5),
             ( B5 < 67108864 -> Size5 = under_64mb ; Size5 = over(B5) ) ), N5-Size5, X5),
    check('3 000 asserta and 2 999 retracts leave one clause and a small store', X5, 2000-under_64mb).

%% ---- everything reachable survives --------------------------------------

survives :-
    section('everything reachable survives a compaction as it was'),
    answer(( forall(between(1, 500, I), assertz(gc_f(I, foo(I), [I]))),
             assertz((gc_g(X) :- gc_f(X, _, _), X > 3)),
             string_concat("a", "b", S0), assertz(gc_s(S0)),
             assertz(gc_h(A, _, A, 1.5)),
             garbage_collect,
             gc_f(499, F, _), findall(Y, gc_g(Y), Ys), length(Ys, NG) ), F-NG, X1),
    check('a keyed lookup and a rule over 500 facts, after one', X1, foo(499)-497),
    answer(( gc_s(S), string(S), string_length(S, SL) ), SL, X2),
    check('a string comes back a string', X2, 2),
    answer(( gc_h(P, _, R, Fl), ( P == R -> Same = shared ; Same = split ) ), Same-Fl, X3),
    check('a shared variable is still one variable, a float still a float', X3, shared-1.5),
    %% a retract orphans the clause; the next compaction must not bring it back
    answer(( retract(gc_f(1, _, _)), garbage_collect,
             ( gc_f(1, _, _) -> One = still ; One = gone ), gc_f(2, T, _) ), One-T, X4),
    check('a retracted clause stays retracted and its neighbour stays', X4, gone-foo(2)),
    %% and the first-argument index, which holds cell VALUES and positions
    %% and so is untouched by a compaction, still finds by key afterwards
    answer(( assertz(gc_f(501, foo(501), [])), gc_f(501, F5, _), gc_f(250, F6, _) ), F5-F6, X5),
    check('the first-argument index is still right after one', X5, foo(501)-foo(250)).

%% ---- the callers that keep cell indices of their own --------------------

holders :-
    section('the callers that keep cell indices of their own are moved with the rest'),
    numlist(1, 4000, L),
    %% a findall's solutions live in the store until the search is over: a
    %% compaction in the middle of the search has to move them
    answer(findall(X, ( member(X, [a, b, c]),
                        forall(between(1, 700, _), nb_setval(gc_k, L)) ), R), R, X1),
    check('a findall whose goal compacts the store three times answers whole', X1, [a, b, c]),
    %% a consult's initialization goals wait in the store until the file is
    %% read: a directive that compacts must not lose them, and the goals
    %% run after a compaction must still be the goals that were written
    scratch(D), atom_concat(D, '/inits.pl', File),
    fixture(File, [ ':- dynamic gc_t/1.',
                    'gc_t(1).',
                    ':- initialization(assertz(gc_t(3))).',
                    ':- numlist(1, 4000, L), forall(between(1, 400, _), nb_setval(gc_cc, L)).',
                    'gc_t(2).',
                    'gc_main :- findall(X, gc_t(X), L), nb_getval(gc_cc, V), length(V, N), write(L-N), nl.' ]),
    sh_join(['run ', File, ' gc_main'], Args2),
    cocolog_run(Args2, Out2, _),
    check('a consult whose directive compacts still runs the goals it put off', Out2, '[1,2,3]-4000').

%% ---- across processes, in the two arrangements that write through -------

%% Four processes against one knowledge base: write 300 facts and compact,
%% read them back, retract one and compact, read again. What a compaction
%% keeps is what the NEXT process sees, which is the claim this project
%% exists to make.
exercise(Prefix) :-
    sh_join([Prefix, ' query "forall(between(1, 300, I), assertz(gc_e(I, [I]))), numlist(1, 4000, L), forall(between(1, 400, _), nb_setval(gc_k, L)), garbage_collect, gc_e(299, V), write(v(V)), nl"'], A1),
    cocolog_run(A1, T1, _),
    has('300 facts written through, a compaction, and the 299th still there', 'v([299])', T1),
    sh_join([Prefix, ' query "findall(X-Y, gc_e(X, Y), L), length(L, N), last(L, La), write(count(N, La)), nl"'], A2),
    cocolog_run(A2, T2, _),
    has('a second process reads all 300 back', 'count(300,300-[300])', T2),
    sh_join([Prefix, ' query "retract(gc_e(1, _)), numlist(1, 4000, L), forall(between(1, 400, _), nb_setval(gc_k, L)), gc_e(2, V), write(v(V)), nl"'], A3),
    cocolog_run(A3, T3, _),
    has('a retract, then a compaction', 'v([2])', T3),
    sh_join([Prefix, ' query "findall(X, gc_e(X, _), L), length(L, N), write(count(N)), nl"'], A4),
    cocolog_run(A4, T4, _),
    has('and a third process sees 299', 'count(299)', T4).

embedded :-
    section('the embedded arrangement, across processes'),
    scratch(D), atom_concat(D, '/store', Store),
    sh_join(['--embed ', Store], Prefix),
    exercise(Prefix).

wire :-
    section('the wire arrangement, across processes'),
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' --kb gc_test --host ', Host, ' --tcp ', Port, ' --timeout 10 list >/dev/null 2>&1'], Probe),
    shell(Probe, _, Exit),
    (   Exit =:= 0
    ->  sh_join(['--kb gc_test --host ', Host, ' --tcp ', Port, ' --timeout 30'], Prefix),
        %% a clean base first, and a clean one left behind
        sh_join([Prefix, ' forget'], Forget),
        cocolog_run(Forget, _, _),
        exercise(Prefix),
        cocolog_run(Forget, _, _)
    ;   format("     (skipped: no Zigurat server at ~w:~w)~n", [Host, Port])
    ).

%% ---- what a writing process costs, and what a vacuum takes back --------

%% THE COMPACTION EVERYWHERE ABOVE IS THIS PROCESS'S CELL ARRAY, NOT THE
%% STORE ON DISK -- a distinction cicili-lang lost, and gave up a C++ header
%% cache over what one command takes back. The Zigurat backend flushes a
%% dirty predicate WHOLESALE, so one assertz copies every row that predicate
%% already held (~360 bytes of new store per EXISTING row) and the old rows
%% stay dead: every process pays it again, an unvacuumed store grows without
%% bound, and each build is slower than the one before.
%%
%% What no vacuum took back was the write ITSELF, which was quadratic in the
%% rows one process writes -- 16 000 rows 0.53 s and 128 000 26.9 s on the
%% Linux box, and splitting them over more predicates did not help
%% (CLAUDE.md has the tables). So the two timed checks are CEILINGS and not
%% targets, test/engine.pl's shape: loose enough that only a real regression
%% can fail them, and they go on passing the day the quadratic is fixed,
%% because a fix only makes the number smaller.
%%
%% THAT DAY CAME: ZiguratIP f5d6dd2. It was the store's page list, walked
%% WHOLE on every sequence draw -- and every row written draws one -- so a
%% draw cost O(pages) and the pages grow with the rows. A page sits in a
%% chain of its own key's pages now, 128 000 rows went 15.0 s to 7.45 s
%% here, and the cost a row is flat. THESE CEILINGS STAY EXACTLY AS THEY
%% ARE: that is what a ceiling is for, and a case edited to accept an
%% improvement is a case that argues against the next one.

%% a program that asserts N rows of gc_w/3
rows_fixture(Dir, Name, N, File) :-
    atom_concat(Dir, Name, File),
    format(atom(Body),
           'main :- forall(between(1, ~w, I), assertz(gc_w(I, I, payload))), write(wrote), nl.',
           [N]),
    fixture(File, [':- dynamic gc_w/3.', Body]).

%% the bytes an --embed store is holding, 0 before it exists
store_bytes(Store, Bytes) :-
    atom_concat(Store, '/data.bin', F),
    ( catch(size_file(F, B), _, fail) -> Bytes = B ; Bytes = 0 ).

%% a child writing into Store, and the milliseconds the whole process took
write_run(Store, File, Ms, Last) :-
    sh_join(['--embed ', Store, ' -s ', File, ' 2>/dev/null'], Args),
    get_time(T0), cocolog_run(Args, Last, _, 180000), get_time(T1),
    Ms is round((T1 - T0) * 1000).

vacuum_store(Store) :-
    sh_join(['--embed ', Store, ' vacuum >/dev/null 2>&1'], Args),
    cocolog_run(Args, _, _, 180000).

writes :-
    section('what a writing process costs, and what a vacuum takes back'),
    scratch(Dw),
    atom_concat(Dw, '/count.pl', Counter),
    fixture(Counter, ['main :- findall(X, gc_w(X, _, _), L), length(L, N), write(n(N)), nl.']),
    write_budget(Dw, Counter),
    write_shape(Dw),
    vacuum_bounds(Dw, Counter),
    compaction_is_not_the_disk(Dw),
    atom_concat('rm -rf ', Dw, Rm), shell(Rm, _, _).

%% THE BUDGET. 32 000 rows took 1.4 s measured; three minutes is a margin
%% only a regression of a different order can spend. The second process is
%% the other half: a write that finished and lost rows passes a stopwatch.
write_budget(D, Counter) :-
    atom_concat(D, '/big', Store),
    rows_fixture(D, '/rows32k.pl', 32000, F1),
    write_run(Store, F1, Ms1, Last1),
    format("     32 000 rows written in ~wms~n", [Ms1]),
    has('32 000 rows write at all, inside three minutes', wrote, Last1),
    sh_join(['--embed ', Store, ' -s ', Counter, ' 2>/dev/null'], A2),
    cocolog_run(A2, Out2, _, 180000),
    has('and a second process reads every one of them back', 'n(32000)', Out2).

%% THE SHAPE. Twice the rows cost 2.4 times the time when this was written,
%% and 1.75 since f5d6dd2 made the write linear -- 8 000 rows 602 ms and
%% 16 000 1 055 ms on the Mac, under the 2 a linear write would cost because
%% a process's own startup is in both numbers. The bound at eight catches a
%% cost going past quadratic and nothing else.
write_shape(D) :-
    atom_concat(D, '/s8', S8), atom_concat(D, '/s16', S16),
    rows_fixture(D, '/rows8k.pl', 8000, F8),
    rows_fixture(D, '/rows16k.pl', 16000, F16),
    write_run(S8, F8, Ms8, _), write_run(S16, F16, Ms16, _),
    format("     8 000 rows in ~wms, 16 000 in ~wms~n", [Ms8, Ms16]),
    (   Ms8 > 0, Ms16 < Ms8 * 8
    ->  Shape3 = 'inside the ceiling'
    ;   Shape3 = past_quadratic(Ms8, Ms16) ),
    check('twice the rows costs well under eight times the time', Shape3,
          'inside the ceiling').

%% THE VACUUM, which is the whole of the growth. Two stores seeded alike and
%% written by the same processes, one vacuumed after each: the unvacuumed one
%% grows every time and the vacuumed one does not grow at all. Its file does
%% not SHRINK below its high-water mark and does not need to -- the space is
%% reused, which is what `does not grow' is measuring.
vacuum_bounds(D, Counter) :-
    atom_concat(D, '/plain', SP), atom_concat(D, '/vac', SV),
    rows_fixture(D, '/rows2k.pl', 2000, FS),
    atom_concat(D, '/one.pl', F1),
    fixture(F1, [':- dynamic gc_w/3.',
                 'main :- assertz(gc_w(999999, 1, payload)), write(wrote), nl.']),
    write_run(SP, FS, _, _), write_run(SV, FS, _, _),
    write_run(SP, F1, _, _),
    write_run(SV, F1, _, _), vacuum_store(SV),
    store_bytes(SP, P4), store_bytes(SV, V4),
    forall(between(1, 2, _), write_run(SP, F1, _, _)),
    forall(between(1, 2, _), ( write_run(SV, F1, _, _), vacuum_store(SV) )),
    store_bytes(SP, P5), store_bytes(SV, V5),
    format("     two more writers: unvacuumed ~w -> ~w bytes, vacuumed ~w -> ~w~n",
           [P4, P5, V4, V5]),
    ( P5 > P4 -> Grew5 = grew ; Grew5 = did_not(P4, P5) ),
    check('an unvacuumed store grows with every writing process', Grew5, grew),
    ( V5 =< V4 -> Flat5 = flat ; Flat5 = grew_to(V4, V5) ),
    check('and a vacuumed one does not grow at all', Flat5, flat),
    sh_join(['--embed ', SV, ' -s ', Counter, ' 2>/dev/null'], A6),
    cocolog_run(A6, Out6, _, 180000),
    has('with every row still in it', 'n(2003)', Out6).

%% AND THE DISTINCTION ITSELF. garbage_collect/0 moves store_used and
%% store_cap, which this process holds; it moves nothing the disk holds.
%% Pinned as `no more', never as equality: a later compaction that DID
%% reclaim on disk would be an improvement, and a case that failed on it
%% would be wrong.
compaction_is_not_the_disk(D) :-
    atom_concat(D, '/nogc', SN), atom_concat(D, '/withgc', SG),
    rows_fixture(D, '/rows2kb.pl', 2000, FS),
    atom_concat(D, '/plainone.pl', FP),
    fixture(FP, [':- dynamic gc_w/3.',
                 'main :- assertz(gc_w(42, 1, payload)), write(wrote), nl.']),
    atom_concat(D, '/gcone.pl', FG),
    fixture(FG, [':- dynamic gc_w/3.',
                 'main :- assertz(gc_w(42, 1, payload)), garbage_collect, statistics(compactions, K), write(k(K)), nl.']),
    write_run(SN, FS, _, _), write_run(SG, FS, _, _),
    store_bytes(SN, N7), store_bytes(SG, G7),
    write_run(SN, FP, _, _), write_run(SG, FG, _, Last7),
    store_bytes(SN, N8), store_bytes(SG, G8),
    DN is N8 - N7, DG is G8 - G7,
    format("     one writer adds ~w bytes, the same writer with a compaction in it ~w~n",
           [DN, DG]),
    has('the compaction really ran', 'k(1)', Last7),
    ( DN > 0, DG =< DN -> Disk7 = 'no more than without it' ; Disk7 = wrote(DN, DG) ),
    check('a forced compaction adds nothing to what the store on disk holds',
          Disk7, 'no more than without it').

%% ---- statistics/2 --------------------------------------------------------

keys :-
    section('statistics/2 answers the keys a program can act on'),
    answer(( statistics(cputime, T), statistics(inferences, I), statistics(globalused, G),
             statistics(trailused, Tr), statistics(atoms, A), statistics(functors, F),
             statistics(store_used, S),
             (   float(T), T >= 0.0, integer(I), integer(G), G > 0, integer(Tr), Tr >= 0,
                 integer(A), A > 100, integer(F), F > 100, integer(S), S > 0
             ->  Shape = sound
             ;   Shape = wrong(T, I, G, Tr, A, F, S) ) ), Shape, X1),
    check('seven keys, each the type SWI gives it', X1, sound),
    answer(( statistics(inferences, I0), numlist(1, 500, Ns0), msort(Ns0, _),
             statistics(inferences, I1), ( I1 > I0 -> Up = counts_up ; Up = stuck(I0, I1) ) ), Up, X2),
    check('inferences count up', X2, counts_up),
    answer(( statistics(globalused, G0), numlist(1, 5000, _), statistics(globalused, G1),
             ( G1 > G0 -> Grew = grew ; Grew = did_not(G0, G1) ) ), Grew, X3),
    check('globalused grows with the heap', X3, grew),
    %% THE CAPS, which are the keys the lengths could not stand in for: CivV
    %% read store_used at 28 MB inside a window holding 13.2 GB, and the
    %% length was telling the truth about the wrong thing. A cap is never
    %% below its length, and a compaction brings the store's cap down to
    %% exactly what it holds.
    answer(( numlist(1, 4000, LC), forall(between(1, 400, _), nb_setval(gc_k, LC)),
             statistics(compactions, K0), garbage_collect, statistics(compactions, K1),
             statistics(store_used, U), statistics(store_cap, C),
             statistics(globalused, GU), statistics(globalcap, GC),
             statistics(trailused, TU), statistics(trailcap, TC),
             statistics(choicepoints, CP), statistics(strings, St),
             (   C >= U, GC >= GU, TC >= TU, integer(CP), integer(St), K1 > K0, C =:= U
             ->  Shape = sound
             ;   Shape = wrong(U, C, GU, GC, TU, TC, CP, St, K0, K1) ) ), Shape, X0),
    check('every cap is at or above its length, and a compaction trims the store to fit',
          X0, sound),
    answer(catch(statistics(nosuch, _), error(E4, _), true), E4, X4),
    check('an unknown key is a domain_error naming it', X4, domain_error(statistics_key, nosuch)),
    answer(( catch(statistics(_, _), error(E5, _), true),
             ( E5 = type_error(atom, V5), var(V5) -> Shape5 = type_error_atom ; Shape5 = E5 ) ), Shape5, X5),
    check('and an unbound key is a type_error', X5, type_error_atom).
