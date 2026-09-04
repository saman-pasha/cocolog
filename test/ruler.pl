%% One interpreter writes the program; eight others read it while it does.
%%
%% THE OTHER HALF OF THE CLAIM. test/groups.pl is many interpreters sharing
%% machine STATE. This is many interpreters sharing the KNOWLEDGE BASE: a ruler
%% process asserts facts and rules one at a time, and eight querier processes
%% ask questions of the same knowledge base at the same time, against the same
%% server, with no coordination beyond the database itself.
%%
%% WHAT IT IS CHECKING, and why each part is there:
%%
%%   A QUERIER NEVER SEES A HALF-WRITTEN PROGRAM. Every answer a querier gives
%%   has to be an answer the finished program would also give. A rule asserted
%%   before the facts it needs is not wrong -- it just proves nothing yet -- so
%%   the check is one-sided on purpose: no answer may ever be OUTSIDE the final
%%   answer set. Anything else means a querier read a clause that was never
%%   committed, or read half of one.
%%
%%   THE PROGRAM REALLY IS BEING WRITTEN WHILE THEY READ. The ruler asserts
%%   with a pause between clauses, so the queriers span the whole of it rather
%%   than all arriving after the last write. The count of clauses seen has to
%%   GROW across the run, or the queriers were only ever reading a finished
%%   program and the test proves nothing about concurrency.
%%
%%   AND AT THE END EVERYONE AGREES. Once the ruler has finished, a fresh query
%%   must produce the complete answer set -- so nothing was lost by being
%%   written under contention.
%%
%% WHY IT IS A DIFFERENT SHAPE OF LOAD FROM groups.pl. The queriers do not
%% claim anything and never write, so this is one writer against eight
%% readers of the same rows -- the case where a reader can catch a row
%% mid-rewrite, and where an indexed lookup and an index update run at the
%% same moment.
%%
%%     cocolog -s test/ruler.pl        from the checkout root
%%
%% Every querier IS a child, eight of them at once, each a shell loop of
%% queries until the ruler is done: that is the claim.

:- use_module('test/prelude.pl').

main :-
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    env_int('SETUP_TIMEOUT', 20, Setup),
    env_int('QUERIER_TIMEOUT', 60, Querier),
    env_int('SOCKET_TIMEOUT', 10, Socket),
    env_int('QUERIERS', 8, Queriers),
    cocolog(C),
    sh_join(['--kb ruler_test --host ', Host, ' --tcp ', Port, ' --timeout ', Socket], Base),
    SetupMs is Setup * 1000,
    sh_join([Base, ' list >/dev/null 2>&1'], Probe),
    (   cocolog_run(Probe, _, 0, SetupMs)
    ->  true
    ;   sh_join(['no Zigurat server at ', Host, ':', Port], Why), skip(Why)
    ),
    scratch(D),
    %% The program, one clause per line, in the order the ruler asserts it.
    %% The rules come FIRST and the facts after, so that for most of the run
    %% there are rules whose facts have not arrived -- which is the state a
    %% querier must handle by proving nothing rather than by proving
    %% something wrong.
    Program = [ 'ancestor(X,Y) :- parent(X,Y).',
                'ancestor(X,Y) :- parent(X,Z), ancestor(Z,Y).',
                'parent(tom,bob).', 'parent(tom,liz).', 'parent(bob,ann).',
                'parent(bob,pat).', 'parent(pat,jim).', 'parent(jim,zoe).' ],
    length(Program, Clauses),
    %% Every ancestor/2 the finished program can prove. A querier that
    %% answers anything not in here read something that was never true.
    Final = [ 'ancestor(bob,ann)', 'ancestor(bob,jim)', 'ancestor(bob,pat)', 'ancestor(bob,zoe)',
              'ancestor(jim,zoe)', 'ancestor(pat,jim)', 'ancestor(pat,zoe)', 'ancestor(tom,ann)',
              'ancestor(tom,bob)', 'ancestor(tom,jim)', 'ancestor(tom,liz)', 'ancestor(tom,pat)',
              'ancestor(tom,zoe)' ],
    section('emptying the knowledge base'),
    sh_join([Base, ' forget >/dev/null 2>&1'], Forget), cocolog_run(Forget, _, _, SetupMs),
    %% ...and reclaim what earlier runs left behind. See the same line in
    %% test/groups.pl for why a store that is never vacuumed makes this suite
    %% slower every time it is run.
    sh_join([Base, ' vacuum >/dev/null 2>&1'], Vacuum), cocolog_run(Vacuum, _, _, SetupMs),
    format("-- one ruler writing ~w clause(s), ~w queriers reading~n", [Clauses, Queriers]),
    %% The queriers go up first, so that they are already asking by the time
    %% the first clause lands -- the same reason groups.pl starts its workers
    %% first. A QUERIER RUNS UNTIL THE RULER IS FINISHED, not for a fixed
    %% number of turns. A fixed count is a race against how long the writing
    %% takes: eight queriers doing forty quick queries each were all done
    %% inside two seconds, the ruler was eight seconds writing, and every one
    %% of them answered `false' to a knowledge base that had nothing in it
    %% yet. The run passed every check about what may not be answered and
    %% proved nothing at all, which is the failure mode this file exists to
    %% avoid.
    %%
    %% `--answers 0' is every answer, not the first ten: a querier that
    %% stopped early could not produce an answer outside the set and the
    %% check would pass without looking at most of the program.
    atom_concat(D, '/ruler-done', Done),
    findall(Pid, ( between(1, Queriers, Q),
                   sh_join(['n=0; while [ ! -f ', Done, ' ] && [ "$n" -lt 400 ]; do timeout ', Querier, ' ', C, ' ', Base,
                            ' --answers 0 query "ancestor(X,Y)" 2>&1 | sed "s/^/q', Q, ' /"; n=$((n + 1)); done > ', D, '/q', Q, '.log 2>&1'], Cmd),
                   proc_spawn(Cmd, Pid) ), Pids),
    %% And now the program arrives, one clause at a time -- EACH FROM A FILE
    %% OF ITS OWN. A consult replaces the clauses the same file put there
    %% before (test/reconsult.pl), so one scratch file rewritten per clause
    %% would leave the knowledge base holding only the last clause written;
    %% a file per clause is eight consults of eight files, which is what
    %% appending means now.
    proc_sleep(1000),
    atom_concat(D, '/ruler.log', RulerLog),
    forall(nth1(N, Program, Clause),
           ( sh_join([D, '/clause-', N], File), fixture(File, [Clause]),
             sh_join([Base, ' consult ', File, ' >> ', RulerLog, ' 2>&1'], Consult), cocolog_run(Consult, _, _, SetupMs),
             proc_sleep(1000) )),
    %% One more round of queries against the finished program before they
    %% stop, so that the last thing every querier saw is the whole of it.
    proc_sleep(2000),
    write_file_from_codes(Done, []),
    format("     ruler done~n", []),
    forall(member(Pid, Pids), ( proc_wait(Pid, 120000, _) -> true ; proc_stop(Pid) )),
    the_checks(D, Base, SetupMs, Clauses, Final),
    shl(['rm -rf ', D]),
    checks_done.

