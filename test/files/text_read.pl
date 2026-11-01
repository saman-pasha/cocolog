%% How the text builtins read their text, and what they raise -- held to
%% swipl 9.0.4 (cocolog 3.0.0).
%%
%% swipl reads a text argument with PL_get_text and a set of CVT_ flags
%% per predicate: some take any atomic text, some lists of codes or
%% characters too, none a compound, and a list is codes or characters by
%% its first element, every element after held to that kind. Its errors
%% name the predicate: context(system:Name/Arity, _). Through 2.16.1
%% cocolog wrote a compound out and read the writing (string_chars(f(x),
%% L) was "f(x)"), took a list of codes and characters mixed, took a code
%% list where swipl takes only atomic text (string_concat/3, sub_atom/5),
%% left every core builtin's context unbound, and had `[]' and `'[]''
%% as one atom.
%%
%% Each line is a goal and what it did: yes(Goal) with its bindings, no,
%% or raised(Formal, Predicate) -- the error and the predicate its
%% context names. A variable left in either is written `_'.

:- set_prolog_flag(double_quotes, codes).

r(Name, Goal) :-
    copy_term(Goal, G),
    (   catch(G, E, true)
    ->  (   var(E) -> R = yes(G)
        ;   E = error(F, C)
        ->  ( nonvar(C), C = context(P, _) -> R = raised(F, P) ; R = raised(F, C) )
        ;   R = threw(E)
        )
    ;   R = no
    ),
    term_variables(R, Vs), maplist(=('$VAR'('_')), Vs),
    format("~w: ", [Name]), print(R), nl.

