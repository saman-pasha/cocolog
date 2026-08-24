:- set_prolog_flag(double_quotes, codes).
:- set_prolog_flag(verbose, silent).

named('$VAR') :- fail.
real_binding(Name=_) :- atom_concat('_', _, Name), !, fail.
real_binding(_=_).

show_solution([]) :- !, write(true).
show_solution(Bs) :-
    findall(S, (member(N=V, Bs), with_output_to(string(S), format("~w=~q", [N, V]))), Ss),
    atomic_list_concat(Ss, ',', Line),
    write(Line).

show([]) :- !.
show([S]) :- !, show_solution(S).
show([S|Rest]) :- show_solution(S), write(' ; '), show(Rest).

first_n(L, N, P) :- length(P, N), append(P, _, L), !.
first_n(L, _, L).

main :-
    current_prolog_flag(argv, [File, QAtom]),
    style_check(-singleton), style_check(-discontiguous),
    (   catch(consult(File), E1,
              (message_to_codes(E1, M1), format("ERROR: loading ~w: ~s~n", [File, M1]), halt))
    ->  true
    ;   format("ERROR: cannot load ~w~n", [File]), halt
    ),
    catch(( read_term_from_atom(QAtom, Goal, [variable_names(Vs0)]),
            include(real_binding, Vs0, Vs),
            findall(Vs, Goal, All)
          ),
          E2,
          (message_to_codes(E2, M2), format("ERROR: ~s~n", [M2]), halt)),
    ( All == [] -> writeln('no solutions')
    ; first_n(All, 10, Some), show(Some), nl ),
    halt.

message_to_codes(E, Codes) :-
    message_to_text(E, Text), atom_codes(Text, Codes).
message_to_text(error(existence_error(procedure, PI), _), Text) :- !,
    format(atom(Text), "unknown procedure ~w", [PI]).
message_to_text(E, Text) :- format(atom(Text), "~w", [E]).

:- initialization(main).
