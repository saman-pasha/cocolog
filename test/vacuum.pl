%% The store's two hygiene verbs -- forget and the vacuum -- in both
%% arrangements, with the vacuum's gate.
%%
%% WHAT IT IS CHECKING, and why each part is there:
%%
%%   FORGET KEEPS ITS CONTRACT WHATEVER ITS SHAPE. The whole-base forget
%%   has been one DELETE, then predicate-at-a-time chunks, then one DELETE
%%   again (cmd_forget in cocolog.cicili tells that story); the count, the
%%   emptiness -- declarations included -- and idempotence must never
%%   depend on how the deleting is carved, and these checks are what held
%%   through both changes of shape.
%%
%%   THE VERB RECLAIMS AND ONLY RECLAIMS. `forget' deletes every clause; the
%%   vacuum after it must answer the same live count twice -- an unchanged
%%   second answer is the statement that there was nothing left to reclaim
%%   -- and a knowledge base consulted AFTER a vacuum must answer queries
%%   exactly as it would in a store that was never vacuumed. Live rows are
%%   untouched; that is what makes it a vacuum and not an emptying.
%%
%%   THE BUILTIN IS GATED. `vacuum_kb' without `--vacuum' must raise
%%   permission_error(vacuum, knowledge_base, _) -- a refusal, never a quiet
%%   success -- because the pass spends the store's point-in-time reads and
%%   that is the operator's decision, not the program's. With `--vacuum' it
%%   must succeed and answer the live count.
%%
%% The embedded half always runs, the store being in the one binary; the
%% wire half is skipped without a server, because "no server here" and "the
%% vacuum is wrong" are different findings.
%%
%%     cocolog -s test/vacuum.pl        from the checkout root
%%
%% Every check IS a child: the verbs are the command line's.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    atom_concat(D, '/facts.pl', Facts),
    fixture(Facts, ['p(1).', 'p(2).', 'p(3).', 'q(a).', 'q(b).', ':- dynamic d/1.']),
    embedded(D, Facts), wire(Facts),
    shl(['rm -rf ', D]),
    checks_done.

%% `cocolog PREFIX VERB ...', both streams, as text
verb(Prefix, Rest, Text) :- sh_join([Prefix, ' ', Rest, ' 2>&1'], Args), cocolog_run(Args, Text, _).

%% grep -c over the lines of Text: how many match the anchored pattern
count(Pat, Text, N) :- atom_codes(Text, Cs), re_lines(Pat, Cs, Ls), length(Ls, N).

%% One arrangement's whole story, parameterised on how to reach the store:
%% Label names it, Prefix is the cocolog command up to but excluding the verb.
exercise(Label, Prefix, Facts) :-
    %% FORGET'S CONTRACT FIRST. The contract that must survive whatever shape
    %% the deleting takes: the count is the clause count, everything goes --
    %% a declared-but-empty dynamic included, the half only the declarations
    %% know -- and a second forget finds nothing.
    sh_join([Prefix, ' consult ', Facts, ' >/dev/null 2>&1'], Consult),
    cocolog_run(Consult, _, _),
    verb(Prefix, forget, Forgot),
    count('^forgot 5 clause', Forgot, N1),
    lbl(Label, 'forget answers the clause count', L1), check(L1, N1, 1),
    verb(Prefix, 'query "catch(p(_), error(existence_error(procedure, _), _), (write(gone), nl))"', Gone),
    count('^gone$', Gone, N2),
    lbl(Label, 'a forgotten predicate is gone, not empty', L2), check(L2, N2, 1),
    verb(Prefix, 'query "catch(d(_), error(existence_error(procedure, _), _), (write(gone), nl))"', DGone),
    count('^gone$', DGone, N3),
    lbl(Label, 'the declared-but-empty dynamic went too', L3), check(L3, N3, 1),
    verb(Prefix, forget, Again),
    count('^forgot 0 clause', Again, N4),
    lbl(Label, 'and a second forget finds nothing', L4), check(L4, N4, 1),
    cocolog_run(Consult, _, _),
    verb(Prefix, 'forget >/dev/null', _),
    verb(Prefix, vacuum, First),
    verb(Prefix, vacuum, Second),
    count('^vacuumed; ', First, N5),
    lbl(Label, 'the vacuum verb reclaims', L5), check(L5, N5, 1),
    ( First == Second -> Same = same ; Same = First-Second ),
    lbl(Label, 'and a second pass finds nothing more', L6), check(L6, Same, same),
    verb(Prefix, 'query "catch(vacuum_kb, error(permission_error(vacuum, knowledge_base, _), _), (write(refused), nl))"', Refused),
    count('^refused$', Refused, N7),
    lbl(Label, 'vacuum_kb without --vacuum is refused', L7), check(L7, N7, 1),
    verb(Prefix, '--vacuum query "vacuum_kb(Live), integer(Live), write(allowed), nl"', Allowed),
    count('^allowed$', Allowed, N8),
    lbl(Label, 'and with --vacuum it answers the live count', L8), check(L8, N8, 1),
    cocolog_run(Consult, _, _),
    verb(Prefix, '--vacuum query "vacuum_kb, findall(X, p(X), L), write(L), nl"', After),
    count('^\\[1,2,3\\]$', After, N9),
    lbl(Label, 'live clauses survive the pass', L9), check(L9, N9, 1),
    verb(Prefix, 'forget >/dev/null', _).

lbl(Label, Text, L) :- sh_join([Label, ': ', Text], L).

embedded(D, Facts) :-
    section('the embedded arrangement'),
    sh_join(['--kb vacuum_test --embed ', D, '/store'], Prefix),
    exercise(embed, Prefix, Facts).

wire(Facts) :-
    section('the wire arrangement'),
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' --kb vacuum_test --host ', Host, ' --tcp ', Port, ' --timeout 10 list >/dev/null 2>&1'], Probe),
    (   sh_exit(Probe, 0)
    ->  sh_join(['--kb vacuum_test --host ', Host, ' --tcp ', Port, ' --timeout 10'], Prefix),
        exercise(wire, Prefix, Facts)
    ;   format("     (skipped: no Zigurat server at ~w:~w)~n", [Host, Port])
    ).
