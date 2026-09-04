%% Twelve interpreters at once, over four distinct machine states.
%%
%% FOUR GROUPS OF THREE. Each group is three interpreter processes taking turns
%% on one machine; the four groups run at the same time against one server, and
%% each group's members hand their machine back and forth through the database
%% -- nobody holds it for more than one turn, and no group can see another's
%% state.
%%
%% WHAT IT IS ACTUALLY CHECKING, and why each part is there:
%%
%%   EACH STATE PRODUCES ITS FULL ANSWER SET, EXACTLY ONCE. A machine advanced
%%   by three processes in turn must produce the same answers one process would
%%   -- none repeated because a turn was replayed, none missing because a save
%%   was lost.
%%
%%   EVERY MEMBER OF EVERY GROUP DOES SOME OF THE WORK. If one worker took every
%%   turn the test would pass while proving nothing about hand-off, so all
%%   three turn counts are checked to be non-zero.
%%
%%   THE FOUR GROUPS DO NOT INTERFERE. The goals differ -- tom's descendants,
%%   bob's descendants, who leads to zoe, who leads to jim -- and they OVERLAP
%%   in the answers they can produce, so a state that had picked up another
%%   group's work answers visibly wrong things rather than plausibly wrong ones.
%%
%% WHAT MAKES IT SAFE. Two things, in two different projects:
%%
%%   cocolog::machine_claim_named marks a machine as one worker's inside a
%%   transaction, so two workers cannot both be advancing it; the losers wait
%%   and take a later turn. Without it they would all load the same state, all
%%   advance it, and the last save would throw the others' work away.
%%
%%   ZiguratIP serialises the two page-store streams that every connection's
%%   thread shares. It did not always: an indexed WHERE walked a B-tree straight
%%   through them holding no lock at all, so several clients reading and writing
%%   at once read from each other's file position. See STATUS.md.
%%
%% NOTHING HERE IS ALLOWED TO HANG. Every step has a timeout and the workers
%% have a wall clock, because the failure this test exists to catch is a worker
%% BLOCKING -- on a lock, on a server that has stopped answering -- and a test
%% whose failure mode is "wait forever" is useless for finding it. A run that
%% goes wrong should be over in seconds and say what it was waiting for.
%%
%%   SETUP_TIMEOUT  each consult/start/drop/list call, seconds
%%   WORKER_TIMEOUT the whole of one worker
%%   SOCKET_TIMEOUT what cocolog itself waits on one socket operation
%%
%%     cocolog -s test/groups.pl        from the checkout root
%%
%% Every interpreter IS a child, twelve of them at once: that is the claim.

:- use_module('test/prelude.pl').

