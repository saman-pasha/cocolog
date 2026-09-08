%% library(cowork) -- a crew of workers that outlives the turn.
%%
%% THE CLAIM THAT MATTERS IS NOT SPEED, it is that parallelism is INVISIBLE
%% in the answer. A crew whose results depended on who finished first would
%% make the same match replay differently on a busier machine, and this
%% family's whole story about deterministic replay would be worth nothing.
%% So the first checks here drive jobs of deliberately unequal cost -- one
%% four times the others, so it certainly finishes last -- and hold the
%% answers to INPUT order.
%%
%% THE SECOND CLAIM IS THAT NOTHING IS SWALLOWED. A job that fails, a job
%% that throws and a job that proves are three different answers, the same
%% decision `thread_join/2' makes, and a crew that folded them together
%% would turn a bug in a worker into a silently missing city.
%%
%% AND THE DISCIPLINE IS CHECKED TOO, because it is the part a caller gets
%% wrong: a worker sees the MODULE REGISTRY, never the caller's store, so a
%% clause the caller asserted is invisible in a job and `cowork_tell/2' is
%% the only way state crosses.
%%
%%     cocolog -s test/cowork.pl        from the checkout root
%%
%% SKIPs without library/thread.so -- sh modules/thread/build.sh.

:- use_module('test/prelude.pl').
:- use_module(library(cowork)).

:- dynamic caller_only/1.

main :-
    (   catch(use_module(library(thread)), _, fail)
    ->  true
    ;   skip('(no library/thread.so -- sh modules/thread/build.sh)')
    ),
    scratch(D),
    %% THE JOBS LIVE IN A MODULE, loaded BEFORE any crew starts, because a
    %% worker's store is filled from the process-wide registry and knows
    %% nothing of this file's own clauses. That is the library's one rule
    %% for the caller and the case has to obey it like anybody else.
    atom_concat(D, '/cowork_jobs.pl', Jobs),
    fixture(Jobs,
            [ 'spin(0) :- !.',
              'spin(N) :- M is N - 1, spin(M).',
              '',
              'double(X, Y) :- Y is X * 2.',
              '',
              '%% Costs X units, so a job list with unequal X finishes out of order.',
              'slow(X, Y) :- S is X * 150000, spin(S), Y is X * 2.',
              '',
              'boom(X) :- throw(too_big(X)).',
              '',
              '%% reads what cowork_tell/2 put in the worker''s own store',
              'yield(Tile, Y) :- tile(Tile, F, P), Y is F + P.' ]),
    use_module(Jobs),
    answers_and_order, outcomes, telling, the_discipline, many_turns, parallel,
    pipelining, a_worker_always_answers(D), bounded_waits,
    shl(['rm -rf ', D]),
    checks_done.

%% ---- the answers, and their order ---------------------------------------

answers_and_order :-
    section('a crew answers what the sequential path answers, in input order'),
    cowork_start(4, [], C1),
    written(( cowork_map(C1, [double(1,_), double(2,_), double(3,_), double(4,_)], R1) ), R1, G1),
    check('the answers are the goals as the workers proved them', G1,
          '[ok(double(1,2)),ok(double(2,4)),ok(double(3,6)),ok(double(4,8))]'),
    %% THE ONE THAT WOULD CATCH A COMPLETION-ORDER CREW. Job 1 costs four
    %% times what the others do, so on four workers it finishes LAST; if the
    %% results were gathered as they arrived, ok(slow(4,8)) would not be
    %% first.
    written(( cowork_map(C1, [slow(4,_), slow(1,_), slow(1,_), slow(1,_)], R2) ), R2, G2),
    check('a job that finishes last is still the first answer', G2,
          '[ok(slow(4,8)),ok(slow(1,2)),ok(slow(1,2)),ok(slow(1,2))]'),
    %% more jobs than workers, so the dispatcher hands seconds out as
    %% workers free up -- and the order still has to survive it
    written(( numlist(1, 12, Ns3),
              findall(double(N3, _), member(N3, Ns3), Gs3),
              cowork_map(C1, Gs3, R3),
              findall(V3, member(ok(double(_, V3)), R3), Vs3) ), Vs3, G3),
    check('twelve jobs over four workers keep their order', G3,
          '[2,4,6,8,10,12,14,16,18,20,22,24]'),
    written(( cowork_map(C1, [], R4) ), R4, G4),
    check('and no jobs is an empty answer, not a hang', G4, '[]'),
    cowork_stop(C1).

