%% library(cowork) -- a crew of workers that outlives the turn.
%%
%% WHY A CREW AND NOT A PARALLEL MAP. A worker thread's store starts empty
%% and is filled from the process-wide module registry on its first goal, so
%% starting one costs what the PROGRAM costs, not what the job costs:
%% measured at 3.1ms with the default modules and 23.8ms with one
%% 3 000-clause module registered. A game with several thousand clauses is
%% then tens of milliseconds a thread -- several frames -- so a crew is
%% started ONCE, at load, and lives for the session. There is no spawn-and-
%% join here. library/cowork/DESIGN.md carries the measurements.
%%
%% WHAT IS FREE AND WHAT IS METERED. Every registered module is already in
%% every worker, so the static half of a world -- rules, terrain, a tech
%% tree -- costs nothing to share. Only mutable state crosses, as canonical
%% text, at about 1.1ms per 1 000 five-argument facts. That is a per-TURN
%% budget: a 5 000-fact snapshot to eight workers is ~43ms, which is
%% affordable once a turn and is the whole of a 16ms frame.
%%
%% So the rule for what is worth sending is arithmetic: a small query in, a
%% small answer out, real compute in between, against a world the worker
%% already holds.
%%
%% THE SURFACE (stage 1 of the design; see the note at the end)
%%
%%   cowork_start(+N, +Options, -Crew)   Options: on_start(Goal)
%%   cowork_stop(+Crew)
%%   cowork_size(+Crew, -N)
%%   cowork_tell(+Crew, +Clauses)        every worker asserts its own copy
%%   cowork_forget(+Crew, +Heads)        every worker retracts them again
%%   cowork_ask(+Crew, ?Goal)            one job, UNIFIED back into the caller's
%%   cowork_ask(+Crew, +Goal, -Answer)   ... or as a copy, leaving Goal alone
%%   cowork_map(+Crew, +Goals, -Results) many jobs; ok(G) | failed | error(B)
%%
%% TWO CONTRACTS, AND BOTH ARE LOAD-BEARING.
%%
%% A JOB IS A QUERY, NEVER A MUTATION. The only way state enters a worker is
%% `cowork_tell/2'. A job that asserts leaves one worker holding what the
%% others do not, and the crew stops being interchangeable the moment it
%% does. A job is proved ONCE -- the first answer is the answer.
%%
%% `cowork_map/3' ANSWERS IN INPUT ORDER, whatever order the jobs finish in.
%% That is not tidiness: everything this family claims about deterministic
%% replay depends on parallelism being invisible in the answer, and a crew
%% that returned results in completion order would make the same match
%% replay differently on a busier machine.
%%
%% AND ONE RULE ABOUT WHERE THE WORK LIVES. A worker sees the module
%% registry, not the caller's store, so the predicates a job calls must be
%% in a module loaded with `use_module' BEFORE the crew starts. Clauses the
%% caller asserted are invisible; that is what `cowork_tell/2' is for.
%%
%% AN UNTOLD PREDICATE RAISES. A job that calls something the worker has no
%% clauses for gets `existence_error(procedure, ...)' -- ordinary Prolog, and
%% carried back rather than folded into a `failed', because "the snapshot
%% never arrived" and "this tile has no yield" are different answers. A
%% caller who wants absence to be an ordinary no declares the turn's
%% predicates in the warm-up: `cowork_start(N, [on_start(dynamic(tile/3))], C)'.
%%
%% A CREW BELONGS TO ONE THREAD. `tell', `forget', `ask' and `map' share the
%% crew's result channel, so two of them at once would read each other's
%% messages. Drive a crew from the thread that started it.
%%
%% NOT HERE YET, and named so the absence is visible: `cowork_post/2' and
%% `cowork_poll/2' -- fire-and-forget and the pipelined collect -- are stage
%% 4 of the design, which is where the "one frame behind" arrangement is
%% measured. Everything above is stage 1.

:- use_module(library(thread)).

%% ---- starting and stopping ----------------------------------------------

%% A crew is its channels and its threads: an inbox per worker, one result
%% channel shared, and the thread ids to join at the end. Handles are
%% integers into library(thread)'s own tables, so the term copies to a
%% worker as it stands.
cowork_start(N, Options, crew(N, Ins, Out, Tids)) :-
    integer(N), N > 0,
    length(Ins, N),
    cowork_channels(Ins),
    channel_new(Out),
    (   memberchk(on_start(Start), Options)
    ->  true
    ;   Start = true
    ),
    findall(T,
            ( nth1(Id, Ins, In),
              thread_create(cowork_run(Id, In, Out, Start), T) ),
            Tids).

cowork_channels([]).
cowork_channels([C|Cs]) :- channel_new(C), cowork_channels(Cs).

%% Every inbox is told to stop and every thread is joined, so a crew that
%% has been stopped has left nothing running. A worker inside a long job
%% finishes it first: `stop' is a message in the queue, not a signal.
cowork_stop(crew(_, Ins, _, Tids)) :-
    forall(member(In, Ins), channel_send(In, stop)),
    forall(member(T, Tids), thread_join(T, _)).

cowork_size(crew(N, _, _, _), N).

%% ---- the worker ---------------------------------------------------------

%% `on_start' is the warm-up: it runs once, in the worker, before any job.
%% It is caught because a crew that half-starts is worse than one that
%% starts cold -- the failure belongs to the first job's answer, not to a
%% thread that vanished.
cowork_run(Id, In, Out, Start) :-
    ( catch(Start, _, true) -> true ; true ),
    cowork_loop(Id, In, Out).

