%% Consulting a file REPLACES the clauses it put in the store last time.
%%
%% WHAT IS BEING PINNED. A tutorial is three processes -- train, test,
%% predict -- against one store, and each of them consults the same file.
%% The store used to APPEND, so the second process held two copies of every
%% clause and a generator without a cut answered once per copy: a batch of
%% three became twelve pictures (tutorials/tensor/README.md keeps the
%% story, and the cut convention it forced). Now every clause a consult
%% reads is owned by the file, under its real path, and the first clause
%% of each predicate the file defines takes the file's old clauses of it
%% out before going in. Three things follow, and each is checked:
%%
%%   THE SAME FILE TWICE IS ONE COPY. A second process counting the file's
%%   facts finds the number the file holds.
%%
%%   WHAT THE PROGRAM ASSERTED STAYS. An assertz into a predicate the file
%%   defines survives the next consult of the file, beside the file's own
%%   clauses -- and comes first, since the file's are added again after it.
%%   A model saved into the store is exactly this, under other names.
%%
%%   AN EDITED FILE IS THE NEW FILE. The previous version's clauses go with
%%   it; a reused store no longer answers with the file as it was.
%%
%% On the wire the owner travels with the clause as '$from'(Path, Clause)
%% in the same text column, which the fetch takes off again -- so the same
%% three claims hold against a Zigurat server, and are checked there when
%% one answers; a row written before this existed is a bare clause and
%% nobody's to replace, so an older store reads as it always did.
%%
%%     cocolog -s test/reconsult.pl        from the checkout root
%%
%% Every check IS a child: the claim is what a SECOND process reads.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    atom_concat(D, '/prog.pl', F),
    twice(D, F), survives(D, F), edited(D, F), two_spellings(D, F),
    a_librarys_clauses(D), over_the_wire(F),
    shl(['rm -rf ', D]),
    checks_done.

two(F) :-
    fixture(F, [ 'fact(1).', 'fact(2).',
                 'count(N) :- findall(X, fact(X), L), length(L, N).',
                 'facts(L) :- findall(X, fact(X), L).' ]).
three(F) :-
    fixture(F, [ 'fact(1).', 'fact(2).', 'fact(3).',
                 'count(N) :- findall(X, fact(X), L), length(L, N).',
                 'facts(L) :- findall(X, fact(X), L).' ]).

%% a process against the embedded store, consulting the file, proving Goal
q(D, F, Goal, Got) :-
    sh_join(['--kb reconsult --embed ', D, '/store run ', F, ' "', Goal, '"'], Args),
    cocolog_answer(Args, Got).

twice(D, F) :-
    section('the same file, twice, into one embedded store'),
    two(F),
    q(D, F, 'count(N), write(answer(N)), nl', G1),
    check('the first process counts the file''s two facts', G1, answer(2)),
    q(D, F, 'count(N), write(answer(N)), nl', G2),
    check('the second still counts two: replaced, not appended', G2, answer(2)).

survives(D, F) :-
    section('what the program asserted survives the next consult of the file'),
    q(D, F, 'assertz(fact(9)), count(N), write(answer(N)), nl', G1),
    check('a fact the program asserts joins the file''s two', G1, answer(3)),
    q(D, F, 'count(N), write(answer(N)), nl', G2),
    check('and is still there after the file is consulted again', G2, answer(3)).

edited(D, F) :-
    section('an edited file is the new file; the asserted clause stays and comes first'),
    three(F),
    q(D, F, 'count(N), write(answer(N)), nl', G1),
    check('three from the file now, and the asserted one', G1, answer(4)),
    q(D, F, 'facts(L), write(answer(L)), nl', G2),
    check('the old version''s clauses are gone, the asserted one is kept ahead', G2, answer([9,1,2,3])).

two_spellings(D, _) :-
    section('one file under two spellings of its path is one file'),
    cocolog(C),
    sh_join(['cd ', D, ' && ', C, ' --kb reconsult --embed ', D, '/store run ./prog.pl "count(N), write(answer(N)), nl" 2>&1'], Cmd),
    proc_run(Cmd, 60000, Out, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out, A) -> term_to_atom(G, A) ; G = none ),
    check('consulted as ./prog.pl from its own directory, nothing doubles', G, answer(4)).

