%% atom_length/2 and string_length/2, held to swipl 9.0.4 (cocolog 2.16.1,
%% 3.0.0).
%%
%% The text is an atom, a number, a string, or a list of codes or of
%% characters, and the length an integer or unbound. Through 2.16.0 a length
%% that was no integer FAILED where swipl raises type_error(integer, L), a
%% compound was written out and the writing counted (atom_length(f(x), N)
%% was 4), and a list was counted as written (atom_length([a,b], N) was 5).
%%
%% Each line is a case and what it did: yes(N) with the length, no, or
%% raised(F, P) with the error's formal and the predicate its context names,
%% system:atom_length/2 (through 2.16.1 cocolog left every core builtin's
%% context unbound, and the case printed the formal alone). `[]' is the empty
%% list, whose atom_length is 0; `'[]'', the atom, has two characters (they
%% were one atom through 2.16.1, and `[]' was no case).

len(Name, Goal, L) :-
    (   catch(Goal, E, true)
    ->  (   var(E) -> R = yes(L)
        ;   E = error(F, C)
        ->  ( nonvar(C), C = context(P, _) -> R = raised(F, P) ; R = raised(F) )
        ;   R = threw(E)
        )
    ;   R = no
    ),
    format("~w: ~q~n", [Name, R]).

%% a culprit that is a cyclic term, or holds a variable the two systems
%% name apart, is named by its error's type alone
cyc(Name, Goal) :-
    (   catch(Goal, error(type_error(T, _), _), true)
    ->  ( var(T) -> R = no_error ; R = raised(type_error(T)) )
    ;   R = no
    ),
    format("~w: ~q~n", [Name, R]).

%% how many answers, or the error's formal
all(Name, Goal) :-
    (   catch(findall(x, Goal, Xs), E, true)
    ->  ( var(E) -> length(Xs, K), R = yes(K) ; E = error(F, _) -> R = raised(F) ; R = threw(E) )
    ;   R = no
    ),
    format("~w: ~q~n", [Name, R]).

%% the text: an atom or a number as written, a compound refused, the first
%% argument asked before the second
texts :-
    len(atom, atom_length(abc, L1), L1),
    len(empty_atom, atom_length('', L2), L2),
    len(nil_atom, atom_length('[]', L3), L3),
    len(nil, atom_length([], L14), L14),
    len(integer, atom_length(123, L4), L4),
    len(negative, atom_length(-7, L5), L5),
    len(float, atom_length(1.5, L6), L6),
    len(big_float, atom_length(1.0e10, L7), L7),
    len(negative_zero, atom_length(-0.0, L8), L8),
    len(infinity, atom_length(1.0Inf, L9), L9),
    len(rational, atom_length(1r3, L10), L10),
    len(max_integer, atom_length(9223372036854775807, L11), L11),
    len(compound, atom_length(f(x), L12), L12),
    len(compound_bad_length, atom_length(f(x), foo), foo),
    len(compound_length, atom_length(f(x), 3), 3),
    len(compound_negative, atom_length(f(x), -1), -1),
    len(unbound, atom_length(_, 3), 3),
    len(unbound_both, atom_length(_, L13), L13),
    len(unbound_bad_length, atom_length(_, foo), foo).

%% the length: an integer compared, unbound bound, anything else refused
lengths :-
    len(given, atom_length(abc, 3), 3),
    len(wrong, atom_length(abc, 4), 4),
    len(negative_length, atom_length(abc, -1), -1),
    len(boxed_length, atom_length(abc, 9223372036854775807), 9223372036854775807),
    len(atom_length, atom_length(abc, foo), foo),
    len(float_length, atom_length(abc, 1.5), 1.5),
    len(whole_float_length, atom_length(abc, 3.0), 3.0),
    len(infinite_length, atom_length(abc, 1.0Inf), 1.0Inf),
    len(rational_length, atom_length(abc, 1r3), 1r3),
    len(compound_length2, atom_length(abc, f(x)), f(x)),
    len(nil_length, atom_length(abc, []), []).

%% a list: codes when its first element is an integer, characters when that
%% is a character, every element after held to the kind, the tail to []
lists :-
    len(chars, atom_length([a, b], L1), L1),
    len(codes, atom_length([0'a, 0'b], L2), L2),
    len(codes_given, atom_length([0'a, 0'b, 0'c], 3), 3),
    len(chars_wrong, atom_length([a, b, c], 4), 4),
    len(code_zero, atom_length([0], L3), L3),
    len(code_max, atom_length([1114111], L4), L4),
    len(code_past_max, atom_length([1114112], L5), L5),
    len(code_negative, atom_length([-1], L6), L6),
    len(code_float, atom_length([1.5], L7), L7),
    len(first_compound, atom_length([f(x)], L8), L8),
    len(first_long_atom, atom_length([ab], L9), L9),
    len(first_nil, atom_length([[]], L10), L10),
    len(codes_then_char, atom_length([0'a, b], L11), L11),
    len(codes_then_float, atom_length([0'a, 1.5], L12), L12),
    len(chars_then_code, atom_length([a, 0'b], L13), L13),
    len(chars_then_negative, atom_length([a, -1], L14), L14),
    len(chars_then_compound, atom_length([a, f(x)], L15), L15),
    len(chars_then_long_atom, atom_length([a, bc], L16), L16),
    len(partial_chars, atom_length([a|_], L17), L17),
    len(partial_codes, atom_length([0'a|_], L18), L18),
    len(unbound_first, atom_length([_], L19), L19),
    len(unbound_first_of_two, atom_length([_, a], L20), L20),
    len(unbound_char, atom_length([a, _], L21), L21),
    len(unbound_code, atom_length([0'a, _], L22), L22),
    len(improper, atom_length([a|b], L23), L23),
    len(improper_longer, atom_length([a, b|c], L24), L24),
    len(list_bad_length, atom_length([a, b], foo), foo),
    len(partial_bad_length, atom_length([a|_], foo), foo).

%% string_length/2 reads its text and its length the same way, [] the
%% empty list as swipl's is; a string is text to both
strings :-
    atom_string(ab, S),
    len(string_atom_length, atom_length(S, L1), L1),
    len(string_length, string_length(S, L2), L2),
    len(s_atom, string_length(abc, L3), L3),
    len(s_number, string_length(12, L4), L4),
    len(s_nil, string_length([], L5), L5),
    len(s_chars, string_length([a, b], L6), L6),
    len(s_codes, string_length([0'a, 0'b], L7), L7),
    len(s_atom_length, string_length(abc, foo), foo),
    len(s_float_length, string_length(abc, 1.5), 1.5),
    len(s_whole_float_length, string_length(abc, 3.0), 3.0),
    len(s_negative_length, string_length(abc, -1), -1),
    len(s_compound, string_length(f(x), L8), L8),
    len(s_compound_bad_length, string_length(f(x), foo), foo),
    len(s_unbound, string_length(_, 3), 3),
    len(s_codes_then_char, string_length([0'a, b], L9), L9),
    len(s_chars_then_code, string_length([a, 0'b], L10), L10),
    len(s_chars_then_compound, string_length([a, f(x)], L11), L11),
    len(s_improper, string_length([a|b], L12), L12),
    len(s_partial, string_length([a|_], L13), L13).

%% a list that is its own tail is no text
cycles :-
    L1 = [a|L1],
    cyc(cyclic_chars, atom_length(L1, _)),
    L2 = [0'a|L2],
    cyc(cyclic_codes, string_length(L2, _)).

%% the predicates that ask a length first refuse what is no text in their
%% own word, of the whole term: sub_atom/5 `atom', atom_concat/3 and
%% string_concat/3 `atomic', sub_string/5 `string'
built_on :-
    all(sub_atom, sub_atom(abc, _, _, _, _)),
    all(sub_atom_compound, sub_atom(f(x), 0, 1, _, _)),
    all(sub_atom_compound_sub, sub_atom(f(x), _, _, _, f)),
    all(sub_atom_bad_element, sub_atom([a, f(x)], 0, 1, _, _)),
    cyc(sub_atom_partial, sub_atom([a|_], 0, 1, _, _)),
    all(sub_atom_unbound, sub_atom(_, 0, 1, _, _)),
    all(sub_atom_bad_length, sub_atom(abc, _, foo, _, ab)),
    all(atom_concat, atom_concat(_, _, abc)),
    all(atom_concat_compound, atom_concat(_, _, f(x))),
    all(atom_concat_bad_element, atom_concat(_, _, [a, f(x)])),
    cyc(atom_concat_partial, atom_concat(_, _, [a|_])),
    all(string_concat, string_concat(_, _, abc)),
    all(string_concat_compound, string_concat(_, _, f(x))),
    cyc(string_concat_partial, string_concat(_, _, [a|_])),
    all(sub_string, sub_string(abc, _, _, _, _)),
    all(sub_string_compound, sub_string(f(x), 0, 1, _, _)),
    all(sub_string_compound_sub, sub_string(abc, _, _, _, f(x))),
    cyc(sub_string_partial, sub_string([a|_], 0, 1, _, _)).

main :-
    texts,
    lengths,
    lists,
    strings,
    cycles,
    built_on.