%% the texts each builtin is given: a compound, lists that mix codes and
%% characters, a list of codes and one of characters (which the four that
%% take only atomic text refuse), lists with a compound in them, the list's
%% end and the atom of its name, numbers, partial and improper lists, and an
%% atom
texts([f(x), [a, 0'b], [0'a, b], [0'a, 0'b], [a, b], [a, f(x)], [0'a, f(x)],
       [], '[]', 12, 1.5, [a|_], [0'a|_], [a|b], abc]).

%% every text builtin over every text, in each argument it reads
builtins :-
    atom_string(ab, S), atom_string(' ', Sp),
    texts(Ts),
    forall(nth1(I, Ts, T), probe(I, T, S, Sp)).

probe(I, T, S, Sp) :-
    atom_concat(t, I, P),
    p(P, string_chars, string_chars(T, _)),
    p(P, string_codes, string_codes(T, _)),
    p(P, string_to_atom, string_to_atom(T, _)),
    p(P, string_to_atom2, string_to_atom(_, T)),
    p(P, string_code, string_code(1, T, _)),
    p(P, atom_string, atom_string(T, _)),
    p(P, atom_string2, atom_string(_, T)),
    p(P, string_length, string_length(T, _)),
    p(P, split1, split_string(T, Sp, Sp, _)),
    p(P, split2, split_string(S, T, Sp, _)),
    p(P, split3, split_string(S, Sp, T, _)),
    p(P, upcase_atom, upcase_atom(T, _)),
    p(P, downcase_atom, downcase_atom(T, _)),
    p(P, string_upper, string_upper(T, _)),
    p(P, string_lower, string_lower(T, _)),
    p(P, atomic_list_concat2, atomic_list_concat([a, T], _)),
    p(P, atomic_list_concat3, atomic_list_concat([a, T], '-', _)),
    p(P, atomic_list_concat_sep, atomic_list_concat([a, b], T, _)),
    p(P, atomic_list_concat_split, atomic_list_concat(_, '-', T)),
    p(P, atomics_to_string, atomics_to_string([a, T], _)),
    p(P, text_to_string, text_to_string(T, _)),
    p(P, term_to_atom, term_to_atom(_, T)),
    p(P, term_string, term_string(_, T)),
    p(P, atom_to_term, atom_to_term(T, _, _)),
    p(P, read_term_from_atom, read_term_from_atom(T, _, [])),
    p(P, atom_number, atom_number(T, _)),
    p(P, number_string, number_string(_, T)),
    p(P, number_codes, number_codes(_, T)),
    p(P, atom_codes, atom_codes(_, T)),
    p(P, atom_chars, atom_chars(_, T)),
    p(P, char_code, char_code(T, _)),
    p(P, string_bytes, string_bytes(T, _, utf8)),
    p(P, sub_atom, sub_atom(T, 0, 1, _, _)),
    p(P, sub_string, sub_string(T, 0, 1, _, _)),
    p(P, string_concat, string_concat(T, a, _)),
    p(P, atom_concat, atom_concat(T, a, _)),
    p(P, string, string(T)),
    p(P, number_codes2, number_codes(T, _)),
    p(P, char_type, char_type(T, alpha)),
    p(P, code_type, code_type(T, alpha)),
    p(P, get_string_code, get_string_code(1, T, _)),
    ( ground(T) -> p(P, term_string2, term_string(T, _)) ; true ),
    p(P, format_atom, format(atom(_), T, [])).

p(P, Q, G) :- atom_concat(P, '_', P1), atom_concat(P1, Q, N), r(N, G).

%% A LIST THAT DOES NOT UNIFY FAILS, OR IS READ: a bound first argument's
%% text is unified with the list, and a list that does not unify fails
%% where an unbound element or tail comes before anything wrong with it
%% (swipl's CVT_VARNOFAIL) and is otherwise read, and raises for what is
%% wrong. Through 2.16.1 it failed whatever it held.
lists :-
    r(codes_one_unbound, atom_codes(casa, [_])),
    r(codes_prefix, atom_codes(casa, [0'c|_])),
    r(codes_wrong_prefix, atom_codes(casa, [0'x|_])),
    r(codes_compound_first, atom_codes(abc, [f(x), _])),
    r(codes_compound_after_unbound, atom_codes(abc, [_, f(x)])),
    r(codes_compound_second, atom_codes(abc, [0'a, f(x)])),
    r(codes_as_chars, atom_codes(abc, [a, b, c])),
    r(codes_chars_unbound, atom_codes(abc, [a, _, c])),
    r(codes_chars_unbound_wrong, atom_codes(abc, [a, _, z])),
    r(codes_chars_wrong, atom_codes(abc, [a, b, z])),
    r(codes_chars_then_code, atom_codes(abc, [a, 0'b, c])),
    r(codes_code_then_char, atom_codes(abc, [0'a, b, c])),
    r(codes_improper, atom_codes(abc, [a, b|z])),
    r(codes_partial, atom_codes(abc, [a, b|_])),
    r(codes_atom, atom_codes(abc, foo)),
    r(codes_negative, atom_codes(abc, [0'a, -1])),
    r(codes_longer, atom_codes(abc, [0'a, 0'b, 0'c, 0'd])),
    r(chars_one_unbound, atom_chars(abc, [_])),
    r(chars_long_first, atom_chars(abc, [ab, _])),
    r(chars_long_second, atom_chars(abc, [a, ab])),
    r(chars_as_codes, atom_chars(abc, "abc")),
    r(chars_number, atom_chars(12, "12")),
    r(chars_code_prefix, atom_chars(abc, [0'a|_])),
    r(number_partial, number_codes(12, [0'1, _])),
    r(number_one_unbound, number_codes(12, [_])),
    r(number_wrong_prefix, number_codes(12, [0'1, 0'3|_])),
    r(number_other_prefix, number_codes(12, [0'2, 0'1|_])),
    r(number_layout, number_codes(12, " 12")),
    r(number_compound, number_codes(12, [f(x)])),
    r(number_compound_second, number_codes(12, [0'1, f(x)])),
    r(number_unbound_partial, number_codes(_, [0'1|_])),
    r(number_unbound_element, number_codes(_, [0'1, _])),
    r(number_chars_unbound, number_chars(12, [_, _, _])),
    r(number_chars_partial, number_chars(12, ['1', _])),
    r(number_string_unbound, number_string(12, [_])),
    r(number_string_wrong, number_string(12, "13")),
    r(number_string_layout, number_string(12, " 12")),
    r(atom_unbound_partial, atom_codes(_, [0'a|_])),
    r(atom_unbound_element, atom_codes(_, [0'a, _])).

%% THE LIST'S END IS NO ATOM, AND `'[]'' IS NOT IT: two terms, the one
%% read from `[]', the other from `'[]'' and made from the text "[]"
nil :-
    r(atom_nil, atom([])),
    r(atom_nil_atom, atom('[]')),
    r(atomic_nil, atomic([])),
    r(callable_nil, callable([])),
    r(nil_is_not_its_atom, [] == '[]'),
    r(compare_nil_atom, compare(_, [], '[]')),
    r(compare_nil_a, compare(_, [], a)),
    r(compare_nil_number, compare(_, [], 1)),
    r(msort, msort(['[]', [], a, 1, f(x)], _)),
    r(length_nil, atom_length([], _)),
    r(length_nil_atom, atom_length('[]', _)),
    r(codes_nil, atom_codes([], _)),
    r(codes_nil_atom, atom_codes('[]', _)),
    r(atom_from_text, (atom_codes(A1, "[]"), A1 == '[]')),
    r(term_to_atom_nil, term_to_atom([], _)),
    r(term_to_atom_nil_atom, term_to_atom('[]', _)),
    r(term_from_text, (term_to_atom(T1, '[]'), T1 == [])),
    r(term_from_quoted_text, (term_to_atom(T2, '\'[]\''), T2 == '[]')),
    r(written_nil, format(atom(_), "~w ~q ~a", [[], [], '[]'])),
    r(written_nil_atom, format(atom(_), "~w ~q", ['[]', '[]'])),
    r(written_compound, format(atom(_), "~q ~q", ['[]'(a), f([], '[]')])),
    r(string_of_nil, atom_string([], _)),
    r(string_concat_nil, string_concat([], a, _)),
    r(atom_concat_nil, atom_concat([], a, _)),
    r(upcase_nil, upcase_atom([], _)),
    r(univ_nil, [] =.. _),
    r(functor_nil, functor([], _, _)),
    r(atom_number_nil, atom_number('[]', _)),
    r(atom_to_term_nil, (atom_to_term('[]', T3, _), T3 == [])),
    r(char_code_open, char_code(_, 91)).

main :-
    builtins,
    lists,
    nil.
