%  arg/3 with its index unbound, as swipl 9.0.4's foreign arg/3 answers it.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  Each goal's every answer, with whether it left a choice point (det or
%  nondet, by setup_call_cleanup/3's own report). The places are tried
%  in order, the third argument unified first and then the index; an
%  answer short of the term's last place leaves a choice point whatever
%  the places after it hold, and the last place leaves none. Through
%  3.28.0 cocolog raised instantiation_error for every one of these, and
%  library(aggregate)'s free_variables/4, which walks a term with
%  arg(_, T, A), raised with it.

:- set_prolog_flag(double_quotes, codes).

pv(T) :- \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

t(G) :-
    catch(( findall(G-D, ( setup_call_cleanup(true, G, D0 = det),
                           ( D0 == det -> D = det ; D = nondet ) ), L),
            pv(G), write(' => '), pv(L), nl ),
          E, ( pv(G), write(' raised '), pv(E), nl )).

main :-
    t(arg(_, f(2, 1), _)), t(arg(N1, f(2, 1), N1)), t(arg(N2, f(1, 2), N2)),
    t(arg(N3, f(a, N3), _)), t(arg(_, f(X4, _), X4)), t(arg(_, f(_, b), a)),
    t(arg(_, f(a), a)), t(arg(_, f(a), b)), t(arg(_, f(), _)), t(arg(_, [a, b], _)),
    t(arg(_, foo, _)), t(arg(_, _, _)), t(arg(_, "ab", _)), t(arg(_, 3, _)),
    t(arg(_, 1.5, _)), t(arg(_, [], _)), t(arg(_, f(a, b, c), c)),
    t(arg(_, f(a, b, c), b)), t(arg(_, f(X5, X5), a)), t(arg(_, f(g(_), g(1)), g(2))),
    t((arg(N7, f(a, b), _), N7 > 1)), t(arg(_, f(a, b), _)), t(arg(N8, f(a), N8)),
    t(arg(1, f(a), _)), t(arg(N9, f(N9), _)), t(arg(_, -(a), _)), t(arg(_, 'f'(x), x)),
    %  inside a clause's body, a disjunction, a negation and a findall/3
    t(ab(_, _)), t(ac(_)), t(ad), t(ae(_)), t(af(_)), t(ag(_)),
    %  its answers undone by backtracking into it, and a cut after it
    t(( arg(N10, f(a, b, c), A10), A10 \== a, N10 < 3 )), t(once(arg(_, f(x, y), _))),
    t(( arg(N11, f(a, b), _), ! , N11 > 1 )),
    %  module-qualified -- `user:' taken off, a library's module or
    %  `system' asked of the builtin by name -- and through call/N
    t(user:arg(_, f(p, q), _)), t(system:arg(_, f(p, q), _)), t(lists:arg(_, f(p, q), q)),
    t(qa(_)), t(call(arg, _, f(p, q), q)), t(call(arg(_), f(p), _)).

ab(N, A) :- ( arg(N, g(x, y), A) ; N = 0, A = none ).
ac(L) :- findall(N-A, arg(N, h(1, 2, 3), A), L).
ad :- \+ arg(_, f(a, b), c).
ae(N) :- arg(N, f(a, b), A), A == b.
af(N-L) :- ( L = 1 ; L = 2 ), arg(N, f(a, b), _).
ag(N) :- \+ fail, arg(N, f(a, b, b), b), N > 0.
qa(X) :- system:arg(_, g(1, 2), X).
