%% argv: the engine flag, and library(main) over it.
%%
%% TWO HALVES, AND THE FIRST IS THE ONE THAT COULD NOT BE FAKED.
%% `current_prolog_flag(argv, V)' is answered by lib/library.cicili out of
%% main()'s own argv, and the rule is that `--' ends cocolog's arguments and
%% everything after belongs to the program. There has to be a separator
%% because `run FILE GOAL' reads the LAST argument as the goal: without one,
%% `run p.pl main --check' would try to prove `--check'. So the cases below
%% check what a program REACHES, never what the parser did.
%%
%% The second half is library/main.pl, whose guided parsing tutorial 38
%% covers. What is here and not there is UNGUIDED parsing -- the mode a
%% program gets when it defines no opt_type/3 -- which a lesson that defines
%% one cannot demonstrate from inside itself.
%%
%%     cocolog -s test/argv.pl        from the checkout root
%%
%% Every check IS a child, since what is pinned is a command line.

:- use_module('test/prelude.pl').

main :-
    scratch(D),
    the_flag(D), unguided(D), main0(D), a_tool(D), dash_s(D),
    shl(['rm -rf ', D]),
    checks_done.

%% `cocolog --local run FILE GOAL ...', both streams, as text
ran(Args, Got) :- sh_join(['--local run ', Args, ' 2>&1'], A), cocolog_run(A, Got, _).

the_flag(D) :-
    section('the flag'),
    atom_concat(D, '/av.pl', F),
    fixture(F,
            [ 'show :- current_prolog_flag(argv, [_Exe|A]), write(A), nl.',
              'os   :- current_prolog_flag(os_argv, V), length(V, N), write(N), nl.',
              'head :- current_prolog_flag(argv, [E|_]),',
              '        current_prolog_flag(executable, E2),',
              '        ( E == E2 -> write(same) ; write(differ) ), nl.' ]),
    sh_join([F, ' show -- --check --fix file.pl'], A1), ran(A1, G1),
    check('the tail after -- reaches the program', G1, '[--check,--fix,file.pl]'),
    sh_join([F, ' show'], A2), ran(A2, G2),
    check('no -- means an empty tail', G2, '[]'),
    sh_join([F, ' show --'], A3), ran(A3, G3),
    check('-- with nothing after it is also empty', G3, '[]'),
    %% THE ONE THAT MATTERS: an argument that reads as a cocolog option must
    %% NOT be eaten by cocolog's own option loop. If this fails, --embed would
    %% open a store the program meant to name as a file.
    sh_join([F, ' show -- --local --embed /nope --kb x'], A4), ran(A4, G4),
    check('cocolog''s own options pass through untouched', G4, '[--local,--embed,/nope,--kb,x]'),
    %% and a goal-shaped argument does not become the goal
    sh_join([F, ' show -- os'], A5), ran(A5, G5),
    check('an argument is not mistaken for the goal', G5, '[os]'),
    sh_join([F, ' head'], A6), ran(A6, G6),
    check('argv''s head is the executable flag', G6, same),
    %% os_argv is the LITERAL line: cocolog --local run FILE os -- a b  = 8
    sh_join([F, ' os -- a b'], A7), ran(A7, G7),
    check('os_argv is the whole command line', G7, '8').

unguided(D) :-
    section('library(main), unguided'),
    %% NO opt_type/3 IN THIS FILE, which is the whole point of it: tutorial
    %% 38 defines one and so can never reach this branch.
    atom_concat(D, '/ug.pl', F),
    fixture(F,
            [ ':- use_module(library(main)).',
              'main(Argv) :- argv_options(Argv, P, O), msort(O, S), write(P-S), nl.' ]),
    sh_join([F, ' main -- --name=value --count 7 --flag --no-colour f.pl'], A), ran(A, G),
    check('unguided: --name=value, --name value, --flag, --no-x', G,
          '[f.pl]-[colour(false),count(7),flag(true),name(value)]').

main0(D) :-
    section('main/0 is the library''s, main/1 is yours'),
    atom_concat(D, '/m0.pl', F),
    fixture(F, [':- use_module(library(main)).', 'main(Argv) :- write(Argv), nl.']),
    sh_join([F, ' main -- one two'], A), ran(A, G),
    check('main/0 hands main/1 the tail, not the executable', G, '[one,two]').

a_tool(D) :-
    section('a program that ACTS on its arguments'),
    %% END TO END, because everything above could pass over a flag nothing
    %% uses. This one counts its positional files and honours -n, which is
    %% what a real tool does with argv_options/3.
    atom_concat(D, '/tool.pl', F),
    fixture(F,
            [ ':- use_module(library(main)).',
              'opt_type(n, count, integer).',
              'opt_type(count, count, integer).',
              'opt_type(v, verbose, boolean).',
              'main(Argv) :-',
              '    argv_options(Argv, Files, Opts),',
              '    ( memberchk(count(N), Opts) -> true ; N = 1 ),',
              '    ( memberchk(verbose(true), Opts) -> V = loud ; V = quiet ),',
              '    length(Files, F),',
              '    format("~w files, n=~w, ~w~n", [F, N, V]).' ]),
    sh_join([F, ' main -- -v -n 5 a.pl b.pl c.pl'], A1), ran(A1, G1),
    check('a real tool reads its own command line', G1, '3 files, n=5, loud'),
    sh_join([F, ' main --'], A2), ran(A2, G2),
    check('and its defaults are the program''s, not invented', G2, '0 files, n=1, quiet').

dash_s(D) :-
    section('`-s'' is the form to use, and here is why'),
    %% `-s FILE' IS `use_module(FILE), main' AND `run FILE main' IS A
    %% CONSULT, and the difference is not brevity: consulting WRITES THROUGH.
    %% A tool run with `run' against a real knowledge base leaves its own
    %% source in the database. This is the case that says so, and it needs a
    %% store to say it -- --embed, so no server is required.
    %%
    %% It is also why `-s' is the right form for library(main) in particular:
    %% loading the file as a module puts the LIBRARY's main/0 ahead of the
    %% file's own clauses, which is the one that strips the executable and
    %% calls main/1.
    atom_concat(D, '/tool.pl', Tool),
    sh_join(['-s ', Tool, ' -- -v -n 5 a.pl b.pl c.pl 2>&1'], A1), cocolog_run(A1, G1, _),
    check('-s runs a program and gives it argv', G1, '3 files, n=5, loud'),
    atom_concat(D, '/kb', KB),
    atom_concat(D, '/priv.pl', Priv),
    fixture(Priv, ['tool_private_fact(1).', 'main :- write(ran), nl.']),
    sh_join(['--embed ', KB, ' -s ', Priv, ' >/dev/null 2>&1'], A2), cocolog_run(A2, _, _),
    stored(KB, S2),
    check('-s leaves the program''s clauses OUT of the store', S2, absent),
    sh_join(['--embed ', KB, ' run ', Priv, ' main >/dev/null 2>&1'], A3), cocolog_run(A3, _, _),
    stored(KB, S3),
    check('and run CONSULTS, so the same clauses land in it', S3, stored).

%% whether the private fact is in the store: `query' exits 0 when it proved
stored(KB, S) :-
    sh_join(['--embed ', KB, ' query "tool_private_fact(_)" >/dev/null 2>&1'], A),
    cocolog_run(A, _, Rc),
    ( Rc =:= 0 -> S = stored ; S = absent ).