%% ---- what is not swallowed ----------------------------------------------

outcomes :-
    section('proved, failed and threw are three answers'),
    cowork_start(2, [], C1),
    written(( cowork_map(C1, [double(1,_), fail, boom(5), double(2,_)], R1) ), R1, G1),
    check('each outcome is carried, in its own slot', G1,
          '[ok(double(1,2)),failed,error(too_big(5)),ok(double(2,4))]'),
    %% THE CREW SURVIVES A THROWN BALL. A worker that died of one would take
    %% the next job with it, so the check is that the same crew still works.
    written(( cowork_map(C1, [double(7,_)], R2) ), R2, G2),
    check('and the worker that threw is still in the crew', G2, '[ok(double(7,14))]'),
    written(( cowork_ask(C1, double(21, X3)) ), X3, G3),
    check('cowork_ask/2 unifies the answer into the caller''s goal', G3, '42'),
    yes_no(cowork_ask(C1, fail), G4),
    check('a failing job fails cowork_ask/2', G4, no),
    written(( catch(cowork_ask(C1, boom(9)), B5, true) ), B5, G5),
    check('and a thrown ball is thrown again here', G5, 'too_big(9)'),
    cowork_stop(C1).

%% ---- telling the crew ---------------------------------------------------

telling :-
    section('cowork_tell/2 is the only way state crosses'),
    cowork_start(3, [], C1),
    %% AN UNTOLD PREDICATE RAISES, IT DOES NOT FAIL, and that is ordinary
    %% Prolog rather than anything this library does: `tile/3' has no clauses
    %% in a worker that was never told any, and an undefined procedure is an
    %% existence_error. What the crew is being held to here is that it
    %% CARRIED it -- a crew that answered `failed' would have turned "the
    %% snapshot never arrived" into "this tile has no yield", which is the
    %% silent kind of wrong.
    written(( cowork_map(C1, [yield(a, _)], R1),
              R1 = [error(error(E1, _))] ), E1, G1),
    check('before it is told, an untold predicate is an error and not a no', G1,
          'existence_error(procedure,tile/3)'),
    written(( cowork_tell(C1, [tile(a, 2, 1), tile(b, 3, 4)]),
              cowork_map(C1, [yield(a, _), yield(b, _)], R2) ), R2, G2),
    check('every worker gets its own copy, so any of them can answer', G2,
          '[ok(yield(a,3)),ok(yield(b,7))]'),
    %% EVERY worker, not one: twelve jobs over three workers all answer, which
    %% they could not if the broadcast had reached only whoever was first.
    written(( findall(yield(a, _), between(1, 12, _), Gs3),
              cowork_map(C1, Gs3, R3),
              findall(x, member(ok(_), R3), Oks3), length(Oks3, N3) ), N3, G3),
    check('all three workers hold it, not just the one that was idle', G3, '12'),
    written(( cowork_forget(C1, [tile(_, _, _)]),
              cowork_map(C1, [yield(a, _)], R4) ), R4, G4),
    check('and forgetting it takes it out of every worker', G4, '[failed]'),
    cowork_stop(C1),
    %% THE CALLER'S LEVER FOR THE ERROR ABOVE, and the only check of
    %% `on_start' there is: a goal run once in each worker before any job.
    %% Declaring the turn's predicates dynamic there makes an untold one FAIL
    %% like an empty table, which is what a caller that treats absence as an
    %% ordinary answer wants.
    cowork_start(2, [on_start(dynamic(tile/3))], C5),
    written(( cowork_map(C5, [yield(a, _)], R5) ), R5, G5),
    check('on_start runs in every worker: declared dynamic, it fails instead', G5,
          '[failed]'),
    cowork_stop(C5).

the_discipline :-
    section('a worker sees the module registry, never the caller''s store'),
    assertz(caller_only(1)),
    cowork_start(2, [], C1),
    written(( cowork_map(C1, [caller_only(_)], R1) ), R1, G1),
    check('a clause the caller asserted is invisible in a job', G1, '[failed]'),
    written(( cowork_map(C1, [double(3,_)], R2) ), R2, G2),
    check('while a predicate from a module is there', G2, '[ok(double(3,6))]'),
    retractall(caller_only(_)),
    cowork_stop(C1).

%% ---- the crew outlives the turn -----------------------------------------

many_turns :-
    section('a crew outlives many turns, which is why it is started once'),
    cowork_start(3, [], C1),
    %% Ten rounds of tell, ask, forget on ONE crew. The library exists
    %% because starting a worker costs what the program costs -- 23.8ms
    %% against a 3 000-clause module, measured -- so a crew that could not
    %% be reused would have no reason to exist.
    written(( turns(C1, 10, Sum1) ), Sum1, G1),
    check('ten turns of tell, ask and forget on one crew', G1, '110'),
    written(( cowork_size(C1, N2) ), N2, G2),
    check('and the crew is the size it was started at', G2, '3'),
    cowork_stop(C1).

turns(_, 0, 0) :- !.
turns(C, N, Sum) :-
    cowork_tell(C, [tile(t, N, N)]),
    cowork_ask(C, yield(t, Y)),
    cowork_forget(C, [tile(_, _, _)]),
    M is N - 1,
    turns(C, M, S0),
    Sum is S0 + Y.

%% ---- and it really is parallel -------------------------------------------

parallel :-
    section('four workers do four times the work in well under four times'),
    %% THE SAME SHAPE test/thread.pl USES, and the same loose threshold: this
    %% proves the workers are not taking turns, not that the scheduler is
    %% good. A tight ratio fails on a loaded machine and proves nothing extra.
    cowork_start(1, [], C1),
    get_time(T0), cowork_map(C1, [slow(2,_), slow(2,_), slow(2,_), slow(2,_)], _), get_time(T1),
    cowork_stop(C1),
    One is round((T1 - T0) * 1000),
    cowork_start(4, [], C2),
    get_time(T2), cowork_map(C2, [slow(2,_), slow(2,_), slow(2,_), slow(2,_)], _), get_time(T3),
    cowork_stop(C2),
    Four is round((T3 - T2) * 1000),
    format("     one worker ~wms, four workers ~wms~n", [One, Four]),
    ( One > 0, Four < One * 3 // 4 -> R = parallel ; R = serial ),
    check('the same four jobs are faster on four workers than on one', R, parallel).

%% ---- posting, and collecting a frame later ------------------------------
%%
%% THE ONLY WAY WORK LEAVES A FRAME THAT HAS A DEADLINE. `cowork_map/3'
%% waits, so a frame calling it has not moved the work -- it has moved where
%% the time is spent. `cowork_post/2' does not wait and `cowork_poll/2' asks
%% without blocking, which is the "one frame behind" arrangement: measured,
%% a loop doing its own derived state cost 35.4ms a frame and the same loop
%% posting it cost 3.7ms.
%%
%% THE CHECK THAT MATTERS IS THE ISOLATION. A posted answer must not be
%% taken by a `map', and a map's answers must not be taken by a `poll' --
%% they are different channels for exactly that reason, and a crew that
%% shared one would hand a renderer somebody else's answer.
pipelining :-
    section('post and poll: work that leaves the frame'),
    cowork_start(3, [], C1),
    yes_no(cowork_poll(C1, _), G1),
    check('a poll with nothing posted FAILS rather than blocking', G1, no),
    written(( cowork_post(C1, double(4, _)),
              ( cowork_poll(C1, 5000, R2) -> true ; R2 = never ) ), R2, G2),
    check('a posted job comes back through poll/3', G2, 'ok(double(4,8))'),
    %% THE ISOLATION, in both directions and in one goal: a posted answer is
    %% outstanding while a whole map runs, and neither takes the other's.
    written(( cowork_post(C1, slow(1, _)),
              cowork_map(C1, [double(1,_), double(2,_), double(3,_)], R3),
              ( cowork_poll(C1, 5000, P3) -> true ; P3 = eaten_by_the_map ),
              length(R3, N3) ), N3-P3, G3),
    check('a map cannot take a posted answer, nor a poll a map''s', G3,
          '3-ok(slow(1,2))'),
    yes_no(cowork_poll(C1, _), G4),
    check('and nothing is left over afterwards', G4, no),
    %% several in flight is allowed -- the pacing is the caller's choice, and
    %% the library's job is only to keep them apart and give them all back
    written(( cowork_post(C1, double(5, _)), cowork_post(C1, double(6, _)),
              cowork_post(C1, double(7, _)),
              findall(V4, ( between(1, 3, _), cowork_poll(C1, 5000, ok(double(_, V4))) ), Vs4),
              msort(Vs4, S4) ), S4, G5),
    check('three posted, three collected', G5, '[10,12,14]'),
    cowork_stop(C1).

