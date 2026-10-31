%  setup_call_cleanup/3, setup_call_catcher_cleanup/4 and call_cleanup/2
%  (cocolog 3.1.0), run by BOTH SWI-Prolog and cocolog and the output
%  compared byte for byte: the setup once; the cleanup once, on the first
%  of the goal's exit with nothing left to retry, its failure, its ball, a
%  cut that takes it, a ball raised after it exited, or the end of the
%  goal that asked for it; the catcher each of those binds; and the
%  cleanup's bindings, failure, choice points and ball. A goal that leaves
%  a choice point here is mem/2, written as swipl's member/2 is, whose last
%  answer leaves none in either system (cocolog's own member/2 keeps one:
%  its clauses are the textbook pair). An error is shown as its formal term
%  and the predicate its context names; no unbound variable is written.

%  the last goal leaves its cleanup for the toplevel, which cuts it once
%  main has answered: `end(!)' is written after `last_line'
main :-
    catchers, cuts, balls, cleanups, setups, nested, builtins_cut,
    setup_call_catcher_cleanup(true, mem(_, [1, 2]), C, say(end(C))),
    say(last_line).

mem(X, [H|T]) :- mem_(T, X, H).
mem_(_, X, X).
mem_([H|T], X, _) :- mem_(T, X, H).

say(T) :- print(T), nl.

t(L, G) :-
    catch((G -> R = yes ; R = no), E, shown(E, R)),
    print(L-R), nl.

shown(error(F, context(P, _)), ex(F, P)) :- !.   % cocolint: C2 -- a core builtin's error, whose context is swipl's since 3.0.0 (card row C3)
shown(E, ex(E)).

catchers :-
    t(exit, setup_call_catcher_cleanup(true, true, C1, say(c1(C1)))),
    t(fail, setup_call_catcher_cleanup(true, fail, C2, say(c2(C2)))),
    t(exception, setup_call_catcher_cleanup(true, throw(oops), C3, say(c3(C3)))),
    t(all_answers, (findall(X4, setup_call_catcher_cleanup(true, mem(X4, [a, b]), C4, say(c4(C4))), L4),
                    say(L4))),
    t(last_answer, (setup_call_catcher_cleanup(true, mem(X5, [a, b]), C5, say(c5(C5, X5))), X5 == b,
                    say(x5))),
    t(retried_into_fail, (setup_call_catcher_cleanup(true, mem(X6, [1, 2]), C6, say(c6(C6))), X6 == 3)),
    t(retried_into_exit, (setup_call_catcher_cleanup(true, mem(X7, [1, 2]), C7, say(c7(C7))), X7 == 2,
                          say(got2))),
    t(retried_into_ball, (setup_call_catcher_cleanup(true, (mem(X8, [a, b]), (X8 == b -> throw(inb) ; true)),
                                                     C8, say(c8(C8))), X8 == a, fail)),
    t(catcher_bound_no, setup_call_catcher_cleanup(true, true, fail, say(not_run))),
    t(catcher_bound_yes, setup_call_catcher_cleanup(true, true, exit, say(run))),
    t(catcher_binds, catch(setup_call_catcher_cleanup(true, throw(err(1)), exception(err(N9)), say(n(N9))),
                           _, true)),
    t(catcher_after, (setup_call_catcher_cleanup(true, true, C10, true), say(after(C10)))),
    t(cut_in_goal, (setup_call_catcher_cleanup(true, (mem(X11, [1, 2]), !), C11, say(cg(C11))), say(x(X11)))).

cuts :-
    t(cut, (setup_call_catcher_cleanup(true, mem(X1, [a, b]), C1, say(k1(C1))), !, say(x1(X1)))),
    t(once, (once(setup_call_catcher_cleanup(true, mem(X2, [a, b]), C2, say(k2(C2)))), say(x2(X2)))),
    t(not, \+ setup_call_catcher_cleanup(true, mem(_, [a, b]), C3, say(k3(C3)))),
    t(if_then, (setup_call_catcher_cleanup(true, mem(_, [a, b]), C4, say(k4(C4))) -> say(then) ; true)),
    t(call_cut, call((setup_call_catcher_cleanup(true, mem(_, [1, 2]), C5, say(k5(C5))), !))),
    t(second_answer_cut, (setup_call_catcher_cleanup(true, mem(X6, [1, 2, 3]), C6, say(k6(C6))), X6 >= 2, !)),
    t(findall_cut, (findall(X7, (setup_call_catcher_cleanup(true, mem(X7, [a, b, c]), C7, say(k7(C7))),
                                 X7 == b, !), L7), say(L7))),
    t(in_body, cut_in_body),
    t(ite_in_body, ite_in_body),
    t(once_in_body, once_in_body),
    t(env_in_body, env_cut_in_body).

