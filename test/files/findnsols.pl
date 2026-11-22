%  findnsols/4,5, swipl 9.0.4's (cocolog 3.72.0): COMPAT.md's fifth group
%  of small built-ins, the solutions'. The case holds:
%  - the chunks: the goal's answers a chunk at a time, each chunk an
%    answer of findnsols/4,5 and the next found on backtracking into it,
%    in the order the goal found them, findnsols/5's ending in its Tail;
%  - the last chunk: a chunk the goal's last answer fills is the last
%    where the goal leaves no choice point, and findnsols/4,5 too, and
%    where the goal ends otherwise the answers after the last full chunk
%    are one more, [] where there are none;
%  - the count: an integer, or count(N), whose N is read again before
%    each chunk after the first, so nb_setarg/3 sizes the next -- 0 or a
%    negative N the rest of the answers as one chunk;
%  - the copies: the template and the goal copied once, nothing of the
%    caller's bound, each answer a copy of its own (fresh variables, a
%    cyclic term, floats and strings across a collection);
%  - a List given: unified once its chunk is made, the chunk spent
%    whether it unified or not;
%  - the errors: the count's -- domain_error(not_less_than_zero, N),
%    type_error(integer, C), instantiation_error, the context unbound --
%    and the goal's, named system:setup_call_catcher_cleanup/4;
%  - a cut after a chunk and inside the goal, and findnsols/4 under
%    findall/3, forall/2, aggregate_all/3 and itself;
%  - the guards: $/0 and $/1 over a findnsols/4 that leaves a choice
%    point and one that does not;
%  - the two as predicate_property/2, current_predicate/1 and clause/2
%    see them.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.71.0 cocolog had neither, and a call raised existence_error.
%  Not here, cocolog's own: a findnsols/4 a frozen machine was inside
%  (`cocolog step', test/engine.pl), and findnsols/4 in a thread and a
%  green task (test/thread.pl, test/async.pl).

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
    % cocolint: C2 -- each ball here is a builtin's or the goal's, whose context names it as swipl's
    (   R = caught(error(F, context(C, _)))
    ->  pv(L-caught(F, C))
    ;   pv(L-R)
    ),
    nl.

%% every answer of a goal, then how it ended
all(L, G) :-
    catch(( G, pv(L-G), nl, fail ; true ), E, ( pv(L-caught(E)), nl )).

%% each chunk of findnsols/4, and whether it was the call's last answer
ch(L, N, T, G) :-
    catch(( call_cleanup(findnsols(N, T, G, C), Det = true),
            ( Det == true -> D = last ; D = more ),
            pv(L-C-D), nl, fail
          ; true ),
          E, ( pv(L-caught(E)), nl )).

%% the properties swipl's predicate_property/2 gives a system predicate,
%% less those that move with the build and the file swipl's is read from
pp(H) :-
    findall(P, ( predicate_property(H, P),
                 \+ memberchk(P, [defined, size(_), last_modified_generation(_),
                                  number_of_clauses(_), number_of_rules(_),
                                  file(_), line_count(_)]) ), Ps),
    functor(H, N, A), print(N/A-Ps), nl.

p(1).
p(2).
p(3).
p(4).

%% a clause guarded by $/0 whose findnsols/4 leaves a choice point, and
%% one whose call leaves none
gq :- $, findnsols(2, X, member(X, [a,b,c]), _), true.
gr :- $, findnsols(2, X, member(X, [a,b]), _), true.

main :-
    chunks,
    counts,
    copies,
    given,
    errors,
    control,
    guards,
    seen.

chunks :-
    ch(c1, 5, I1, between(1, 12, I1)),
    ch(c2, 2, I2, between(1, 4, I2)),
    ch(c3, 2, I3, p(I3)),
    ch(c4, 4, I4, between(1, 4, I4)),
    ch(c5, 2, I5, between(1, 5, I5)),
    ch(c6, 2, I6, ( member(I6, [a,b]) ; fail )),
    ch(c7, 2, I7, ( member(I7, [a,b,c]) ; fail )),
    ch(c8, 3, I8, fail),
    ch(c9, 2, X9-Y9, member(X9-Y9, [1-a, 2-b, 3-c])),
    ch(c10, 2, I10, ( member(I10, [1,2,3,4,5]), I10 > 1 )),
    ch(c11, 1, I11, member(I11, [only])),
    t(c12, findnsols(2, I12, between(1, inf, I12), L12)),
    all(c13, findnsols(1, I13, member(I13, [a,b]), L13, T13)),
    all(c14, findnsols(2, I14, member(I14, [a,b,c]), L14, [end])),
    all(c15, findnsols(2, I15, ( member(I15, [1,2,3,4,5]), I15 > 1 ), L15, T15)),
    all(c16, findnsols(2, I16, fail, L16, T16)).

counts :-
    ch(n1, 0, I1, between(1, 4, I1)),
    ch(n2, count(2), I2, between(1, 5, I2)),
    C3 = count(2),
    all(n3, ( findnsols(C3, I3, between(1, 7, I3), L3), nb_setarg(1, C3, 3) )),
    C4 = count(2),
    all(n4, ( findnsols(C4, I4, between(1, 7, I4), L4), nb_setarg(1, C4, 0) )),
    C5 = count(2),
    all(n5, ( findnsols(C5, I5, between(1, 7, I5), L5), nb_setarg(1, C5, -1) )),
    C6 = count(1),
    forall(( findnsols(C6, I6, between(1, 9, I6), L6),
             arg(1, C6, K6), K7 is K6 + 1, nb_setarg(1, C6, K7) ),
           ( pv(n6-L6), nl )).

copies :-
    t(k1, ( X1 = 5, findnsols(2, X1, member(X1, [1,5]), L1) )),
    t(k2, ( findnsols(2, I2, between(1, 3, I2), L2), var(I2) )),
    t(k3, ( findnsols(3, Z3, member(Z3, [V1, V2, V1]), [P3, Q3, R3]),
            P3 \== Q3, P3 \== R3, Q3 \== R3, var(P3), P3 \== V1 )),
    t(k4, ( findnsols(1, X4, X4 = f(X4), [A4]), cyclic_term(A4), A4 = f(B4), B4 == A4 )),
    all(k5, findnsols(2, X5-F5-S5, ( member(X5, [1,2,3,4,5]), F5 is X5 / 7,
                                     atom_concat(s, X5, A5), atom_string(A5, S5),
                                     garbage_collect ), L5)),
    all(k6, findnsols(2, X6, ( member(X6, [1.5, 2.25, 3.125]), garbage_collect ), L6)),
    %% a float and a string an answer holds, made again after a collection
    %% that kept only the chunk's earlier answers to name them
    all(k7, findnsols(3, F7-S7, ( member(X7, [1,2,3,4]), F7 is X7 / 7,
                                  atom_concat(t, X7, A7), atom_string(A7, S7),
                                  garbage_collect, _ is X7 * 1.5 + 0.25,
                                  atom_string(zz, _) ), L7)).

given :-
    t(g1, findnsols(2, I1, member(I1, [a,b,c,d,e]), [c|T1])),
    t(g2, findnsols(2, I2, member(I2, [a,b,c,d,e]), [a,b])),
    t(g3, findnsols(2, I3, member(I3, [a,b,c]), [x|_])),
    t(g4, findnsols(2, I4, member(I4, [a,b,c]), [c])),
    t(g5, ( findnsols(2, I5, between(1, 6, I5), L5), L5 = [3|_] )).

errors :-
    t(e1, findnsols(-1, I1, true, L1)),
    t(e2, findnsols(a, I2, true, L2)),
    t(e3, findnsols(_, I3, true, L3)),
    t(e4, findnsols(1.0, I4, true, L4)),
    t(e5, findnsols(count(a), I5, true, L5)),
    t(e6, findnsols(count(-2), I6, true, L6)),
    t(e7, findnsols(count(_), I7, true, L7)),
    t(e8, findnsols(f(1), I8, true, L8)),
    t(e9, findnsols(-1, I9, true, L9, T9)),
    t(e10, findnsols(2, I10, foo_undefined(I10), L10)),
    t(e11, findnsols(2, I11, 3, L11)),
    t(e12, findnsols(2, I12, _, L12)),
    t(e13, findnsols(2, I13, ( I13 = 1 ; throw(boom) ), L13)),
    all(e14, findnsols(1, I14, ( member(I14, [a,b]) ; throw(x) ), L14)),
    t(e15, findnsols(0, I15, foo_undefined(I15), L15)),
    t(e16, findnsols(-1, I16, foo_undefined(I16), L16)).

control :-
    t(o1, ( findnsols(2, I1, member(I1, [a,b,c,d]), L1), ! )),
    t(o2, findnsols(2, I2, ( member(I2, [a,b,c]), ! ), L2)),
    t(o3, findall(L3, findnsols(2, I3, between(1, 5, I3), L3), Ls3)),
    t(o4, forall(findnsols(3, I4, between(1, 10, I4), L4), ( length(L4, N4), N4 =< 3 ))),
    t(o5, aggregate_all(count, findnsols(3, I5, between(1, 10, I5), _), N5)),
    all(o6, findnsols(2, L6, findnsols(1, Y6, member(Y6, [a,b,c]), L6), M6)),
    t(o7, findall(L7-M7, ( findnsols(2, I7, member(I7, [a,b,c]), L7),
                           findnsols(1, J7, member(J7, [x,y]), M7) ), Ls7)),
    t(o8, ( findnsols(2, I8, between(1, 4, I8), L8), findall(K8, member(K8, L8), Ks8),
            Ks8 == [3,4] )),
    t(o9, ( findnsols(1, I9, member(I9, [a,b,c]), L9), L9 == [b] )).

guards :-
    t(d1, catch(gq, E1, true)),
    t(d2, catch(gr, E2, true)),
    t(d3, catch($(findnsols(2, X3, member(X3, [a,b,c]), _)), E3, true)),
    t(d4, catch($(findnsols(2, X4, member(X4, [a,b]), _)), E4, true)).

seen :-
    pp(findnsols(_, _, _, _)),
    pp(findnsols(_, _, _, _, _)),
    t(s1, current_predicate(findnsols/4)),
    t(s2, current_predicate(findnsols/5)),
    t(s3, ( clause(findnsols(A3, B3, C3, D3), Body3), Body3 == findnsols(A3, B3, C3, D3, []) )),
    t(s4, ( predicate_property(findnsols(_, _, _, _), number_of_clauses(N4)), N4 > 0 )).