%% ---- a worker that cannot do it says so, and does not vanish ------------
%%
%% REPORTED FROM CivV AS A HANG, and it was one: `cowork_tell/2' asserted in
%% each worker and waited for an acknowledgement, and the worker sent one
%% only if the assert had WORKED. A clause too long for a row raises
%% `resource_error(clause_length)' the moment a worker has a database under
%% it -- which is every worker under `--embed' -- so the worker fell out of
%% its loop, nobody acked, and the caller waited for ever on a channel
%% nothing would ever be sent to. CivV met it with `chronicle_snap/2', whose
%% rows each hold a whole sorted LIST of another predicate's facts, so the
%% terms are far bigger than the fact count suggests.
%%
%% A HANG IS THE WORST WAY TO REPORT THAT. It names nothing, it happens on
%% another thread, and it reads as the crew being slow. The ack carries the
%% outcome now and is always sent.
%%
%% IN A CHILD, WITH A TIMEOUT, because the thing being checked is that a
%% goal RETURNS: a regression here would hang this case rather than fail it,
%% and a suite that has to be killed says nothing about what broke.
a_worker_always_answers(D) :-
    section('a worker that cannot assert says so, and the caller is not left waiting'),
    atom_concat(D, '/toolong.pl', Prog),
    fixture(Prog,
            [ ':- use_module(library(cowork)).',
              'main :-',
              '    cowork_start(2, [], C),',
              '    length(L, 9000), maplist(=(0''x), L), atom_codes(A, L),',
              '    (   catch(cowork_tell(C, [big(A)]), error(E, _), true)',
              '    ->  ( var(E) -> R = told ; R = E )',
              '    ;   R = failed',
              '    ),',
              '    cowork_tell(C, [small(1)]),',
              '    cowork_map(C, [small(_)], M),',
              '    cowork_stop(C),',
              '    write(answer(R-M)), nl.' ]),
    atom_concat(D, '/kb', KB),
    cocolog(C1),
    sh_join(['timeout 60 ', C1, ' --embed ', KB, ' -s ', Prog, ' 2>&1'], Cmd),
    proc_run(Cmd, 90000, Out, Rc),
    check('the child returned at all -- a hang here is the defect itself', Rc, 0),
    ( re_first_atom('answer\\([^\n]*\\)', Out, A1) -> sub_atom(A1, 7, _, 1, G1) ; G1 = no_answer ),
    check('a clause too long for a row RAISES, and the crew still answers', G1,
          'resource_error(clause_length)-[ok(small(1))]').