main :-
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    env_int('SETUP_TIMEOUT', 20, Setup),
    env_int('WORKER_TIMEOUT', 60, Worker),
    env_int('SOCKET_TIMEOUT', 10, Socket),
    %% How many turns a group must take before "all three took turns" is a
    %% claim about the scheduler rather than a coin toss. See the --steps note
    %% below: a fair split of N turns three ways starves somebody about
    %% 3*(2/3)^N of the time, so 20 is 0.09% per group and the four groups
    %% measure 34, 24, 60 and 60.
    env_int('TURNS_FLOOR', 20, Floor),
    cocolog(C),
    sh_join(['--kb groups_test --host ', Host, ' --tcp ', Port, ' --timeout ', Socket], Base),
    SetupMs is Setup * 1000, WorkerMs is Worker * 1000,
    sh_join([Base, ' list >/dev/null 2>&1'], Probe),
    (   cocolog_run(Probe, _, 0, SetupMs)
    ->  true
    ;   sh_join(['no Zigurat server at ', Host, ':', Port], Why), skip(Why)
    ),
    scratch(D),
    section('loading the program'),
    %% CONSULT ASSERTS, IT DOES NOT REPLACE, so a run that consulted into a
    %% knowledge base a previous run had already filled would leave two copies
    %% of every clause -- and then every proof answers everything twice and the
    %% recursive one never terminates. The symptom reads exactly like a broken
    %% interpreter, which is why this line is here and not left to whoever
    %% cleans up after a failed run.
    sh_join([Base, ' forget >/dev/null 2>&1'], Forget), cocolog_run(Forget, _, _, SetupMs),
    %% AND RECLAIM WHAT THE LAST RUN LEFT. `forget' deletes rows; under MVCC a
    %% deleted row is kept so that a transaction entitled to an earlier view
    %% can still read it, and nothing takes it away afterwards. Saving a
    %% machine rewrites its row, so one proof of thirty turns leaves
    %% twenty-nine dead ones -- and this suite runs twelve of them. Without
    %% this line the store grows by every run that has ever happened and every
    %% read walks past all of it: the same twelve interpreters took 12 seconds
    %% against an empty store and 60 against one a few hundred runs had been
    %% through, which is how this test came to fail on its WORKER_TIMEOUT with
    %% nothing wrong anywhere.
    sh_join([Base, ' vacuum >/dev/null 2>&1'], Vacuum), cocolog_run(Vacuum, _, _, SetupMs),
    sh_join([Base, ' consult demo/family.pl >/dev/null 2>&1'], Consult), cocolog_run(Consult, _, _, SetupMs),
    %% Anything left over from a previous run would be claimed by these
    %% workers.
    forall(group(G, _, _), ( sh_join([Base, ' drop state-', G, ' >/dev/null 2>&1'], Drop), cocolog_run(Drop, _, _, SetupMs) )),
    section('twelve interpreters, three per machine'),
    %% THE WORKERS GO UP BEFORE THE WORK DOES, and that is not a nicety.
    %% Starting twelve processes takes long enough -- fork, exec, connect,
    %% hand-shake -- that the first few were finishing a machine before the
    %% last few were running, and a worker that arrives after its machine is
    %% gone can only report that there was nothing to do. Then the run passes
    %% every check about ANSWERS and fails the one that asks whether the group
    %% actually shared, which is the check the whole arrangement exists for.
    %% `cocolog work' waits for a machine it has never seen, so the honest
    %% order is: everybody up, then the work.
    %%
    %% --steps 1 is the smallest turn there is, and the size of the turn is
    %% what decides whether "all three took turns" is a claim about the
    %% scheduler or a coin toss. THAT DISTINCTION COST THIS CASE ITS ONLY
    %% FLAKE, so the arithmetic is written out rather than left as a feeling.
    %%
    %% The scheduler hands a released machine to whichever partner polls
    %% first, which over a whole run is a FAIR RANDOM SPLIT -- and it measured
    %% fair: sixteen runs put the smallest share of each group at or slightly
    %% above what a fair three-way split of the same number of turns predicts.
    %% A fair split of N turns among three workers leaves one of them with
    %% NONE about 3*(2/3)^N of the time, and that is not a bug to fix in the
    %% interpreter; it is a property of splitting a small number of turns
    %% three ways.
    %%
    %% At --steps 2 the four groups took 17, 12, 30 and 30 turns -- and
    %% 3*(2/3)^12 is 2.3%, so group b alone failed about one run in forty.
    %% That is exactly the rate this case was flaking at. --steps 1 doubles
    %% every group's turn count for about 0.9s of wall clock, and TURNS_FLOOR
    %% below turns the premise into a checked precondition instead of an
    %% assumption, so a future change that makes the work smaller fails
    %% saying so rather than flaking a fortnight later.
    findall(W-Pid, ( group(G, _, _), member(M, [1, 2, 3]), sh_join([G, M], W),
                     sh_join(['timeout ', Worker, ' ', C, ' ', Base, ' --steps 1 --answers 0 work ', W, ' state-', G, ' > ', D, '/', W, '.log 2>&1'], Cmd),
                     spawn(Cmd, Pid) ), Workers),
    section('starting four machines'),
    forall(group(G, Goal, _),
           ( sh_join([Base, ' start state-', G, ' "', Goal, '" > ', D, '/start-', G, '.log 2>&1'], Start),
             cocolog_run(Start, _, _, SetupMs) )),
    %% 124 is what `timeout' exits with when it had to kill the command
    WaitMs is WorkerMs + 5000,
    findall(W, ( member(W-Pid, Workers), ( proc_wait(Pid, WaitMs, Rc) -> Rc =:= 124 ; proc_stop(Pid) ) ), TimedOut),
    ( TimedOut == [] -> true ; format("     TIMED OUT: ~w~n", [TimedOut]) ),
    answers(D), turns(D, Floor),
    %% And nothing is left suspended: a machine that finished is dropped.
    sh_join([Base, ' list 2>/dev/null | grep -cE ''^  state-'' || true'], List), cocolog_run(List, Left, _, SetupMs),
    check('no machine left suspended', Left, '0'),
    shl(['rm -rf ', D]),
    checks_done.

env_int(Name, Default, V) :- ( getenv(Name, A), atom_number(A, N) -> V = N ; V = Default ).

%% The four groups, each with its goal and the answer set that goal must
%% produce. Kept here rather than spread through the file, so that adding a
%% fifth group is one clause.
group(a, 'ancestor(tom,X)', ['ancestor(tom,ann)', 'ancestor(tom,bob)', 'ancestor(tom,jim)', 'ancestor(tom,liz)', 'ancestor(tom,pat)', 'ancestor(tom,zoe)']).
group(b, 'ancestor(bob,X)', ['ancestor(bob,ann)', 'ancestor(bob,jim)', 'ancestor(bob,pat)', 'ancestor(bob,zoe)']).
group(c, 'ancestor(X,zoe)', ['ancestor(bob,zoe)', 'ancestor(jim,zoe)', 'ancestor(pat,zoe)', 'ancestor(tom,zoe)']).
group(d, 'ancestor(X,jim)', ['ancestor(bob,jim)', 'ancestor(pat,jim)', 'ancestor(tom,jim)']).

%% The answers of a machine, however many of its workers produced them. The
%% numbering restarts each turn, so it is stripped.
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

%% Every member of every group has to have done some of it, or the hand-off
%% was never exercised and the run proves only that one worker can finish a
%% machine.
%%
%% AND THE PREMISE IS CHECKED FIRST, because it is the premise that broke.
%% The share check is only meaningful over enough turns: a fair three-way
%% split of N leaves somebody with none about 3*(2/3)^N of the time, which at
%% TURNS_FLOOR is under a tenth of a percent per group and at the twelve
%% turns this case used to give group b was one run in forty. So the total
%% is checked as well as the split, and a change that shrinks the work -- a
%% smaller program, a bigger --steps, a faster proof -- fails HERE, naming
%% the number, instead of turning back into an occasional red nobody can
%% reproduce.
turns(D, Floor) :-
    forall(group(G, _, _),
           ( findall(W=N, ( member(M, [1, 2, 3]), sh_join([G, M], W), turns_of(D, W, N) ), Counts),
             findall(N, member(_=N, Counts), Ns), sum_list(Ns, Total),
             format("     turns: ~w  (total ~w)~n", [Counts, Total]),
             %% A WORKER THAT WAS KILLED BY ITS TURN SAYS SO, and this is where
             %% it gets read. Without it a 1 in the line above is
             %% indistinguishable from a worker whose partners simply beat it
             %% to every claim -- which is exactly how the uneven split here
             %% was misread once already.
             forall(( member(M, [1, 2, 3]), sh_join([D, '/', G, M, '.log'], Log), exists_file(Log),
                      read_file_to_codes(Log, Cs), re_lines('STOPPED after', Cs, Ss), member(S, Ss) ),
                    ( atom_codes(SA, S), format("     ~w~n", [SA]) )),
             ( Total >= Floor -> Enough = yes ; sh_join(['no: ', Total, ' < ', Floor], Enough) ),
             sh_join(['group ', G, ' did enough turns to be worth splitting'], L1), check(L1, Enough, yes),
             ( member(_=0, Counts) -> Shared = no ; Shared = yes ),
             sh_join(['all three interpreters of group ', G, ' took turns'], L2), check(L2, Shared, yes) )).
