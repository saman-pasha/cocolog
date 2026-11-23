%% The control predicates swipl calls as predicates -- held to swipl 9.0.4
%% (cocolog 3.78.6).
%%
%% call/N whose closure names `,', `;', `->', `*->', `\+' or `$' calls
%% boot/init.pl's predicate of it (I_USERCALLN resolves a predicate by the
%% functor and compiles nothing): its errors are that predicate's
%% (`context(system:(',')/2, _)', a structure that is no goal shown with
%% its parts said of user), a call/N among its parts a frame of its own
%% (`system:call/1'), and call_with_depth_limit/3 counts its frame, the
%% meta-call its clause makes and the parts below. A setup, a cleanup,
%% with_output_to/2's and format/2's `~@' goal are called so too
%% (callProlog()). Through 3.78.5 call/N ran the structure in place: its
%% errors were `'<meta-call>'/1''s and the depth a level short.
%%
%% Each probe is called under catch/3 and printed as the goal, then yes,
%% no or the ball, every variable written `_'. Left out (COMPAT.md):
%% call/N's inference counts, which are cocolog's own. call/N whose closure
%% is `@', `|' or `:' is test/files/call_preds.pl's since 3.78.8.

e(G) :-
    (   catch(( G -> R = yes ; R = no ), E, R = E) -> true ; R = failed ),
    copy_term(G-R, G2-R2),
    term_variables(G2-R2, Vs), maplist(=('$VAR'('_')), Vs),
    print(G2), write('  ==>  '), print(R2), nl.

main :- forall(p(G), e(G)).

dp(X) :- X = 1.
dq :- dp(_).
dr :- call(',', dq, dq).

%% the errors
p(call(',', true, 1)).
p(call(;, fail, foo:nope)).
p(call(\+, 1)).
p(call(->, true, _)).
p(call(',', nope_x, true)).
p(call(\+, \+ 1)).
p(call(',', true, _)).
p(call(',', true, call(1))).
p(call($, member(_, [1, 2]))).
p(call($, fail)).
p(call($, 1)).
p(call($, (true ; true))).
p(call(;, true, 1)).
p(call(',')).
p(call(','(a, b, c), d)).
p(call(user:1)).
p(setup_call_cleanup(\+ 1, true, true)).
p(setup_call_cleanup((true, 1), true, true)).
p(setup_call_cleanup((true, call(1)), true, true)).
p(with_output_to(string(_), (true, 1))).
p(with_output_to(string(_), \+ 1)).
p(with_output_to(string(_), (true, call(1)))).
%% the answers
p(call(@, true, user)).
p(call(call, true)).
p(call(lists:(','), true, true)).
p(call(',', X = 1, X == 1)).
p((call(;, X = 1, X = 2), X == 2)).
p(findall(X, call(;, X = 1, X = 2), [1, 2])).
p(call(->, fail, true)).
p(call(*->, member(X, [1, 2]), X > 1)).
p((call(',', !, fail) ; true)).
p(forall(member(G, [true, (true, true)]), call(',', G, G))).
p((call(\+, X = 1), var(X))).
p(call(',', fail, _)).
p(maplist(;(fail), [true, true])).
p(maplist(','(true), [true])).
%% the depth call_with_depth_limit/3 counts
p(call_with_depth_limit(call(',', dq, dq), 10, _)).
p(call_with_depth_limit(call(;, fail, dq), 10, _)).
p(call_with_depth_limit(call(\+, fail), 10, _)).
p(call_with_depth_limit(call(->, dq, dq), 10, _)).
p(call_with_depth_limit(call(*->, dq, dq), 10, _)).
p(call_with_depth_limit(call($, dq), 10, _)).
p(call_with_depth_limit(call(user:(','), dq, dq), 10, _)).
p(call_with_depth_limit(dr, 10, _)).
p(call_with_depth_limit(call(','(dq), dq), 10, _)).
p(call_with_depth_limit(call(;, (dq, dq), dq), 10, _)).
p(call_with_depth_limit(call(\+, \+ dq), 10, _)).
p(call_with_depth_limit(call(',', dq, dq), 3, _)).
p(call_with_depth_limit(call(',', dq, dq), 4, _)).
p(call_with_depth_limit(call(',', dq, dq), 5, _)).
p(call_with_depth_limit(findall(x, call(',', dq, dq), _), 10, _)).
p(call_with_depth_limit(maplist(','(dq), [dq]), 10, _)).
p(call_with_depth_limit(with_output_to(string(_), (dq, dq)), 10, _)).
p(call_with_depth_limit(with_output_to(string(_), dq), 10, _)).
p(call_with_depth_limit(with_output_to(string(_), call(dq)), 10, _)).
p(call_with_depth_limit(with_output_to(string(_), \+ fail), 10, _)).
p(call_with_depth_limit(format(atom(_), '~@', [(dq, dq)]), 10, _)).
p(call_with_depth_limit(setup_call_cleanup((dq, dq), true, (dq ; true)), 10, _)).
p(call_with_depth_limit(setup_call_cleanup(true, true, (dq, dq)), 10, _)).
p(call_with_depth_limit(setup_call_cleanup(true, true, \+ fail), 10, _)).
p(call_with_depth_limit(setup_call_cleanup(true, true, call(dq)), 10, _)).
p(call_with_depth_limit(setup_call_cleanup(call(dq), true, true), 10, _)).
p(call_with_depth_limit(setup_call_cleanup(true, true, (dq -> dq)), 10, _)).
