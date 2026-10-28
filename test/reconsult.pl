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
    a_librarys_clauses(D), as_a_goal(D), loaded_once(D), when_changed(D), reports(D),
    over_the_wire(F),
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

%% CONSULT/1 AS A GOAL IS A CONSULT (2.13.0). A running program reads the
%% file into the knowledge base as `run' reads it: written through, so a
%% second process that consulted nothing finds the clauses, and replaced
%% the next time rather than appended. Through 2.12 none of consult/1,
%% load_files/2 and `[File]' was a goal (cicilang's report).
as_a_goal(D) :-
    section('consult/1, load_files/2 and [File] as goals write through, and replace'),
    atom_concat(D, '/goal.pl', G), atom_concat(D, '/gstore', S),
    fixture(G, ['gfact(1).', 'gfact(2).']),
    sh_join(['--kb goals --embed ', S, ' query "consult(''', G,
             '''), findall(X, gfact(X), L), write(answer(L)), nl"'], A1),
    cocolog_answer(A1, G1),
    check('consult/1 as a goal reads the file', G1, answer([1,2])),
    sh_join(['--kb goals --embed ', S, ' query "findall(X, gfact(X), L), write(answer(L)), nl"'], A2),
    cocolog_answer(A2, G2),
    check('a second process that consulted nothing finds its clauses', G2, answer([1,2])),
    sh_join(['--kb goals --embed ', S, ' query "load_files(''', G, ''', []), [''', G,
             '''], findall(X, gfact(X), L), write(answer(L)), nl"'], A3),
    cocolog_answer(A3, G3),
    check('load_files/2 and [File] read it again, and replace it', G3, answer([1,2])).

%% NO FILE IS LOADED TWICE BY TWO ROADS (2.13.0). Through 2.12 a file that
%% `run' had consulted and the program then ensure_loaded/1'd, or one
%% use_module/1'd under two spellings, was read a second time -- into the
%% store and as a module, or as two modules -- and each of its clauses
%% answered twice. The file counts its reads in a global, so a read that
%% should not happen shows even where it would add nothing new.
loaded_once(D) :-
    section('one file, loaded by two roads, is loaded once'),
    atom_concat(D, '/once.pl', O), atom_concat(D, '/once', Ob),
    fixture(O, [':- ( nb_current(oreads, N) -> M is N + 1 ; M = 1 ), nb_setval(oreads, M).',
                'ofact(1).', 'ofact(2).']),
    Count = 'findall(X, ofact(X), L), nb_getval(oreads, N), write(answer(L-N)), nl',
    sh_join(['--local run ', O, ' "ensure_loaded(''', Ob, '''), ', Count, '"'], A1),
    cocolog_answer(A1, G1),
    check('run consults it; ensure_loaded/1 of it then reads nothing', G1, answer([1,2]-1)),
    sh_join(['--local query "consult(''', O, '''), ensure_loaded(''', Ob, '''), load_files(''', O,
             ''', [if(not_loaded)]), load_files(''', O, ''', [if(changed)]), ', Count, '"'], A2),
    cocolog_answer(A2, G2),
    check('after consult/1: ensure_loaded/1, if(not_loaded) and if(changed) read nothing', G2, answer([1,2]-1)),
    sh_join(['--local query "consult(''', O, '''), consult(''', O, '''), ', Count, '"'], A3),
    cocolog_answer(A3, G3),
    check('consult/1 twice reads it twice and holds it once', G3, answer([1,2]-2)),
    sh_join(['--local query "use_module(''', Ob, '''), use_module(''', O, '''), consult(''', O,
             '''), ', Count, '"'], A4),
    cocolog_answer(A4, G4),
    check('use_module/1 under two spellings, then consult/1: the module stands', G4, answer([1,2]-1)),
    atom_concat(D, '/self.pl', Self),
    fixture(Self, ['sfact(1).',
                   'main :- consult(''self.pl''), findall(X, sfact(X), L), write(answer(L)), nl.']),
    cocolog(C),
    sh_join(['cd ', D, ' && ', C, ' -s self.pl 2>&1'], Cmd5),
    proc_run(Cmd5, 60000, Out5, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out5, T5) -> term_to_atom(G5, T5) ; G5 = none ),
    check('a -s program that consults itself is the module it already is', G5, answer([1])),
    %% a consult INSIDE a module's load -- an `-s' file's initialization/1,
    %% run while the store is muted for that file -- is the program's: it
    %% owns its clauses, so the second consult replaces the first
    atom_concat(D, '/inmod.pl', IM), atom_concat(D, '/dm.pl', DM),
    fixture(DM, ['dm(1).']),
    fixture(IM, [':- initialization((consult(dm), consult(dm), findall(X, dm(X), L), write(answer(L)), nl)).',
                 'main.']),
    sh_join(['cd ', D, ' && ', C, ' -s inmod.pl 2>&1'], Cmd6),
    proc_run(Cmd6, 60000, Out6, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out6, T6) -> term_to_atom(G6, T6) ; G6 = none ),
    check('consult/1 inside a module''s load: the second replaces the first', G6, answer([1])).

%% IF(CHANGED) ASKS THE FILE'S TIME, TO THE NANOSECOND (2.12.2, 2.13.0): the
%% file's stamp moves a quarter of a second, inside one whole second, and
%% the file is read again -- with time_file/2's whole seconds of 2.12.1 it
%% would not have been. The same stamp reads nothing.
when_changed(D) :-
    section('load_files(F, [if(changed)]) reads a file again only when its time moved'),
    atom_concat(D, '/chg.pl', F), atom_concat(D, '/chgprog.pl', P),
    fixture(F, [':- ( nb_current(creads, N) -> M is N + 1 ; M = 1 ), nb_setval(creads, M).', 'cfact(1).']),
    shl(['touch -d 2026-10-28T12:00:00.25Z ', F]),
    sh_join(['touch -d 2026-10-28T12:00:00.50Z ', F], Touch),
    atomic_list_concat(['main :- step(A), step(B), proc_run(''', Touch,
                        ''', 10000, _, _), step(C), step(E),'], MainLine),
    fixture(P, [':- use_module(library(process)).',
                'step(N) :- load_files(''chg.pl'', [if(changed)]), nb_getval(creads, N).',
                MainLine,
                '    findall(X, cfact(X), L), write(answer([A, B, C, E]-L)), nl.']),
    cocolog(C),
    sh_join(['cd ', D, ' && ', C, ' -s chgprog.pl 2>&1'], Cmd),
    proc_run(Cmd, 60000, Out, _),
    ( re_first_atom('answer\\([^\n]*\\)', Out, T) -> term_to_atom(G1, T) ; G1 = none ),
    check('read, not again, again once its stamp moved a quarter second, then not', G1,
          answer([1, 1, 2, 2]-[1])).

%% WHAT WILL NOT LOAD (2.13.0), as swipl 9.0.4 has it: a missing file alone
%% raises; one in a list is reported on stderr and the next file loads; a
%% syntax error is reported and the goal succeeds. The consult ends at the
%% error, so the clause after it is not read -- where SWI reads it.
reports(D) :-
    section('what will not load: raised alone, reported in a list or for a syntax error'),
    atom_concat(D, '/nofile', NF), atom_concat(D, '/fine.pl', Fine), atom_concat(D, '/bad.pl', Bad),
    fixture(Fine, ['ffact(1).']),
    fixture(Bad, ['bfact(1).', 'broken( .', 'bfact(2).']),
    sh_join(['--local query "catch(consult(''', NF, '''), error(E, _), true), writeq(answer(E)), nl"'], A1),
    cocolog_answer(A1, G1),
    check('a missing file alone raises existence_error(source_sink, F)', G1,
          answer(existence_error(source_sink, NF))),
    sh_join(['--local query "consult([''', NF, ''', ''', Fine, ''']), findall(X, ffact(X), L), write(answer(L)), nl"'], A2),
    cocolog_out(A2, Out2),
    ( re_first_atom('answer\\([^\n]*\\)', Out2, T2) -> term_to_atom(G2, T2) ; G2 = none ),
    check('in a list, the next file loads', G2, answer([1])),
    ( re_first_atom('ERROR: [^\n]*', Out2, E2) -> true ; E2 = none ),
    format(atom(Want2), "ERROR: source_sink `~q' does not exist", [NF]),
    check('and the missing one is reported in SWI''s words', E2, Want2),
    sh_join(['--local query "consult(''', Bad, '''), findall(X, bfact(X), L), write(answer(L)), nl"'], A3),
    cocolog_out(A3, Out3),
    ( re_first_atom('answer\\([^\n]*\\)', Out3, T3) -> term_to_atom(G3, T3) ; G3 = none ),
    check('a syntax error: the goal succeeds with what came before it', G3, answer([1])),
    ( re_first_atom('ERROR: [^\n]*Syntax error[^\n]*', Out3, E3) -> R3 = reported ; R3 = silent ),
    check('and the error is reported', R3, reported).

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
