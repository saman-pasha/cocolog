%% library(thread) -- threads that share nothing, channels that copy.
%%
%% THE TWO CLAIMS WORTH CHECKING are that it is really parallel and that
%% nothing is lost under contention. Everything else here is semantics --
%% what a closed channel does, what a failed thread reports -- and those are
%% cheap. The two that matter are the last two sections, and neither can be
%% checked by reading the code.
%%
%% CONTENTION IS CHECKED BY COUNTING, not by timing. Eight threads each send
%% a hundred terms into one channel; if the ring, the head index or the
%% condition variables were wrong the count comes out short or the run hangs,
%% and a count is a verdict where a stopwatch is an opinion.
%%
%% PARALLELISM IS CHECKED BY TIMING, because there is no other way. Four
%% threads doing the same work as one should take rather less than four times
%% as long, and the threshold here is deliberately loose: this proves the
%% threads are not taking turns, not that the scheduler is good.
%%
%%     cocolog -s test/thread.pl        from the checkout root
%%
%% ONE PROCESS FOR NINETEEN CHECKS, where test/thread.sh spawned one per
%% check (13.1 s on this machine). The timing pair is cleaner for it: the
%% .sh timed two whole processes, start-up included, and this times the
%% threads.

:- use_module('test/prelude.pl').

main :-
    (   catch(use_module(library(thread)), _, fail)
    ->  true
    ;   skip('(no library/thread.so -- sh modules/thread/build.sh)')
    ),
    scratch(D),
    %% A MODULE, loaded before any thread starts. This is how a thread sees
    %% a predicate at all: its store is empty, and what fills it is the
    %% process-wide module registry consulted on the first goal.
    atom_concat(D, '/work.pl', Work),
    fixture(Work,
            [ 'spin(0) :- !.',
              'spin(N) :- M is N - 1, spin(M).',
              '',
              '%% Sends Count terms into Ch, tagged with Who, then stops. The body of the',
              '%% contention case.',
              'flood(_, _, 0) :- !.',
              'flood(Ch, Who, N) :- channel_send(Ch, item(Who, N)), M is N - 1, flood(Ch, Who, M).',
              '',
              '%% Receive up to Want items, counting what actually arrived. The timeout is',
              '%% what turns a LOST message into a short count instead of a hung test --',
              '%% which is the difference between a failure that names itself and one that',
              '%% has to be killed and guessed at.',
              'th_drain_n(_, 0, N, N) :- !.',
              'th_drain_n(Ch, K, Acc, N) :-',
              '    channel_recv(Ch, 5000, _), !,',
              '    A is Acc + 1, K1 is K - 1,',
              '    th_drain_n(Ch, K1, A, N).',
              'th_drain_n(_, _, N, N).',
              '',
              '%% ---- what the lock section spawns ----',
              '%% Takes the lock, SAYS SO, and holds it until it is told to let go --',
              '%% which is what makes the exclusion check deterministic: the parent',
              '%% knows the child is inside before it tries.',
              'holder(M, Ready, Rel) :- mutex_lock(M), channel_send(Ready, in), channel_recv(Rel, _), mutex_unlock(M).',
              'named_holder(Ready, Rel) :- with_mutex(shared_name, ( channel_send(Ready, in), channel_recv(Rel, _) )).',
              '',
              '%% READY IS SENT WHILE THE MUTEX IS HELD, which is the whole of the',
              '%% lost-wakeup problem: the parent cannot take M to signal until this',
              '%% thread is inside cond_wait, because that is where M is released.',
              'waiter(C, M, Ready, Out) :- mutex_lock(M), channel_send(Ready, r), cond_wait(C, M), mutex_unlock(M), channel_send(Out, woke).',
              'nested(M, Out) :- with_mutex(M, with_mutex(M, true)), channel_send(Out, nested_ok).',
              '',
              '%% IS IT FREE? ONLY ANOTHER THREAD CAN SAY. A recursive mutex says yes to',
              '%% a trylock from the thread that already holds it -- that is what',
              '%% recursive MEANS -- so asking in the thread under test proves nothing.',
              'try_take(M, Out) :- ( mutex_trylock(M) -> mutex_unlock(M), channel_send(Out, free) ; channel_send(Out, still_held) ).',
              'leak(M, Out) :- catch(( mutex_lock(M), throw(x) ), _, true), channel_send(Out, leaked).',
              '',
              '%% Count up to K arrivals, or stop at the timeout -- a lost wakeup is a',
              '%% short count here rather than a suite that hangs.',
              'nrecv(_, 0, N, N) :- !.',
              'nrecv(Ch, K, A, N) :- channel_recv(Ch, 5000, _), !, A1 is A + 1, K1 is K - 1, nrecv(Ch, K1, A1, N).',
              'nrecv(_, _, N, N).' ]),
    use_module(Work),
    a_thread, what_it_sees, a_channel, closed, backpressure, helpers, contention, parallel,
    locks, conditions,
    shl(['rm -rf ', D]),
    checks_done.

