%  op/3 of an operator name of any length, as swipl's: through 3.34.0
%  cocolog's table held a name in 64 bytes, and op/3 of a longer one --
%  64 letters, or 32 of U+00E9 -- raised cocolog_error('that operator name will
%  not fit'), as a goal and as a directive alike.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  A DIRECTIVE first: a declaration takes effect for the rest of the file,
%  so the clause after it is read with this one in force (70 letters).
:- op(700, xfx, dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd).

d_rule(x dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd y).

%  a name of N copies of the character code C
long(N, C, A) :- length(L, N), maplist(=(C), L), atom_codes(A, L).

%  a line: the label, then what the goal answered or raised
s(Label, Goal, Out) :-
    write(Label), write(': '),
    (   catch(Goal, error(E, _), (print(caught(E)), nl, fail))
    ->  print(Out), nl
    ;   true
    ).

%  the writer's text of T: its length, and the codes of its last characters
w(Label, T) :-
    with_output_to(string(S), writeq(T)),
    string_length(S, N), sub_string(S, _, 6, 0, End), string_codes(End, Cs),
    write(Label), write(': '), print(N-Cs), nl.

main :-
    long(64, 0'a, A64), long(200, 0'b, B200), long(5000, 0'c, C5k),
    long(40, 233, E40),
    %  ---- a goal, each kind ----
    s(infix_64, ( op(700, xfx, A64), current_op(P1, T1, A64) ), P1-T1),
    s(prefix_200, ( op(200, fy, B200), current_op(P2, T2, B200) ), P2-T2),
    s(list_5000, ( op(500, yfx, [short_one, C5k]), current_op(P3, T3, C5k) ), P3-T3),
    s(list_short, current_op(P4, T4, short_one), P4-T4),
    s(utf8_40, ( op(700, xfx, E40), current_op(P5, T5, E40) ), P5-T5),
    %  ---- the writer writes them as operators ----
    X1 =.. [A64, 1, 2], w(write_64, X1),
    X2 =.. [B200, z], w(write_200, X2),
    X3 =.. [C5k, p, q], w(write_5000, X3),
    %  (and the name of 40 U+00E9, bare and spaced as a name since 3.35.0)
    X4 =.. [E40, 1, 2], w(write_utf8, X4),
    %  ---- and the reader reads them ----
    atomic_list_concat([u, A64, v], ' ', R1),
    s(read_64, ( term_to_atom(Y1, R1), Y1 =.. [F1|As1], atom_length(F1, N1) ), N1-As1),
    atomic_list_concat([B200, w], ' ', R2),
    s(read_200, ( term_to_atom(Y2, R2), Y2 =.. [F2|As2], atom_length(F2, N2) ), N2-As2),
    atomic_list_concat([m, C5k, n, C5k, o], ' ', R3),
    s(read_5000, ( term_to_atom(Y3, R3), Y3 =.. [_, L3, _], L3 =.. [_|As3] ), As3),
    atomic_list_concat([g, E40, h], ' ', R4),
    s(read_utf8, ( term_to_atom(Y4, R4), Y4 =.. [F4|As4], atom_length(F4, N4) ), N4-As4),
    %  ---- the directive's, and the clause read with it ----
    long(70, 0'd, D70),
    s(directive_70, current_op(P6, T6, D70), P6-T6),
    s(directive_clause, ( d_rule(Z6), Z6 =.. [F6|As6], atom_length(F6, N6) ), N6-As6),
    %  ---- taken away again ----
    op(0, xfx, A64),
    s(gone_64, ( current_op(_, xfx, A64) -> G = still ; G = gone ), G),
    s(gone_read, ( catch(term_to_atom(_, R1), error(syntax_error(Why), _), true), nonvar(Why) ), syntax_error(Why)),
    %  ---- and what op/3 refuses of a long name is what it refuses of any ----
    long(64, 0'z, Z64),
    s(bad_type, op(700, xxx, Z64), none),
    s(bad_priority, op(1201, xfx, Z64), none),
    s(not_atom, op(700, xfx, f(Z64)), none).
