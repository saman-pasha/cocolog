%  Where a call is keyed inside a compound its clauses share, as swipl's
%  deep index keys it (pl-index.c, first_clause_guarded, bestHash and
%  nextClauseFromBucket, read at 9.0.4; cocolog 3.64.0): an argument
%  whose assessment makes it a list index -- under 0.8 of the clauses'
%  speedup, no clause with no key there, a functor whose first run of
%  clauses holds two compounds the compiler makes indexable -- holds a
%  clause list a functor, and the call goes on inside the compound: a list
%  of ten clauses or fewer walks its first argument and asks the others
%  only where its first two candidates are both of the call's key there,
%  else the bound argument that promises the most, seven levels down at
%  most. Told by $/0 at the exit of a clause that calls it and then
%  `true', where a choice point left is determinism_error(PI, det,
%  nondet, guard), by $/1 around a call whose body's first goal is the
%  one asked (a call from the registers, which no guard of $/0 takes), and
%  by the answers and their order. Run by BOTH SWI-Prolog and cocolog,
%  output compared byte for byte; each line is one of swipl 9.0.4's
%  answers. And since 3.73.2 (`later') a compound in a later argument
%  where the first leaves no fewer clauses. Not here (COMPAT.md): a
%  predicate of eight clauses or more
%  whose call's key leaves four candidates or fewer, which cocolog keys on
%  the argument with the fewest and goes no deeper; keys of floats and
%  strings; an index of two arguments together; and what swipl's indexes
%  kept from the calls before decide.

p(X, G) :- catch((findall(X, G, L), shown(L, S), print(S)), error(E, _), print(E)), nl.
dd(G) :- $, G, true.
d(G) :- catch((dd(G) -> shown(G, S), print(det(S)) ; print(fail)), error(E, _), print(E)), nl.
e(G) :- catch(($(G) -> shown(G, S), print(det(S)) ; print(fail)), error(E, _), (shown(E, S), print(S))), nl.
shown(T, S) :- copy_term(T, S), term_variables(S, Vs), maplist(=('_'), Vs).

