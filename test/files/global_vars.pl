%  b_setval/2 and b_getval/2 as swipl 9.0.4's pl-gvar.c keeps them, beside
%  nb_setval/2: a backtrackable global, its value the term itself and not
%  a copy, which backtracking takes back. Run by BOTH systems, output
%  compared byte for byte. The case writes the files it loads into the
%  sandbox.
%
%  A b_setval/2 is undone by backtracking, by a throw unwinding past it,
%  by the end of \+'s, findall/3's and forall/2's search, and by the end
%  of the goal a load ran it in -- a directive's, an initialization
%  goal's, a hook's -- as swipl's load loop fails back over every term:
%  what such a goal did to what was there before the load, a box, a term
%  in one, ends with it too. The value is linked: a later binding of it is
%  seen, and setarg/3 on it writes the global. nb_setval/2 replaces it,
%  and a b_setval/2 undone after that does not bring it back. nb_getval/2,
%  b_getval/2 and nb_current/2 read either kind. expand_term/2 sets
%  '$term', which prolog_load_context/2's `term' reads: the term while its
%  hooks run, `[]' after; a load's own hooks see the load's term whatever
%  was set before.
%
%  Through cocolog 3.51.0 b_setval/2 was nb_setval/2: it copied its term
%  and nothing undid it. Not held here, as the two differ (COMPAT.md): a
%  hook's work on what is older than its term ends as the hook returns in
%  cocolog, and as every term its expansion gave is done in swipl.

:- set_prolog_flag(double_quotes, codes).
:- if(\+ current_predicate(open/4)).
:- use_module(library(stream)).
:- endif.

show(Tag, K) :- ( nb_current(K, V) -> pr(Tag-V) ; pr(Tag-unset) ).

%  what each line says, its variables named the same in both systems
pr(T) :- \+ \+ ( numbervars(T, 0, _), print(T) ), nl.

lterm(Tag) :- ( prolog_load_context(term, T) -> pr(Tag-T) ; pr(Tag-none) ).

t(1) :- b_setval(a, f(X)), X = 1, b_getval(a, V), pr(1-V).
t(2) :- b_setval(b, f(X)), nb_getval(b, V), X = 2, pr(2-V).
t(3) :- nb_setval(c, 1), b_setval(c, 2), nb_getval(c, V), pr(3-V).
t(4) :- b_setval(d, 1), nb_setval(d, 2), ( b_setval(d, 3), fail ; true ), nb_getval(d, V), pr(4-V).
t(5) :- ( b_setval(e, 1), nb_setval(e, 2), fail ; true ), show(5, e).
t(6) :- b_setval(f, 1), ( nb_setval(f, 2), fail ; true ), nb_getval(f, V), pr(6-V).
t(7) :- nb_setval(g, 1), ( b_setval(g, 2), fail ; true ), nb_getval(g, V), pr(7-V).
t(8) :- catch(b_getval(nokey, _), E, pr(8-E)).
t(9) :- catch(b_setval(_, 1), E, pr(9-E)), catch(b_setval(1, 1), E2, pr(9-E2)).
t(10) :- catch(b_getval(_, _), E, pr(10-E)), catch(b_getval(f(x), _), E2, pr(10-E2)).
t(11) :- b_setval(h, X), X = q, b_getval(h, V), pr(11-V).
t(12) :- b_setval(i, X), b_getval(i, V), pr(12-(V == X)).
t(13) :- findall(K-V, ( member(K, [j1, j2]), b_setval(K, K), nb_current(K, V) ), L), pr(13-L), show(13, j1).
t(14) :- b_setval(k, 1), forall(member(_, [a]), b_setval(k, 2)), nb_getval(k, V), pr(14-V).
t(15) :- b_setval(l, 1), \+ \+ ( b_setval(l, 2), nb_getval(l, V2), pr(15-V2) ), nb_getval(l, V), pr(15-V).
t(16) :- b_setval(m, 1), catch(( b_setval(m, 2), throw(z) ), z, true), nb_getval(m, V), pr(16-V).
t(17) :- nb_setval(n, f(Y)), Y = 3, nb_getval(n, V), pr(17-V).
t(18) :- b_setval(o, 1), b_setval(o, 2), ( b_setval(o, 3), fail ; true ), nb_getval(o, V), pr(18-V).
t(19) :- ( member(Z, [1, 2, 3]), b_setval(p, Z), Z >= 2 -> true ; true ), nb_getval(p, V), pr(19-V).
t(20) :- b_setval(q, abc), garbage_collect, b_getval(q, V), pr(20-V).
t(21) :- T = f(a), b_setval(r, T), setarg(1, T, b), b_getval(r, V), pr(21-V).
t(22) :- nb_setval(s, f(1)), nb_getval(s, _), b_setval(s, f(2)), nb_getval(s, V1),
         ( b_setval(s, f(3)), fail ; true ), nb_getval(s, V2), pr(22-V1-V2).
t(23) :- ( b_setval(u, g(a)), garbage_collect, fail ; true ), show(23, u).
t(24) :- numlist(1, 2000, L), b_setval(w, L), findall(S, ( b_getval(w, L2), sum_list(L2, S) ), Ss), pr(24-Ss).
t(25) :- b_cut, nb_getval(ct, V), pr(25-V).
t(26) :- catch(t26, e1, true), show(26, x).
t(27) :- b_setval(y, 1), b_rec(3), nb_getval(y, V), pr(27-V).
t(28) :- nb_setval(zz2, 2), b_setval(zz1, 1), findall(K, ( nb_current(K, _), memberchk(K, [zz1, zz2]) ), Ks), msort(Ks, S), pr(28-S).
t(29) :- b_setval(aa, f(_)), b_getval(aa, f(X)), X = 7, b_getval(aa, V), pr(29-V).
%  a freeze (nb_setarg/3 into a term older than the choice point) keeps
%  the heap, and the trail still takes the b_setval/2 back
t(30) :- T = f(a), ( b_setval(fz, 1), nb_setarg(1, T, g(x)), fail ; true ), show(30, fz).
t(31) :- b_setval(k7, f(X)), nb_getval(k7, V1), nb_setval(k7, V1), X = 3, nb_getval(k7, V2), pr(31-V1-V2).
t(32) :- length(L, 3), b_setval(k9, L), L = [a|_], b_getval(k9, V), pr(32-V).
t(33) :- b_setval(k10, "str"), b_getval(k10, V), pr(33-V).
t(34) :- b_setval(k11, 1.5), b_getval(k11, V), pr(34-V).
t(35) :- X = f(Y), b_setval(k12, X), Y = 5, nb_setval(k12b, X), b_getval(k12, V), nb_getval(k12b, W), pr(35-V-W).
t(36) :- b_setval(k13, []), show(36, k13), ( b_setval(k14, 1), fail ; true ), show(36, k14),
         findall(K, ( nb_current(K, _), K == k14 ), L), pr(36-L).
%  expand_term/2's '$term': the term while its hooks run, `[]' after, and
%  backtracking takes it back
t(37) :- \+ \+ ( expand_term(probe_t(1), X), pr(37-X), lterm(37) ), lterm(37).
t(38) :- \+ \+ ( b_setval('$term', mine), lterm(38) ), lterm(38).
%  a box a later key makes where an undone one stood is that key's alone
t(39) :- ( b_setval(p1, 1), fail ; true ), b_setval(p2, 2), show(39, p1), show(39, p2).
%  and one a collection kept past its choice point, its trail entry dropped
%  as a newer cell's is, is past the heap backtracking left: read before
%  anything is written there, no box
t(40) :- ( b_setval(v40, x), garbage_collect, fail ; nb_current(v40, V) ), !, pr(40-V).
t(40) :- pr(40-unset).

