%% call/N where swipl calls a predicate it builds -- held to swipl 9.0.4
%% (cocolog 3.78.8).
%%
%% swipl's I_USERCALLN resolves the goal call/N builds by its functor, so
%% call/N of `@' calls boot/init.pl's @/2 -- a frame, its errors
%% system:(@)/2's, its goal two below it, a `'<meta-call>'/1' between --
%% and call/N of `|' and of `:' finds no predicate: the unknown procedure,
%% named by the frame call/N runs in, whose frame a depth limit fails at its
%% call port before the error. A meta-called goal that is call/N, and a
%% variable of a meta-called structure bound to one as it ran, is call/N's
%% own frame, which call_with_depth_limit/3 counts. Through 3.78.7 call/N
%% of `@' ran the construct in place, call/N of `|' and of `:' ran the
%% disjunction and the qualified goal, and call/N bound so was no frame.
%%
%% Each probe is called under catch/3 and printed as the goal, then yes,
%% no or the ball, every variable written `_'. Left out (COMPAT.md): call/N
%% written in a clause with the closure `:' (`p :- call(:, user, a)'),
%% whose closure swipl's compiler reads as a qualified variable; a part a
%% construct hands over (a condition, a branch, a negation's goal) that a
%% variable of the structure bound as it ran made call/N, and a structure
%% built with a variable it ran after the variable was bound to call/N,
%% where swipl's compile sees the variable's state when the structure was
%% called and cocolog's how the structure was built.

e(G) :-
    (   catch(( G -> R = yes ; R = no ), E, R = E) -> true ; R = failed ),
    copy_term(G-R, G2-R2),
    term_variables(G2-R2, Vs), maplist(=('$VAR'('_')), Vs),
    print(G2), write('  ==>  '), print(R2), nl.

main :- forall(p(G), e(G)).

cp_a.
cp_b.
cp_m(1).
cp_m(2).
dp(X) :- X = 1.
dq :- dp(_).

%% call/N of `|' and `:': the unknown procedure
p(call('|', cp_a, cp_b)).
p(call('|', fail, cp_b)).
p(call('|'(cp_a), cp_b)).
p(call(:, user, cp_a)).
p(call(:, lists, cp_a)).
p(call(call, '|', cp_a, cp_b)).
p(call(call('|', cp_a, cp_b))).
p(call((true, call('|', cp_a, cp_b)))).
p(call(user:('|'), cp_a, cp_b)).
p(with_output_to(string(_), call('|', cp_a, cp_b))).
p(findall(x, call('|', cp_a, cp_b), _)).
%% call/N of @/2: system:(@)/2's errors
p(call(@, cp_a, 1)).
p(call(@, _, user)).
p(call(@, 1, user)).
p(call(@, cp_a, _)).
p(call(@(cp_a), 1)).
p(call(@, nope_cp, user)).
p(call(call(@, cp_a, 1))).
p(call((true, call(@, cp_a, 1)))).
p(with_output_to(string(_), call(@, cp_a, 1))).
p(with_output_to(string(_), @(cp_a, 1))).
p(with_output_to(string(_), @(1, user))).
p(setup_call_cleanup(call(@, cp_a, 1), true, true)).
p(setup_call_cleanup(true, true, call(@, cp_a, 1))).
p(format(atom(_), '~@', [call(@, cp_a, 1)])).
p(call(@(@(cp_a, user)), 1)).
%% the answers
p(call(@, (cp_a, cp_b), user)).
p((call(@, cp_m(X), user), X == 2)).
p(findall(X, call(@, cp_m(X), user), [1, 2])).
p(call(@, fail, user)).
p((call(@, !, user), fail ; true)).
p(call(@(cp_a), user)).
p(call(@, call(cp_a), user)).
p(forall(call(@, cp_m(X), user), integer(X))).
p(call(call(@, cp_a, user))).
p((G = call(@, cp_m(X), user), G, X == 2)).
%% the depth call_with_depth_limit/3 counts
p(call_with_depth_limit(call(@, dq, user), 10, _)).
p(call_with_depth_limit(call(@, (dq, dq), user), 10, _)).
p(call_with_depth_limit((true, call(@, dq, user)), 10, _)).
p(call_with_depth_limit(call(@(dq), user), 10, _)).
p(call_with_depth_limit(call(@, \+ fail, user), 10, _)).
p(call_with_depth_limit(call(@(dq, user)), 10, _)).
p(call_with_depth_limit(with_output_to(string(_), @(dq, user)), 10, _)).
p(call_with_depth_limit(with_output_to(string(_), call(@, dq, user)), 10, _)).
p(call_with_depth_limit(setup_call_cleanup(true, true, @(dq, user)), 10, _)).
p(call_with_depth_limit(call('|', dq, dq), 1, _)).
p(call_with_depth_limit(call('|', dq, dq), 2, _)).
p(call_with_depth_limit((true, call('|', dq, dq)), 1, _)).
p(call_with_depth_limit((true, call('|', dq, dq)), 2, _)).
p(call_with_depth_limit(call(:, user, dq), 1, _)).
p(call_with_depth_limit(call(:, user, dq), 2, _)).
p(call_with_depth_limit((G = call(dq), G), 10, _)).
p(call_with_depth_limit((G = call((dq, dq)), G), 10, _)).
p(call_with_depth_limit((G = call(dq), (true, G)), 10, _)).
p(call_with_depth_limit((G = call(call, dq), G), 10, _)).
p(call_with_depth_limit((G = call(@, dq, user), G), 10, _)).
p(call_with_depth_limit((G = once(dq), G), 10, _)).
p(call_with_depth_limit(once(call((dq, dq))), 10, _)).
p(call_with_depth_limit(catch(call(dq), _, true), 10, _)).