%  a list's head, the compound's first argument, its second
dp([a|_], x).
dp([b|_], y).
df(f(a, _), x).
df(f(b, _), y).
dg(f(_, a), x).
dg(f(_, b), y).
%  the walk's own duplicate: the first two candidates of one key ask the
%  others, and a tie keeps the first
dk(f(a, x), 1).
dk(f(a, y), 2).
dh(f(a, x), 1).
dh(f(a, y), 2).
dh(f(b, x), 3).
%  a clause with no key there is no list index: every clause a candidate
dv3(f(a), x).
dv3(f(b), y).
dv3(_, z).
%  a clause with no key there is no list index though eleven keys make
%  its share small: a call keyed there goes no deeper, and leaves a choice
%  point after f(1) where the walk inside would leave none (f(3) and f(5)
%  are keyed on the second argument, which one clause each holds)
dvw(_, z).
dvw(f(1), 1). dvw(f(2), 2). dvw(f(3), 3). dvw(f(4), 4). dvw(f(5), 5).
dvw(g(1), 1). dvw(g(2), 2). dvw(h(1), 1). dvw(h(2), 2). dvw(i(1), 1). dvw(i(2), 2).
dvw(j(1), 1). dvw(j(2), 2). dvw(k(1), 1). dvw(k(2), 2). dvw(l(1), 1). dvw(l(2), 2).
dvw(m(1), 1). dvw(m(2), 2). dvw(n(1), 1). dvw(n(2), 2). dvw(o(1), 1). dvw(o(2), 2).
%  two functors, apart and interleaved: a functor's later run of clauses
%  adds nothing to its count (9.0.4's), so di2 is no list index
dm(f(a), 1).
dm(f(b), 2).
dm(g(a), 3).
dm(g(b), 4).
di2(f(a), 1).
di2(g(a), 2).
di2(f(b), 3).
di2(g(b), 4).
%  and a functor whose first run is one clause and a later run two is no
%  list index either: only the first run is counted
dj(f(a), 1).
dj(g(a), 2).
dj(f(b), 3).
dj(f(c), 4).
dx(a, 1).
dx(f(a), 2).
dx(f(b), 3).
%  the compound in the second argument, the first one atom: a single
%  value that is no compound promises nothing
dn(x, f(a)).
dn(x, f(b)).
%  and inside a node: an argument whose members all hold one atom
%  promises nothing, and the compound after it is asked
do1(f(a, g(1)), x).
do1(f(a, g(2)), y).
do2(f(a, b, g(1)), x).
do2(f(a, b, g(2)), y).
%  depth: six and seven levels go down, eight stop at the seventh
c6(f(f(f(f(f(f(a))))))).
c6(f(f(f(f(f(f(b))))))).
c7(f(f(f(f(f(f(f(a)))))))).
c7(f(f(f(f(f(f(f(b)))))))).
c8(f(f(f(f(f(f(f(f(a))))))))).
c8(f(f(f(f(f(f(f(f(b))))))))).
%  what swipl's compiler makes an indexable compound: an argument that is
%  no variable, or a variable that occurs once before one that occurs again,
%  but not one at the end; a list cell of two variables met first there is
%  H_LIST_FF, which reads what follows it
q3([H|T], H, T).
q3([a|b], c, d).
q4(g([H|T]), H, T).
q4(g([a|b]), c, d).
q5(g([H|T], 1), H, T).
q5(g([a|b], 1), c, d).
q6(f(_, X), X).
q6(f(a, b), c).
q7(f(X, _), X).
q7(f(a, b), c).
q8(f(_, _, X), X).
q8(f(a, b, c), d).
q9(f(_, X, _), X).
q9(f(a, b, c), d).
%  two levels, and lists of lists
dl([a|_], x).
dl([b|_], y).
dl([a, b|_], z).
dd2(f(g(a), x), 1).
dd2(f(g(b), x), 2).
dd2(f(h(a), y), 3).
%  a list of ten or fewer walks its first argument where its first two
%  candidates are not both of the call's key; past ten it asks them all
wv(f(a, 1), x).
wv(f(_, 2), y).
wv(f(b, 3), z).
wv12(f(a, 1)).
wv12(f(_, 2)).
wv12(f(b, 3)).
wv12(f(c, 4)).
wv12(f(d, 5)).
wv12(f(e, 6)).
wv12(f(g, 7)).
wv12(f(h, 8)).
wv12(f(i, 9)).
wv12(f(j, 10)).
wv12(f(k, 11)).
wv12(f(l, 12)).
%  a node where no bound argument promises anything is walked on its first
%  argument: f(b, 5), keyed b there, is no candidate, and the last answer
%  leaves no choice point
dq(f(a, 1), x).
dq(f(a, 2), y).
dq(f(_, 3), z).
dq(f(_, 4), w).
dq(f(b, 5), v).
dql(V) :- dq(f(a, _), V), V == w.
%  from the registers: the body's first goal is the call asked
cd(X) :- dk(f(a, x), X).
cq(X) :- q6(f(z, w), X).
cl(X) :- dl([b, a], X).
:- dynamic dz/2.
dz(f(a), 1).
dz(f(b), 2).
:- dynamic node/2.
:- dynamic it/2.
it(f(a), 1).
it(f(a), 2).
it(f(b), 3).

det :-
    d(dp([a], _)), d(dp([b], _)), d(dp([c], _)), d(dp(_, x)),
    d(df(f(a, 1), _)), d(df(f(b, 1), _)),
    d(dg(f(1, a), _)), d(dg(f(1, b), _)),
    d(dk(f(a, x), _)), d(dk(f(a, y), _)), d(dk(f(a, _), _)),
    d(dh(f(a, x), _)), d(dh(f(a, y), _)), d(dh(f(b, x), _)), d(dh(f(_, x), _)),
    d(dv3(f(a), _)), d(dv3(f(c), _)),
    d(dvw(f(3), 3)), d(dvw(f(5), 5)), d(dvw(f(1), 1)),
    d(dm(f(a), _)), d(dm(f(b), _)), d(dm(g(a), _)), d(dm(h(a), _)), d(dm(f(_), _)),
    d(di2(f(a), _)), d(di2(f(b), _)), d(di2(g(a), _)),
    d(dj(f(b), _)), d(dj(f(c), _)), d(dj(f(a), _)),
    d(dx(a, _)), d(dx(f(a), _)), d(dx(f(b), _)),
    d(dn(x, f(a))), d(dn(_, f(b))), d(dn(x, f(c))),
    d(do1(f(a, g(1)), _)), d(do1(f(a, g(2)), _)), d(do2(f(a, b, g(1)), _)), d(do2(f(a, b, g(2)), _)),
    nest(6, a, T6), d(c6(T6)), nest(7, a, T7), d(c7(T7)),
    nest(8, a, T8), d(c8(T8)), nest(8, b, T9), d(c8(T9)).

nest(0, A, A) :- !.
nest(N, A, f(T)) :- N1 is N - 1, nest(N1, A, T).

shapes :-
    d(q3([z|w], _, _)), d(q3([a|w], _, _)),
    d(q4(g([z|w]), _, _)), d(q5(g([z|w], 1), _, _)),
    d(q6(f(z, w), _)), d(q7(f(z, w), _)), d(q8(f(z, w, v), _)), d(q9(f(z, w, v), _)),
    d(dl([a], _)), d(dl([a, b], _)), d(dl([a, c], _)), d(dl([b, a], _)), d(dl([_|_], _)),
    d(dd2(f(g(a), x), _)), d(dd2(f(g(b), _), _)), d(dd2(f(h(a), _), _)), d(dd2(f(g(_), x), _)),
    d(wv(f(a, 1), _)), d(wv(f(b, 3), _)), d(wv12(f(a, 1))), d(wv12(f(b, 3))), d(wv12(f(l, 12))),
    d(dql(_)),
    e(cd(_)), e(cq(_)), e(cl(_)), e(dk(f(a, y), _)), e(dh(f(a, y), _)).

changes :-
    d(dz(f(a), _)),
    assertz(dz(f(a), 3)), d(dz(f(a), _)), d(dz(f(b), _)), p(N1, dz(f(a), N1)),
    asserta(dz(f(c), 0)), d(dz(f(c), _)), d(dz(f(b), _)),
    retract(dz(f(a), 1)), d(dz(f(a), _)), p(N2, dz(f(a), N2)),
    assertz(dz(_, 4)), d(dz(f(b), _)), p(N3, dz(f(b), N3)).

%  a call open while its clauses change sees the ones that stood when it
%  began: an asserta in front, which moves every clause, and a retract of
%  one it has still to try
views :-
    p(N1, (it(f(a), N1), ( N1 == 1 -> asserta(it(f(a), 0)) ; true ))),
    p(N2, it(f(a), N2)),
    p(N3, (it(f(a), N3), ( N3 == 0 -> retract(it(f(a), 2)) ; true ))),
    p(N4, it(f(a), N4)).

%  forty facts keyed by a handle: past ten, the argument that promises the
%  most inside it
handles :-
    forall(between(1, 40, I),
           ( D is I mod 4, G is I mod 3, assertz(node(n(D, I, G), v(I))) )),
    d(node(n(1, 13, 1), _)), d(node(n(2, 6, 0), _)), d(node(n(1, _, 1), _)),
    d(node(n(3, 40, 0), _)), d(node(n(0, 40, 1), _)),
    p(V1, node(n(2, 6, 0), V1)), p(I2, node(n(1, I2, 1), _)), p(V3, node(n(0, 40, 1), V3)).

%  a list index promises less than four fifths of its clauses: five
%  clauses of one functor among four hundred of others key nothing inside
%  the compound, and f(3) leaves a choice point
:- dynamic ds/2.
spread :-
    forall(between(1, 5, I), assertz(ds(f(I), I))),
    forall(between(1, 400, I), ( atom_concat(g, I, F), T =.. [F, 1], assertz(ds(T, I)) )),
    d(ds(f(3), _)), d(ds(f(5), _)), d(ds(g7(1), _)).

answers :-
    p(N1, dm(f(N1), _)), p(X2-N2, dm(X2, N2)), p(N3, dl([a|_], N3)),
    p(N4, dd2(f(g(_), x), N4)), p(L5, dl(L5, z)), p(X6, wv(f(X6, _), _)),
    p(N7, wv12(f(_, N7))).

%  A COMPOUND IN A LATER ARGUMENT (cocolog 3.73.2): past eight clauses, a
%  call whose first argument is unbound, or bound to a key that leaves as
%  many clauses as the compound's argument does, goes down into the
%  compound, where swipl's list index takes it (its assessment finds no
%  better argument); a first argument that leaves fewer is walked, in
%  both. Through 3.73.1 every one of them walked the whole predicate, and
%  left a choice point. Each call on a predicate of its own: swipl's
%  indexes stay with the calls that built them
lrows(t1, R) :- findall([es, [W]], (between(1, 20, I), atom_concat(w, I, W)), R).
lrows(t2, R) :- findall([K, [W]], (between(1, 20, I), atom_concat(w, I, W), atom_concat(k, I, K)), R).
lrows(t4, R) :-
    findall([A, g(W), h(W)], (between(1, 20, I), atom_concat(w, I, W), (I mod 2 =:= 1 -> A = a ; A = b)), R).