%% ---- no wait here is unbounded ------------------------------------------
%%
%% THE CATCH IN THE WORKER LOOP CANNOT COVER EVERYTHING. A worker can die
%% before it reads its first message -- a store fill that raises, say -- and
%% then the loop that would have answered was never reached, so a caller
%% waiting for an acknowledgement waits for ever. That is not fixable in the
%% worker; it is fixable by refusing to wait without a bound.
%%
%% Every wait takes the crew's timeout (60s by default, `timeout(Ms)' at
%% start) and a missing answer is `timeout_error(cowork, Missing)' naming how
%% many never came. Generous enough that a cold worker paying its store fill
%% is never mistaken for a dead one, finite so a dead one is never mistaken
%% for a slow crew.
bounded_waits :-
    section('a wait that cannot be answered ends, and says so'),
    %% A one-worker crew given 60ms and a job that takes far longer is the
    %% same shape as a worker that will never answer, and it is deterministic
    %% where killing a thread is not.
    cowork_start(1, [timeout(60)], C1),
    written(( catch(cowork_map(C1, [slow(9, _)], _), error(E1, _), true) ), E1, G1),
    check('a gather that cannot finish raises rather than hanging', G1,
          'timeout_error(cowork,1)'),
    cowork_stop(C1),
    cowork_start(2, [], C2),
    written(( cowork_warm(C2), cowork_pending(C2, P2) ), P2, G2),
    check('a warmed crew has nothing queued behind it', G2, '0'),
    %% and the ordinary path is unaffected by the bound
    written(( cowork_tell(C2, [warm_fact(1)]), cowork_map(C2, [warm_fact(_)], R3) ), R3, G3),
    check('and the bound does not disturb an ordinary tell and map', G3,
          '[ok(warm_fact(1))]'),
    cowork_stop(C2).
