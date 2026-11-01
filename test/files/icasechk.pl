%  sub_atom_icasechk/3, run by BOTH SWI-Prolog and cocolog and the output
%  compared byte for byte: the needle at Start, or at the first place it
%  is when Start is unbound, a character of the needle matching one of the
%  haystack that is it or whose lowercase it is -- a fold one way only, so
%  an uppercase needle finds no lowercase haystack. Any text reads as text
%  (an atom, a string, a number, codes, characters), and the errors are
%  swipl's, Start's checked first. ASCII only: past it the lowercase is
%  the locale's.

r(Label, Goal, Show) :-
    catch(( Goal -> R = Show ; R = no ), E, R = ex(E)),
    copy_term(Label-R, C), term_variables(C, Vs), bindv(Vs), print(C), nl.
bindv([]).
bindv([v|Vs]) :- bindv(Vs).

main :- found, folded, texts, refused.

found :-
    r(first, sub_atom_icasechk(hello, S1, l), S1),
    r(at_start, sub_atom_icasechk(hello, S2, hel), S2),
    r(at_end, sub_atom_icasechk(hello, S3, llo), S3),
    r(whole, sub_atom_icasechk(hello, S4, hello), S4),
    r(longer, sub_atom_icasechk(hel, _, hello), yes),
    r(absent, sub_atom_icasechk(hello, _, z), yes),
    r(empty_needle, sub_atom_icasechk(hello, S5, ''), S5),
    r(empty_both, sub_atom_icasechk('', S6, ''), S6),
    r(empty_haystack, sub_atom_icasechk('', _, a), yes),
    r(bound_yes, sub_atom_icasechk(hello, 2, l), yes),
    r(bound_second, sub_atom_icasechk(hello, 3, l), yes),
    r(bound_no, sub_atom_icasechk(hello, 1, l), yes),
    r(bound_end_empty, sub_atom_icasechk(hello, 5, ''), yes),
    r(bound_past_end, sub_atom_icasechk(hello, 6, ''), yes),
    r(bound_past, sub_atom_icasechk(hello, 9, l), yes),
    r(once_only, findall(S7, sub_atom_icasechk(abab, S7, b), L7), L7).

folded :-
    r(upper_haystack, sub_atom_icasechk('HELLO', S1, ell), S1),
    r(upper_both, sub_atom_icasechk('HELLO', S2, 'ELL'), S2),
    r(upper_needle, sub_atom_icasechk(hello, _, 'ELL'), yes),
    r(mixed, sub_atom_icasechk('HeLLo WoRLD', S3, 'world'), S3),
    r(mixed_needle, sub_atom_icasechk('HeLLo', S4, 'LLo'), S4),
    r(mixed_needle_no, sub_atom_icasechk('HeLlo', _, 'LLo'), yes),
    r(digits, sub_atom_icasechk('A1B2', S5, b2), S5),
    r(punct, sub_atom_icasechk('X-Y', S6, '-y'), S6).

texts :-
    r(string_haystack, sub_atom_icasechk("Hello", S1, ell), S1),
    r(string_needle, sub_atom_icasechk(hello, S2, "ll"), S2),
    r(number_haystack, sub_atom_icasechk(12345, S3, 34), S3),
    r(float_haystack, sub_atom_icasechk(1.5, S4, '.'), S4),
    r(codes_haystack, sub_atom_icasechk([0'A, 0'b, 0'c], S5, bc), S5),
    r(chars_needle, sub_atom_icasechk(abc, S6, [b, c]), S6),
    r(nil_needle, sub_atom_icasechk(abc, _, []), yes).

refused :-
    r(start_atom, sub_atom_icasechk(abc, x, a), yes),
    r(start_float, sub_atom_icasechk(abc, 1.0, a), yes),
    r(start_negative, sub_atom_icasechk(abc, -1, a), yes),
    r(start_first, sub_atom_icasechk(_, x, _), yes),
    r(needle_unbound, sub_atom_icasechk(abc, _, _), yes),
    r(haystack_unbound, sub_atom_icasechk(_, _, a), yes),
    r(needle_compound, sub_atom_icasechk(abc, _, f(x)), yes),
    r(haystack_compound, sub_atom_icasechk(f(x), _, a), yes),
    r(needle_before_haystack, sub_atom_icasechk(_, _, f(x)), yes),
    r(partial_list, sub_atom_icasechk([0'a|_], _, a), yes),
    r(mixed_list, sub_atom_icasechk([a, 0'b], _, a), yes).
