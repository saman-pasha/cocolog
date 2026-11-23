
%% call/N where swipl calls it as a predicate, for test/trace.pl (3.78.8):
%% swipl's call/1 to call/8 are predicates of boot/init.pl, `call(G) :- G.'
%% and its kin, which its compiler calls in place where they are written --
%% in a clause, in a structure it compiles into a `'<meta-call>'/1' -- and
%% which a meta-called goal resolves to as to any predicate: a frame of its
%% own, a port, which hides what the system does in it and shows a
%% program's predicate, its goal a level below it. call/N of `@' is the
%% system's @/2 there, a port, its goal two below it; call/N of `|' and of
%% `:' names no predicate, the unknown procedure. Through 3.78.7 call/N was
%% no port anywhere, call/N of `@' ran the construct in place and call/N of
%% `|' ran it as `;'.

cn_a.
cn_b.
cn_m(1).
cn_m(2).
cn_n(X) :- cn_m(X).

%% call/N of @/2: the system's @/2, its goal two below
cn1 :- call(@, (cn_a, cn_b), user).
cn2 :- call(@, cn_m(X), user), X > 1.
cn3 :- call(@, cn_a, user).
cn4 :- call(@(cn_a), user).
cn5 :- call(@, cn_n(X), user), X > 1.
cn6 :- G = call(@, cn_a, user), G.
cn7 :- call(@, (cn_m(X), X > 1), user).
cn8 :- call(@, \+ fail, user).
cn9 :- call(@, fail, user) ; true.

%% call/N of `|' and of `:': no predicate, the unknown procedure
cn10 :- catch(call('|', cn_a, cn_b), _, true).
cn11 :- catch(call('|', fail, cn_b), _, true).
cn12 :- catch(call(('|'), cn_a, cn_b), error(existence_error(_, _), _), true).

%% a C-called call/N: with_output_to/2's goal, `~@''s, a setup's, a cleanup's
cn13 :- with_output_to(string(_), call(cn_m, X)), X > 1.
cn14 :- with_output_to(string(_), @(cn_a, user)).
cn15 :- with_output_to(string(_), call(@, cn_a, user)).
cn16 :- with_output_to(string(_), call(call, cn_a)).
cn17 :- format(atom(_), '~@', [call(cn_a)]).
cn18 :- setup_call_cleanup(call(cn_a), true, true).
cn19 :- setup_call_cleanup(true, true, call(cn_a)).
cn20 :- with_output_to(string(_), call(cn_n, X)), X > 1.

%% call/1 called as a predicate: a meta-called goal that is call/N
cn21 :- G = call(cn_m, X), G, X > 1.
cn22 :- G = call(call, cn_a), G.
cn23 :- call(call(cn_a)).
cn24 :- once(call((cn_a, cn_b))).
cn25 :- G = call((cn_a, cn_b)), G.
cn26 :- G = call(cn_m(X)), G, X > 1.
cn27 :- call((G = call(cn_a), G)).
cn28 :- call((G = call(cn_a), (true, G))).
cn29 :- call((G = call(cn_a), once(G))).
cn30 :- call((G = call(cn_a), call(G))).
cn31 :- catch(call(cn_m(X)), _, true), X > 1.
cn32 :- ignore(call(fail)).
cn33 :- not(call(fail)).
cn34 :- once(call(cn_n(X))), X > 0.
cn35 :- call(call, cn_m, X), X > 1.
cn36 :- G = call(cn_m), call(G, X), X > 1.
cn37 :- call(call(call(cn_a))).
cn38 :- G = call(fail), ( G ; true ).
cn39 :- G = call(cn_a), call((cn_b, G)).
cn40 :- once(call(call, cn_a)).
cn41 :- forall(call(cn_m, _), true).
cn42 :- G = call(@, cn_m(X), user), G, X > 1.
cn43 :- catch(call(call, '|', cn_a, cn_b), _, true).
cn44 :- G = call(user:cn_a), G.
cn45 :- once(call(user:(cn_a, cn_b))).
%% call/N's frame hides what the system does in it, as swipl's call/N does
cn46 :- G = call(atom(a)), G.
cn47 :- G = call(atom, a), G.
cn48 :- G = call((atom(a), cn_a)), G.
cn49 :- G = call(cn_m, X), G, atom(a), X > 1.
%% a goal C runs that is call/N: call/N's own port, as swipl's callProlog() calls it
cn50 :- with_output_to(string(_), call(',', cn_a, cn_b)).
cn51 :- with_output_to(string(_), call(;, fail, cn_a)).
cn52 :- format(atom(_), '~@', [call(',', cn_a, cn_b)]).
