%% The twelve-interpreter group test, EMBEDDED: the same four groups of
%% three over the same four machine states as test/groups.pl, with the
%% knowledge base inside the process instead of behind a server.
%%
%% WHAT CHANGES AND WHY. An embedded store belongs to one process at a
%% time, so the arrangement differs from groups.pl in exactly two ways:
%%
%%   THE MACHINES START FIRST. groups.pl starts its workers first because
%%   twelve processes take long enough to launch that early ones finished
%%   machines before late ones existed. Here the setup steps are still one
%%   process each (open store, do the thing, close), but the WORKERS are
%%   twelve THREADS of a single `cocolog swarm' process -- and that process
%%   cannot share the store with a concurrent `start'. So: state first,
%%   then the swarm. The workers' claim logic is indifferent to the order.
%%
%%   ONE `swarm' INSTEAD OF TWELVE `work's. Each thread opens its own
%%   embedded session and runs the very same work loop the processes run,
%%   writing to --out DIR/WORKER.log so the checks below read the same
%%   logs groups.pl reads.
%%
%% Everything checked is checked identically: full answer set exactly
%% once per machine, and every member of every group took a turn.
%%
%%     cocolog -s test/groups-embed.pl        from the checkout root
%%     GROUPS_EMBED_STORE=DIR cocolog -s test/groups-embed.pl
%%
%% A fresh store by default; GROUPS_EMBED_STORE names a persistent one, for
%% measuring what repeated runs do to a store that lives on -- it survives
%% the run, only the logs are cleaned up. Not in test/run.pl's list, by the
%% owner's arrangement; run by hand.

:- use_module('test/prelude.pl').

main :-
    env_int('SETUP_TIMEOUT', 20, Setup),
    env_int('WORKER_TIMEOUT', 60, Worker),
    %% How many turns a group must take before "all three took turns" is a
    %% claim about the scheduler rather than a coin toss -- test/groups.pl
    %% carries the arithmetic. 20 is 0.09% per group; the four groups
    %% measure well above it.
    env_int('TURNS_FLOOR', 20, Floor),
    scratch(D),
    ( getenv('GROUPS_EMBED_STORE', Store), Store \== '' -> true ; atom_concat(D, '/store', Store) ),
    sh_join(['--kb groups_test --embed ', Store], Base),
    SetupMs is Setup * 1000, WorkerMs is Worker * 1000,
    section('loading the program'),
    sh_join([Base, ' forget >/dev/null 2>&1'], Forget), cocolog_run(Forget, _, _, SetupMs),
    %% AND RECLAIM WHAT THE LAST RUN LEFT -- see the same line in
    %% test/groups.pl. The embedded engine keeps deleted rows under MVCC
    %% exactly as the server does, and a persistent store ages exactly as the
    %% server's did: measured here, 25s, 50s, and then past the 60s
    %% WORKER_TIMEOUT by the third run. On the default fresh store this is a
    %% no-op that costs nothing.
    sh_join([Base, ' vacuum >/dev/null 2>&1'], Vacuum), cocolog_run(Vacuum, _, _, SetupMs),
    sh_join([Base, ' consult demo/family.pl >/dev/null 2>&1'], Consult), cocolog_run(Consult, _, _, SetupMs),
    section('starting four machines'),
    forall(group(G, Goal, _),
           ( sh_join([Base, ' start state-', G, ' "', Goal, '" > ', D, '/start-', G, '.log 2>&1'], Start),
             cocolog_run(Start, _, _, SetupMs) )),
    section('twelve interpreters, three per machine, as threads of one process'),
    %% --steps 1, and TURNS_FLOOR below, for the reason test/groups.pl writes
    %% out at length: the share check is a claim about the scheduler only
    %% when there are enough turns to split.
    %%
    %% AND THE UNEVEN SPLIT THIS FILE USED TO BLAME ON THE SWARM'S HAND-OFF
    %% IS NOT THE HAND-OFF. That was written here on the numbers alone --
    %% one thread of three taking 59 turns of 62 while a partner took 1 --
    %% and the numbers were right and the reading was wrong. Traced: THE
    %% PARTNER DIES. A load that meets a machine mid-save fails with
    %% `missing chunk 3 of 4', cmd_step calls that FAILED because its test
    %% for the mid-save window matches one message and not this one, and a
    %% FAILED turn ends the worker for good. About two workers per machine
    %% per run go that way.
    %%
    %% BOTH ARE FIXED NOW, and the split is what it should be. `missing
    %% chunk' is MISSED and retried like the other half of its window, and
    %% the duplication that retrying used to uncover -- one machine reaching
    %% ninety rows of its name -- was cocolog's own: the save meant to UPDATE
    %% the header by id never ran (its id was wiped by a re-attach before the
    %% save could read it), so every save was still a delete and an insert
    %% with a lookup between. With the id kept, five runs in a row: no worker
    %% stopped, every group's total exactly the proof's length (34, 24, 60,
    %% 59), the window hit in four runs of five and simply taken again.
    %% STATUS.md has the numbers. The STOPPED line stays, because a worker
    %% killed by its turn should say so.
    findall(P, ( group(G, _, _), member(M, [1, 2, 3]), sh_join([G, M, ' state-', G], P) ), Pairs0),
    atomic_list_concat(Pairs0, ' ', Pairs),
    sh_join([Base, ' --steps 1 --answers 0 --out ', D, ' swarm ', Pairs], Swarm),
    cocolog_run(Swarm, _, Rc, WorkerMs),
    ( Rc =:= 124 -> format("     TIMED OUT: the swarm~n", []) ; true ),
    answers(D), turns(D, Floor),
    sh_join([Base, ' list 2>/dev/null | grep -cE ''^  state-'' || true'], List), cocolog_run(List, Left, _, SetupMs),
    check('no machine left suspended', Left, '0'),
    shl(['rm -rf ', D]),
    checks_done.

