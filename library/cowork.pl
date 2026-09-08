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
%%   cowork_start(+N, +Options, -Crew)   Options: on_start(Goal), timeout(Ms)
%%   cowork_stop(+Crew)
%%   cowork_size(+Crew, -N)
%%   cowork_warm(+Crew)                  pay the store fill now, not in the first turn
%%   cowork_pending(+Crew, -N)           jobs QUEUED and not yet taken
%%   cowork_tell(+Crew, +Clauses)        every worker asserts its own copy
%%   cowork_forget(+Crew, +Heads)        every worker retracts them again
%%   cowork_ask(+Crew, ?Goal)            one job, UNIFIED back into the caller's
%%   cowork_ask(+Crew, +Goal, -Answer)   ... or as a copy, leaving Goal alone
%%   cowork_map(+Crew, +Goals, -Results) many jobs; ok(G) | failed | error(B)
%%   cowork_post(+Crew, +Goal)           fire and forget -- nothing waits
%%   cowork_poll(+Crew, -Result)         a posted answer if one is ready, else FAILS
%%   cowork_poll(+Crew, +Timeout, -Result)   ... or wait that many milliseconds
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
%% PIPELINING IS WHAT `post' AND `poll' ARE FOR, and it is the only way work
%% leaves a frame that has a deadline. A 16ms frame cannot MOVE work and then
%% wait for it -- the wait is the frame -- so the answer has to be wanted
%% next frame instead: post the job while frame N draws, poll for it at the
%% top of frame N+1. `cowork_poll/2' FAILS rather than blocking when the
%% answer is not ready yet, which is what lets a loop ask every frame and
%% carry on drawing when the answer has not come.
%%
%% POSTED ANSWERS COME BACK ON A CHANNEL OF THEIR OWN, so a poll can never
%% take a result belonging to a `map' and a map can never swallow a posted
%% one. That is why a job carries the channel to answer on rather than the
%% crew having a single outbox.
%%
%% AND A PIPELINE HAS TO BE PACED, which is the part that is easy to get
%% wrong and was measured getting it wrong. Posting every frame regardless
%% is a queue that GROWS: forty frames posting a 35ms job to four workers
%% collected twelve answers and left TWENTY-EIGHT queued, every one of them
%% stale by dozens of frames by the time anybody could look at it. The frame
%% was cheap (3.6ms) and the work was pointless.
%%
%% ONE IN FLIGHT IS THE PATTERN: post only when the last answer has come
%% back. The same forty frames then posted four jobs, collected three, and
%% cost 3.3ms a frame -- the same frame, none of the backlog. The library
%% does not enforce it because a caller may legitimately want several in
%% flight; it is `cowork_poll/2' answering that tells you whether to post.
%%
%% A POSTED JOB GOES TO THE SHORTEST QUEUE. There is no dispatcher watching
%% -- nothing is waiting for the answer, by definition -- so the choice is
%% made by asking each inbox how many messages it is holding, which is
%% `channel_size/2'. It is not perfect balance and does not need to be: a
%% background job is one nobody is timing.

:- use_module(library(thread)).

%% ---- starting and stopping ----------------------------------------------