%% A MODULE'S CLAUSES ARE NOT THE PROGRAM'S, AND THE STORE MUST NOT WRITE THEM.
%%
%% The backend rewrites a dirty predicate WHOLESALE -- every row of it
%% forgotten and every clause the store holds sent back -- and the store holds
%% a library's clauses beside the program's the moment anything asserts into a
%% name a library defines. So one `assertz(member(foo,[a]))' used to put THREE
%% rows in the knowledge base: the program's clause and both of
%% library(lists)'s own. The next process then fetched those two ON TOP of the
%% copy its own modules had already given it, and `member(X,[p,q])' answered
%% [p,q,q,p,q,q] -- five clauses where there should be three.
%%
%% THE SYMPTOM IS THE CHECK, not the row count, because the row count is only
%% visible from inside. A second process asking `member(X,[p,q])' is what any
%% program would do, and it is wrong by exactly the duplication.
a_librarys_clauses(D) :-
    section('a library''s own clauses never reach the knowledge base'),
    atom_concat(D, '/libstore', S),
    cocolog(C),
    %% tier 1, compiled into the binary: library(lists) defines member/2, and
    %% its clauses carry origin 0 exactly as a runtime assertz does -- so
    %% nothing but the MUTE that put them there can tell them apart.
    sh_join(['--kb libclauses --embed ', S,
             ' query "assertz(member(foo,[a]))"'], W1),
    cocolog_out(W1, _),
    sh_join(['--kb libclauses --embed ', S,
             ' query "findall(X, member(X,[p,q]), L), write(answer(L)), nl"'], R1),
    cocolog_answer(R1, G1),
    check('member/2 answers two solutions, not six', G1, answer([p,q])),
    sh_join(['--kb libclauses --embed ', S,
             ' query "( member(foo,[a]) -> R = yes ; R = no ), write(answer(R)), nl"'], R2),
    cocolog_answer(R2, G2),
    check('and what the program asserted IS in the store', G2, answer(yes)),
    %% tier 2, a .pl file on the library path: its clauses carry a REAL origin,
    %% the file's own path, so `origins' cannot be the discriminator either.
    atom_concat(D, '/libstore2', S2),
    sh_join(['--kb libclauses2 --embed ', S2,
             ' query "use_module(library(http)), assertz(http_header(mine,a,b))"'], W3),
    cocolog_out(W3, _),
    sh_join(['--kb libclauses2 --embed ', S2,
             ' query "findall(A-B-Cc, clause(http_header(A,B,Cc), _), L), length(L, N), write(answer(N)), nl"'], R3),
    cocolog_answer(R3, G3),
    check('a tier-2 library''s clause is not written either', G3, answer(1)).

over_the_wire(F) :-
    section('and the same three claims over the wire, when a server answers'),
    ( getenv('ZIGURAT_HOST', Host) -> true ; Host = '127.0.0.1' ),
    ( getenv('ZIGURAT_PORT', Port) -> true ; Port = 2160 ),
    cocolog(C),
    sh_join(['timeout 20 ', C, ' --host ', Host, ' --tcp ', Port, ' --timeout 10 --kb reconsult_case list >/dev/null 2>&1'], Probe),
    (   sh_exit(Probe, 0)
    ->  sh_join(['timeout 60 ', C, ' --host ', Host, ' --tcp ', Port, ' --timeout 60 --kb reconsult_case forget >/dev/null 2>&1'], Forget),
        sh_exit(Forget, _),
        two(F),
        wire(Host, Port, F, 'count(N), write(answer(N)), nl', G1),
        check('wire: the first process counts two', G1, answer(2)),
        wire(Host, Port, F, 'count(N), write(answer(N)), nl', G2),
        check('wire: the second still counts two', G2, answer(2)),
        wire(Host, Port, F, 'assertz(fact(9)), count(N), write(answer(N)), nl', G3),
        check('wire: an asserted fact survives the third', G3, answer(3)),
        three(F),
        wire(Host, Port, F, 'facts(L), write(answer(L)), nl', G4),
        check('wire: the edited file replaces its own, keeps the asserted', G4, answer([9,1,2,3])),
        sh_exit(Forget, _)
    ;   format("     (skipped: no Zigurat server at ~w:~w -- the wire half not run)~n", [Host, Port])
    ).

wire(Host, Port, F, Goal, Got) :-
    sh_join(['--host ', Host, ' --tcp ', Port, ' --timeout 60 --kb reconsult_case run ', F, ' "', Goal, '"'], Args),
    cocolog_answer(Args, Got).
