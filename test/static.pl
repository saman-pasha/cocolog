%% tools/compile/static.pl -- the count DESIGN-compiling.md §7 cites, held
%% to a corpus small enough to count by hand.
%%
%% Two files. The first has each thing the count tells apart, once: a
%% predicate declared dynamic and retracted by name, a fact asserted by
%% name that no file defines, a closure, a meta-predicate only the
%% fixpoint finds (r/1 calls its argument; s/0 hands it q), a goal built
%% at run time, two grammar rules and a call through phrase/2, facts whose
%% `true' is no call, and a predicate nothing reaches. The second asserts
%% a clause it is handed, so every predicate of its file is one a compiler
%% could not call fixed, and it has no root, so each is its own.
%%
%%     cocolog -s test/static.pl        from the checkout root
%%
%% The tool runs as a child, the way it is run: consulted here, its clauses
%% and the facts it asserts would join this case's.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    atom_concat(D, '/a.pl', A),
    fixture(A, [ ':- dynamic kept/1.',
                 'kept(0).',
                 'p(X) :- q(X), seen(X).',
                 'q(1).',
                 'q(2).',
                 'r(G) :- call(G, 1).',
                 's :- r(q).',
                 't(N) :- G =.. [N, 1], call(G).',
                 'u --> [a], v.',
                 'v --> [].',
                 'w :- assertz(seen(1)), retract(kept(_)).',
                 'lone :- q(_).',
                 'main :- p(_), s, t(q), phrase(u, [a]), w.' ]),
    atom_concat(D, '/b.pl', B),
    fixture(B, [ 'x(C) :- assertz(C).',
                 'y.' ]),
    sh_join(['--local run tools/cocolint/blocklist.pl tools/compile/static.pl sf_main -- ', D], Args),
    cocolog_out(Args, O),
    atom_codes(T, O),
    atomic_list_concat(Ls, '\n', T),
    section('what a compiler may take: clauses nothing changes'),
    line_in(Ls, '   fixed while it runs: 10 predicates (76.9 %), 11 clauses (78.6 %)', G1),
    check('the declared one and the file that asserts what it is handed are not fixed', G1, yes),
    line_in(Ls, '   fixed if an unnamed change reaches only data: 12 predicates (92.3 %)', G2),
    check('and read as data, the handed clause leaves only the declared one', G2, yes),
    line_in(Ls, '   changed by name: 1 predicates (1 declared dynamic)', G3),
    check('a fact asserted by name and defined nowhere is no predicate of the file', G3, yes),
    line_in(Ls, '   in a file that changes what it cannot name, or consults: 2 predicates in 1 files', G4),
    check('an unnamed assert marks its whole file', G4, yes),
    atom_concat(D, '/a.pl [seen/1]', W5), atom_concat('   ', W5, L5),
    line_in(Ls, L5, G5),
    check('and the head changed and not defined is named', G5, yes),
    section('what calls what'),
    line_in(Ls, '   calls: 19 -- local 10 (52.6 %) builtin 5 (26.3 %) library 1 (5.3 %) asserted 1 (5.3 %) closure 1 (5.3 %) computed 1 (5.3 %) unresolved 0 (0.0 %)', G6),
    check('each kind once: the fixpoint''s q/1, the grammar bodies, phrase/2''s u/2, no fact''s true', G6, yes),
    line_in(Ls, '   reached from the roots by literal calls: 11 (84.6 %), fixed 9 (81.8 %)', G7),
    check('main/0 reaches all but lone/0 and kept/1, and a file with no root is all roots', G7, yes),
    line_in(Ls, '   files with no root (every predicate one): 1', G8),
    check('the file with no root is counted', G8, yes),
    checks_done.

%% yes, or the lines that begin as the wanted one does
line_in(Ls, L, yes) :- memberchk(L, Ls), !.
line_in(Ls, L, no(Near)) :-
    sub_atom(L, 0, 10, _, P),
    findall(X, ( member(X, Ls), sub_atom(X, 0, 10, _, P) ), Near).
