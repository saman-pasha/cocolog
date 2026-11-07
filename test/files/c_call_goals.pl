%% The goals swipl's C calls, and the qualifier a meta-call strips -- held
%% to swipl 9.0.4 (cocolog 3.44.0).
%%
%% with_output_to/2, format/2's `~@', setup_call_cleanup/3's setup (which
%% sig_atomic/1 calls) and its cleanup are C in swipl, and call their goal
%% by callProlog(): its qualifiers off, a plain goal in the frame
%% '$c_call_prolog'/0, a control construct as the system's predicate of it
%% in boot/init.pl -- ','/2, (->)/2 and (*->)/2 call `(M:A, M:B)' again,
%% (;)/2 calls `M:(A ; B)' where its arguments share M, (\+)/1 and ($)/1
%% meta-call theirs in their own frame, `$(Goal) :- $(Goal)' showing the
%% goal it compiled, `call(user:G)'. The cleanup is called by the cleanup
%% handler, which compiles a structure as call/1 does; the goal of
%% setup_call_cleanup/3 runs in setup_call_catcher_cleanup/4's own frame.
%%
%% A meta-call strips the qualifiers of its goal and compiles the rest in
%% the innermost module: what nothing defines is named by that module
%% (`lists:foo_undef/0'), call/N in a structure stays in place, its goal
%% that module's, and a goal of a construct's name with an arity no
%% construct has is the module's (`lists:true/1'). A qualifier written in
%% code that runs -- a clause, a part of a structure a meta-call compiled
%% -- calls `M:call(G)' as call/N, a frame of its own, and has M said of
%% each goal of a structure. When the goal and its cleanup both raise, the
%% more urgent ball wins: time_limit_exceeded over error(_, _) over any
%% other, the goal's where they are as urgent.
%%
%% Each probe is called under catch/3 and printed as the goal, then yes,
%% no or the ball, every variable written `_'. Left out (COMPAT.md): a goal
%% swipl's C calls whose qualifier is unbound or no atom, or that is `A|B',
%% which swipl calls as (:)/2 or ('|')/2 and cocolog takes apart;
%% `user:call(G)' in a clause, which cocolog stores as call(G); a
%% determinism error's goal under a qualifier, which swipl shows
%% decompiled.

e(G) :-
    (   catch(( G -> R = yes ; R = no ), E, R = E) -> true ; R = failed ),
    copy_term(G-R, G2-R2),
    term_variables(G2-R2, Vs), maplist(=('$VAR'('_')), Vs),
    print(G2), write('  ==>  '), print(R2), nl.

main :- forall(p(G), e(G)).

%% with_output_to/2: a plain goal, the constructs, their arguments
p(with_output_to(string(_), foo_undef)).
p(with_output_to(string(_), _)).
p(with_output_to(string(_), 1)).
p(with_output_to(string(_), (true, (true, call(foo_undef))))).
p(with_output_to(string(_), (fail ; call(foo_undef)))).
p(with_output_to(string(_), (true -> call(foo_undef)))).
p(with_output_to(string(_), (true *-> call(foo_undef)))).
p(with_output_to(string(_), (true -> call(foo_undef) ; true))).
p(with_output_to(string(_), (true *-> call(foo_undef) ; true))).
p(with_output_to(string(_), (fail ; true, call(foo_undef)))).
p(with_output_to(string(_), (true, \+ call(foo_undef)))).
p(with_output_to(string(_), \+ call(foo_undef))).
p(with_output_to(string(_), \+ (true, call(foo_undef)))).
p(with_output_to(string(_), \+ foo_undef(1))).
p(with_output_to(string(_), (true, foo_undef(1, 2)))).
p(with_output_to(string(_), (_, true))).
p(with_output_to(string(_), (true, _))).
p(with_output_to(string(_), (fail ; _))).
p(with_output_to(string(_), (true -> _))).
p(with_output_to(string(_), \+ _)).
p(with_output_to(string(_), (true, (true, 1)))).
p(with_output_to(string(_), (true *-> 1))).
p(with_output_to(string(_), (true, !))).
p(with_output_to(string(_), (true ; 1))).
p(with_output_to(string(_), call((true, 1)))).
p(with_output_to(string(_), call((true, call(foo_undef))))).
p(with_output_to(string(_), not(foo_undef))).
p(with_output_to(string(_), not(1))).
p(with_output_to(string(_), once(1))).
p(with_output_to(string(_), ignore(foo_undef))).
p(with_output_to(string(_), catch(foo_undef, nope, true))).
p(with_output_to(string(_), forall(foo_undef, true))).
p(with_output_to(string(_), findall(x, foo_undef, _))).
p(with_output_to(string(_), @(foo_undef, lists))).
p(with_output_to(string(_), (true, @(foo_undef, lists)))).

%% with_output_to/2: qualified goals and constructs
p(with_output_to(string(_), lists:foo_undef)).
p(with_output_to(string(_), lists:1)).
p(with_output_to(string(_), lists:_)).
p(with_output_to(string(_), lists:true(1))).
p(with_output_to(string(_), (true, lists:foo_undef))).
p(with_output_to(string(_), (lists:true, 1))).
p(with_output_to(string(_), (fail ; lists:foo_undef))).
p(with_output_to(string(_), (lists:fail ; 1))).
p(with_output_to(string(_), (1 ; lists:true))).
p(with_output_to(string(_), (lists:foo_undef ; true))).
p(with_output_to(string(_), (lists:fail ; call(foo_undef)))).
p(with_output_to(string(_), (lists:fail ; foo_undef))).
p(with_output_to(string(_), (true, user:(fail ; call(foo_undef))))).
p(with_output_to(string(_), lists:(true, 1))).
p(with_output_to(string(_), lists:(true, call(foo_undef)))).
p(with_output_to(string(_), lists:(fail ; call(foo_undef)))).
p(with_output_to(string(_), lists:(fail ; foo_undef))).
p(with_output_to(string(_), user:(fail ; foo_undef))).
p(with_output_to(string(_), user:(true, 1))).
p(with_output_to(string(_), system:(true, 1))).
p(with_output_to(string(_), lists:(\+ foo_undef))).
p(with_output_to(string(_), lists:(\+ (true, foo_undef)))).
p(with_output_to(string(_), lists:(\+ call(foo_undef)))).
p(with_output_to(string(_), lists:call(foo_undef))).
p(with_output_to(string(_), lists:call((true, foo_undef)))).

%% with_output_to/2: $/1, as `$(Goal) :- $(Goal)'
p(with_output_to(string(_), $fail)).
p(with_output_to(string(_), $member(_, [1, 2]))).
p(with_output_to(string(_), $foo_undef)).
p(with_output_to(string(_), $call(foo_undef))).
p(with_output_to(string(_), $((true, call(foo_undef))))).
p(with_output_to(string(_), $(1))).
p(with_output_to(string(_), $(_))).
p(with_output_to(string(_), (true, $(foo_undef)))).
p(with_output_to(string(_), lists:($foo_undef))).
p(with_output_to(string(_), lists:($fail))).
p(with_output_to(string(_), '$'(true, foo_undef))).
p(with_output_to(string(_), lists:'$'(true, foo_undef))).

%% format/2's ~@
p(format(atom(_), '~@', [foo_undef])).
p(format(atom(_), '~@', [_])).
p(format(atom(_), '~@', [1])).
p(format(atom(_), '~@', [(true, call(foo_undef))])).
p(format(atom(_), '~@', [(fail ; foo_undef)])).
p(format(atom(_), '~@', [\+ foo_undef])).
p(format(atom(_), '~@', [lists:(\+ foo_undef)])).
p(format(atom(_), '~@', [lists:foo_undef])).
p(format(atom(_), '~@', [$fail])).
p(format(atom(_), '~@', [(true, 1)])).

%% setup_call_cleanup/3: the setup
p(setup_call_cleanup(lists:foo_undef, true, true)).
p(setup_call_cleanup(lists:1, true, true)).
p(setup_call_cleanup((fail ; call(foo_undef)), true, true)).
p(setup_call_cleanup((true ; call(foo_undef)), true, true)).
p(setup_call_cleanup((true -> call(foo_undef)), true, true)).
p(setup_call_cleanup($(1), true, true)).
p(setup_call_cleanup($(foo_undef), true, true)).
p(setup_call_cleanup(\+ _, true, true)).
p(setup_call_cleanup(lists:(true, 1), true, true)).
p(setup_call_cleanup(lists:(\+ foo_undef), true, true)).
p(setup_call_cleanup(call(1), true, true)).
p(setup_call_cleanup((true, call(1)), true, true)).
p(setup_call_cleanup((true, 1), true, true)).
p(setup_call_cleanup((true -> 1), true, true)).
p(setup_call_cleanup((1, true), true, true)).
p(setup_call_cleanup(user:(true, 1), true, true)).
p(setup_call_cleanup((true, call(foo_undef)), true, true)).
p(setup_call_cleanup((true, foo_undef), true, true)).

%% setup_call_cleanup/3: the goal
p(setup_call_cleanup(true, (true, 1), true)).
p(setup_call_cleanup(true, lists:(true, 1), true)).
p(setup_call_cleanup(true, (true, call(foo_undef)), true)).
p(setup_call_cleanup(true, call(foo_undef), true)).
p(setup_call_cleanup(true, \+ foo_undef, true)).
p(setup_call_cleanup(true, lists:foo_undef, true)).
p(setup_call_cleanup(true, _, true)).
p(setup_call_cleanup(true, (true ; call(foo_undef)), true)).
p(setup_call_cleanup(true, (fail ; call(foo_undef)), true)).
p(setup_call_cleanup(true, \+ 1, true)).
p(setup_call_cleanup(true, lists:1, true)).
p(setup_call_cleanup(true, '|'(fail, foo_undef), true)).

%% setup_call_cleanup/3: the cleanup
p(setup_call_cleanup(true, true, (true, 1))).
p(setup_call_cleanup(true, true, (fail ; call(foo_undef)))).
p(setup_call_cleanup(true, true, \+ foo_undef)).
p(setup_call_cleanup(true, true, (true, call(foo_undef)))).
p(setup_call_cleanup(true, true, lists:foo_undef)).
p(setup_call_cleanup(true, fail, foo_undef)).
p(setup_call_cleanup(true, true, _)).
p(setup_call_cleanup(true, true, 1)).
p(setup_call_cleanup(true, true, \+ 1)).
p(setup_call_cleanup(true, true, call(foo_undef))).
p(setup_call_cleanup(true, true, call(foo_undef, a))).
p(setup_call_cleanup(true, true, (1 ; true))).
p(setup_call_cleanup(true, true, $(foo_undef))).
p(setup_call_cleanup(true, true, $(1))).
p(setup_call_cleanup(true, true, (true -> 1))).
p(setup_call_cleanup(true, true, lists:(true, 1))).
p(setup_call_cleanup(true, true, lists:(\+ foo_undef))).
p(setup_call_cleanup(true, true, (lists:fail ; foo_undef))).
p(setup_call_cleanup(true, true, once(foo_undef))).
p(setup_call_cleanup(true, true, \+ _)).
p(setup_call_cleanup(true, true, (true, _))).
p(setup_call_cleanup(true, true, lists:_)).
p(setup_call_cleanup(true, true, lists:1)).
p(setup_call_cleanup(true, true, foo_undef(1))).
p(setup_call_cleanup(true, true, '|'(fail, foo_undef))).
p(setup_call_cleanup(true, true, @(foo_undef, lists))).
p(setup_call_catcher_cleanup(true, foo_undef, E, (E = exception(_) -> foo2_undef ; true))).
p(setup_call_cleanup(true, (true ; true), foo_undef)).
p(call_cleanup(true, (true, 1))).

%% setup_call_cleanup/3: the goal's ball and the cleanup's
p(setup_call_cleanup(true, throw(x), foo_undef)).
p(setup_call_cleanup(true, throw(x), throw(y))).
p(setup_call_cleanup(true, throw(x), fail)).
p(setup_call_cleanup(true, throw(x), (true, 1))).
p(setup_call_cleanup(true, throw(x), 1)).
p(setup_call_cleanup(true, throw(error(a, _)), foo_undef)).
p(setup_call_cleanup(true, throw(error(a, _)), throw(error(resource_error(b), _)))).
p(setup_call_cleanup(true, throw(error(resource_error(a), _)), foo_undef)).
p(setup_call_cleanup(true, throw(x), throw(error(resource_error(b), _)))).
p(setup_call_cleanup(true, throw(x), throw(time_limit_exceeded))).
p(setup_call_cleanup(true, throw(error(a, _)), throw(time_limit_exceeded))).
p(setup_call_cleanup(true, throw(time_limit_exceeded), foo_undef)).
p(setup_call_cleanup(true, throw(error(a, _)), throw(error(b, _)))).
p(setup_call_cleanup(true, throw(x), throw(error))).
p(setup_call_cleanup(true, throw(x), throw(error(b)))).
p(setup_call_cleanup(true, throw(x), throw(error(b, c, d)))).
p(setup_call_cleanup(true, throw(x), throw(error(_, _)))).
p(setup_call_cleanup(true, throw(error(_, _)), throw(error(b, _)))).
p(setup_call_cleanup(true, throw(f(x)), throw(error(b, _)))).
p(setup_call_cleanup(true, throw(x), throw(time_limit_exceeded(1)))).
p(setup_call_cleanup(true, throw(time_limit_exceeded), throw(time_limit_exceeded(1)))).
p(setup_call_cleanup(true, throw(error(type_error(a, b), _)), (true, foo_undef))).
p(setup_call_cleanup(true, throw(x), (true ; foo_undef))).
p((setup_call_cleanup(true, true, foo_undef), throw(ext))).
p((setup_call_cleanup(true, member(_, [1, 2]), foo_undef), throw(ext))).
p((setup_call_cleanup(true, member(_, [1, 2]), throw(y)), throw(ext))).

%% a meta-call strips its qualifiers
p(call(lists:foo_undef)).
p(call(lists:1)).
p(call(lists:_)).
p(call(lists:(\+ foo_undef))).
p(call(lists:call(foo_undef))).
p(call(lists:(true, call(foo_undef)))).
p(call(_:foo)).
p(call(1:foo)).
p(call(lists:(true, 1:foo))).
p(findall(x, (true, 1:foo), _)).
p(findall(x, (true, _:foo), _)).
p(findall(x, _:foo, _)).
p(findall(x, 1:foo, _)).
p(call(lists:catch(a))).
p(call(lists:'$cut'(1))).
p(lists:true(1)).
p(lists:foo_undef).
p(lists:(\+ foo_undef)).
p(lists:(true, foo_undef)).
p((true, lists:(\+ foo_undef))).
p(once(lists:(true, 1))).
p(once(lists:(true, foo_undef))).
p(catch(lists:(true, 1), nope, true)).
p(catch(lists:(\+ foo_undef), nope, true)).
p(findall(x, lists:(true, 1), _)).
p(findall(x, lists:(\+ foo_undef), _)).
p(findall(x, (true, lists:(\+ foo_undef)), _)).
p(findall(x, lists:foo_undef, _)).
p(findall(x, \+ lists:foo_undef, _)).
p(findall(x, \+ lists:(true, 1), _)).
p(findall(x, lists:1, _)).
p(findall(x, lists:_, _)).
p(findall(x, lists:call(foo_undef), _)).
p(findall(x, lists:(\+ (true, foo_undef)), _)).
p(findall(x, lists:(true, call(foo_undef)), _)).
p(findall(x, lists:(true, call(foo_undef, a)), _)).
p(findall(x, lists:(true, call(1, a)), _)).
p(findall(x, lists:(true, X), _)) :- X = (true, call(foo_undef)).
p(findall(x, lists:(true, X), _)) :- X = call(foo_undef).
p(call(lists:(true, X))) :- X = (true, call(foo_undef)).
p(findall(x, lists:(X = (true, call(foo_undef)), X), _)).
p(findall(x, lists:(X = foo_undef, X), _)).
p(findall(x, lists:(X = call(foo_undef), X), _)).
p(call(lists:(X = (true, call(foo_undef)), X))).
p(findall(x, $fail, _)).
p(findall(x, $member(_, [1, 2]), _)).
p(findall(x, $foo_undef, _)).
p(findall(x, $(1), _)).
p(findall(x, (true, $(1)), _)).
p(m1). p(m2).

%% a qualifier written in code that runs
p(findall(x, (true, lists:call(foo_undef)), _)).
p(findall(x, (true, lists:(true, foo_undef)), _)).
p(findall(x, (true, lists:(true, call(foo_undef))), _)).
p(findall(x, (true, call((true, user:call(foo_undef)))), _)).
p(findall(x, (true, lists:(true, X)), _)) :- X = (true, call(foo_undef)).
p(findall(x, (true, lists:($fail)), _)).
p(findall(x, lists:($fail), _)).
p(findall(x, (true, lists:(X = (true, call(foo_undef)), X)), _)).
p(findall(x, (true, lists:(X = call(foo_undef), X)), _)).
p(c3). p(c4). p(c5). p(c6). p(c7). p(c8). p(c9). p(c10). p(c11). p(c12). p(c13).
%% ... and the goal of once/1, ignore/1 or not/1 in a clause, whose compile
%% of a structure with `M:G' in it finds what is no goal before it runs
p(c14). p(c15). p(c16). p(c17). p(c18). p(c19). p(c20). p(c21).

m1 :- X = lists:(\+ foo_undef), call(X).
m2 :- X = lists:(true, foo_undef), X.
c3 :- lists:(true, call(foo_undef)).
c4 :- G = (true, user:call(foo_undef)), call(G).
c5 :- call((true, user:call(foo_undef))).
c6 :- lists:call(foo_undef).
c7 :- call(lists:(true, 1)).
c8 :- lists:(true, call(1, a)).
c9 :- X = 1, lists:(true, call(X, a)).
c10 :- lists:(true, foo_undef).
c11 :- lists:($(fail)).
c12 :- lists:(X = (true, call(foo_undef)), X).
c13 :- lists:(X = call(foo_undef), X).
c14 :- once(lists:(true, 1)).
c15 :- ignore(lists:(true, 1:foo)).
c16 :- not(lists:(fail ; 1)).
c17 :- once((true, lists:(true, 1))).
c18 :- once(lists:(true, _:foo)).
c19 :- ignore((true, lists:1)).
c20 :- once(lists:(true, foo_undef)).
c21 :- once((fail, lists:(true, 1))).
