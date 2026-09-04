%% library(zigurat): the connection under the knowledge base, steered from
%% Prolog.
%%
%% WHAT IT IS CHECKING, and why each part is there:
%%
%%   THE TRANSACTION IS THE PROGRAM'S TO SHAPE. zigurat_begin,
%%   zigurat_isolation/1, zigurat_auto_commit/1 and zigurat_transaction_id/1
%%   answer on a live connection; an explicit zigurat_commit makes a write
%%   durable BEFORE the turn's own commit, and an explicit zigurat_rollback
%%   takes an uncommitted write back -- both proven ACROSS PROCESSES,
%%   because "committed" is a claim about what another process sees.
%%
%%   DML TRAVELS AS PROCEDURE CALLS. zigurat_call/3 calls a compiled
%%   procedure with typed arguments and hands back what came: a RETURNS
%%   value as itself, a cursor's rows as lists -- the same rows the
%%   knowledge base's own hooks ride.
%%
%%   DDL IS THE SERVER'S COMPILER, AND THE SERVER'S GATE. zigurat_compile/1
%%   ships Parsi source; a server with COMPILER/REMOTE_MODE FALSE -- the
%%   shipped default -- refuses it, and the refusal arrives as a catchable
%%   error. That the refusal is exact is what this suite can check against
%%   a default server; the positive road needs an operator who turned the
%%   gate, and is documented rather than assumed here.
%%
%%   --local HAS NO CONNECTION, and every predicate says so as a catchable
%%   error instead of pretending a local store has a transaction to steer.
%%
%% THERE IS NO `use_module(library(zigurat))' IN ANY CASE HERE, and that is
%% the point rather than an omission: zigurat is TIER 1 -- compiled in and
%% registered before the first goal, like lists, apply, dcg, files and
%% builtins -- so asking for it is a directive that does nothing. These
%% cases used to open with one, which made every query read as though the
%% import were doing some work. `test/library.pl' is where the fact that
%% `use_module' on a registered module succeeds at once is checked.
%%
%%     cocolog -s test/zigurat-lib.pl        from the checkout root
%%
%% Every check but the first IS a child: the claim is what another process
%% sees over its own connection. SKIPs without a server.

:- use_module('test/prelude.pl').

main :-
    local_refuses,
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    sh_join(['--kb ziglib_test --host ', Host, ' --tcp ', Port], Base),
    sh_join([Base, ' query "true" >/dev/null 2>&1'], Probe),
    (   cocolog_run(Probe, _, 0)
    ->  true
    ;   sh_join(['no Zigurat server at ', Host, ':', Port], Why), skip(Why)
    ),
    sh_join([Base, ' --timeout 10'], W),
    port_is_tcp(Host, Port),
    sh_join([W, ' forget >/dev/null 2>&1'], Forget),
    cocolog_run(Forget, _, _),
    the_verbs(W), commit(W), rollback(W), dml(W), ddl(W),
    cocolog_run(Forget, _, _),
    checks_done.

%% a child's stdout, and how many of its lines match an anchored pattern
lines(Args, Pat, N) :-
    sh_join([Args, ' 2>/dev/null'], A), cocolog_run(A, Text, _),
    atom_codes(Text, Cs), re_lines(Pat, Cs, Ls), length(Ls, N).

local_refuses :-
    section('--local refuses, catchably, with no server needed'),
    written(catch(zigurat_commit, error(cocolog_error(_), _), R1 = refused), R1, G1),
    check('--local refuses the connection verbs', G1, refused).

port_is_tcp(Host, Port) :-
    section('`--port'' is deprecated and still exactly `--tcp'''),
    %% It named a number when there was one transport; there are four now,
    %% and --tcp/--tls/--http/--https say WHICH as well as where. Nothing in
    %% this tree spells it any more -- but a script somewhere does, so it
    %% keeps working, and SILENTLY: a deprecation notice on stderr every run
    %% would land in the output of every pipeline that has one.
    sh_join(['--kb ziglib_test --host ', Host, ' --port ', Port, ' --timeout 10 query "true"'], A),
    lines(A, '^  1\\. true$', N1),
    check('--port still reaches the server', N1, 1),
    cocolog(C),
    sh_join([C, ' --kb ziglib_test --host ', Host, ' --port ', Port, ' --timeout 10 query "true" 2>&1 >/dev/null | wc -c | tr -d '' '''], Cmd),
    shell(Cmd, Bytes, _),
    check('--port says nothing on stderr', Bytes, '0').

the_verbs(W) :-
    section('the verbs answer'),
    sh_join([W, ' query "zigurat_begin, zigurat_isolation(serializable), zigurat_isolation(read_committed), zigurat_auto_commit(false), zigurat_transaction_id(T), integer(T), write(ok), nl"'], A),
    lines(A, '^ok$', N),
    check('begin, isolation, auto_commit, transaction_id', N, 1).

commit(W) :-
    section('an explicit commit is durable across processes'),
    sh_join([W, ' query "assert(zlib_c(1)), zigurat_commit, write(done), nl" >/dev/null 2>&1'], A1), cocolog_run(A1, _, _),
    sh_join([W, ' query "zlib_c(X), write(X), nl"'], A2), lines(A2, '^1$', N),
    check('an explicit commit is seen by a second process', N, 1).

rollback(W) :-
    section('an explicit rollback takes an uncommitted write back'),
    sh_join([W, ' query "assert(zlib_r(1)), zigurat_rollback, write(done), nl" >/dev/null 2>&1'], A1), cocolog_run(A1, _, _),
    %% an unknown procedure THROWS here (as in SWI) -- a rolled-back
    %% predicate is not merely false, it is not there at all
    sh_join([W, ' query "catch(( zlib_r(_) -> write(seen) ; write(clean) ), error(existence_error(_, _), _), write(clean)), nl"'], A2),
    lines(A2, '^clean$', N),
    check('an explicit rollback is invisible to a second process', N, 1).

dml(W) :-
    section('DML: a compiled procedure, called with typed arguments'),
    sh_join([W, ' query "assert(zlib_q(41)), assert(zlib_q(42))" >/dev/null 2>&1'], A0), cocolog_run(A0, _, _),
    sh_join([W, ' query "zigurat_call(''cocolog::clause_count'', [ziglib_test, zlib_q, int(1)], [N]), write(N), nl"'], A1),
    lines(A1, '^2$', N1),
    check('zigurat_call answers a RETURNS value', N1, 1),
    sh_join([W, ' query "zigurat_call(''cocolog::clauses_of'', [ziglib_test, zlib_q, int(1)], Rows), length(Rows, N), write(N), nl"'], A2),
    lines(A2, '^2$', N2),
    check('and hands a cursor''s rows back as lists', N2, 1),
    sh_join([W, ' query "zigurat_call(''cocolog::clauses_of'', [ziglib_test, zlib_q, int(1)], [[_, B] | _]), write(B), nl"'], A3),
    lines(A3, 'zlib_q\\(41\\)', N3),
    check('with the fields readable in place', N3, 1).

ddl(W) :-
    section('DDL: the compiler''s gate answers as an error'),
    %% The shipped default is COMPILER/REMOTE_MODE FALSE, and the refusal
    %% must arrive as a catchable error naming the server's reason -- not as
    %% a hang, not as a success. An operator who turned the gate on gets the
    %% compile instead, and then the catch simply never fires; either way the
    %% goal proves, which is what makes this checkable against any server.
    sh_join([W, ' query "catch((zigurat_compile(''SUITE zlib_ddl; CREATE TABLE cocolog::zlib_ddl (id Long NOT NULL); END SUITE;''), write(compiled)), error(cocolog_error(_), _), write(refused)), nl"'], A),
    lines(A, '^(refused|compiled)$', N),
    check('zigurat_compile answers, gate or compile', N, 1).