cowork_loop(Id, In, Out) :-
    channel_recv(In, Msg),
    (   Msg == stop
    ->  true
    ;   cowork_do(Id, Msg, Out),
        cowork_loop(Id, In, Out)
    ).

cowork_do(Id, tell(Clauses), Out) :- !,
    forall(member(C, Clauses), assertz(C)),
    channel_send(Out, ack(Id)).
cowork_do(Id, forget(Heads), Out) :- !,
    forall(member(H, Heads), ( catch(retractall(H), _, true) )),
    channel_send(Out, ack(Id)).
%% THE THREE OUTCOMES ARE KEPT APART, which is the same decision
%% `thread_join/2' makes: a goal that did not prove is not a goal that
%% raised, and neither is a job that never ran. The `->' is what makes a job
%% once/1 -- the first answer is the answer.
cowork_do(Id, job(I, G), Out) :- !,
    (   catch(G, Ball, true)
    ->  ( var(Ball) -> R = ok(G) ; R = error(Ball) )
    ;   R = failed
    ),
    channel_send(Out, res(Id, I, R)).
cowork_do(Id, Other, Out) :-
    channel_send(Out, res(Id, 0, error(domain_error(cowork_message, Other)))).

%% ---- telling the crew ---------------------------------------------------

%% Broadcast, and WAIT for every worker to have it. Without the acks a
%% `tell' followed by a `map' would race: a job could reach a worker that
%% had not yet asserted the snapshot the job asks about.
cowork_tell(crew(N, Ins, Out, _), Clauses) :-
    forall(member(In, Ins), channel_send(In, tell(Clauses))),
    cowork_acks(Out, N).

cowork_forget(crew(N, Ins, Out, _), Heads) :-
    forall(member(In, Ins), channel_send(In, forget(Heads))),
    cowork_acks(Out, N).

cowork_acks(_, 0) :- !.
cowork_acks(Out, N) :-
    channel_recv(Out, ack(_)),
    M is N - 1,
    cowork_acks(Out, M).

%% ---- asking -------------------------------------------------------------

%% THE VARIABLES CANNOT BIND ACROSS THE SEAM, and that is what `cowork_ask/2'
%% is for. A goal is COPIED to the worker and its answer copied back, so the
%% caller's own `X' in `double(21, X)' is not the `X' the worker proved --
%% `cowork_ask/3' hands back the proven copy and leaves the caller's goal
%% untouched, which reads as a puzzle the first time. `cowork_ask/2' unifies
%% the copy with the goal, so `cowork_ask(Crew, double(21, X))' binds X, and
%% it is the form to reach for.
cowork_ask(Crew, Goal) :-
    cowork_ask(Crew, Goal, Answer),
    Goal = Answer.

%% The single shot as a copy: the answer is the goal as the worker proved
%% it, a job that failed fails here, and a ball thrown there is thrown here.
cowork_ask(Crew, Goal, Answer) :-
    cowork_map(Crew, [Goal], [R]),
    (   R = ok(Answer)
    ->  true
    ;   R = error(Ball)
    ->  throw(Ball)
    ;   fail
    ).

%% THE DISPATCHER, and it balances by construction. One job goes to each
%% worker to begin with; after that a worker gets its next job when its last
%% ANSWER arrives, so a worker with a slow job is not handed more while the
%% others idle. The results carry their index and are keysorted at the end,
%% which is what makes the answer independent of who finished first.
cowork_map(crew(_, Ins, Out, _), Goals, Results) :-
    cowork_seed(Ins, Goals, 1, Rest, NextI, Outstanding),
    cowork_gather(Out, Ins, Rest, NextI, Outstanding, [], Pairs),
    keysort(Pairs, Sorted),
    cowork_values(Sorted, Results).

cowork_seed([], Rest, I, Rest, I, 0) :- !.
cowork_seed(_, [], I, [], I, 0) :- !.
cowork_seed([In|Ins], [G|Gs], I, Rest, NextI, Outstanding) :-
    channel_send(In, job(I, G)),
    I1 is I + 1,
    cowork_seed(Ins, Gs, I1, Rest, NextI, N0),
    Outstanding is N0 + 1.

cowork_gather(_, _, _, _, 0, Acc, Acc) :- !.
cowork_gather(Out, Ins, Rest, NextI, Outstanding, Acc, Pairs) :-
    channel_recv(Out, res(Id, I, R)),
    (   Rest = [G|Rest1]
    ->  nth1(Id, Ins, In),
        channel_send(In, job(NextI, G)),
        NextI1 is NextI + 1,
        Out1 = Outstanding
    ;   Rest1 = [],
        NextI1 = NextI,
        Out1 is Outstanding - 1
    ),
    cowork_gather(Out, Ins, Rest1, NextI1, Out1, [I-R|Acc], Pairs).

cowork_values([], []).
cowork_values([_-R|Ps], [R|Rs]) :- cowork_values(Ps, Rs).