%% A crew is its channels and its threads: an inbox per worker, one result
%% channel shared, and the thread ids to join at the end. Handles are
%% integers into library(thread)'s own tables, so the term copies to a
%% worker as it stands.
cowork_start(N, Options, crew(N, Ins, Out, Post, Ack, Tids, Timeout)) :-
    integer(N), N > 0,
    %% NO BLOCKING WAIT IS UNBOUNDED, and this is the number that makes that
    %% true. A worker can die before it ever reads a message -- a store fill
    %% that raises, say -- and then nothing it was going to answer will ever
    %% be answered. The catch inside the loop cannot help there, because the
    %% loop was never reached. So every wait below is bounded and a missing
    %% answer becomes `timeout_error(cowork, Missing)': generous enough that
    %% a cold worker paying its fill is never mistaken for a dead one, and
    %% finite so a dead one is never mistaken for a slow crew.
    ( memberchk(timeout(Timeout), Options) -> true ; Timeout = 60000 ),
    length(Ins, N),
    cowork_channels(Ins),
    channel_new(Out),
    %% posted answers land here and nowhere else, so `poll' and `map' cannot
    %% take each other's
    channel_new(Post),
    %% AND ACKNOWLEDGEMENTS LAND ON A THIRD, for a reason that cost a
    %% silent failure in CivV before it was found. A channel receive with a
    %% pattern CONSUMES whatever it dequeues and then fails if it does not
    %% unify -- measured -- so one stale `res(...)' left on the ack channel
    %% by a map that timed out made the next `cowork_tell/2' eat it, fail to
    %% match `ack(_, _)', and FAIL. Silently: a caller cannot tell a refusal
    %% from an empty answer. The same lost message then cost a later wait its
    %% whole timeout, waiting for an acknowledgement that had already come
    %% and been thrown away. Three channels, three kinds of message, and no
    %% receive can ever see somebody else's.
    channel_new(Ack),
    (   memberchk(on_start(Start), Options)
    ->  true
    ;   Start = true
    ),
    findall(T,
            ( nth1(Id, Ins, In),
              thread_create(cowork_run(Id, In, Ack, Start), T) ),
            Tids).

cowork_channels([]).
cowork_channels([C|Cs]) :- channel_new(C), cowork_channels(Cs).

%% Every inbox is told to stop and every thread is joined, so a crew that
%% has been stopped has left nothing running. A worker inside a long job
%% finishes it first: `stop' is a message in the queue, not a signal.
cowork_stop(crew(_, Ins, _, _, _, Tids, _)) :-
    forall(member(In, Ins), channel_send(In, stop)),
    forall(member(T, Tids), thread_join(T, _)).

cowork_size(crew(N, _, _, _, _, _, _), N).

%% THE FILL IS PAID ON A WORKER'S FIRST GOAL, not when its thread starts --
%% `cowork_start/3' returns in a fifth of a millisecond and the store fill
%% lands on whatever message the worker handles first. Measured from CivV: a
%% thread with its whole program registered costs 14ms, and a crew that is
%% merely started hands that bill to the first real turn. One trivial job to
%% EACH worker pays it up front, which is what a crew started at load is for.
cowork_warm(Crew) :-
    cowork_size(Crew, N),
    findall(true, between(1, N, _), Goals),
    cowork_map(Crew, Goals, _).

%% QUEUED, AND NOT WHAT IS BEING WORKED ON, which is the honest limit of it:
%% a job a worker has already taken is inside that worker and nothing can see
%% it. So this answers "have I posted faster than the crew is taking them",
%% which is the question a pipeline asks -- see the pacing note above.
cowork_pending(crew(_, Ins, _, _, _, _, _), N) :- cowork_queued(Ins, 0, N).

cowork_queued([], N, N).
cowork_queued([In|Ins], A, N) :-
    channel_size(In, K),
    A1 is A + K,
    cowork_queued(Ins, A1, N).

%% ---- the worker ---------------------------------------------------------

%% `on_start' is the warm-up: it runs once, in the worker, before any job.
%% It is caught because a crew that half-starts is worse than one that
%% starts cold -- the failure belongs to the first job's answer, not to a
%% thread that vanished.
cowork_run(Id, In, Out, Start) :-
    ( catch(Start, _, true) -> true ; true ),
    cowork_loop(Id, In, Out).