env_int(Name, Default, V) :- ( getenv(Name, A), atom_number(A, N) -> V = N ; V = Default ).

group(a, 'ancestor(tom,X)', ['ancestor(tom,ann)', 'ancestor(tom,bob)', 'ancestor(tom,jim)', 'ancestor(tom,liz)', 'ancestor(tom,pat)', 'ancestor(tom,zoe)']).
group(b, 'ancestor(bob,X)', ['ancestor(bob,ann)', 'ancestor(bob,jim)', 'ancestor(bob,pat)', 'ancestor(bob,zoe)']).
group(c, 'ancestor(X,zoe)', ['ancestor(bob,zoe)', 'ancestor(jim,zoe)', 'ancestor(pat,zoe)', 'ancestor(tom,zoe)']).
group(d, 'ancestor(X,jim)', ['ancestor(bob,jim)', 'ancestor(pat,jim)', 'ancestor(tom,jim)']).

answers_of(D, G, Answers) :-
    findall(A, ( member(M, [1, 2, 3]), sh_join([D, '/', G, M, '.log'], Log), exists_file(Log),
                 read_file_to_codes(Log, Cs), re_lines('^  [0-9]+\\. ', Cs, Ls),
                 member(L, Ls), atom_codes(LA, L), re_replace_atom('^ *[0-9]*\\. ', '', LA, A) ), Answers).

answers(D) :-
    forall(group(G, _, Want),
           ( answers_of(D, G, As), msort(As, Sorted),
             sh_join(['state-', G, ' produced its full answer set'], L1), check(L1, Sorted, Want),
             sort(As, Unique), length(As, NA), length(Unique, NU), Dups is NA - NU,
             sh_join(['state-', G, ' answered nothing twice'], L2), check(L2, Dups, 0) )).

turns_of(D, W, N) :-
    sh_join([D, '/', W, '.log'], Log),
    ( exists_file(Log) -> read_file_to_codes(Log, Cs), re_lines(': took ', Cs, Ls), length(Ls, N) ; N = 0 ).

turns(D, Floor) :-
    forall(group(G, _, _),
           ( findall(W=N, ( member(M, [1, 2, 3]), sh_join([G, M], W), turns_of(D, W, N) ), Counts),
             findall(N, member(_=N, Counts), Ns), sum_list(Ns, Total),
             format("     turns: ~w  (total ~w)~n", [Counts, Total]),
             forall(( member(M, [1, 2, 3]), sh_join([D, '/', G, M, '.log'], Log), exists_file(Log),
                      read_file_to_codes(Log, Cs), re_lines('STOPPED after', Cs, Ss), member(S, Ss) ),
                    ( atom_codes(SA, S), format("     ~w~n", [SA]) )),
             ( Total >= Floor -> Enough = yes ; sh_join(['no: ', Total, ' < ', Floor], Enough) ),
             sh_join(['group ', G, ' did enough turns to be worth splitting'], L1), check(L1, Enough, yes),
             ( member(_=0, Counts) -> Shared = no ; Shared = yes ),
             sh_join(['all three interpreters of group ', G, ' took turns'], L2), check(L2, Shared, yes) )).