%  a directive's b_setval/2 ends with it when the directive collected too:
%  the collection dropped the trail entry that made the box, and the copy
%  of a ground global it read keeps the box's cells past the directive
:- nb_setval(gk0, f(a)).
:- b_setval(dk, 1), nb_getval(gk0, _), garbage_collect.
:- show(load_dk, dk).

%  the first box main makes, undone, and a term built where it stood, each
%  argument its serial, 2 (the load's directive above made the run's
%  first): it holds the serial and a value that is no dead mark, and its
%  own header tells it from the box
first_box :- ( b_setval(p0, x), fail ; true ), functor(T, f, 30), wide(T, 1, 30), show(first_box, p0).
wide(_, I, N) :- I > N, !.
wide(T, I, N) :- setarg(I, T, 2), I1 is I + 1, wide(T, I1, N).

term_expansion(probe_t(N), probe_done(N)) :- lterm(in_hook).

b_cut :- b_setval(ct, 1), !, b_setval(ct, 2).
b_cut :- b_setval(ct, 3).

t26 :- b_setval(x, outer), catch(( b_setval(x, inner), throw(e1) ), e2, true).

b_rec(0) :- !.
b_rec(N) :- b_setval(y, N), N1 is N - 1, b_rec(N1), nb_getval(y, V), pr(27-N-V).