%% A WORKER MUST NOT DIE QUIETLY, and this catch is why. Every message a
%% worker takes has somebody waiting for its reply, so a worker that fell out
%% of this loop turned into a caller blocked for ever on a channel nobody
%% would ever send to -- a HANG where the truth was an error. `cowork_do'
%% answers before it can fail; this is the belt around that brace, so an
%% unexpected ball costs one message rather than the crew.
cowork_loop(Id, In, Out) :-
    channel_recv(In, Msg),
    (   Msg == stop
    ->  true
    ;   ( catch(cowork_do(Id, Msg, Out), _, true) -> true ; true ),
        cowork_loop(Id, In, Out)
    ).

%% THE ACK CARRIES THE OUTCOME, and it is always sent. A clause that will
%% not assert is an ordinary thing -- one too long for a row raises
%% `resource_error(clause_length)' the moment a worker has a database under
%% it, and a term that is not callable raises a type_error -- and the first
%% shape of this predicate simply asserted, so a worker that raised never
%% acked and every caller of `cowork_tell/2' waited for ever. A hang is the
%% worst possible way to report a fact that would not fit: it names nothing,
%% it happens in another thread, and it looks like the crew being slow.
cowork_do(Id, tell(Clauses), Out) :- !,
    (   catch(forall(member(C, Clauses), assertz(C)), Ball, true)
    ->  ( var(Ball) -> S = true ; S = error(Ball) )
    ;   S = failed
    ),
    channel_send(Out, ack(Id, S)).
cowork_do(Id, forget(Heads), Out) :- !,
    (   catch(forall(member(H, Heads), ( catch(retractall(H), _, true) )), Ball, true)
    ->  ( var(Ball) -> S = true ; S = error(Ball) )
    ;   S = failed
    ),
    channel_send(Out, ack(Id, S)).
%% THE THREE OUTCOMES ARE KEPT APART, which is the same decision
%% `thread_join/2' makes: a goal that did not prove is not a goal that
%% raised, and neither is a job that never ran. The `->' is what makes a job
%% once/1 -- the first answer is the answer.
%% THE JOB CARRIES THE CHANNEL IT ANSWERS ON -- `Out' for a map, the crew's
%% post channel for a posted one -- which is what keeps the two apart.
cowork_do(Id, job(I, G, ReplyTo), _) :- !,
    (   catch(G, Ball, true)
    ->  ( var(Ball) -> R = ok(G) ; R = error(Ball) )
    ;   R = failed
    ),
    channel_send(ReplyTo, res(Id, I, R)).
cowork_do(Id, Other, Out) :-
    channel_send(Out, ack(Id, error(domain_error(cowork_message, Other)))).

%% ---- telling the crew ---------------------------------------------------

%% Broadcast, and WAIT for every worker to have it. Without the acks a
%% `tell' followed by a `map' would race: a job could reach a worker that
%% had not yet asserted the snapshot the job asks about.
cowork_tell(crew(N, Ins, _, _, Ack, _, T), Clauses) :-
    cowork_drain(Ack),
    forall(member(In, Ins), channel_send(In, tell(Clauses))),
    cowork_acks(Ack, T, N, Bad),
    cowork_report(Bad).

cowork_forget(crew(N, Ins, _, _, Ack, _, T), Heads) :-
    cowork_drain(Ack),
    forall(member(In, Ins), channel_send(In, forget(Heads))),
    cowork_acks(Ack, T, N, Bad),
    cowork_report(Bad).

%% WHAT IS ALREADY ON THE CHANNEL BELONGS TO SOMETHING DEAD. A wait that
%% gave up leaves its workers still working, and their answers arrive
%% afterwards addressed to nobody -- so the next map inherited them and
%% answered a question it had not been asked (measured: a map for `after(_)'
%% came back `ok(slow(1,2))', the previous map's job). Results carry an index
%% within their own map and indices start again at one, so they cannot be
%% told apart by name; they can only be cleared before a new wait begins,
%% which is the one moment nothing legitimate can be there.
cowork_drain(Ch) :-
    (   channel_recv(Ch, 0, _)
    ->  cowork_drain(Ch)
    ;   true
    ).

cowork_acks(_, _, 0, []) :- !.
cowork_acks(Out, T, N, Bad) :-
    (   channel_recv(Out, T, ack(_, S))
    ->  M is N - 1,
        cowork_acks(Out, T, M, Bad0),
        ( S == true -> Bad = Bad0 ; Bad = [S|Bad0] )
    ;   throw(error(timeout_error(cowork, N), _))
    ).

