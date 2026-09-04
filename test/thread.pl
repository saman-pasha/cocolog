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
              'th_drain_n(_, _, N, N).' ]),
    use_module(Work),
    a_thread, what_it_sees, a_channel, closed, backpressure, helpers, contention, parallel,
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