a_thread :-
    section('a thread is a goal on a machine of its own'),
    written(( thread_create((X1 is 2+2, X1 =:= 4), I1), thread_join(I1, S1) ), S1, G1),
    check('it runs and joins', G1, true),
    %% A THREAD THAT FAILED IS A THREAD THAT RAN. Failing the join instead
    %% would make "it did not prove it" and "it never started" the same answer.
    written(( thread_create(fail, I2), thread_join(I2, S2) ), S2, G2),
    check('a goal that fails reports false, and join succeeds', G2, false),
    written(( thread_create((X3 is 1/0, write(X3)), I3), thread_join(I3, S3),
              ( S3 = error(_) -> W3 = tagged ; W3 = S3 ) ), W3, G3),
    check('a goal that raises reports error(Message)', G3, tagged),
    written(( thread_create((X4 is 1/0, write(X4)), I4), thread_join(I4, error(M4)),
              ( sub_atom(M4, _, _, _, zero_divisor) -> W4 = named ; W4 = vague ) ), W4, G4),
    check('and the message names the fault', G4, named).

what_it_sees :-
    section('what a thread can see, and what it cannot'),
    %% The registry is process-wide, so a module loaded BEFORE the thread
    %% started is there. This is the whole reason a worker can be useful at all.
    written(( thread_create(spin(1000), I1), thread_join(I1, S1) ), S1, G1),
    check('a module loaded before it started is there', G1, true),
    %% ...and the parent's own clauses are NOT, because a thread's store is
    %% empty and clauses are shared through the database in this project, not
    %% memory. Documented rather than fixed: it is the share-nothing rule holding.
    written(( assertz(only_here(1)), thread_create(only_here(_), I2), thread_join(I2, S2),
              ( S2 = error(_) -> A2 = unseen ; A2 = S2 ) ), A2, G2),
    check('a clause the PARENT asserted is not', G2, unseen).