cut_in_body :-
    setup_call_catcher_cleanup(true, mem(X, [a, b]), C, say(kb(C))), !, say(xb(X)).

%  a construct after the body's first goal: the body is an environment, and
%  its `!' is one of the environment's units
env_cut_in_body :-
    setup_call_catcher_cleanup(true, mem(X, [a, b]), C, say(ke(C))),
    ( X == a -> say(a) ; say(not_a) ),
    !,
    say(xe(X)).

ite_in_body :-
    (   setup_call_catcher_cleanup(true, mem(X, [a, b]), C, say(ki(C)))
    ->  say(then(X))
    ;   say(else)
    ).

once_in_body :-
    once(setup_call_catcher_cleanup(true, mem(X, [a, b]), C, say(ko(C)))), say(x(X)).

balls :-
    t(external, catch((setup_call_catcher_cleanup(true, mem(X1, [a, b]), C1, say(e1(C1))), X1 == a,
                       throw(ext)), E1, say(caught(E1)))),
    t(external_det, catch((setup_call_catcher_cleanup(true, true, C2, say(e2(C2))), throw(after)),
                          E2, say(caught(E2)))),
    t(external_inner, catch((setup_call_catcher_cleanup(true, mem(_, [1, 2]), C3, say(e3(C3))), throw(z)),
                            z, say(gotz))).

cleanups :-
    t(binding, (setup_call_cleanup(true, true, X1 = 1), say(x1(X1)))),
    t(sees_goal, setup_call_cleanup(true, Z = 5, say(z(Z)))),
    t(fail_undone, setup_call_cleanup(true, (W = 1, fail), ( var(W) -> say(w(unbound)) ; say(w(W)) ))),
    t(fails, setup_call_cleanup(true, true, fail)),
    t(nondet, (setup_call_cleanup(true, true, mem(_, [1, 2])), say(after))),
    t(cut_inside, setup_call_cleanup(true, true, (!, say(cci)))),
    t(throws, setup_call_cleanup(true, true, throw(inclean))),
    t(throws_after_fail, setup_call_cleanup(true, fail, throw(inclean2))),
    t(throws_after_ball, setup_call_cleanup(true, throw(g), throw(inclean3))),
    t(throws_at_cut, (setup_call_cleanup(true, mem(_, [a, b]), throw(c)), !)),
    t(call_cleanup, call_cleanup(true, say(cc))).

setups :-
    t(setup_fails, setup_call_cleanup(fail, say(g), say(c))),
    t(setup_throws, setup_call_cleanup(throw(s), say(g), say(c))),
    t(setup_once, (setup_call_cleanup(mem(S, [1, 2]), true, say(c(S))), say(s(S)))),
    t(setup_first, setup_call_cleanup(say(s), true, _)),
    t(goal_checked_after, setup_call_cleanup(say(s2), 1, true)),
    t(goal_var, setup_call_cleanup(true, _, true)),
    t(goal_not_callable, setup_call_cleanup(true, 1, true)),
    t(setup_not_callable, setup_call_cleanup(1, true, true)),
    t(setup_var, setup_call_cleanup(_, true, true)).

nested :-
    t(both_cut, (setup_call_catcher_cleanup(true,
                     setup_call_catcher_cleanup(true, mem(Y, [1, 2]), I, say(inner(I))),
                     O, say(outer(O))), !, say(y(Y)))),
    t(both_ball, catch(setup_call_catcher_cleanup(true,
                           setup_call_catcher_cleanup(true, throw(q), I2, say(i2(I2))),
                           O2, say(o2(O2))), q, say(gotq))),
    t(both_external, catch((setup_call_catcher_cleanup(true,
                                setup_call_catcher_cleanup(true, mem(_, [1, 2]), I3, say(i3(I3))),
                                O3, say(o3(O3))), throw(r)), r, say(gotr))).

%  what a builtin keeps one answer of cuts while it is still the builtin's:
%  with_output_to/2's text holds the cleanup's output
builtins_cut :-
    t(with_output_to, (with_output_to(atom(A),
                           setup_call_catcher_cleanup(true, mem(_, [1, 2]), C, say(w(C)))),
                       writeq(A), nl)),
    t(aggregate_all, (aggregate_all(count, setup_call_catcher_cleanup(true, mem(_, [1, 2]), C2,
                                                                      say(ag(C2))), N),
                      say(N))),
    t(forall, forall(setup_call_catcher_cleanup(true, mem(_, [a, b]), C3, say(fa(C3))), true)).

%  a directive's goal that leaves its cleanup pending: the load cuts it once
%  the goal has answered, before main runs
:- initialization(pending_at_load).

pending_at_load :-
    setup_call_catcher_cleanup(true, mem(_, [1, 2]), C, say(load(C))),
    say(load_end).