lrows(t5, R) :- findall([A, [W]], (between(1, 20, I), atom_concat(w, I, W), (I =< 19 -> A = es ; A = fr)), R).
lrows(t6, R) :- findall([I, x, f(W)], (between(1, 20, I), atom_concat(w, I, W)), R).
lrows(t7, R) :- findall([_, [W]], (between(1, 20, I), atom_concat(w, I, W)), R).
lrows(t8, R) :- findall([I, [W], [W]], (between(1, 20, I), atom_concat(w, I, W)), R).
%  a variable in one clause's second argument makes it no list index, and
%  the third, which is, takes the call; an atom there leaves it one
lrows(t9, R) :- findall([I, A, [W]], (between(1, 20, I), atom_concat(w, I, W), (I =:= 7 -> true ; A = [W])), R).
lrows(t10, R) :- findall([I, A, [W]], (between(1, 20, I), atom_concat(w, I, W), (I =:= 7 -> A = x ; A = f(W))), R).
%  two list indexes tie, and the first keeps the call, though inside the
%  second every clause holds the same atom
lrows(t11, R) :- findall([I, [W], [x]], (between(1, 20, I), atom_concat(w, I, W)), R).
lcalls([ t1-[es, [w3]], t1-[_, [w3]], t1-[_, [w20]], t1-[_, [none]], t1-[_, [_]],
         t2-[_, [w3]], t2-[k3, [w3]], t2-[k3, [_]], t2-[_, [w3, w4]],
         t4-[_, g(w3), _], t4-[_, _, h(w3)], t4-[a, g(w3), _], t4-[b, g(w3), _],
         t5-[es, [w3]], t5-[_, [w3]], t5-[fr, [w20]],
         t6-[_, _, f(w9)], t6-[_, x, f(w9)], t6-[_, y, f(w9)],
         t7-[_, [w6]], t8-[_, [w6], _], t8-[_, _, [w6]], t8-[_, [w6], [w6]], t8-[_, [w6], [w7]],
         t9-[_, [w5], [w5]], t9-[_, _, [w5]], t9-[_, [w7], [w7]], t10-[_, f(w5), [w5]], t10-[_, x, [w7]],
         t11-[_, [w5], [x]], t11-[_, [w5], _], t11-[_, _, [x]] ]).
lnew(N, B, P) :-
    atom_concat(B, '_', B1), atom_concat(B1, N, P), lrows(B, Rows),
    forall(member(R, Rows), ( T =.. [P|R], assertz(T) )).
later :-
    lcalls(Cs),
    forall(nth1(N, Cs, B-Args), ( lnew(N, B, P), G =.. [P|Args], d(G) )),
    lnew(a1, t2, P1), G1 =.. [P1, K1, [w5]], p(K1, G1),
    lnew(a2, t4, P2), G2 =.. [P2, X2, g(_), h(w7)], p(X2, G2),
    lnew(a3, t1, P3), G3 =.. [P3, _, [W3]], p(W3, G3),
    lnew(a4, t6, P4), G4 =.. [P4, I4, _, f(w9)], p(I4, G4).

main :- det, shapes, changes, views, handles, spread, answers, later.