a_channel :-
    section('a channel carries a term between two machines'),
    written(( channel_new(Ch1), thread_create(channel_send(Ch1, hello(world)), I1),
              channel_recv(Ch1, M1), thread_join(I1, _) ), M1, G1),
    check('a term crosses', G1, 'hello(world)'),
    %% STRUCTURE SURVIVES, which is what canonical form buys: quoted atoms and
    %% operators written as compounds, so the far machine reads the same term
    %% even having run no `op/3' of its own.
    written(( channel_new(Ch2),
              thread_create(channel_send(Ch2, f(1+2, 'an atom', [a,b|_], "xy")), I2),
              channel_recv(Ch2, f(A2, B2, C2, D2)), thread_join(I2, _),
              ( A2 == 1+2, B2 == 'an atom', C2 = [a,b|_], D2 == "xy" -> R2 = intact ; R2 = mangled ) ), R2, G2),
    check('and so does its structure, operators and all', G2, intact).

closed :-
    section('what a closed channel does'),
    written(( channel_new(Ch1), channel_close(Ch1),
              ( channel_recv(Ch1, _) -> R1 = got ; R1 = failed ) ), R1, G1),
    check('receiving from a closed empty channel FAILS', G1, failed),
    %% CLOSING DOES NOT DISCARD. Anything already queued comes out first, and
    %% only then does recv start saying no -- otherwise a close would silently
    %% drop whatever was in flight.
    written(( channel_new(Ch2), channel_send(Ch2, a), channel_send(Ch2, b),
              channel_close(Ch2), channel_recv(Ch2, X2), channel_recv(Ch2, Y2),
              ( channel_recv(Ch2, _) -> Z2 = more ; Z2 = done ),
              atomic_list_concat([X2,Y2,Z2], '-', R2) ), R2, G2),
    check('but what was queued before the close still comes out', G2, 'a-b-done'),
    written(( channel_new(Ch3), channel_close(Ch3),
              ( channel_send(Ch3, x) -> R3 = sent ; R3 = refused ) ), R3, G3),
    check('sending to a closed channel fails rather than raising', G3, refused),
    written(( channel_new(Ch4), ( channel_recv(Ch4, 300, _) -> R4 = got ; R4 = timed_out ) ), R4, G4),
    check('a timeout fails rather than hanging', G4, timed_out),
    written(( channel_new(Ch5), channel_send(Ch5, only), channel_recv(Ch5, 0, X5),
              ( channel_recv(Ch5, 0, _) -> Y5 = more ; Y5 = empty ),
              atomic_list_concat([X5,Y5], '-', R5) ), R5, G5),
    check('and zero means take only what is already there', G5, 'only-empty').

backpressure :-
    section('backpressure: a bounded channel makes the sender wait'),
    %% The sender fills the channel and then BLOCKS. If the bound were not
    %% enforced this would finish immediately with a size of 3; if the block
    %% were not released by the receive it would hang and time out.
    written(( channel_new(2, Ch1),
              thread_create((channel_send(Ch1,1), channel_send(Ch1,2), channel_send(Ch1,3), channel_send(Ch1,4)), I1),
              channel_recv(Ch1, _), channel_recv(Ch1, _), channel_recv(Ch1, _), channel_recv(Ch1, _),
              thread_join(I1, S1) ), S1, G1),
    check('a bounded channel holds no more than its capacity', G1, true).

helpers :-
    section('the helpers the Coco half adds'),
    %% The failure-driven consumer, and the reason `recv fails when closed and
    %% empty' is the right semantics: no sentinel value, no counting, the loop
    %% just ends. It runs in THIS thread, so assertz is the parent's own store.
    written(( channel_new(Ch1), channel_send(Ch1,1), channel_send(Ch1,2), channel_send(Ch1,3), channel_close(Ch1),
              channel_forall(Ch1, [T1]>>assertz(seen(T1))),
              findall(X1, seen(X1), L1), length(L1, N1) ), N1, G1),
    check('channel_forall reads until the channel is done', G1, '3'),
    written(( channel_new(Ch2), channel_send(Ch2,a), channel_send(Ch2,b),
              channel_drain(Ch2, L2), length(L2, N2) ), N2, G2),
    check('channel_drain takes what is queued without blocking', G2, '2'),
    written(( thread_pool(4, spin(1000), Ids3), thread_join_all(Ids3), length(Ids3, N3) ), N3, G3),
    check('thread_pool starts them and join_all waits', G3, '4').

contention :-
    section('NOTHING IS LOST UNDER CONTENTION, which is the channel''s real claim'),
    %% Eight threads, a hundred terms each, one channel. A wrong head index, a
    %% missed signal or a torn ring shows up as a short count or a hang -- and
    %% a count is a verdict where a stopwatch is an opinion.
    written(( channel_new(Ch1), thread_pool(8, flood(Ch1, w, 100), Ids1),
              th_drain_n(Ch1, 800, 0, N1), thread_join_all(Ids1) ), N1, G1),
    check('eight senders, 800 terms, all 800 arrive', G1, '800').

parallel :-
    section('and it is really parallel, not taking turns'),
    %% a million steps is about a second on this machine, and the claim is a
    %% RATIO -- the .sh spun three million to drown two process start-ups
    %% that are not in the measurement any more
    get_time(T0), thread_create(spin(1000000), I1), thread_join(I1, _), get_time(T1),
    One is round((T1 - T0) * 1000),
    get_time(T2), thread_pool(4, spin(1000000), Ids), thread_join_all(Ids), get_time(T3),
    Four is round((T3 - T2) * 1000),
    format("     one thread ~wms, four threads ~wms~n", [One, Four]),
    %% THE THRESHOLD IS LOOSE ON PURPOSE. Four times the work in under three
    %% times the time cannot happen if the threads are serialised; how much
    %% under depends on the machine, the allocator and what else is running,
    %% and this is not a benchmark.
    ( One > 0, Four < One * 3 -> R = parallel ; R = serial ),
    check('four times the work in well under four times the time', R, parallel).