%  ---- the files a load reads ---------------------------------------------

%  a directive's b_setval/2 ends with it, as an initialization goal's does;
%  nb_setval/2's stays
lines(gv_d, [ ":- b_setval(d1, 1), show(d1, d1).",
              ":- show(d1b, d1).",
              ":- nb_setval(d2, 1), b_setval(d2, 2), show(d2, d2).",
              ":- show(d2b, d2).",
              ":- initialization(b_setval(d3, 3)).",
              ":- initialization(show(d3, d3)).",
              ":- b_setval(d4, f(X)), X = 1, nb_getval(d4, V), pr(d4-V).",
              %  and where the read of a ground global keeps the heap the
              %  directive made
              ":- nb_setval(gg, f(a)).",
              ":- b_setval(d5, 1), nb_getval(gg, _), show(d5, d5).",
              ":- show(d5b, d5)." ]).
%  a hook's b_setval/2 ends with its term; the hook sees the load's term,
%  and the term of an expand_term/2 it calls itself while that one's hooks
%  run, `[]' after
lines(gv_h, [ "term_expansion(hx(N), [hx_done(N)]) :- b_setval(hk, N), nb_getval(gg, _), lterm(hook).",
              "term_expansion(hy(N), [hy_done(N)]) :- expand_term(inner(N), X), pr(hy-X), lterm(after_inner).",
              "term_expansion(inner(N), [inner_done(N)]) :- lterm(inner).",
              "hx(1).",
              ":- show(hk, hk).",
              "hy(2).",
              ":- lterm(dir)." ]).
%  a load's goals reach what was there before the load -- a box made before
%  it, a term in one -- and what each did to it ends with it, as swipl's
%  load loop fails back over each term: a write, a binding, a setarg/3, an
%  initialization goal's, a hook's; and a binding a directive an expansion
%  gave makes is the next expanded term's
lines(gv_o, [ ":- b_setval(ok1, g(a, [1, 2, 3])), b_getval(ok1, V), pr(o1-V).",
              "o_pad(1, 2, 3, f(x, y, z)).",
              "o_pad([a, b, c, d, e, f, g, h]).",
              ":- b_getval(ok1, V), pr(o1b-V).",
              ":- b_getval(ok2, f(Z)), Z = g(1), b_getval(ok2, V), pr(o2-V).",
              ":- b_getval(ok2, V), pr(o2b-V).",
              ":- b_getval(ok3, T), setarg(1, T, b), pr(o3-T).",
              ":- b_getval(ok3, V), pr(o3b-V).",
              ":- initialization(b_setval(ok1, h(1))).",
              ":- initialization((b_getval(ok1, V), pr(o4-V))).",
              "term_expansion(o_x(N), [(:- X = N), o_done(X)]) :- b_setval(ok1, x(N)).",
              "o_x(5).",
              ":- b_getval(ok1, V), pr(o5-V), ( o_done(D) -> pr(o5d-D) ; pr(o5d-none) ).",
              "term_expansion(o_w(T), []) :- b_getval(ok2, f(Q)), Q = w(T).",
              "o_w(zz).",
              ":- b_getval(ok2, V), pr(o6-V)." ]).
%  a load a term's expansion runs, or an include it gives, and the terms
%  that expansion gives after it, a goal expansion's bindings of them
%  kept; and a load a hook runs, whose directives are each a directive's,
%  the last after the hook has taken every hook away, so that no hook of
%  the load clears the flag the hook's own goal set
lines(gv_n, [ "goal_expansion(n_never, true).",
              "term_expansion(n_go, [(:- consult(gv_ni)), n_after(1)]).",
              "n_go.",
              ":- ( catch(n_after(X), _, fail) -> pr(n1-X) ; pr(n1-none) ).",
              "term_expansion(n_inc, [(:- include(gv_ni2)), n_after2(1)]).",
              "n_inc.",
              ":- ( catch(n_after2(X), _, fail) -> pr(n2-X) ; pr(n2-none) ).",
              "term_expansion(n_h, []) :- consult(gv_nh).",
              "n_h.",
              ":- b_getval(ok1, V), pr(n3-V).",
              "goal_expansion(n_g(X), true) :- X = bound.",
              "term_expansion(n_go3, [(:- consult(gv_ni3)), (n_after3(X) :- n_g(X))]).",
              "n_go3.",
              ":- ( catch(n_after3(X), _, fail) -> pr(n4-X) ; pr(n4-none) ).",
              "term_expansion(n_inc5, [(:- include(gv_ni5)), (n_after5(X) :- n_g(X))]).",
              "n_inc5.",
              ":- ( catch(n_after5(X), _, fail) -> pr(n5-X) ; pr(n5-none) ).",
              "term_expansion(n_r, []) :- retractall(term_expansion(_, _)), retractall(goal_expansion(_, _)), consult(gv_nr).",
              "n_r.",
              ":- b_getval(ok1, V), pr(n6-V)." ]).
lines(gv_ni, [ "ni(1)." ]).
lines(gv_ni2, [ "ni2(1)." ]).
lines(gv_ni3, [ "ni3(1).", "ni3(2)." ]).
lines(gv_ni5, [ "ni5(1).", "ni5(2)." ]).
lines(gv_nr, [ ":- b_setval(ok1, nr).", ":- b_getval(ok1, V), pr(nr1-V)." ]).
lines(gv_nh, [ ":- b_setval(ok1, nh).", ":- b_getval(ok1, V), pr(nh1-V)." ]).

write_file(N) :-
    lines(N, Ls), atom_concat(N, '.pl', F),
    open(F, write, S),
    forall(member(L, Ls), format(S, "~s~n", [L])),
    close(S).

main :-
    first_box,
    lterm(first),
    forall(between(1, 40, N), ( t(N) -> true ; pr(N-failed) )),
    show(after, a), show(after, c), show(after, d), show(after, g), show(after, s), show(after, x),
    forall(lines(N, _), write_file(N)),
    format("-- a load~n"),
    consult(gv_d),
    show(main_d1, d1), show(main_d2, d2), show(main_d3, d3),
    format("-- a load's hooks, after an expand_term/2 that left '$term' set~n"),
    expand_term(plain, _),
    lterm(before),
    consult(gv_h),
    lterm(after),
    show(main_hk, hk),
    format("-- a load's goals, over what was there before it~n"),
    b_setval(ok1, 1), b_setval(ok2, f(_)), b_setval(ok3, f(a)),
    consult(gv_o),
    b_getval(ok1, V1), b_getval(ok2, V2), b_getval(ok3, V3),
    pr(main_o-V1-V2-V3),
    format("-- loads an expansion and a hook run~n"),
    consult(gv_n).
