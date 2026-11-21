%  nb_delete/1, term_variables/3, term_singletons/2, unifiable/3, ?=/2
%  and same_term/2, swipl 9.0.4's (cocolog 3.68.0): COMPAT.md's second
%  group of small built-ins, each foreign in swipl's system module. The
%  case holds:
%  - term_variables/3's difference list: the tail given, a Vars that names
%    the term's own variables, a cyclic term;
%  - term_singletons/2: the variables the term's tree holds once, in the
%    order first met, a shared subterm counted at each place, and a cyclic
%    term refused;
%  - unifiable/3: the bindings a unification would make, newest first and
%    none of them made, the shortcut of two variables, the side of a
%    binding of two (the younger's, made where the body lays them out),
%    and the list unified after;
%  - ?=/2: identical, or not unifiable;
%  - same_term/2: one term -- a variable, a compound's cell, an atomic
%    value, a float by its bits;
%  - nb_delete/1: nb_setval/2's and b_setval/2's globals gone, a key with
%    none no error, the errors, and nb_current/2 of `[]';
%  - the six as predicate_property/2, listing/1 and clause/2 see them.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.67.0 cocolog had none of the six, and a call raised
%  existence_error.

%% the goals below name a variable to see what a call bound it to
:- style_check(-singleton).

%% a term with its variables named, by a walk of its own
pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

%% how a goal ended, with its bindings; an error by its formal and the
%% predicate its context names
t(L, G) :-
    catch(( G -> R = yes(G) ; R = no ), E, R = caught(E)),
    % cocolint: C2 -- each ball here is a builtin's, whose context names it as swipl's
    (   R = caught(error(F, context(C, _)))
    ->  pv(L-caught(F, C))
    ;   pv(L-R)
    ),
    nl.

%% the properties swipl's predicate_property/2 gives a system predicate,
%% less those that move with the build
pp(H) :-
    findall(P, ( predicate_property(H, P),
                 \+ memberchk(P, [defined, size(_), last_modified_generation(_),
                                  number_of_clauses(_), number_of_rules(_)]) ), Ps),
    functor(H, N, A), print(N/A-Ps), nl.

%% a term of N levels, each level the one below twice, and its singletons
%% beside two variables more: Y twice, Z once
dag(0, T, T) :- !.
dag(N, T0, T) :- N1 is N - 1, dag(N1, f(T0, T0), T).
dag_single(N, Ok) :-
    dag(N, g(_, Y), T), term_singletons(f(T, Y, Z), L),
    ( L == [Z] -> Ok = yes ; Ok = L ).

main :-
    vars3,
    singletons,
    unifiers,
    decided,
    same,
    deletes,
    seen.

vars3 :-
    t(v1, term_variables(f(X1, g(Y1, X1), Z1), _, [])),
    t(v2, term_variables(f(X2, g(Y2, X2), Z2), L2, T2)),
    t(v3, ( term_variables(a, L3, T3), L3 == T3 )),
    t(v4, term_variables(f(A4), L4, [x])),
    t(v5, term_variables(f(A5), L5, foo)),
    t(v6, ( term_variables(f(A6, B6), [B6|_], _), A6 == B6 )),
    t(v7, term_variables(f(A7), [z], T7)),
    t(v8, ( X8 = f(X8, Y8), term_variables(X8, L8, T8), L8 = [V8|T8], V8 == Y8 )),
    t(v9, ( term_variables(f(A9, B9), L9, T9), term_variables(g(B9, C9), T9, []) )),
    t(v10, ( term_variables(f(A10, B10), [A10|T10], T10), cyclic_term(T10) )),
    t(v11, term_variables(f(A11), [x, y], T11)),
    t(v12, term_variables(f(A12, B12), [_], _)),
    t(v13, ( T13 = g(X13), term_variables(f(T13, Y13, T13), L13, T13x) )),
    nl.

singletons :-
    t(s1, term_singletons(f(X1, g(Y1, X1), Z1), _)),
    t(s2, term_singletons(a, S2)),
    t(s3, term_singletons(f(A3, A3), S3)),
    t(s4, term_singletons([A4, B4, A4, C4], S4)),
    t(s5, term_singletons(f(_, _), S5)),
    t(s6, ( T6 = g(X6), term_singletons(f(T6, T6), S6) )),
    t(s7, ( T7 = g(X7), term_singletons(f(T7, Y7, T7, Z7, Y7), S7) )),
    t(s8, ( X8 = f(X8, Y8), term_singletons(X8, S8) )),
    t(s9, ( X9 = f(X9, Y9, Y9), term_singletons(X9, S9) )),
    t(s10, term_singletons(X10, S10)),
    t(s11, term_singletons(f(X11, Y11, X11, Z11, Y11), S11)),
    t(s12, term_singletons(f(A12), [x])),
    t(s13, ( term_singletons(f(A13, B13), [B13, A13]), A13 == B13 )),
    t(s14, term_singletons(f(_), foo)),
    t(s15, term_singletons(f(A15, g(A15, B15), [C15, B15, D15]), S15)),
    t(s16, ( atom_string(ab, S16), term_singletons(f(S16, 1.5, X16, [Y16|X16]), L16) )),
    t(s17, dag_single(10, Ok17)),
    t(s18, term_singletons(f(A18, B18), [C18|D18])),
    t(s19, ( X19 = f(Y19), term_singletons(g(X19, X19, Z19), L19) )),
    nl.

unifiers :-
    t(u1, unifiable(f(X1, b), f(a, Y1), U1)),
    t(u2, unifiable(a, b, U2)),
    t(u3, unifiable(X3, X3, U3)),
    t(u4, unifiable(f(X4, Y4), f(Y4, X4), U4)),
    t(u5, unifiable(X5, f(X5), U5)),
    t(u6, unifiable(g(A6, B6, C6), g(1, 2, 3), U6)),
    t(u7, unifiable(X7, Y7, U7)),
    t(u8, unifiable(Y8, X8, U8)),
    t(u9, unifiable(a, X9, U9)),
    t(u10, unifiable(f(a), X10, U10)),
    t(u11, unifiable(f(X11), f(X11), U11)),
    t(u12, ( unifiable(f(X12, a), f(b, c), _) -> true ; var(X12) )),
    t(u13, unifiable(1, 1.0, U13)),
    t(u14, ( atom_string(abc, S14), atom_string(abc, R14), unifiable(S14, R14, U14) )),
    t(u15, unifiable(f(X15, Y15, Z15), f(Y15, Z15, a), U15)),
    t(u16, unifiable([X16, Y16, Z16], [Z16, X16, Y16], U16)),
    t(u17, unifiable(f(X17, g(Y17)), f(h(Y17), X17), U17)),
    t(u18, ( X18 = f(X18), Y18 = f(Y18), unifiable(X18, Y18, U18) )),
    t(u19, unifiable(a, a, U19)),
    t(u20, unifiable(f(a), f(a), U20)),
    t(u21, unifiable(X21, a, [X21 = b])),
    t(u22, unifiable(X22, a, [Y22 = Z22])),
    t(u23, unifiable(f(X23, X23), f(a, b), U23)),
    t(u24, ( unifiable(f(X24, Y24), f(a, b), U24), var(X24), var(Y24) )),
    t(u25, ( unifiable(f(X25), f(Y25), [X25 = Y25]), X25 == Y25 )),
    t(u26, ( unifiable(f(X26), f(Y26), [Y26 = X26]), X26 \== Y26 )),
    t(u27, unifiable(X27, a, foo)),
    t(u28, unifiable([A28|B28], [1, 2, 3], U28)),
    t(u29, unifiable(f(X29, Y29), f(Y29, a), U29)),
    t(u30, unifiable(f(A30, B30, C30), f(B30, C30, A30), U30)),
    t(u31, unifiable(p(X31, q(Y31, r(Z31))), p(1, q(2, r(3))), U31)),
    t(u32, unifiable(f(0.0), f(-0.0), U32)),
    t(u33, unifiable(f(X33, Y33), f(Y33, X33), [_, _|_])),
    t(u34, ( X34 = g(Y34), unifiable(X34, g(Z34), U34) )),
    t(u35, ( X35 = Y35, unifiable(X35, Y35, U35) )),
    t(u36, ( unifiable(X36, f(Y36), [V36 = W36]), V36 == X36, W36 = f(Y36x), Y36x == Y36 )),
    %% the side of a binding of two variables is the younger's: a compound's
    %% arguments are made before the compounds inside them
    t(u37, unifiable(g(h(A37), B37), g(h(B37), A37), U37)),
    t(u38, ( X38 = g(h(C38), D38), unifiable(X38, g(h(D38), C38), U38) )),
    t(u39, unifiable(f(P39, k(Q39)), f(Q39, k(P39)), U39)),
    t(u40, unifiable([E40|F40], [F40|E40], U40)),
    t(u41, unifiable(f(k(G41), H41), f(k(H41), G41), U41)),
    t(u42, p42(U42)),
    t(u43, ( T43 = t(I43, J43), unifiable(T43, t(J43, I43), U43) )),
    nl.

decided :-
    t(q1, ?=(a, a)),
    t(q2, ?=(a, b)),
    t(q3, ?=(X3, X3)),
    t(q4, ?=(X4, Y4)),
    t(q5, ?=(f(X5), f(a))),
    t(q6, ?=(f(X6, b), f(a, c))),
    t(q7, ?=(1, 1.0)),
    t(q8, ?=(f(X8), f(X8))),
    t(q9, ?=(f(X9, a), f(Y9, b))),
    t(q10, ?=(f(X10, a), f(Y10, a))),
    t(q11, ?=([], [])),
    t(q12, ?=(X12, a)),
    t(q13, ?=(f(X13, Y13), f(Y13, X13))),
    t(q14, ( ?=(f(X14), f(Y14)) ; var(X14), var(Y14) )),
    t(q15, ( X15 = f(X15), Y15 = f(Y15), ?=(X15, Y15) )),
    t(q16, ?=(0.0, -0.0)),
    t(q17, ( atom_string(s, S17), atom_string(s, R17), ?=(S17, R17) )),
    t(q18, ( ?=(f(X18), f(a)) -> true ; var(X18) )),
    nl.

same :-
    t(t1, same_term(a, a)),
    t(t2, same_term(X2, X2)),
    t(t3, same_term(X3, Y3)),
    t(t4, same_term(f(a), f(a))),
    t(t5, ( T5 = f(a), same_term(T5, T5) )),
    t(t6, same_term(1, 1)),
    t(t7, same_term(1.0, 1.0)),
    t(t8, same_term(0.0, -0.0)),
    t(t9, ( X9 is nan, Y9 is nan, same_term(X9, Y9) )),
    t(t10, same_term(1, 1.0)),
    t(t11, same_term('[]', [])),
    t(t12, same_term([], [])),
    t(t13, same_term(a, X13)),
    t(t14, same_term(X14, a)),
    t(t15, ( X15 = f(a), g(X15) = g(Y15), same_term(X15, Y15) )),
    t(t16, ( atom_string(abc, S16), atom_string(abc, R16), same_term(S16, R16) )),
    t(t17, ( atom_string(abc, S17), atom_string(abd, R17), same_term(S17, R17) )),
    %% integers past a cell's 60 bits, each boxed apart (64 bits at most:
    %% COMPAT.md)
    t(t18, ( X18 is 2 ** 62, Y18 is 2 ** 62, same_term(X18, Y18) )),
    t(t19, ( X19 is 2 ** 62, Y19 is 2 ** 62 + 1, same_term(X19, Y19) )),
    t(t20, same_term(1r3, 2r6)),
    t(t21, same_term(1r3, 1r4)),
    t(t22, ( p22(X22), p22(Y22), same_term(X22, Y22) )),
    t(t23, ( X23 = Y23, same_term(X23, Y23) )),
    t(t24, ( X24 = f(Y24), X24 = f(Z24), same_term(Y24, Z24) )),
    t(t25, same_term(f(), f())),
    t(t26, ( X26 = f(), same_term(X26, X26) )),
    t(t27, same_term(-1, -1)),
    t(t28, ( X28 is -(2 ** 62) * 2, same_term(X28, -9223372036854775808) )),
    t(t29, same_term(1.5NaN, 1.5NaN)),
    t(t30, same_term(1.0Inf, 1.0Inf)),
    nl.
p22(f(a)).
%% a clause's head makes its variables before its body's goals run
p42(v(A, B, U)) :- unifiable(f(k(A), B), f(k(B), A), U).

deletes :-
    t(d1, nb_delete(td_nope)),
    t(d2, ( nb_setval(td_k1, 1), nb_delete(td_k1), nb_current(td_k1, _) )),
    t(d3, nb_delete(_)),
    t(d4, nb_delete(1)),
    t(d5, nb_delete(f(x))),
    t(d6, ( atom_string(str, S6), nb_delete(S6) )),
    t(d7, ( b_setval(td_k2, 2), nb_delete(td_k2), nb_current(td_k2, _) )),
    t(d8, ( nb_setval(td_k3, 3), nb_delete(td_k3), nb_getval(td_k3, _) )),
    t(d9, nb_delete([])),
    t(d10, nb_delete('')),
    t(d11, ( ( b_setval(td_k5, 1), nb_delete(td_k5), fail ; true ), nb_current(td_k5, _) )),
    t(d12, ( nb_setval(td_k6, 1), b_setval(td_k6, 2), nb_delete(td_k6), nb_current(td_k6, _) )),
    t(d13, ( nb_setval(td_k7, f(a)), nb_getval(td_k7, A13), nb_delete(td_k7),
             nb_setval(td_k7, g(b)), nb_getval(td_k7, B13) )),
    t(d14, ( nb_setval(td_k8a, 1), nb_setval(td_k8b, 2), nb_delete(td_k8a),
             findall(K14, ( nb_current(K14, _), memberchk(K14, [td_k8a, td_k8b]) ), L14) )),
    t(d15, ( b_setval(td_k9, 1), nb_delete(td_k9), b_getval(td_k9, _) )),
    t(d16, ( b_setval(td_k10, 1), nb_delete(td_k10), b_setval(td_k10, 2), b_getval(td_k10, V16) )),
    t(d17, ( nb_setval(td_k11, 1), nb_delete(td_k11), nb_delete(td_k11) )),
    t(d18, nb_setval([], 1)),
    t(d19, nb_getval([], _)),
    t(d20, nb_current([], _)),
    t(d21, ( nb_delete([]), nb_getval([], _) )),
    %% the globals made after a delete, and the ones before it, read again
    t(d22, ( nb_setval(td_a, x(1)), nb_setval(td_b, x(2)), nb_setval(td_c, x(3)),
             nb_getval(td_b, B22), nb_getval(td_c, C22), nb_delete(td_a),
             nb_getval(td_b, B22x), nb_getval(td_c, C22x), nb_setval(td_d, x(4)),
             nb_getval(td_d, D22), nb_delete(td_c), nb_getval(td_b, B22y), nb_getval(td_d, D22y) )),
    t(d23, ( nb_setval(td_e, 1), nb_delete(td_e), nb_setval(td_e, 2), nb_getval(td_e, E23) )),
    t(d24, ( forall(between(1, 300, I), ( atom_concat(td_m, I, K), nb_setval(K, v(I)) )),
             forall(between(1, 300, I), ( I mod 3 =:= 0 -> atom_concat(td_m, I, K), nb_delete(K) ; true )),
             findall(I, ( between(1, 300, I), atom_concat(td_m, I, K),
                          nb_current(K, v(I)) ), Is24),
             length(Is24, N24) )),
    nl.

seen :-
    forall(member(H, [nb_delete(_), term_variables(_, _, _), term_singletons(_, _),
                      unifiable(_, _, _), ?=(_, _), same_term(_, _)]),
           pp(H)),
    listing(unifiable/3),
    listing((?=)/2),
    t(c1, clause(same_term(_, _), _)),
    t(c2, clause(nb_delete(_), _)).
