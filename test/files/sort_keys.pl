%  sort/4's key and order, and atomics_to_string/3's split, as swipl 9.0.4's
%  pl-list.c and pl-prims.c have them. Run by BOTH systems, output compared
%  byte for byte.
%
%  THE KEY is read as get_key_arg_ex() reads it: a positive integer, 0
%  (the whole term) or an atom, a dict key -- `[]' among them, an atom to
%  swipl's C. A PROPER LIST OF KEYS IS A PATH: [1, 2] sorts f(g(1, b)) by
%  b, each step a positive integer or an atom. 0 or a negative integer is
%  domain_error(not_less_than_one, K), at the top or as a step; a step of
%  any other kind -- a string, a float, a compound, a list, an unbound one
%  -- FAILS with no error, as swipl's returns FALSE; any other key is
%  type_error(sort_key, K), an unbound one instantiation_error. A positive
%  integer past swipl's tagged ones (max_tagged_integer, 2^56 - 1 on 64
%  bits) fails as well. Each element is walked step by step, swipl's
%  extract_key(): type_error(compound, T), then type_error(dict, T) for a
%  dict key, then existence_error(argument, K, T), T where the walk is.
%
%  THE ORDER is read after the whole key, PL_get_atom_ex()'s: an unbound
%  one instantiation_error, anything but an atom type_error(atom, O), and
%  an atom not in the table domain_error(order, O). The table has swipl's
%  other names too: < =< > >= beside @< @=< @> @>=.
%
%  THE SPLIT of atomics_to_string/3 is atomic_list_concat/3's: an unbound
%  TAIL after the elements read cuts the text of the third argument at the
%  separator, the parts ATOMS as swipl's split_atom() makes them; an empty
%  separator is domain_error(non_empty_atom, Sep). An unbound ELEMENT is
%  instantiation_error, as swipl's: only the atom's version splits there.
%
%  Through cocolog 3.49.1 a list key was type_error(sort_key, L), the order
%  names < =< > >= and a non-atom order domain_error(order, O), and
%  atomics_to_string/3 of an unbound tail instantiation_error.

:- set_prolog_flag(double_quotes, string).

t(G) :-
    copy_term(G, G0),
    catch(( G -> R = yes(G) ; R = no ), E, R = ex(E)),
    \+ \+ ( numbervars(G0-R, 0, _), print(G0), write('  =>  '), print(R) ), nl.

f(G) :-
    copy_term(G, G0),
    catch(( G -> R = yes ; R = no ), error(F, _), R = ex(F)),
    \+ \+ ( numbervars(G0-R, 0, _), print(G0), write('  =>  '), print(R) ), nl.

main :-
    format("-- keys~n"),
    t(sort(0, @<, [c,a,b,a], _)),
    t(sort(1, @<, [f(2),f(1),f(2)], _)),
    t(sort([1,2], @<, [f(g(1,b)), f(g(2,a)), f(g(3,b))], _)),
    t(sort([1,2], @=<, [f(g(1,b)), f(g(2,a)), f(g(3,b))], _)),
    t(sort([1,1], @>=, [f(f(1)), f(f(2)), f(f(1))], _)),
    t(sort([1,1,1], @>, [f(f(f(1))), f(f(f(3))), f(f(f(2)))], _)),
    t(sort([2], @<, [f(x,2), f(y,1)], _)),
    t(sort([], @<, [b,a], _)),
    t(sort([], @<, [], _)),
    t(sort([0], @<, [f(1)], _)),
    t(sort([-1], @<, [f(1)], _)),
    t(sort(-1, @<, [f(1)], _)),
    t(sort([1,"a"], @<, [f(1)], _)),
    t(sort([1,_], @<, [f(1)], _)),
    t(sort([1,1.5], @<, [f(1)], _)),
    t(sort([1,f(x)], @<, [f(1)], _)),
    t(sort([1,[1]], @<, [f(1)], _)),
    t(sort([1|_], @<, [f(1)], _)),
    t(sort([1|a], @<, [f(1)], _)),
    t(sort(_, @<, [f(1)], _)),
    t(sort(a, @<, [f(1)], _)),
    t(sort(a, @<, [], _)),
    t(sort([a], @<, [f(1)], _)),
    t(sort([1,a], @<, [f(g)], _)),
    t(sort([[]], @<, [f(1)], _)),
    t(sort(1.5, @<, [], _)),
    t(sort("ab", @<, [], _)),
    t(sort(f(x), @<, [], _)),
    t(sort(72057594037927935, @<, [], _)),
    t(sort(72057594037927936, @<, [], _)),
    t(sort(-72057594037927937, @<, [], _)),
    t(sort([1,72057594037927936], @<, [], _)),
    t(sort([1,-72057594037927937], @<, [], _)),
    format("-- the order~n"),
    t(sort(0, <, [b,a,b], _)),
    t(sort(0, =<, [b,a,b], _)),
    t(sort(0, >, [b,a,b], _)),
    t(sort(0, >=, [b,a,b], _)),
    t(sort(1, <, [f(2),f(1),f(1)], _)),
    t(sort(0, foo, [], _)),
    t(sort(0, _, [], _)),
    t(sort(0, 1, [], _)),
    t(sort(0, "@<", [], _)),
    t(sort(0, f(x), [], _)),
    t(sort(0, [], [], _)),
    t(sort(0, '@ <', [], _)),
    format("-- which comes first~n"),
    t(sort([0], foo, [], _)),
    t(sort(["a"], foo, [], _)),
    t(sort(1.5, foo, [], _)),
    t(sort(1, foo, a, _)),
    t(sort(1, _, a, _)),
    t(sort([1,0], @<, a, _)),
    format("-- the list and its elements~n"),
    t(sort(1, @<, _, _)),
    t(sort(1, @<, [f(1)|_], _)),
    t(sort(1, @<, [f(1)|a], _)),
    t(sort(1, @<, a, _)),
    t(sort(1, @<, [f(1), a, g], _)),
    t(sort(1, @<, [a], _)),
    t(sort(0, @<, [a], _)),
    t(sort(1, @<, [_], _)),
    t(sort([1,1], @<, [f(_)], _)),
    t(sort(2, @<, [f(1)], _)),
    t(sort(2, @<, [f(1,2), f(1)], _)),
    t(sort([1,2], @<, [f(g(1))], _)),
    t(sort([1,2], @<, [f(a)], _)),
    t(sort(1, @<, [f()], _)),
    t(sort(1, @=<, [f(1)], _)),
    t(sort(1, @<, [f(b)-1, f(a)-2], _)),
    t(sort(a, @<, [_], _)),
    t(sort(a, @<, [[]], _)),
    format("-- a cyclic key~n"),
    L = [1|L],
    catch(sort(L, @<, [], _), error(type_error(T0, C0), _), true),
    ( T0 == sort_key, C0 == L -> writeln(type_error(sort_key, 'the cyclic key')) ; writeln(T0) ),
    format("-- atomics_to_string/3 splits an unbound tail~n"),
    t(atomics_to_string(_, -, "a-b")),
    t(atomics_to_string([a|_], -, "a-b")),
    t(atomics_to_string([a,b|_], -, "a-b-c")),
    t(atomics_to_string([a,c|_], -, "a-b-c")),
    t(atomics_to_string([_,b], -, "a-b")),
    t(atomics_to_string([a,_|_], -, "a-b")),
    t(atomics_to_string(_, '', "ab")),
    t(atomics_to_string(_, "", "ab")),
    t(atomics_to_string(_, -, _)),
    t(atomics_to_string(_, -, f(x))),
    t(atomics_to_string(_, -, 'a-b')),
    t(atomics_to_string(_, -, 12)),
    t(atomics_to_string(_, -, 1.5)),
    t(atomics_to_string(_, -, [0'a, 0'-, 0'b])),
    t(atomics_to_string(_, _, "a-b")),
    t(atomics_to_string(_, f(x), "a")),
    t(atomics_to_string(_, "-", "a-b-c")),
    t(atomics_to_string(_, -, "-a-")),
    t(atomics_to_string(_, -, "")),
    t(atomics_to_string(_, ab, "xabyabz")),
    t(atomics_to_string(_, 1, "213")),
    t(atomics_to_string(_, -, "a--b")),
    t(atomics_to_string(_, --, "a---b")),
    t(wide),
    t(( atomics_to_string(L1, -, "a-b"), L1 = [A1|_], atom(A1) )),
    t(atomics_to_string([a,b], -, _)),
    t(atomics_to_string([a|b], -, _)),
    t(atomics_to_string([a,f(x)|_], -, "a-b")),
    t(atomics_to_string(_, _)),
    t(atomics_to_string([a|_], _)),
    t(atomics_to_string([a,b], '', _)),
    t(atomics_to_string([a,b], -, "a-b")),
    t(atomics_to_string([a,b], -, 'a-b')),
    format("-- atomic_list_concat/3 as it was~n"),
    t(atomic_list_concat(_, -, "a-b")),
    t(atomic_list_concat([_,b], -, "a-b")),
    t(atomic_list_concat([a|_], -, 'a-b')),
    t(atomic_list_concat(_, '', ab)).

%  a separator past ASCII, its parts written as codes: a write of the
%  character itself is the locale's, swipl's \u00E9 under POSIX
wide :-
    atomics_to_string(Ps, '\xE9\', "a\xE9\b\xE9\c"),
    maplist(atom_codes, Ps, Cs), print(Cs), nl.
