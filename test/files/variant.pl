%  =@=/2, \=@=/2 and subsumes_term/2, checked against SWI.
%  Run by BOTH systems, output compared byte for byte.
%
%  Each case is a clause of its own, so no two share a variable. The two
%  zeros and a NaN under =@=/2 are test/files/float_order.pl's.

s(Label, Value) :- write(Label), write(=), write(Value), nl.
r(Label) :- ( catch(c(Label), E, (s(Label, E), fail)) -> s(Label, yes) ; s(Label, no) ).

dag(0, L, L) :- !.
dag(N, L, f(T, T)) :- N1 is N - 1, dag(N1, L, T).

%  ---- =@=/2: SWI's own examples, then shared variables ----
c(v01) :- a =@= _.
c(v02) :- _ =@= _.
c(v03) :- x(A, A) =@= x(_, _).
c(v04) :- x(A, A) =@= x(B, B).
c(v05) :- x(A, A) =@= x(A, _).
c(v06) :- x(_, _) =@= x(_, _).
c(v07) :- x(A, B) =@= x(B, A).
c(v08) :- x(A, B) =@= f(A, B).
c(v09) :- f(A, B, A) =@= f(B, A, A).
c(v10) :- f(A, B, A) =@= f(B, A, B).
c(v11) :- X =@= X.
c(v12) :- f(X) =@= f(f(X)).
c(v13) :- f(_) =@= f(a).
c(v14) :- a =@= a.
c(v15) :- 1 =@= 1.0.
c(v16) :- f(1.5, 2) =@= f(1.5, 2).
c(v17) :- 9007199254740993 =@= 9007199254740992.
c(v18) :- 9223372036854775807 =@= 9223372036854775807.
c(v19) :- f('$VAR'(0), _) =@= f(_, '$VAR'(0)).
c(v20) :- [A, B, C|T] =@= [C, A, B|T].
c(v21) :- [A, B, C|_] =@= [C, A, B|_].
c(v22) :- g(A, _, h(A, _)) =@= g(D, _, h(D, _)).
c(v23) :- g(A, _, h(A, _)) =@= g(_, E, h(E, _)).
c(v24) :- A = f(_), A =@= f(_).
c(v25) :- f(A, g(B)) =@= f(g(B), A).
c(v26) :- call(=@=, f(A, B), f(B, A)).

%  ---- =@=/2 over cycles, a DAG and a long list ----
c(y01) :- X = f(X), Y = f(Y), X =@= Y.
c(y02) :- X = f(X, _), Y = f(Y, _), X =@= Y.
c(y03) :- X = f(X, A, A), Y = f(Y, _, _), X =@= Y.
c(y04) :- X = f(X), Y = f(f(Y)), X =@= Y.
c(y05) :- X = f(X, A), Y = f(Y, A), X =@= Y.
c(y06) :- X = [A|X], Y = [B|Y], X =@= Y, A \== B.
c(y07) :- X = f(X, A, B), Y = f(Y, B, A), X =@= Y.
c(y08) :- X = f(X), Y = f(Y, Y), X =@= Y.
c(y09) :- dag(40, a, T1), dag(40, a, T2), T1 =@= T2.
c(y10) :- dag(40, _, T1), dag(40, _, T2), T1 =@= T2.
c(y11) :- dag(40, A, T1), dag(40, B, T2), f(T1, A) =@= f(T2, B).
c(y12) :- dag(40, A, T1), dag(40, _, T2), f(T1, A) =@= f(T2, a).
c(y13) :- length(L, 200000), copy_term(L, L2), L =@= L2.
c(y14) :- length(L, 200000), copy_term(L, L2), L2 = [X|_], X = a, L =@= L2.

%  ---- \=@=/2 ----
c(n01) :- a \=@= _.
c(n02) :- x(A, B) \=@= x(B, A).
c(n03) :- f(A, B, A) \=@= f(B, A, A).
c(n04) :- X = f(X), Y = f(Y, Y), X \=@= Y.
c(n05) :- \=@=(f(_), f(_)).

