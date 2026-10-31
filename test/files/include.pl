%% include/1, as swipl 9.0.4 has it (cocolog 3.5.0): the file is looked for
%% where a load looks -- beside the file that names it first -- and read
%% where the directive stands. Its clauses are the including file's, and a
%% reconsult replaces them; its directives, source_location/2 and its
%% initialization goals name its own places, the goals run after the whole
%% load; a spec that names nothing it can read ends the load, swipl's ball
%% raised out of consult/1. The sandbox holds the fixtures (test/files.pl's
%% fixtures(include, _)): this file is in test/files, the working directory
%% is the sandbox.

yes_no(G) :- ( catch(G, _, fail) -> format("~w yes~n", [G]) ; format("~w no~n", [G]) ).

%% one file that ends its load at an include: the ball, and what was read
%% before it
err(N) :-
    atom_concat(e, N, F), atom_concat(r, N, R),
    format("== ~w~n", [F]),
    (   catch(consult(F), E, (print_message(error, E), writeln(caught)))
    ->  true
    ;   writeln(failed)
    ),
    G =.. [R, X], findall(X, catch(G, _, fail), L), writeln(r(L)).

main :-
    %% beside the file that names it, then beside that one, in file order
    consult('sub/m'),
    findall(X, p(X), L), writeln(p(L)),
    findall(Y, q(Y), M), writeln(q(M)),
    yes_no(wrong_a),
    yes_no(skipped),
    %% read again, the included clauses are replaced with the file's own,
    %% and a predicate only the included files define stays defined
    consult('sub/m'),
    findall(X2, p(X2), L2), writeln(again(L2)),
    findall(Y2, q(Y2), M2), writeln(again_q(M2)),
    %% what names nothing it can read: no file, a variable, a list of
    %% files, a directory, a number, `[]', a list of characters
    forall(member(N, [1, 2, 3, 5, 6, 7, 8]), err(N)),
    yes_no(x1),
    yes_no(x2),
    %% a directive, never a goal: as one it is an unknown procedure
    catch(include(sub/x1), error(F, _), true),
    print(F), nl.
