%  write_term/2's fullstop(B), nl(B), dotlists(B) and no_lists(B), and its
%  booleans, as swipl 9.0.4's pl-write.c writes them. Run by BOTH systems,
%  output compared byte for byte.

:- set_prolog_flag(double_quotes, codes).

w(T, Os) :- write_term(T, Os), write('|'), nl.

%  a full stop, a space before it where it would join the token before it,
%  and a space after it, or a newline with nl(true)
t(1) :- w(f(x), [fullstop(true)]).
t(2) :- w(abc, [fullstop(true)]).
t(3) :- w(1, [fullstop(true)]).
t(4) :- w(1.5, [fullstop(true)]).
t(5) :- w(-1, [fullstop(true)]).
t(6) :- w(- 1, [fullstop(true)]).
t(7) :- w(- a, [fullstop(true)]).
t(8) :- w(- - a, [fullstop(true)]).
t(9) :- w(-, [fullstop(true)]).
t(10) :- w(:-, [fullstop(true)]).
t(11) :- w(\, [fullstop(true)]).
t(12) :- w(#, [fullstop(true)]).
t(13) :- w(a:b, [fullstop(true)]).
t(14) :- w(a- (-), [fullstop(true)]).
t(15) :- w('a b', [fullstop(true), quoted(true)]).
t(16) :- w('a b', [fullstop(true)]).
t(17) :- w('/*', [fullstop(true), quoted(true)]).
t(18) :- w([a, b], [fullstop(true)]).
t(19) :- w({a}, [fullstop(true)]).
t(20) :- w('$VAR'(1), [fullstop(true), numbervars(true)]).
t(21) :- w(a=b, [fullstop(true)]).
t(22) :- w(f(x), [fullstop(true), nl(true)]).
t(23) :- w(f(x), [nl(true)]).
t(24) :- w(f(x), [fullstop(true), nl(true), nl(false)]).
t(25) :- w(f(x), [fullstop(true), fullstop(false)]).
t(26) :- w(f(x), [fullstop(false), nl(false)]).
t(27) :- with_output_to(codes(C), write_term(f(x), [fullstop(true), nl(true)])), atom_codes(A, C), writeq(A), nl.
t(28) :- format("~W|~n", [f(x), [fullstop(true)]]).
t(29) :- format("~W|~n", [- a, [fullstop(true), nl(true)]]).
t(30) :- w(f(x), [fullstop]).
t(31) :- w(f(x), [fullstop = true, nl = true]).
t(32) :- w(f, [fullstop(true), max_depth(1)]).
%  dotlists(true): a list is '.'(H, T)
t(40) :- w([1, 2, 3], [dotlists(true)]).
t(41) :- w([], [dotlists(true)]).
t(42) :- w([a|b], [dotlists(true)]).
t(43) :- w([a, [b]], [dotlists(true)]).
t(44) :- w(f([1]), [dotlists(true)]).
t(45) :- w(- [1], [dotlists(true)]).
t(46) :- w([- 1], [dotlists(true)]).
t(47) :- w(f([1, 2]), [dotlists(true), spacing(next_argument)]).
t(48) :- w([1, 2, 3, 4], [dotlists(true), max_depth(3)]).
t(49) :- w(['a b', 'C'], [dotlists(true), quoted(true)]).
t(50) :- w({[1]}, [dotlists(true)]).
t(51) :- w([1|[2|[]]], [dotlists(true)]).
t(52) :- w(a-[1], [dotlists(true)]).
t(53) :- w([1, 2], [dotlists(true), fullstop(true)]).
t(54) :- w([a, b, c], [dotlists(true), max_depth(2)]).
%  no_lists(true): a list is '[|]'(H, T)
t(60) :- w([1, 2, 3], [no_lists(true)]).
t(61) :- w([], [no_lists(true)]).
t(62) :- w([a|b], [no_lists(true)]).
t(63) :- w([a, [b]], [no_lists(true), quoted(true)]).
t(64) :- w(- [1], [no_lists(true)]).
t(65) :- w(1 - [1], [no_lists(true)]).
t(66) :- w([1, 2, 3, 4], [no_lists(true), max_depth(3)]).
t(67) :- w(f([1, 2]), [no_lists(true), spacing(next_argument)]).
t(68) :- w([a], [no_lists(true), dotlists(true)]).
t(69) :- w([a, b, c], [no_lists(true), max_depth(2)]).
%  a boolean is true, false, on, off, 1 or 0
t(80) :- w('a b', [quoted(1)]).
t(81) :- w('a b', [quoted(0)]).
t(82) :- w(f(x), [fullstop(1), nl(0)]).
t(83) :- w([1], [dotlists(on)]).
t(84) :- w([1], [no_lists(off)]).
t(85) :- catch(w('a b', [quoted(2)]), error(E, _), (print(E), nl)).
t(86) :- catch(w(f(x), [fullstop(yes)]), error(E, _), (print(E), nl)).
t(87) :- catch(w(f(x), [nl(-1)]), error(E, _), (print(E), nl)).
t(88) :- catch(w(f(x), [dotlists(_)]), error(E, _), (print(E), nl)).
t(89) :- catch(w(f(x), [no_lists(1.0)]), error(E, _), (print(E), nl)).

%  more: the list's end, the solo characters, an operator's own atom,
%  a cycle cut by a depth, ignore_ops, format's ~W, a number's full stop
t(101) :- w([], [fullstop(true)]).
t(102) :- w('[]', [fullstop(true), quoted(true)]).
t(103) :- w({}, [fullstop(true)]).
t(104) :- w((a;b), [fullstop(true)]).
t(105) :- w((a:-b), [fullstop(true)]).
t(106) :- w(!, [fullstop(true)]).
t(107) :- w(;, [fullstop(true)]).
t(108) :- w('|', [fullstop(true)]).
t(109) :- w(f(:-), [fullstop(true)]).
t(110) :- w(1 - (- 1), [fullstop(true)]).
t(111) :- w([a,b], [dotlists(true), quoted(true), fullstop(true), nl(true)]).
t(112) :- L = [a|L], w(L, [dotlists(true), max_depth(4)]).
t(115) :- w('$VAR'(3), [fullstop(true), numbervars(false), quoted(true)]).
t(116) :- w(- (-), [fullstop(true)]).
t(117) :- w(a = \, [fullstop(true)]).
t(118) :- w([[]], [dotlists(true)]).
t(119) :- w('[]'(x), [dotlists(true)]).
t(120) :- w(f(a, [b]), [dotlists(true), ignore_ops(true)]).
t(121) :- w(1+[2], [dotlists(true), ignore_ops(true)]).
t(122) :- format("~W|~n", [[1,2], [dotlists(true)]]).
t(123) :- format("~W|~n", [[1,2], [no_lists(true), quoted(true)]]).
t(124) :- w("ab", [dotlists(true)]).
t(125) :- w(-(1), [dotlists(true), fullstop(true)]).
t(126) :- w(1.0e10, [fullstop(true)]).
t(127) :- w(-0.0, [fullstop(true)]).
t(128) :- w(0'a, [fullstop(true)]).
t(129) :- w('\n', [fullstop(true), quoted(true)]).
t(130) :- w(f('$VAR'(1)), [fullstop(true), numbervars(true)]).

main :- forall(( between(1, 130, N), clause(t(N), _) ),
               ( write(N), write(': '), ( catch(t(N), E, (print(caught(E)), nl)) -> true ; write(failed), nl ) )).
