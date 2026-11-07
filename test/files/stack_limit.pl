%  The stack limit, swipl's `stack_limit' flag: how many bytes a search may
%  hold before it is stopped with error(resource_error(stack), Context) --
%  a recursion that never ends, choice points that pile up, a list that
%  grows while something still names it -- and the flag's own answers and
%  errors. Through 3.31.0 cocolog had no such flag: its heap grew until
%  memory was refused, error(resource_error(memory), _), or until the
%  kernel killed the process first.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  NOT COMPARED, each in COMPAT.md: the error's context, which swipl makes a
%  dict of its stacks (stack_overflow{choicepoints:..., depth:..., ...}) and
%  cocolog leaves unbound, and so print_message/2 of it, which swipl writes
%  from that dict; how much a search holds when it is stopped (swipl counts
%  its local, global and trail stacks, cocolog its heap, its trail and its
%  choice frames); a value past 64 bits, which cocolog does not read; and a
%  search whose growth nothing names again (`chain(0, _)'), which swipl's
%  collector frees for ever and cocolog's may keep and stop.

:- use_module(library(ordsets)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form

%% a recursion that is no last call, choice points that pile up, and a
%% list that grows
foo(N) :- N1 is N + 1, foo(N1), true.
cp(N) :- N1 is N + 1, ( true ; true ), cp(N1).
chain(N, [N|T]) :- N1 is N + 1, chain(N1, T).

h(S) :- write('== '), write(S), nl.

%% the formal of what G raised, or none
f(Name, G) :-
    catch(G, E, true),
    (   var(E) -> R = none
    ;   E = error(F, _) -> R = F
    ;   R = E
    ),
    print(Name-R), nl.

%% set the flag to V, then what it answers
s(Name, V) :-
    catch(set_prolog_flag(stack_limit, V), E, true),
    (   var(E) -> R = ok
    ;   E = error(F, _) -> R = F
    ;   R = E
    ),
    current_prolog_flag(stack_limit, L),
    print(Name-R-L), nl.

main :- flag, overflow.

flag :-
    h(flag),
    current_prolog_flag(stack_limit, L0), print(L0), nl,
    ( current_prolog_flag(F, 1073741824), F == stack_limit -> writeln(enumerated) ; writeln(not_enumerated) ),
    s(unbound, _),
    s(atom, foo),
    s(fraction, 1.5),
    s(rational, 1r2),
    s(zero, 0),
    s(below_use, 1000),
    s(whole_float, 2.0e7),
    s(negative, -1),
    s(twenty_million, 20000000),
    s(again, 20000000).

overflow :-
    h(overflow),
    set_prolog_flag(stack_limit, 20000000),
    f(deep, foo(0)),
    f(deep_again, foo(0)),
    f(choice_points, cp(0)),
    f(held_list, ( chain(0, L1), length(L1, _) )),
    f(held_memberchk, ( ord_memberchk(a, L2), length(L2, _) )),
    f(in_findall, findall(x, foo(0), _)),
    f(in_forall, forall(foo(0), true)),
    f(in_aggregate, aggregate_all(count, foo(0), _)),
    f(caught_inside, catch(foo(0), error(resource_error(stack), _), true)),
    f(after, ( numlist(1, 1000, NL), length(NL, 1000) )),
    current_prolog_flag(stack_limit, Lim), print(Lim), nl.
