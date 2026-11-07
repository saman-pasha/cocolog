%% call/N inside the goal of a search a clause started -- held to swipl
%% 9.0.4 (cocolog 3.43.0).
%%
%% swipl's findall/3, findall/4, bagof/3, setof/3, forall/2 and
%% aggregate_all/3 are clauses that meta-call their goal, and a goal that
%% is a control structure -- a conjunction, a disjunction, an if-then-else,
%% a soft cut, \+ -- is compiled into a '<meta-call>'/1 frame, in which
%% call/N is compiled in place (I_USERCALL): an error of the goal call/N
%% runs, or of call/N's own goal that is no goal, names '<meta-call>'/1.
%% The goal itself, when it is call/N, is called as call/N, a frame of its
%% own; so is call/N under once/1, ignore/1, not/1 or catch/3, each of which
%% meta-calls its argument afresh, and a call/N that a variable of the
%% structure was bound to as it ran. A search C starts -- with_output_to/2
%% -- compiles the structure into a '<meta-call>'/1 too, but runs call/N as
%% a frame of its own. Through 3.42.3 cocolog named call/N's own frame for
%% every call/N at a search's root: context(system:call/2, _) where swipl's
%% is context(system:'<meta-call>'/1, _).
%%
%% Each probe is called under catch/3 and printed as the goal, then yes,
%% no or the ball, every variable written `_'. Left out: setup_call_cleanup/3
%% with a structure for its setup goal, whose call/N swipl names
%% differently again ('$c_call_prolog'/0's frame).

e(G) :-
    (   catch(( G -> R = yes ; R = no ), E, R = E) -> true ; R = failed ),
    copy_term(G-R, G2-R2),
    term_variables(G2-R2, Vs), maplist(=('$VAR'('_')), Vs),
    print(G2), write('  ==>  '), print(R2), nl.

main :- forall(p(G), e(G)).

g2(X) :- $, member(X, [1, 2]).
g3(X) :- member(X, [1, 2]).
ok(_).

%% call/N in a structure of findall/3's goal: '<meta-call>'/1
p(findall(x, (true, call(foo_undef)), _)).
p(findall(x, (true, call(foo_undef, a, b)), _)).
p(findall(x, (true, call(1, a)), _)).
p(findall(x, (true, call(_, a)), _)).
p(findall(x, (true, call(1)), _)).
p(findall(x, (true, call(_)), _)).
p(findall(x, (true, call(lists:foo_undef, a)), _)).
p(findall(x, (true, call(foo_mod:bar, a)), _)).
p(findall(x, (G = foo_undef, call(G)), _)).
p(findall(x, (true, (true, call(foo_undef, a))), _)).
p(findall(x, (true ; call(foo_undef, a)), _)).
p(findall(x, (fail ; call(foo_undef, a)), _)).
p(findall(x, (true -> call(foo_undef, a) ; true), _)).
p(findall(x, (true, call(foo_undef, a) -> true ; true), _)).
p(findall(x, (call(foo_undef, a) *-> true ; true), _)).
p(findall(x, (fail ; true, call(foo_undef, a)), _)).
p(findall(x, (call(foo_undef, a), true), _)).
p(findall(x, (call(foo_undef), true), _)).
p(findall(x, (call(call, foo_undef), true), _)).
p(findall(x, \+ call(foo_undef, a), _)).
p(findall(x, \+ \+ call(foo_undef, a), _)).
p(findall(x, (true, \+ call(foo_undef, a)), _)).
p(findall(x, (true, call((true, call(foo_undef, a)))), _)).
p(findall(x, (true, findall(y, (true, call(foo_undef, a)), _)), _)).
%% ... and in a structure of the other searches a clause starts
p(findall(x, (true, call(foo_undef, a)), _, [])).
p(bagof(x, (true, call(foo_undef, a)), _)).
p(bagof(x, X^(true, call(foo_undef, X)), _)).
p(setof(x, (true, call(foo_undef, a)), _)).
p(aggregate_all(count, (true, call(foo_undef, a)), _)).
p(aggregate_all(count, (true ; call(foo_undef, a)), _)).
p(aggregate_all(bag(x), (true, call(foo_undef, a)), _)).
p(aggregate_all(max(1), (true, call(foo_undef, a)), _)).
p(aggregate_all(count, X^(true, call(foo_undef, X)), _)).
p(forall((true, call(foo_undef)), true)).
p(forall((true, call(foo_undef, a)), true)).
p(forall(true, (call(foo_undef), true))).
p(forall(true, (true, call(foo_undef, a)))).
p(forall(true, (true ; call(foo_undef, a)))).

%% call/N as the goal itself, or meta-called afresh: call/N's own frame;
%% and catch/3's goal its frame's, a plain one named catch/3
p(findall(x, call(foo_undef, a), _)).
p(findall(x, call(call, foo_undef, a), _)).
p(findall(x, (G = call(foo_undef, a), G), _)).
p(findall(x, (G = foo_undef, call(G, a)), _)).
p(findall(x, (true, once(call(foo_undef, a))), _)).
p(findall(x, (true, ignore(call(foo_undef, a))), _)).
p(findall(x, (true, not(call(foo_undef, a))), _)).
p(findall(x, (true, catch(call(foo_undef, a), nope, true)), _)).
p(findall(x, (true, catch(foo_undef, nope, true)), _)).
p(findall(x, (true, catch((true, foo_undef), nope, true)), _)).
p(findall(x, catch(foo_undef, nope, true), _)).
p(findall(x, (true, call(call, foo_undef)), _)).
p(findall(x, (true, call(call, foo_undef, a)), _)).
p(findall(x, (true, call(call(foo_undef), a)), _)).
p(findall(x, (true, findall(y, call(foo_undef, a), _)), _)).
p(findall(x, (true, forall(call(foo_undef, a), true)), _)).
p(findall(x, (true, apply(foo_undef, [a])), _)).
p(aggregate_all(count, call(foo_undef, a), _)).
p(forall(call(foo_undef, a), true)).
p(forall(true, call(foo_undef, a))).
p(bagof(x, call(foo_undef, a), _)).

%% a search C starts: call/N a frame of its own
p(with_output_to(string(_), (true, call(foo_undef)))).
p(with_output_to(string(_), (true, call(foo_undef, a)))).
p(with_output_to(string(_), (true ; call(foo_undef, a)))).
p(with_output_to(string(_), \+ call(foo_undef, a))).
p(with_output_to(string(_), (true, call(1, a)))).
p(with_output_to(string(_), call(foo_undef, a))).

%% a plain goal of the structure, and what call/N's goal does, as before
p(findall(x, (true, foo_undef), _)).
p(findall(X, (member(X, [1, 2, 3]), call(succ, X, _)), [1, 2, 3])).
p(findall(X, (member(X, [1, 2, 3]), call(!)), [1, 2, 3])).
p(findall(X, (member(X, [1, 2, 3]), call((!, true))), [1, 2, 3])).
p(findall(X, (member(X, [1, 2, 3]), call(ok, X)), [1, 2, 3])).
p(findall(X, (true, call(g3, X)), [1, 2])).
p(findall(X, (true, call(g2, X)), _)).
p(findall(X, (call(g2, X), true), _)).
p(findall(X, call(g2, X), _)).
p(forall((true, call(g3, X)), integer(X))).
p(aggregate_all(count, (true, call(g3, _)), 2)).
p(aggregate_all(sum(X), (true, call(g3, X)), 3)).
