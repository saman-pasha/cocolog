%% What test/gc.pl runs in a child process to prove that a proof goes on as
%% it was across heap collections: once with `COCOLOG_GC_CELLS=1000', so
%% the collector runs every thousand cells and every root it has is moved
%% many times over, and once without, where nothing here comes near the
%% floor and nothing is collected. The two outputs must be the same but for
%% the last line, which says whether a collection happened.
%%
%% Each line exercises one thing the collector must not disturb: choice
%% points and the answers behind them, a binding a backtrack must undo, a
%% ball thrown across collections, a cut's barrier, live lists and floats
%% and strings, the knowledge base written mid-loop, sorting and copying,
%% globals, a recursion that leaves a choice point per level, the if-then-
%% else and the soft cut, findall, and an error raised by a builtin.

burn(0) :- !.
burn(N) :- N1 is N - 1, burn(N1).

t1 :- ( member(X, [1,2,3,4,5]), burn(3000), X > 3, write(t1(X)), nl, fail ; true ).

t2 :- V = f(A), ( member(Y, [1,2,3]), A = Y, burn(3000), Y >= 3 -> true ; true ),
      write(t2(V)), nl,
      W = g(B), ( member(Z, [x,y]), B = Z, burn(3000), fail ; true ),
      ( var(B) -> write(t2(unbound)) ; write(t2(bound(B))) ), nl,
      ( W = g(B) -> write(t2(shared)) ; write(t2(lost)) ), nl.

t3 :- catch(( burn(5000), numlist(1, 2000, L), throw(ball(L)) ), ball(M),
            ( length(M, N), write(t3(N)), nl )).

t4 :- once(( member(X, [1,2,3]), burn(3000), X > 1 )), write(t4(X)), nl,
      ( member(Y, [a,b,c]), burn(2000), Y == b, ! ; Y = none ), write(t4(Y)), nl.

t5 :- numlist(1, 50000, L), burn(20000), sum_list(L, S), write(t5(S)), nl,
      X is 1.5 * 3, burn(5000), Y is X + 0.25, write(t5(Y)), nl,
      atom_string(hello, Str), burn(5000), string_concat(Str, " world", R),
      string_length(R, RL), write(t5(R, RL)), nl.

:- dynamic gcp_cnt/1.
t6 :- retractall(gcp_cnt(_)), assertz(gcp_cnt(0)),
      ( between(1, 300, I), burn(200), retract(gcp_cnt(C)), C1 is C + I,
        assertz(gcp_cnt(C1)), fail
      ; true ),
      gcp_cnt(T), write(t6(T)), nl.

t7 :- numlist(1, 3000, L0), reverse(L0, L1), burn(5000), msort(L1, L2),
      last(L2, La), burn(5000), copy_term(f(L2, _), f(C, _)), length(C, Lc),
      write(t7(La, Lc)), nl.

t8 :- nb_setval(gcp_k, big(1, 2, 3)), burn(10000), nb_getval(gcp_k, V), write(t8(V)), nl.

nat(0).
nat(N) :- nat(M), N is M + 1.
t9 :- nat(N), N >= 2000, !, write(t9(N)), nl.

t10 :- ( \+ ( burn(4000), fail ) -> write(t10(negation)) ; write(t10(wrong)) ), nl,
       ( ( member(X, [1,2,3]), burn(2000), X > 1 ) *-> write(t10(X)) ; write(t10(none)) ), nl.

t11 :- burn(5000), findall(X-Y, ( member(X, [1,2,3]), Y = X ), L), burn(5000), write(t11(L)), nl.

t12 :- burn(3000), catch(atom_length(_, _), error(E, _), ( write(t12(E)), nl )).

main :- t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12,
        statistics(heap_collections, G),
        ( G > 0 -> write(collected(yes)) ; write(collected(no)) ), nl.