%% WHAT ONE WORKER COULD NOT DO IS TRUE OF THE CREW, because the crew is only
%% useful while its workers are interchangeable. A ball is thrown on -- the
%% caller asked for a snapshot and has not got one -- and a plain failure
%% fails.
cowork_report(Bad) :-
    (   member(error(Ball), Bad)
    ->  throw(Ball)
    ;   Bad == []
    ->  true
    ;   fail
    ).

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
cowork_map(crew(_, Ins, Out, _, _, _, T), Goals, Results) :-
    cowork_drain(Out),
    cowork_seed(Ins, Goals, Out, 1, Rest, NextI, Outstanding),
    cowork_gather(Out, T, Ins, Rest, NextI, Outstanding, [], Pairs),
    keysort(Pairs, Sorted),
    cowork_values(Sorted, Results).

cowork_seed([], Rest, _, I, Rest, I, 0) :- !.
cowork_seed(_, [], _, I, [], I, 0) :- !.
cowork_seed([In|Ins], [G|Gs], Out, I, Rest, NextI, Outstanding) :-
    channel_send(In, job(I, G, Out)),
    I1 is I + 1,
    cowork_seed(Ins, Gs, Out, I1, Rest, NextI, N0),
    Outstanding is N0 + 1.

cowork_gather(_, _, _, _, _, 0, Acc, Acc) :- !.
cowork_gather(Out, T, Ins, Rest, NextI, Outstanding, Acc, Pairs) :-
    (   channel_recv(Out, T, res(Id, I, R))
    ->  true
    ;   throw(error(timeout_error(cowork, Outstanding), _))
    ),
    (   Rest = [G|Rest1]
    ->  nth1(Id, Ins, In),
        channel_send(In, job(NextI, G, Out)),
        NextI1 is NextI + 1,
        Out1 = Outstanding
    ;   Rest1 = [],
        NextI1 = NextI,
        Out1 is Outstanding - 1
    ),
    cowork_gather(Out, T, Ins, Rest1, NextI1, Out1, [I-R|Acc], Pairs).

cowork_values([], []).
cowork_values([_-R|Ps], [R|Rs]) :- cowork_values(Ps, Rs).

%% ---- posting, and collecting later --------------------------------------
%%
%% THE ONLY WAY WORK LEAVES A FRAME WITH A DEADLINE. `map' waits, so a frame
%% that calls it has not moved the work anywhere -- it has moved where the
%% time is spent. `post' does not wait: the answer is wanted NEXT frame, and
%% `poll' asks for it without blocking.
cowork_post(crew(_, Ins, _, Post, _, _, _), Goal) :-
    cowork_shortest(Ins, In),
    channel_send(In, job(0, Goal, Post)).

%% The shortest inbox, by asking each one how much it is holding. Nothing is
%% waiting for a posted answer, so this is the whole of the scheduling: it
%% keeps a background job off a worker that is already three deep.
cowork_shortest([In|Ins], Best) :-
    channel_size(In, N),
    cowork_shortest(Ins, In, N, Best).

cowork_shortest([], Best, _, Best).
cowork_shortest([In|Ins], Sofar, N, Best) :-
    channel_size(In, M),
    (   M < N
    ->  cowork_shortest(Ins, In, M, Best)
    ;   cowork_shortest(Ins, Sofar, N, Best)
    ).

%% FAILS WHEN THERE IS NOTHING YET, which is the whole point: a loop asks
%% every frame and carries on drawing when the answer has not come. A zero
%% timeout on a channel takes only what is already queued.
cowork_poll(Crew, Result) :- cowork_poll(Crew, 0, Result).

cowork_poll(crew(_, _, _, Post, _, _, _), Timeout, Result) :-
    channel_recv(Post, Timeout, res(_, _, Result)).