env_int(Name, Default, V) :- ( getenv(Name, A), atom_number(A, N) -> V = N ; V = Default ).

%% every querier's log, as one code list
all_logs(D, Cs) :-
    directory_files(D, Fs),
    findall(L, ( member(F, Fs), re_match('^q[0-9]+\\.log$', F), sh_join([D, '/', F], P), read_file_to_codes(P, L) ), Ls),
    append(Ls, Cs).

the_checks(D, Base, SetupMs, Clauses, Final) :-
    all_logs(D, All),
    %% Everything every querier ever answered.
    re_lines('^q[0-9]+ +[0-9]+\\. ', All, AnsLines),
    findall(A, ( member(L, AnsLines), atom_codes(LA, L), re_replace_atom('^q[0-9]* *[0-9]*\\. ', '', LA, A) ), Seen0),
    sort(Seen0, Seen),
    %% One-sided: nothing outside the finished program's answers.
    findall(A, ( member(A, Seen), \+ memberchk(A, Final) ), Outside),
    check('no querier answered outside the program', Outside, []),
    %% Nobody fell over, and nobody was refused.
    re_lines('refused|failed|cannot|no server', All, Errs), length(Errs, NErrs),
    check('no querier hit an error', NErrs, 0),
    atom_concat(D, '/ruler.log', RulerLog),
    ( exists_file(RulerLog) -> read_file_to_codes(RulerLog, RCs) ; RCs = [] ),
    re_lines('consulted 1 clause', RCs, Wrote), length(Wrote, NWrote),
    check('the ruler wrote every clause', NWrote, Clauses),
    %% The program was genuinely growing while they read: the first query of
    %% the run and the last must not have seen the same thing.
    re_lines('^q[0-9]+ +1\\. ', All, Firsts), length(Firsts, NFirst),
    ( NFirst > 0 -> Ran = yes ; Ran = no ),
    check('queriers ran while it was being written', Ran, yes),
    atom_concat(D, '/q1.log', Q1),
    ( exists_file(Q1) -> read_file_to_codes(Q1, Q1Cs) ; Q1Cs = [] ),
    codes_lines(Q1Cs, Q1Lines),
    head_lines(40, Q1Lines, Head), tail_lines(40, Q1Lines, Tail),
    codes_lines(HeadCs, Head), codes_lines(TailCs, Tail),
    re_lines('^q1 +[0-9]+\\. ', HeadCs, EarlyL), length(EarlyL, Early),
    re_lines('^q1 +[0-9]+\\. ', TailCs, LateL), length(LateL, Late),
    format("     q1 answered ~w time(s) in its first queries, ~w in its last~n", [Early, Late]),
    ( Late > Early -> Grew = yes ; Grew = no ),
    check('the knowledge base grew under them', Grew, yes),
    %% And the finished program proves everything, from a process that took
    %% no part.
    sh_join([Base, ' --answers 0 query "ancestor(X,Y)" 2>/dev/null'], Args),
    cocolog_run(Args, Out, _, SetupMs),
    atom_codes(Out, OCs), re_lines('^  [0-9]+\\. ', OCs, OL),
    findall(A, ( member(L, OL), atom_codes(LA, L), re_replace_atom('^ *[0-9]*\\. ', '', LA, A) ), Now0),
    msort(Now0, Now),
    check('the finished program proves all of it', Now, Final).
