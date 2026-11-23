%  A value setarg/3, nb_setarg/3 and b_setval/2 write is the value a
%  variable bound to it keeps (cocolog 3.78.2), held to swipl 9.0.4. Run by
%  BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  A variable arg/3 or a unification binds to an argument that holds an
%  atomic value takes the value, and the argument's next write leaves it as
%  it was -- the counter idiom, `arg(1, C, N0), N is N0 + 1, nb_setarg(1,
%  C, N)', collects 0, 1, 2. Through 3.78.1 the write put an atomic value in
%  the argument itself, the variable named the argument, and the next write
%  moved it: 0, 2, 3. A variable the argument IS follows each write, in
%  both systems; what cocolog binds where a clause's variable meets an
%  argument that is a variable is COMPAT.md's (the variable is the
%  clause's there, and stays as it was).

w(T) :- \+ \+ ( numbervars(T, 0, _), print(T) ), nl.
t(G) :- ( catch(G, E, ( w(caught(E)), fail )) -> true ; w(failed(G)) ).

next(S, N) :- arg(1, S, N), N1 is N + 1, nb_setarg(1, S, N1).
next_b(S, N) :- arg(1, S, N), N1 is N + 1, setarg(1, S, N1).

main :-
    counted,
    kinds,
    undone,
    linked,
    boxed,
    older.

%% the counter idiom: what each turn read stays what it read
counted :-
    t(( C1 = c(0), findall(N1, ( between(1, 3, _), arg(1, C1, N1), M1 is N1 + 1, nb_setarg(1, C1, M1) ), L1), w(L1-C1) )),
    t(( S2 = s(0), next(S2, A2), next(S2, B2), next(S2, D2), w([A2, B2, D2]-S2) )),
    t(( S3 = s(0), next_b(S3, A3), next_b(S3, B3), next_b(S3, D3), w([A3, B3, D3]-S3) )),
    t(( S4 = s(0), findall(N4, ( between(1, 3, _), next(S4, N4) ), L4), w(L4-S4) )),
    t(( C5 = c(0), L5 = [V5a, V5b], arg(1, C5, V5a), nb_setarg(1, C5, 1), arg(1, C5, V5b), nb_setarg(1, C5, 2), w(L5-C5) )),
    t(( functor(C6, c, 1), nb_setarg(1, C6, 0), arg(1, C6, V6), nb_setarg(1, C6, 7), w(V6-C6) )),
    t(( nb_setval(sv_k7, s(0)), nb_getval(sv_k7, S7), next(S7, A7), nb_getval(sv_k7, T7), next(T7, B7), nb_getval(sv_k7, F7), w([A7, B7]-F7) )),
    t(( C8 = c(0), ( between(1, 1000, I8), arg(1, C8, K8), J8 is K8 + I8, nb_setarg(1, C8, J8), fail ; true ), w(C8) )).

%% every atomic kind, read between two writes, by arg/3 and by unification
kinds :-
    X9 is 2 ** 62, Y9 is 2 ** 62 + 1,
    atom_string(s1, S9), atom_string(s2, T9),
    forall(member(P9-Q9, [1-2, a-b, []-z, 1.5-2.5, X9-Y9, S9-T9, f-g(1)]),
           ( t(( C9 = c(0), nb_setarg(1, C9, P9), arg(1, C9, V9), nb_setarg(1, C9, Q9), w(V9-C9) )),
             t(( D9 = c(0), setarg(1, D9, P9), D9 = c(W9), setarg(1, D9, Q9), w(W9-D9) )) )),
    t(( C10 = c(0), nb_setarg(1, C10, 1r3), arg(1, C10, V10), nb_setarg(1, C10, 2r3), w(V10-C10) )),
    t(( C11 = c(0), setarg(1, C11, f), arg(1, C11, V11), nb_setarg(1, C11, g(1)), w(V11-C11) )).

%% what backtracking takes back and leaves, the reads beside it
undone :-
    t(( C12 = c(0), nb_setarg(1, C12, f), arg(1, C12, V12), ( setarg(1, C12, h), fail ; true ), w(V12-C12) )),
    t(( C13 = c(0), ( nb_setarg(1, C13, f), fail ; true ), arg(1, C13, V13), nb_setarg(1, C13, g), w(V13-C13) )),
    t(( C14 = c(0), findall(V14, ( between(1, 3, I14), nb_setarg(1, C14, I14), arg(1, C14, V14) ), L14), w(L14-C14) )),
    t(( C15 = c(0), findall(V15, ( between(1, 3, I15), setarg(1, C15, I15), arg(1, C15, V15) ), L15), w(L15-C15) )),
    t(( C16 = c(0), forall(between(1, 3, I16), nb_setarg(1, C16, I16)), w(C16) )),
    t(( C17 = c(0), arg(1, C17, V17), ( setarg(1, C17, 1), arg(1, C17, W17), setarg(1, C17, 2), w(in(V17, W17, C17)), fail ; true ), w(V17-C17) )),
    t(( C18 = c(0), arg(1, C18, V18), ( nb_setarg(1, C18, 1), arg(1, C18, W18), nb_setarg(1, C18, 2), fail ; true ), w(V18-W18-C18) )).

%% a variable written into an argument is linked, and the argument follows it
linked :-
    t(( functor(C19, c, 1), setarg(1, C19, V19), V19 = 3, w(V19-C19) )),
    t(( functor(C20, c, 1), nb_setarg(1, C20, V20), V20 = 3, w(V20-C20) )),
    t(( functor(C21, c, 1), arg(1, C21, V21), ( setarg(1, C21, 5), fail ; true ), w(V21-C21) )),
    t(( C22 = c(0), nb_setarg(1, C22, 1), setarg(1, C22, V22), arg(1, C22, W22), V22 = 9, w(V22-W22-C22) )).

%% b_setval/2 writes its value as setarg/3 writes an argument
boxed :-
    t(( b_setval(sv_b1, 1), b_getval(sv_b1, V23), b_setval(sv_b1, 2), b_getval(sv_b1, W23), w(V23-W23) )),
    t(( b_setval(sv_b2, [V24]), V24 = 1, b_getval(sv_b2, X24), w(X24) )),
    t(( b_setval(sv_b3, a), b_getval(sv_b3, V25), ( b_setval(sv_b3, b), b_getval(sv_b3, W25), w(in(V25, W25)), fail ; true ), b_getval(sv_b3, X25), w(V25-X25) )),
    t(( b_setval(sv_b4, 1.5), b_getval(sv_b4, V26), b_setval(sv_b4, 2.5), w(V26) )).

%% a value older than the argument it is written into outlives the
%% backtracking the write outlives: the compound made after the value, by
%% functor/3, copy_term/2 or a clause's body
older :-
    t(( X27 is 2 + 3, functor(C27, c, 1), ( member(_, [1, 2]), nb_setarg(1, C27, X27), fail ; true ), w(C27) )),
    t(( X28 = k, copy_term(c(0), C28), ( between(1, 3, _), nb_setarg(1, C28, X28), fail ; true ), w(C28) )),
    t(( X29 is 2 ** 62, functor(C29, c, 1), ( member(_, [1, 2, 3]), nb_setarg(1, C29, X29), fail ; true ), w(C29) )),
    t(( old_in_clause(C30), w(C30) )),
    t(( X31 = 1.5, functor(C31, c, 2), ( member(_, [1, 2]), nb_setarg(2, C31, X31), fail ; true ), w(C31) )).

old_in_clause(C) :- X is 2 + 3, functor(C, c, 1), ( member(_, [1, 2]), nb_setarg(1, C, X), fail ; true ).
