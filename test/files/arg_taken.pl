%  arg/3 a program file took over, and the system's called as system:arg/3
%  with its index unbound, as swipl 9.0.4 answers it. Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte.
%
%  The program's arg/3 answers the program's calls; `system:arg(...)' is
%  the builtin's, which cocolog reaches through the `:' construct's own
%  call of the row (`coco_colon_run'), where an unbound index is handed to
%  the walk as at the step (test/files/arg_enum.pl). `user:', `lists:' and
%  `system:' of a name nobody took over go the step's way.

:- redefine_system_predicate(arg(_, _, _)).
arg(mine, _, _).

pv(T) :- \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

t(G) :-
    catch(( findall(G-D, ( setup_call_cleanup(true, G, D0 = det),
                           ( D0 == det -> D = det ; D = nondet ) ), L),
            pv(G), write(' => '), pv(L), nl ),
          E, ( pv(G), write(' raised '), pv(E), nl )).

main :-
    t(system:arg(_, f(a, b), _)), t(arg(_, f(a, b), _)), t(system:arg(_, f(a, b, c), b)),
    t(sa(_)), t(system:arg(_, foo, _)), t(system:arg(1, f(a), _)).
sa(X) :- system:arg(_, g(1, 2), X).
