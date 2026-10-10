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
%%   linear since ZiguratIP f5d6dd2 (and faster again since 0.1.2), so the
%%   two timed checks are CEILINGS: only a regression past quadratic fails
%%   them, and the fixes only made the numbers smaller -- which is exactly
%%   what they were written for;
%% * `statistics/2' answers the keys a program can act on and refuses the
%%   rest by name;
%% * since 1.8.36 the HEAP is collected too: a deterministic recursion
%%   and a failure-driven loop each stay under twice the collector's floor
%%   where they used to hold everything they ever built, `garbage_collect/0'
%%   collects at the next step, and a proof goes on exactly as it was -- the
%%   same program, collected every thousand cells and never, answers the
%%   same (`coco_heap_gc' in lib/solve.cicili; test/gc-program.pl);
%% * and since 1.9.6 so is a goal a load runs -- a directive, an
%%   initialization goal -- with the term it runs and the marks the load
%%   winds the heap back to moved with the rest (`coco_consult_owned' in
%%   lib/kb.cicili).

:- use_module('test/prelude.pl').

:- dynamic gc_f/3, gc_g/1, gc_s/1, gc_h/4, gc_r/2, gc_d/1.

main :-
    bounded,
    survives,
    holders,
    embedded,
    wire,
    writes,
    keys,
    heap,
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
    check('3 000 asserta and 2 999 retracts leave one clause and a small store', X5, 2000-under_64mb),
    %% a base drained with nothing asserted meanwhile, which the growth
    %% trigger cannot answer for: only the count of the dead can. 1 500
    %% clauses of 3 000 variables each take 6 003 cells in the store and 3 003
    %% on the heap, and a thousand are retracted. Counted at the copy's length
    %% (1.8.43 to 1.8.47) the dead never came to half the store and nothing
    %% was compacted; 1.8.48 counts the span, and the store compacts once.
    answer(( forall(between(1, 1500, _), ( functor(T6, gc_wide, 3000), assertz(gc_d(T6)) )),
             statistics(compactions, C6a), statistics(store_used, B6a),
             forall(between(1, 1000, _), retract(gc_d(_))),
             statistics(compactions, C6b), statistics(store_used, B6b),
             D6 is C6b - C6a,
             ( B6b < B6a -> Fell6 = fell ; Fell6 = held ) ), D6-Fell6, X6),
    check('a thousand of 1 500 clauses of 3 000 variables retracted compacts the store', X6, 1-fell).

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
%% THAT DAY CAME, TWICE. ZiguratIP f5d6dd2: it was the store's page list,
%% walked WHOLE on every sequence draw -- and every row written draws one --
%% so a draw cost O(pages) and the pages grow with the rows; a page sits in
%% a chain of its own key's pages now, and 128 000 rows went 15.0 s to
%% 7.45 s here. Then the file's own growing went with it: six ftruncates a
%% page became one a megabyte, 9.22 s to 3.26 s over three runs each.
%% THESE CEILINGS STAY EXACTLY AS THEY ARE: that is what a ceiling is for,
%% and a case edited to accept an improvement is a case that argues against
%% the next one.
%%
%% AND THE OTHER CHECK IN THIS SECTION EARNED ITS KEEP over the same work.
%% The first shape of that second fix (ZiguratIP 0.1.1) made the extending
%% write a pwrite, which put content through a second path -- and a store
%% written that way was intermittently incomplete to the NEXT PROCESS on
%% Linux/ext4: ~30% of first reads could not find gc_w/3 though every row
%% was there. "a second process reads every one of them back" is what went
%% red, and it is red for the right reason: a write that finished and cannot
%% be read back by somebody else has not finished. ZiguratIP#32.

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
%% and 1.6 since ZiguratIP f5d6dd2 and 0.1.2 -- 8 000 rows 404 ms and
%% 16 000 641 ms on the Mac, under the 2 a linear write would cost because a
%% process's own startup is in both numbers. The bound at eight catches a
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
    %% COLLECTED FIRST AND THE LIST KEPT, because a heap collection between
    %% the two readings is free to take a list nobody holds -- and does, with
    %% `COCOLOG_GC_CELLS' small: 4.9 MB of garbage, then 3 KB
    answer(( garbage_collect, statistics(globalused, G0), numlist(1, 5000, L3),
             statistics(globalused, G1), length(L3, _),
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

%% ---- the heap is collected (1.8.36) -------------------------------------
%%
%% THE HEAP WAS GIVEN BACK BY BACKTRACKING AND BY NOTHING ELSE: three lines
%% of deterministic recursion, two million times round, held 560 MB at the
%% end, and a failure-driven `between/3' loop peaked at a gigabyte, because
%% each level's choice point is pushed above the leftovers of the level
%% before it and no backtrack ever reaches below them. The collector
%% (`coco_heap_gc' in lib/solve.cicili) slides what is reachable down IN
%% ORDER, which is what keeps every choice point's heap mark true. Its
%% floor is four million cells, 32 MB, and each bound here is pinned at a
%% small multiple of that.

%% THE RECURSION KEEPS A STRUCTURE EACH TURN (`gc_keep/1'), because since
%% 1.9.1 it has to be told to make garbage: `N1 is N - 1' is run as the
%% clause is entered and the call goes in registers, so the plain
%% `gc_count(N) :- N1 is N - 1, gc_count(N1)' leaves one cell a turn where
%% it left fourteen, never reaches the collector's floor and passed this
%% check only by not being collected at all. With the structure each turn
%% is nine cells.
gc_count(0) :- !.
gc_count(N) :- N1 is N - 1, gc_keep(f(N1)), gc_count(N1).
gc_keep(_).

gc_program_lines(['t1(4)', 't1(5)', 't2(f(3))', 't2(unbound)', 't2(shared)',
                  't3(2000)', 't4(2)', 't4(b)', 't5(1250025000)', 't5(4.75)',
                  't5(hello world,11)', 't6(45150)', 't7(3000,3000)',
                  't8(big(1,2,3))', 't9(2000)', 't10(negation)', 't10(2)',
                  't11([1-1,2-2,3-3])', 't12(instantiation_error)']).

heap :-
    section('the heap is collected, and a proof goes on as it was'),
    %% a million and a half turns of the recursion build 13.5 million cells
    answer(( statistics(heap_collections, C0), gc_count(1500000),
             statistics(heap_collections, C1), statistics(globalused, U),
             ( C1 > C0, U < 67108864 -> Shape1 = bounded ; Shape1 = grew(C0, C1, U) ) ),
           Shape1, H1),
    check('a deterministic recursion is collected, and stays under twice the floor', H1, bounded),
    answer(( numlist(1, 20000, _), statistics(globalused, U0), statistics(heap_collections, K0),
             garbage_collect, statistics(heap_collections, K1), statistics(globalused, U1),
             ( K1 > K0, U1 < U0 -> Shape2 = collected ; Shape2 = wrong(K0, K1, U0, U1) ) ),
           Shape2, H2),
    check('garbage_collect/0 collects the heap at the next step, and it shrinks', H2, collected),
    %% THE PEAK, which only the cap remembers -- so a fresh process
    cocolog_out('query "( between(1, 300000, _), fail ; true ), statistics(globalcap, Cap), write(cap(Cap)), nl"', O3),
    (   re_first_atom('cap\\([0-9]+\\)', O3, A3), sub_atom(A3, 4, _, 1, N3), atom_number(N3, Cap3)
    ->  ( Cap3 < 100663296 -> H3 = bounded ; H3 = grew(Cap3) )
    ;   atom_codes(T3, O3), H3 = no_answer(T3)
    ),
    check('a failure-driven between/3 loop peaks under three times the floor', H3, bounded),
    %% THE SAME PROGRAM, COLLECTED EVERY THOUSAND CELLS AND NEVER: every
    %% root moved many times over, and every answer the same
    cocolog(C),
    gc_program_lines(Lines),
    sh_join(['COCOLOG_GC_CELLS=1000 ', C, ' -s test/gc-program.pl 2>&1'], Cmd4),
    proc_run(Cmd4, 120000, O4, _), chomp(O4, B4), atom_codes(T4, B4),
    append(Lines, ['collected(yes)'], L4), atomic_list_concat(L4, '\n', Want4),
    check('a program collected every thousand cells answers as it always did', T4, Want4),
    sh_join([C, ' -s test/gc-program.pl 2>&1'], Cmd5),
    proc_run(Cmd5, 120000, O5, _), chomp(O5, B5), atom_codes(T5, B5),
    append(Lines, ['collected(no)'], L5), atomic_list_concat(L5, '\n', Want5),
    check('and never collected, the same', T5, Want5),
    %% THE TOPLEVEL KEEPS THE QUERY'S VARIABLES, and registers them so a
    %% collection moves them: the bindings it prints are read through them.
    %% THE FIRST QUERY IS THE ARM. A sliding collector moves no cell with
    %% nothing dead below it, and a query read onto a clean heap has
    %% nothing -- so with one query this passed with the registration taken
    %% out. The first query's list is dead by the second, and without the
    %% registration the second printed `X = 0.'
    sh_join(['printf ''numlist(1, 30000, _), N = done.\\nnumlist(1, 30000, L0), sum_list(L0, S), X = f(S, done).\\n'' | COCOLOG_GC_CELLS=1000 ',
             C, ' 2>&1'], Cmd6),
    proc_run(Cmd6, 120000, O6, _),
    (   re_match('X = f\\(450015000,done\\)', O6) -> H6 = printed
    ;   atom_codes(T6, O6), H6 = wrong(T6)
    ),
    check('the toplevel prints the bindings of a query collected under it', H6, printed),
    %% A GOAL IN HAND IS NOT A ROOT. Since 1.8.55 the step hands the first
    %% goal of the clause it entered to the next step in the engine, not in
    %% a frame -- since 1.9.1 as its arguments in the engine's registers,
    %% never a term -- and builds and pushes it back as a frame before a
    %% collection moves the heap under it (`coco_k_flush'). Naive reverse
    %% enters a clause on nearly every step, so collecting every two
    %% thousand cells meets a goal in hand at almost every collection;
    %% without the flush the program died of an instantiation error or
    %% answered nothing at all, and the program above stayed green.
    scratch(D7), atom_concat(D7, '/nrev.pl', F7),
    fixture(F7, [ 'app([], L, L).',
                  'app([H|T], L, [H|R]) :- app(T, L, R).',
                  'nrev([], []).',
                  'nrev([H|T], R) :- nrev(T, RT), app(RT, [H], R).',
                  'go :- numlist(1, 300, L), nrev(L, R), nrev(R, S), S == L, R = [F|_], write(go(F)), nl.' ]),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F7, ' go 2>&1'], Cmd7),
    proc_run(Cmd7, 120000, O7, _), chomp(O7, B7), atom_codes(T7, B7),
    check('a goal handed from one step to the next survives a collection between them', T7, 'go(300)'),
    %% AN ENVIRONMENT IS KEPT WHOLE FROM ANY OF ITS POSITIONS (Stages 5 and
    %% 6): a continuation names one cell of it, and the collector keeps the
    %% compound that cell belongs to (`coco_gc_mark') -- its code, its
    %% slots, its other positions -- and moves it as one. Two recursions
    %% through a body with an if-then-else, one of them after guards,
    %% collected every two thousand cells, meet an environment between
    %% their goals -- and inside a condition, its slot holding a choice
    %% height -- at nearly every collection.
    %% And the code it names outlives its clause: `rr/1' retracts itself
    %% and then builds enough to be collected, and the collection must keep
    %% the retired code the environment still reads (`coco_gc_codes').
    atom_concat(D7, '/env.pl', F8),
    fixture(F8, [ ':- dynamic rr/1.',
                  'r3(0, A, A) :- !.',
                  'r3(N, A0, A) :- r3s(N, M), ( r3k(f(N), A0, A1) -> true ; A1 = A0 ), r3(M, A1, A).',
                  'r4(0, A, A) :- !.',
                  'r4(N, A0, A) :- N > 0, M is N - 1, ( r3k(f(N), A0, A1) -> true ; A1 = A0 ), r4(M, A1, A).',
                  'r3s(N, M) :- M is N - 1.',
                  'r3k(T, A0, A1) :- arg(1, T, X), A1 is A0 + X.',
                  'rr_s(N, X) :- X is N * 2.',
                  'rr_t(_).',
                  'go :- r3(20000, 0, S), write(go(S)), nl, r4(20000, 0, S4), write(g4(S4)), nl,',
                  '      assertz((rr(X) :- retract((rr(_) :- _)), numlist(1, 3000, L), length(L, N),',
                  '                        ( rr_s(N, X) -> rr_t(X) ; true ))),',
                  '      rr(Y), write(rr(Y)), nl.' ]),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F8, ' go 2>&1'], Cmd8),
    proc_run(Cmd8, 120000, O8, _), chomp(O8, B8), atom_codes(T8, B8),
    check('a recursion through environments, collected every 2000 cells, answers right',
          T8, 'go(200010000)\ng4(200010000)\nrr(6000)'),
    %% THE FREEZE, TORTURED (`COCOLOG_KMAT', 1.9.4). A freeze materialises
    %% the continuation -- every position back to the goal its frame held
    %% -- and freezes are rare, so a fault in it shows nowhere else. Under
    %% the knob every collection materialises first: 1 and puts it back,
    %% as a freeze does to the live machine around its image; 2 and keeps
    %% it, so the run goes on from the frames a thawed machine starts from.
    %% `rt/2' leaves a later builtin pending in every environment of a deep
    %% recursion, so each collection rebuilds thousands of them, and a
    %% wrong one is a wrong sum or an unknown procedure; `rb/2' leaves the
    %% three goals Stage 7 runs in place -- a `=/2', a builtin and an
    %% arithmetic guard -- and each is rebuilt as the term it was written as.
    atom_concat(D7, '/kmat.pl', F9),
    fixture(F9, [ 'rt(N, S) :- ( N =:= 0 -> S = 0 ; M is N - 1, rt(M, S0), S is S0 + N ).',
                  'rb(N, S) :- ( N =:= 0 -> S = 0 ; M is N - 1, rb(M, S0), atom_length(abc, L), T = S0, S is T + L ).',
                  'go :- rt(20000, S), write(rt(S)), nl, rb(20000, B), write(rb(B)), nl.' ]),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F9, ' go 2>&1'], Cmd9),
    proc_run(Cmd9, 120000, O9, _), chomp(O9, B9), atom_codes(T9, B9),
    check('a builtin pending in every environment of a recursion, collected', T9, 'rt(200010000)\nrb(60000)'),
    sh_join(['COCOLOG_GC_CELLS=2000 COCOLOG_KMAT=1 ', C, ' run ', F9, ' go 2>&1'], Cmd10),
    proc_run(Cmd10, 120000, O10, _), chomp(O10, B10), atom_codes(T10, B10),
    check('and materialised at every collection, then put back', T10, 'rt(200010000)\nrb(60000)'),
    sh_join(['COCOLOG_GC_CELLS=2000 COCOLOG_KMAT=2 ', C, ' run ', F9, ' go 2>&1'], Cmd11),
    proc_run(Cmd11, 120000, O11, _), chomp(O11, B11), atom_codes(T11, B11),
    check('and materialised and kept, as a thawed machine runs on', T11, 'rt(200010000)\nrb(60000)'),
    sh_join(['COCOLOG_GC_CELLS=2000 COCOLOG_KMAT=2 ', C, ' run ', F8, ' go 2>&1'], Cmd12),
    proc_run(Cmd12, 120000, O12, _), chomp(O12, B12), atom_codes(T12, B12),
    check('the recursions through environments, materialised and kept',
          T12, 'go(200010000)\ng4(200010000)\nrr(6000)'),
    nested_engines_collect(C, D7),
    directives_collect(C, D7),
    traced_collect(C, D7),
    tables_collect(C, D7).

%% A NESTED ENGINE COLLECTS (1.9.4). findall/3 and its family, call_metered/4
%% and with_output_to/2 run their goal in an engine of its own on the same
%% heap, and through 1.9.3 nothing collected in there: a long deterministic
%% phase inside one kept every cell it made (1.25 GB for the loop below).
%% Now the engines part way through a step are on the machine's chain, the
%% builtin that started each one has told the collector what its frame
%% holds, and the marks it winds the machine back to are a barrier the
%% trail is compacted against -- so a binding the search made to a variable
%% from before it is still undone after it (t2, t10), an outer choice point
%% is still there to backtrack into (t9), a ball still reaches its catch
%% (t8), and every answer is the one a run that never collected gives.
nested_engines_collect(C, D) :-
    atom_concat(D, '/nested.pl', F13),
    fixture(F13, [ 'long(N, S) :- numlist(1, N, L), sum_list(L, S).',
                   't1 :- statistics(heap_collections, C0), findall(S, long(200000, S), [S1]), statistics(heap_collections, C1), ( C1 > C0 -> G = collected ; G = none ), write(t1(S1, G)), nl.',
                   't2 :- X = f(Y), findall(Y-I, (member(I, [1,2,3]), long(50000, _), Y = I), L), write(t2(L)), nl, ( var(Y), X = f(V), var(V) -> write(unbound) ; write(bound) ), nl.',
                   't3 :- findall(X-L, (member(X, [a, b]), findall(S, (member(N, [30000, 40000]), long(N, S)), L)), R), write(t3(R)), nl.',
                   't4 :- forall(member(N, [100000, 120000]), (long(N, S), S > 0)), write(t4), nl.',
                   't5 :- aggregate_all(count, (between(1, 3, _), long(60000, _)), C), write(t5(C)), nl.',
                   't6 :- call_metered(long(100000, S), 100000000, _, R), write(t6(S, R)), nl.',
                   't7 :- with_output_to(atom(A), (long(80000, S), write(S))), write(t7(A)), nl.',
                   't8 :- catch(findall(S, (long(100000, S), throw(ball(S))), _), ball(B), (write(t8(B)), nl)).',
                   't9 :- member(X, [a, b, c]), findall(S, long(70000, S), [_]), X == c, write(t9(X)), nl.',
                   't10 :- length(L0, 3), findall(L0, (long(90000, S), L0 = [S|_]), [[R|_]]), write(t10(R)), nl, ( L0 = [A|_], var(A) -> write(fresh) ; write(bound) ), nl.',
                   't11 :- X = f(Y), findall(S, (Y = 1, garbage_collect, long(2000, S)), [_]), ( X = f(V), var(V) -> write(t11(unbound)) ; write(t11(bound)) ), nl.',
                   'go :- t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11.' ]),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F13, ' go 2>&1'], Cmd13),
    proc_run(Cmd13, 120000, O13, _), chomp(O13, B13), atom_codes(T13, B13),
    check('findall, forall, aggregate_all, call_metered, with_output_to, collected inside',
          T13, 't1(20000100000,collected)\nt2([1-1,2-2,3-3])\nunbound\nt3([a-[450015000,800020000],b-[450015000,800020000]])\nt4\nt5(3)\nt6(5000050000,true)\nt7(3200040000)\nt8(5000050000)\nt9(c)\nt10(4050045000)\nfresh\nt11(unbound)'),
    sh_join(['COCOLOG_GC_CELLS=2000 COCOLOG_KMAT=2 ', C, ' run ', F13, ' go 2>&1'], Cmd14),
    proc_run(Cmd14, 120000, O14, _), chomp(O14, B14), atom_codes(T14, B14),
    check('and with the freeze tortured at every collection', T14, T13),
    %% THREE MILLION TURNS INSIDE A findall/3, each leaving garbage, in an
    %% address space of 400 MB: 1.9.3 needed 1.25 GB and, refused, answered
    %% `done(1)' and then a type error over a cell it had overwritten
    atom_concat(D, '/inner.pl', F15),
    fixture(F15, [ 'loop(0) :- !.',
                   'loop(N) :- g(N, T), _ = f(T, T, T), M is N - 1, loop(M).',
                   'g(N, t(N, [a, b, c], N)).',
                   'go :- findall(x, loop(3000000), L), length(L, K), write(done(K)), nl.' ]),
    sh_join(['ulimit -v 400000; ', C, ' run ', F15, ' go 2>&1'], Cmd15),
    proc_run(Cmd15, 300000, O15, _), chomp(O15, B15), atom_codes(T15, B15),
    check('a long phase inside findall/3 runs in 400 MB', T15, 'done(1)'),
    %% A REQUEST NOTHING INSIDE COULD SERVE WAITS FOR THE OUTER ENGINE. The
    %% request is a threshold of 0 (`gc_next'), served at the top of the next
    %% step, and the end of a search puts back the threshold its start raised
    %% -- all but a 0: a search stopped at its inference limit ends before the
    %% top of the step that would have served it, and with the 0 put back too
    %% the request was gone (`served(0, ...)'). Through 1.9.5 the search here
    %% was a traced findall/3, which did not collect at all; since 1.9.6 it
    %% does.
    atom_concat(D, '/request.pl', F16),
    fixture(F16, [ 'go :- statistics(heap_collections, N0), call_metered(garbage_collect, 1, _, R), statistics(heap_collections, N1), K is N1 - N0, write(served(K, R)), nl.' ]),
    sh_join([C, ' run ', F16, ' go 2>&1'], Cmd16),
    proc_run(Cmd16, 120000, O16, _), chomp(O16, B16), atom_codes(T16, B16),
    check('garbage_collect/0 in a search stopped at its limit is served after it', T16, 'served(1,inference_limit_exceeded)').

%% A GOAL A LOAD RUNS COLLECTS (1.9.6). Through 1.9.5 a directive, an
%% `initialization/1' goal and one run `now' collected nothing (the goal
%% hook set no `gc'), so a long phase in one kept every cell it made, and a
%% script's start-up is mostly that. A goal hook collects now when every C
%% frame above it has said what it holds -- the machine's `dgc', set around
%% the one call by whoever vouches for its frames and cleared after it --
%% and the load registers what it holds across the goal: the directive's
%% term (`g' in `coco_directive'), and the heap mark it winds back to after
%% a directive and after an initialization goal (`mark' and `back' in
%% `coco_consult_owned'), as positions a collection moves. Each line below
%% is a goal that built more than the floor and collected: a directive,
%% both kinds of initialization goal, a binding made before a collection
%% and read after it, a ball caught inside the directive, a directive that
%% fails -- its message names the goal through `g' -- a file loaded as a
%% goal from inside one, its own directives and its initialization goal,
%% and the program after. Without `g' the message read `Goal (directive)
%% failed: 4', a term read at a cell the collection had moved.
directives_collect(C, D) :-
    atom_concat(D, '/dir.pl', F17), atom_concat(D, '/dir_b.pl', F17b),
    fixture(F17b, [ ':- churn(2000), mk(3, L), L == [3, 2, 9].',
                    ':- col(b).',
                    ':- initialization(col(bi)).' ]),
    atomic_list_concat([':- churn(300), ( true -> ensure_loaded(''', F17b, ''') ; true ), col(d2).'], Load17),
    fixture(F17, [ 'mk(0, []) :- !.',
                   'mk(N, [N|T]) :- N1 is N - 1, mk(N1, T).',
                   'churn(0) :- !.',
                   'churn(N) :- mk(50, _), N1 is N - 1, churn(N1).',
                   'col(Tag) :- statistics(heap_collections, A), churn(2000), statistics(heap_collections, B), ( B > A -> C = collected ; C = kept ), write(Tag-C), nl.',
                   ':- initialization(col(i1)).',
                   ':- col(d1).',
                   ':- initialization(col(i2), now).',
                   ':- X = f(Y), churn(2000), mk(4, Y), write(X), nl.',
                   ':- catch((churn(2000), mk(3, L), throw(ball(L))), ball(B), (write(caught(B)), nl)).',
                   Load17,
                   'go :- col(main).' ]),
    atomic_list_concat([ 'd1-collected\ni2-collected\nf([4,3,2,1])\ncaught([3,2,1])\n',
                         'Warning: ', F17b, ':1:\n',
                         'Warning:    Goal (directive) failed: churn(2000),mk(3,[3,2,1]),[3,2,1]==[3,2,9]\n',
                         'b-collected\nbi-collected\nd2-collected\ni1-collected\nmain-collected' ], Want17),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F17, ' go 2>&1'], Cmd17),
    proc_run(Cmd17, 120000, O17, _), chomp(O17, B17), atom_codes(T17, B17),
    check('directives and initialization goals collect, and every one answers right', T17, Want17),
    sh_join(['COCOLOG_GC_CELLS=2000 COCOLOG_KMAT=2 ', C, ' run ', F17, ' go 2>&1'], Cmd18),
    proc_run(Cmd18, 120000, O18, _), chomp(O18, B18), atom_codes(T18, B18),
    check('and with the freeze tortured at every collection', T18, T17),
    %% THE MARKS MOVE WITH THE HEAP. A collection inside the goal slides the
    %% live cells below the load's mark down under it, and a mark left where
    %% it stood puts the heap back as high as before the collection: nothing
    %% wrong, and nothing reclaimed. Each probe leaves garbage on the heap,
    %% loads a file whose one goal builds past the floor, and asks whether
    %% the heap is lower after the load than before it. Without the
    %% registration of `mark' the first probe read `mark-collected-held',
    %% without `back' the second `back-collected-held'.
    atom_concat(D, '/dirm.pl', F19), atom_concat(D, '/diri.pl', F19i),
    atom_concat(D, '/heap.pl', F19h),
    fixture(F19, [ ':- churn(1000).' ]),
    fixture(F19i, [ ':- initialization(churn(1000)).' ]),
    atomic_list_concat(['go :- probe(''', F19, ''', mark), probe(''', F19i, ''', back).'], Go19),
    fixture(F19h, [ 'mk(0, []) :- !.',
                    'mk(N, [N|T]) :- N1 is N - 1, mk(N1, T).',
                    'churn(0) :- !.',
                    'churn(N) :- mk(50, _), N1 is N - 1, churn(N1).',
                    'probe(F, Tag) :- churn(150), statistics(globalused, A), statistics(heap_collections, C0),',
                    '    ensure_loaded(F), statistics(globalused, B), statistics(heap_collections, C1),',
                    '    ( C1 > C0 -> Col = collected ; Col = kept ),',
                    '    ( B < A -> Fell = fell ; Fell = held ),',
                    '    write(Tag-Col-Fell), nl.',
                    Go19 ]),
    sh_join(['COCOLOG_GC_CELLS=100000 ', C, ' run ', F19h, ' go 2>&1'], Cmd19),
    proc_run(Cmd19, 120000, O19, _), chomp(O19, B19), atom_codes(T19, B19),
    check('a collection in a loaded file''s goal leaves the heap lower than before the load',
          T19, 'mark-collected-fell\nback-collected-fell').

%% A TRACED PROGRAM COLLECTS TOO (1.9.6). Through 1.9.5 the tracer kept
%% every collection off but the run's own engine's: a search a builtin
%% starts (findall/3 and its family, call_metered/4, with_output_to/2), a
%% goal a load runs and a file loaded as a goal each left `gc' off under
%% trace, so a traced program kept every cell those made (1.9.5 printed
%% `kept' on every line of the first check but `main'). What the tracer
%% holds is on the engines of the machine's chain -- each one's
%% `trace_goal', its traced choices' goals (`tchoices') and the indices in
%% its `$trace_exit' markers -- and the collector moves it for every engine
%% there, the outer ones too. So a traced run prints, line for line, what
%% a run that never collected prints, the `_G' names aside (a variable's
%% name is its heap position): both Redo lines below name the outer call
%% `w/1' after a findall/3 inside its body collected, the first from a
%% disjunction's choice made after it, the second from the call's own.
traced_collect(C, D) :-
    atom_concat(D, '/tload.pl', F20), atom_concat(D, '/tuse2.pl', F20u),
    atom_concat(D, '/tuse3.pl', F20v),
    fixture(F20u, [ ':- col(u2).' ]),
    fixture(F20v, [ ':- col(u3).' ]),
    atomic_list_concat([':- use_module(''', F20v, ''').'], Use20),
    atomic_list_concat(['go :- use_module(''', F20u, '''), col(main), findall(x, col(findall), _), forall(member(_, [a]), col(forall)), aggregate_all(count, col(aggregate_all), _), call_metered(col(call_metered), 100000000, _, _), with_output_to(atom(A), col(with_output_to)), write(A).'], Go20),
    fixture(F20, [ 'mk(0, []) :- !.',
                   'mk(N, [N|T]) :- N1 is N - 1, mk(N1, T).',
                   'churn(0) :- !.',
                   'churn(N) :- mk(50, _), N1 is N - 1, churn(N1).',
                   'col(Tag) :- statistics(heap_collections, A), churn(60), statistics(heap_collections, B), ( B > A -> C = collected ; C = kept ), write(Tag-C), nl.',
                   ':- col(d1).',
                   Use20,
                   ':- col(d2).',
                   ':- initialization(col(i1)).',
                   ':- initialization(col(i2), now).',
                   Go20 ]),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' --trace run ', F20, ' go 2>/dev/null'], Cmd20),
    proc_run(Cmd20, 120000, O20, _), chomp(O20, B20), atom_codes(T20, B20),
    check('under trace, goals a load runs and searches a builtin starts collect', T20,
          'd1-collected\nu3-collected\nd2-collected\ni2-collected\ni1-collected\nu2-collected\nmain-collected\nfindall-collected\nforall-collected\naggregate_all-collected\ncall_metered-collected\nwith_output_to-collected'),
    atom_concat(D, '/traced.pl', F21),
    fixture(F21, [ 'mk(0, []) :- !.',
                   'mk(N, [N|T]) :- N1 is N - 1, mk(N1, T).',
                   'churn(0) :- !.',
                   'churn(N) :- mk(50, _), N1 is N - 1, churn(N1).',
                   'w(L) :- findall(R, (churn(60), mk(3, R)), L), ( fail ; true ).',
                   'w(x).',
                   'v(X, W) :- X = f(Y), call_metered((churn(60), Y = 7), 100000000, _, _), with_output_to(atom(W), (churn(60), write(w))).',
                   'go :- churn(10), trace, w(L), L == x, v(X, W), notrace, write(L-X-W), nl.' ]),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F21, ' go 2>/dev/null'], Cmd21),
    proc_run(Cmd21, 120000, O21, _), chomp(O21, B21), atom_codes(T21, B21),
    check('a traced program that collects answers right', T21, 'x-f(7)-w'),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F21, ' go 2>&1 >/dev/null | sed ''s/_G[0-9]*/_G/g'' | grep '': (1) '''], Cmd22),
    proc_run(Cmd22, 120000, O22, _), chomp(O22, B22), atom_codes(T22, B22),
    check('and every outer line of its trace names the call it did, Redo too', T22,
          '   Call: (1) w(_G)\n   Redo: (1) w([[3,2,1]])\n   Exit: (1) w([[3,2,1]])\n   Call: (1) [[3,2,1]]==x\n   Fail: (1) [[3,2,1]]==x\n   Redo: (1) w(_G)\n   Exit: (1) w(x)\n   Call: (1) x==x\n   Exit: (1) x==x\n   Call: (1) v(_G,_G)\n   Exit: (1) v(f(7),w)'),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F21, ' go 2>&1 >/dev/null | sed ''s/_G[0-9]*/_G/g'' | cksum'], Cmd23),
    proc_run(Cmd23, 120000, O23, _), chomp(O23, B23), atom_codes(T23, B23),
    sh_join([C, ' run ', F21, ' go 2>&1 >/dev/null | sed ''s/_G[0-9]*/_G/g'' | cksum'], Cmd24),
    proc_run(Cmd24, 120000, O24, _), chomp(O24, B24), atom_codes(T24, B24),
    check('and its whole trace is the one a run that never collects prints', T23, T24),
    sh_join(['COCOLOG_GC_CELLS=2000 COCOLOG_KMAT=2 ', C, ' run ', F21, ' go 2>&1 >/dev/null | sed ''s/_G[0-9]*/_G/g'' | cksum'], Cmd25),
    proc_run(Cmd25, 120000, O25, _), chomp(O25, B25), atom_codes(T25, B25),
    check('and with the freeze tortured at every collection', T25, T24).

%% THE FLOAT AND STRING TABLES ARE RECLAIMED (1.9.6). A float or a string
%% cell names an entry of a table of the machine's, and through 1.9.5 no
%% entry was ever given back: the loop below makes 300 000 strings and as
%% many floats, and the tables grew by as much (1.9.5 printed `grew-grew',
%% with 200 009 and 300 009 strings at the two counts). A collection now
%% marks every entry a word names -- on the heap, in the store of every
%% engine on the machine's chain (the clauses, asserted or consulted, and
%% the globals) and in the compiled programs -- and the next float or
%% string takes a dead entry before the table grows
%% (`coco_tables_reclaim'). Each value printed lives in one of those
%% places across collections that gave back the loop's entries around it;
%% the table stays small (`bounded') and the strings made after the first
%% count take its entries again (`reused'). With the store and the programs
%% left unmarked (the arm) `go' fails: the loop's own `-1.0' is given back
%% and taken by a float the loop makes, so `F > -1.0' fails; without that
%% comparison the global's 3.25 and the clause's 1.25 read back as 48307.0
%% and 48305.0, and their strings as "".
%%
%% A loop that asks for no collection is given one: every `tlimit' entries
%% made (65 536 at first), a collection is asked for if the entries made
%% since the last reclamation reach half the heap's length
%% (`coco_table_made'), so a collection, which costs the heap, is paid for
%% by as many entries. The second fixture's loop grows one cell of heap a
%% turn (the body of `rep''s second clause, built above the choice the
%% next turn leaves; `rep :- true, rep' grows six), too little to reach the
%% floor of 4 194 304 cells in 300 000 turns: with the question taken out
%% (the arm) it ends with 300 000 strings, and with it 92 945. A loop
%% driven by `between/3' grows five cells a turn and is asked nothing: its
%% strings stay within a constant of its heap.
tables_collect(C, D) :-
    atom_concat(D, '/tables.pl', F26),
    fixture(F26, [ ':- set_prolog_flag(double_quotes, string).',
                   ':- dynamic(keep/2).',
                   'lit(1.25, "in a clause").',
                   'churn(N) :- forall(between(1, N, I), (number_string(I, S), atom_length(S, _), F is I * 0.5, F > -1.0)).',
                   'go :-',
                   '    X is 2.5, S0 = "on the heap", nb_setval(gk, f(3.25, "in a global")),',
                   '    assertz(keep(1.75, "asserted")),',
                   '    findall(V-T, (between(1, 3, K), V is K * 0.25, number_string(K, T)), L0),',
                   '    churn(200000), garbage_collect,',
                   '    statistics(strings, Ns1),',
                   '    churn(50000),',
                   '    assertz(keep(9.5, "retracted")), retract(keep(9.5, _)), assertz(keep(8.5, "asserted after")),',
                   '    churn(50000), garbage_collect,',
                   '    statistics(strings, Ns2),',
                   '    nb_getval(gk, G), findall(A-B, keep(A, B), Ks), lit(Lf, Ls),',
                   '    ( Ns1 < 100000 -> Bd = bounded ; Bd = grew ),',
                   '    ( Ns2 =< Ns1 -> Kp = reused ; Kp = grew ),',
                   '    writeq(X-S0-G-Ks-Lf-Ls), nl, writeq(L0), nl, write(Bd-Kp), nl.' ]),
    Want26 = '2.5-"on the heap"-f(3.25,"in a global")-[1.75-"asserted",8.5-"asserted after"]-1.25-"in a clause"\n[0.25-"1",0.5-"2",0.75-"3"]\nbounded-reused',
    sh_join([C, ' run ', F26, ' go 2>&1'], Cmd26),
    proc_run(Cmd26, 120000, O26, _), chomp(O26, B26), atom_codes(T26, B26),
    check('floats and strings a loop made are given back, and every one held reads right', T26, Want26),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F26, ' go 2>&1'], Cmd27),
    proc_run(Cmd27, 120000, O27, _), chomp(O27, B27), atom_codes(T27, B27),
    check('and with a collection every 2000 cells', T27, Want26),
    sh_join(['COCOLOG_GC_CELLS=2000 COCOLOG_KMAT=1 ', C, ' run ', F26, ' go 2>&1'], Cmd28),
    proc_run(Cmd28, 120000, O28, _), chomp(O28, B28), atom_codes(T28, B28),
    check('and with every collection a freeze put back', T28, Want26),
    sh_join(['COCOLOG_GC_CELLS=2000 COCOLOG_KMAT=2 ', C, ' run ', F26, ' go 2>&1'], Cmd29),
    proc_run(Cmd29, 120000, O29, _), chomp(O29, B29), atom_codes(T29, B29),
    check('and with every collection a freeze kept', T29, Want26),
    atom_concat(D, '/churn.pl', F30),
    fixture(F30, [ 'rep.',
                   'rep :- rep.',
                   'churn(N) :- nb_setval(cnt, 0), rep, nb_getval(cnt, I), I1 is I + 1, nb_setval(cnt, I1), number_string(I1, S), atom_length(S, _), F is I1 * 0.5, F > -1.0, I1 >= N, !.',
                   'go :- churn(300000), statistics(strings, Ns), ( Ns < 200000 -> write(bounded) ; write(grew(Ns)) ), nl.' ]),
    sh_join([C, ' run ', F30, ' go 2>&1'], Cmd30),
    proc_run(Cmd30, 120000, O30, _), chomp(O30, B30), atom_codes(T30, B30),
    check('a loop that asks for no collection and grows little heap is given its strings back', T30, bounded),
    sh_join(['COCOLOG_GC_CELLS=2000 ', C, ' run ', F30, ' go 2>&1'], Cmd31),
    proc_run(Cmd31, 120000, O31, _), chomp(O31, B31), atom_codes(T31, B31),
    check('and by the collections a small floor brings', T31, bounded).