%  ---- subsumes_term/2: ISO's examples, then the rest ----
c(s01) :- subsumes_term(a, a).
c(s02) :- subsumes_term(f(_, _), f(Z, Z)).
c(s03) :- subsumes_term(f(Z, Z), f(_, _)).
c(s04) :- subsumes_term(g(X), g(f(X))).
c(s05) :- subsumes_term(X, f(X)).
c(s06) :- subsumes_term(X, Y), subsumes_term(Y, f(X)).
c(s07) :- subsumes_term(f(A, B), f(B, A)).
c(s08) :- subsumes_term(f(A, A), f(B, B)).
c(s09) :- subsumes_term(_, f(_)).
c(s10) :- subsumes_term(f(_), _).
c(s11) :- subsumes_term(f(a, _), f(_, b)).
c(s12) :- subsumes_term(X, X).
c(s13) :- X = f(X), subsumes_term(X, X).
c(s14) :- X = f(X), Y = f(Y), subsumes_term(X, Y).
c(s15) :- X = f(X, _), Y = f(Y, a), subsumes_term(X, Y).
c(s16) :- X = f(X, a), Y = f(Y, _), subsumes_term(X, Y).
c(s17) :- subsumes_term(f(A, A, _), f(C, C, _)).
c(s18) :- subsumes_term(f(_, B, B), f(C, C, _)).
c(s19) :- subsumes_term(9007199254740993, 9007199254740992).
c(s20) :- subsumes_term(1, 1.0).
c(s21) :- subsumes_term(f(A, b), f(a, A)).
c(s22) :- subsumes_term([A|B], [B|A]).
c(s23) :- L = [1, 2, 3|T], subsumes_term(L, [1, 2, 3, 4|T]).
c(s24) :- L = [1, 2, 3|T], subsumes_term([1, 2, 3, 4|T], L).
c(s25) :- dag(40, _, T1), dag(40, _, T2), subsumes_term(T1, T2).
c(s26) :- length(L, 200000), copy_term(L, L2), subsumes_term(L, L2).

%  ---- nothing is left bound, by either ----
c(b01) :- subsumes_term(f(X), f(a)), var(X).
c(b02) :- subsumes_term(f(X, Y), f(Z, Z)), var(X), var(Y), var(Z), X \== Y.
c(b03) :- f(A, B) =@= f(C, D), var(A), var(B), var(C), var(D), A \== B, C \== D.
c(b04) :- x(A, B) =@= x(B, A), var(A), var(B), A \== B.
c(b05) :- T = g(A), \+ T =@= g(b), var(A).
c(b06) :- T = f(A, b), \+ subsumes_term(T, f(a, A)), var(A).

%  ---- the two operators, as the reader and the writer see them ----
w01 :- writeq(f(a =@= b, c \=@= d, (=@=), (\=@=))), nl.
w02 :- X = (a =@= b), X =.. L, writeq(L), nl.
w03 :- ( current_op(P, T, =@=) -> s(op_variant, P-T) ; s(op_variant, none) ),
       ( current_op(P2, T2, \=@=) -> s(op_not_variant, P2-T2) ; s(op_not_variant, none) ).
w04 :- writeq([- (=@=), (a =@= b) =@= c, -(a =@= b)]), nl.

main :-
    forall(member(L, [v01, v02, v03, v04, v05, v06, v07, v08, v09, v10, v11, v12, v13,
                      v14, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26,
                      y01, y02, y03, y04, y05, y06, y07, y08, y09, y10, y11, y12, y13, y14,
                      n01, n02, n03, n04, n05,
                      s01, s02, s03, s04, s05, s06, s07, s08, s09, s10, s11, s12, s13,
                      s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26,
                      b01, b02, b03, b04, b05, b06]),
           r(L)),
    w01, w02, w03, w04.
