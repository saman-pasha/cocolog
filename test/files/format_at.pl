%  format/2's `~@' -- its argument called once, its output put in where the
%  directive stands -- and the text a format put out before it went wrong,
%  which reaches every stream sink and no term sink.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

%  each case's name on a line of its own, then the format and a bar after
%  it; a ball is printed, an error its formal and its context's indicator
f(N, F, A) :-
    writeln(N),
    (   catch(format(F, A), B, (said(B, S), write(S)))
    ->  true
    ;   write(failed)
    ),
    write('|'), nl.
%  into an atom
s(N, F, A) :-
    (   catch(format(atom(X), F, A), B, said(B, X))
    ->  true
    ;   X = failed
    ),
    print(N-X), nl.
% cocolint: C2 -- the context printed, of errors both systems name; the next clause takes the rest
said(error(E, context(P, _)), caught(E, P)) :- nonvar(P), !.
said(error(E, _), caught(E)) :- !.
said(B, ball(B)).

g(X) :- write(X).

main :-
    goals, columns, failures, errors, sinks, partial.

goals :-
    f(plain, "~@", [write(hello)]),
    f(between_text, "a~@b", [write(x)]),
    f(two, "~@~@", [write(a), write(b)]),
    f(once, "~@", [(member(X, [a, b]), write(X))]),
    %  the choice point the goal left is cut while its output is captured
    f(cleanup, "<~@>", [setup_call_cleanup(true, member(_, [a, b]), write(c))]),
    f(nested, "<~@>", [format("~w-~w", [p, q])]),
    f(nested_at, "~@", [format("<~@>", [write(in)])]),
    f(nothing, "[~@]", [true]),
    f(module_pred, "~@", [g(mod)]),
    f(print, "~@", [print(f('A'))]),
    f(writeq, "~@", [writeq('a b')]),
    (   format(atom(_), "~@", [Y = 1]), var(Y)
    ->  writeln(bindings_undone)
    ;   writeln(bindings_kept)
    ),
    (   format(atom(_), "~@~w", [Z = 1, Z]), true
    ->  writeln(next_argument_unbound)
    ;   writeln(next_argument_bound)
    ).

columns :-
    f(left, "~@~t~10|x", [write(abc)]),
    f(right, "~t~@~10|x", [write(abc)]),
    f(center, "~t~@~t~11|x", [write(abc)]),
    f(newline_in, "~@~Nz", [(write(ab), nl)]),
    f(col_after_nl, "~@~t~6|z", [(write(ab), nl, write(c))]),
    f(tab_in, "~@~t~12|z", [write('a\tb')]),
    f(tab_before, "\t~@~t~20|z", [write('x\ty')]),
    f(after_writers, "~w~w~@~t~12|z", [a, 'b\tc', write(d)]),
    s(atom_plain, "~@", [write(hi)]),
    s(atom_cols, "~w~t~@~8|~w", [a, write(b), c]).

failures :-
    f(fails, "x~@y", [fail]),
    f(fails_after_text, "x~@y", [(write(abc), fail)]),
    f(fails_held, "x~t~@~10|y", [(write(abc), fail)]),
    f(fails_after_tab, "\t~@y", [(write(abc), fail)]),
    f(throws, "x~@y", [throw(oops)]),
    f(throws_after_text, "x~@y", [(write(abc), throw(oops))]),
    f(throws_held, "x~t~@~10|y", [(write(abc), throw(oops))]),
    f(throws_error, "x~@y", [atom_length(_, _)]),
    s(atom_fails, "x~@y", [fail]),
    s(atom_throws, "x~@y", [(write(abc), throw(oops))]).

errors :-
    f(not_enough, "~@", []),
    f(unbound, "x~@y", [_]),
    f(number, "x~@y", [1]),
    f(unknown, "x~@y", [no_such_pred_zz]),
    f(unknown_args, "x~@y", [no_such_pred_zz(1)]),
    f(bad_inner_format, "x~@y", [format("~q", [])]).

sinks :-
    with_output_to(string(S1), format("~@", [write(z)])), print(S1), nl,
    format(atom(A2), "~@", [(with_output_to(string(S2), write(inner)), write(S2))]), print(A2), nl,
    format(string(S3), "<~@>", [write(s)]), print(S3), nl,
    %  with_output_to/2 keeps its goal's bindings, where `~@' undoes them
    with_output_to(string(S5), (X5 = 1, write(X5))), print(S5-X5), nl,
    format(codes(C4), "<~@>", [write(c)]), atom_codes(A4, C4), print(A4), nl,
    current_output(O), format(O, "<~@>~n", [write(o)]),
    format(user_output, "<~@>~n", [write(u)]),
    open('fa.txt', write, W),
    format(W, "<~@>~n", [write(w)]),
    close(W),
    open('fa.txt', read, R), read_chars(R, Cs), close(R),
    atom_chars(Back, Cs), print(Back), nl.

%  the text before an error or a failure: to every stream, to no term
partial :-
    catch(format("a1 ~w ~w", [one]), error(E1, _), true), write('|'), print(E1), nl,
    catch(format(user_output, "a2 ~w ~w", [one]), error(E2, _), true), write('|'), print(E2), nl,
    current_output(O),
    catch(format(O, "a3 ~w ~w", [one]), error(E3, _), true), write('|'), print(E3), nl,
    open('fp.txt', write, W),
    catch(format(W, "a4 ~w ~w", [one]), error(E4, _), true),
    ( format(W, "b4 ~@ ~w", [fail, x]) -> true ; true ),
    close(W),
    open('fp.txt', read, R), read_chars(R, Cs), close(R),
    atom_chars(T, Cs), print(T-E4), nl,
    catch(format(atom(A), "a5 ~w ~w", [one]), error(E5, _), true),
    ( var(A) -> print(unbound-E5) ; print(A-E5) ), nl,
    %  a term that will not take the text is no reason not to raise
    (   catch(format(atom(nope), "a9 ~w ~w", [one]), error(E9, _), true)
    ->  print(raised(E9))
    ;   print(failed)
    ),
    nl,
    flush_output,
    catch(format(user_error, "a6 ~w ~w", [one]), error(E6, _), true),
    print(E6), nl,
    ( format("a7 ~@ ~w", [fail, x]) -> true ; write('|failed') ), nl,
    catch(format("a8 ~@ ~w", [throw(oops), x]), B8, true), write('|'), print(B8), nl.

read_chars(R, Cs) :-
    get_char(R, C),
    (   C == end_of_file
    ->  Cs = []
    ;   Cs = [C|T], read_chars(R, T)
    ).