%% ---- mutexes -------------------------------------------------------------
%%
%% THE CLAIM IS THAT IT EXCLUDES, and a lock that does not is indis-
%% tinguishable from one that does until the day it matters. It is checked
%% without a stopwatch: a child takes the lock and SAYS SO down a channel
%% before it lets go, so the parent knows it is inside, and `mutex_trylock'
%% either fails (right) or does not (wrong). No sleeps, no ratios.
%%
%% AND THAT IT ALWAYS RELEASES. Three ways out of `with_mutex/2' -- the goal
%% proves, fails, or throws -- and after each one another thread must be
%% able to take the lock. The throw is the one worth having: a bare
%% mutex_lock with a raising goal after it holds the lock for the life of
%% the process, and the deadlock that follows names whatever ran next.
locks :-
    section('mutexes: it excludes, and with_mutex always lets go'),
    written(( mutex_create(M1), channel_new(Rd1), channel_new(Rl1),
              thread_create(holder(M1, Rd1, Rl1), I1),
              channel_recv(Rd1, 5000, _),
              ( mutex_trylock(M1) -> R1 = taken ; R1 = blocked ),
              channel_send(Rl1, go), thread_join(I1, _) ), R1, G1),
    check('a lock another thread holds cannot be taken', G1, blocked),
    written(( mutex_create(M2), channel_new(Rd2), channel_new(Rl2),
              thread_create(holder(M2, Rd2, Rl2), I2),
              channel_recv(Rd2, 5000, _), channel_send(Rl2, go), thread_join(I2, _),
              ( mutex_trylock(M2) -> R2 = free ; R2 = still_held ) ), R2, G2),
    check('and once it lets go, it can', G2, free),
    %% ASKED FROM ANOTHER THREAD, ALWAYS. A recursive mutex says yes to a
    %% trylock from the thread that already holds it -- that is what recursive
    %% MEANS -- so `is it free?' asked here would answer yes either way, and
    %% these three checks would pass over a with_mutex that never unlocked at
    %% all. The last check in this section is the one that proves they bite.
    written(( mutex_create(M3), with_mutex(M3, true), channel_new(O3),
              thread_create(try_take(M3, O3), I3),
              ( channel_recv(O3, 5000, R3) -> true ; R3 = no_answer ),
              thread_join(I3, _) ), R3, G3),
    check('with_mutex unlocks after a goal that PROVED', G3, free),
    written(( mutex_create(M4), \+ with_mutex(M4, fail), channel_new(O4),
              thread_create(try_take(M4, O4), I4),
              ( channel_recv(O4, 5000, R4) -> true ; R4 = no_answer ),
              thread_join(I4, _) ), R4, G4),
    check('and after one that FAILED', G4, free),
    %% THE ONE THAT PAYS FOR THE PREDICATE. `mutex_lock(M), G, mutex_unlock(M)'
    %% with a raising G is a lock held until the process exits.
    written(( mutex_create(M5), catch(with_mutex(M5, throw(boom)), B5, true),
              channel_new(O5), thread_create(try_take(M5, O5), I5),
              ( channel_recv(O5, 5000, R5) -> true ; R5 = no_answer ),
              thread_join(I5, _),
              atomic_list_concat([B5, R5], '-', X5) ), X5, G5),
    check('and after one that THREW, with the ball still thrown', G5, 'boom-free'),
    written(( mutex_create(M6), findall(X6, with_mutex(M6, member(X6, [a,b,c])), L6) ), L6, G6),
    check('with_mutex is once/1, as SWI''s is', G6, '[a]'),
    %% A RECURSIVE MUTEX OR A DEADLOCK, and this check is the difference. It
    %% runs in a CHILD with a timeout on the answer, so a regression is a red
    %% line rather than a suite that has to be killed.
    written(( mutex_create(M7), channel_new(Out7),
              thread_create(nested(M7, Out7), I7),
              ( channel_recv(Out7, 5000, R7) -> true ; R7 = deadlocked ),
              thread_detach(I7) ), R7, G7),
    check('the mutexes are recursive: with_mutex nests', G7, nested_ok),
    %% THE SHAPE AND THE CULPRIT, NOT THE SLOT NUMBER. Which slot a mutex
    %% gets depends on how many the checks above made, so a pin on the number
    %% is a pin on the order of this case.
    written(( mutex_create(M8), catch(mutex_unlock(M8), error(E8, _), true),
              E8 = permission_error(A8, T8, C8),
              ( C8 == M8 -> S8 = the_one_we_passed ; S8 = somebody_else ),
              atomic_list_concat([A8, T8, S8], '-', X8) ), X8, G8),
    check('unlocking one you do not hold is a permission_error', G8,
          'unlock-mutex-the_one_we_passed'),
    %% A NAME IS A LOCK, and this is why it exists: nothing was handed to the
    %% child. An httpd page is proved on a machine given no handle at all.
    written(( channel_new(Rd9), channel_new(Rl9),
              thread_create(named_holder(Rd9, Rl9), I9),
              channel_recv(Rd9, 5000, _),
              ( mutex_trylock(shared_name) -> R9 = taken ; R9 = blocked ),
              channel_send(Rl9, go), thread_join(I9, _) ), R9, G9),
    check('an ATOM is a lock the whole process shares, no handle passed', G9, blocked),
    %% AND THE CHECK THAT THE THREE RELEASE CHECKS ARE NOT VACUOUS: the same
    %% question, asked the same way, of a thread that took the lock and let a
    %% throw carry it past the unlock. That is exactly what `with_mutex'
    %% exists to prevent, so this must answer the other way.
    written(( mutex_create(M10), channel_new(O10), channel_new(L10),
              thread_create(leak(M10, L10), I10),
              channel_recv(L10, 5000, _), thread_join(I10, _),
              thread_create(try_take(M10, O10), J10),
              ( channel_recv(O10, 5000, R10) -> true ; R10 = no_answer ),
              thread_join(J10, _) ), R10, G10),
    check('and a lock a throw carried past its unlock IS seen as held', G10, still_held).

%% ---- condition variables -------------------------------------------------
%%
%% WHAT A CHANNEL CANNOT SAY IS `EVERYBODY'. One message goes to one
%% receiver; a start gate wakes all of them, and that is `cond_broadcast/1'.
%% Both checks below spawn waiters that send READY while holding the mutex,
%% so the signaller cannot take it until they are genuinely inside the wait
%% -- a lost wakeup would otherwise be a test that passes most mornings.
conditions :-
    section('condition variables: one waiter woken, then all of them'),
    written(( cond_create(C1), mutex_create(M1), channel_new(Rd1), channel_new(Out1),
              thread_create(waiter(C1, M1, Rd1, Out1), I1),
              channel_recv(Rd1, 5000, _),
              mutex_lock(M1), cond_signal(C1), mutex_unlock(M1),
              ( channel_recv(Out1, 5000, R1) -> true ; R1 = never_woke ),
              thread_join(I1, _) ), R1, G1),
    check('a signal wakes a waiter, which takes the mutex back', G1, woke),
    written(( cond_create(C2), mutex_create(M2), channel_new(Rd2), channel_new(Out2),
              thread_pool(4, waiter(C2, M2, Rd2, Out2), Ids2),
              nrecv(Rd2, 4, 0, Ready2),
              mutex_lock(M2), cond_broadcast(C2), mutex_unlock(M2),
              nrecv(Out2, 4, 0, Woke2), thread_join_all(Ids2),
              atomic_list_concat([Ready2, Woke2], '-', X2) ), X2, G2),
    check('and ONE broadcast wakes all four of them', G2, '4-4'),
    written(( cond_create(C3), mutex_create(M3), mutex_lock(M3),
              ( cond_wait(C3, M3, 300) -> R3 = woke ; R3 = timed_out ),
              mutex_unlock(M3) ), R3, G3),
    check('a timed wait fails rather than hanging', G3, timed_out),
    written(( cond_create(C4), mutex_create(M4),
              catch(cond_wait(C4, M4), error(E4, _), true),
              E4 = permission_error(A4, T4, C4b),
              ( C4b == M4 -> S4 = the_mutex ; S4 = something_else ),
              atomic_list_concat([A4, T4, S4], '-', X4) ), X4, G4),
    check('waiting without the mutex is a permission_error', G4,
          'wait-mutex-the_mutex'),
    %% THE UNDEFINED BEHAVIOUR, REFUSED BY NAME. cond_wait releases the mutex
    %% ONCE; at depth two it would release nothing and sleep holding it.
    written(( cond_create(C5), mutex_create(M5), mutex_lock(M5), mutex_lock(M5),
              catch(cond_wait(C5, M5), error(E5, _), true),
              mutex_unlock(M5), mutex_unlock(M5),
              E5 = permission_error(A5, T5, C5b),
              ( C5b == M5 -> S5 = the_mutex ; S5 = something_else ),
              atomic_list_concat([A5, T5, S5], '-', X5) ), X5, G5),
    check('and waiting on one held TWICE is refused, not undefined', G5,
          'wait-recursive_mutex-the_mutex').
