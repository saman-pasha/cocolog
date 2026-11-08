%  The system's own definition of a name a program file took over, called
%  as system:G for the arguments the system's C turns down to its
%  library's clause -- length/2 enumerating, last/2 of a partial list,
%  reverse/2 with its first list unbound, nth0/3 and nth1/3 with the index
%  unbound, aggregate_all/3 of a template of templates -- as swipl 9.0.4
%  answers it. Run by BOTH SWI-Prolog and cocolog, output compared byte for
%  byte.
%
%  swipl's system:G reaches the system's predicate whatever user defines.
%  cocolog keeps the library's clauses of a taken name under a name of
%  their own (`coco_pred_keep_muted', `coco_kept_head') and runs them for a
%  declined system:G (`coco_call_kept'); through 3.58.0 the goal was made
%  system:G again and ran for ever. last/2, reverse/2 and nth0/3 are taken
%  before any directive reads the libraries (their clauses kept as the
%  libraries are read, at `run''s first directive), length/2, nth1/3 and
%  aggregate_all/3 after it (kept at the take-over). The program's own
%  definitions answer its own calls, and a library's own call of a taken
%  name is the system's.

last(_, mine).
reverse(_, mine).
nth0(_, _, mine).
:- redefine_system_predicate(length(_, _)).
length(_, mine).
nth1(_, _, mine).
aggregate_all(_, _, mine).

pv(T) :- \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

t(G) :-
    catch(( findall(G-D, ( setup_call_cleanup(true, G, D0 = det),
                           ( D0 == det -> D = det ; D = nondet ) ), L),
            pv(G), write(' => '), pv(L), nl ),
          E, ( pv(G), write(' raised '), pv(E), nl )).

%% an enumeration cut at its third answer
len3(L-N) :- system:length(L, N), ( N >= 2 -> ! ; true ).
last3(L-X) :- L = [a|_], system:last(L, X), system:length(L, N), ( N >= 3 -> ! ; true ).
%% a guarded frame's last call takes the guard on, and the system's clause
%% hands it to its own last call -- as it does for the name not taken.
%% swipl's first call of a library predicate it autoloads keeps the guard
%% on the caller (COMPAT.md), so main calls each of these once before
dl(L) :- $, system:length(L, _).
gq :- $, system:aggregate_all(r(count), member(_, [a]), r(5)).
gn :- $, system:nth0(_, [], _).
gn2 :- $, system:nth0(_, [a, b], c).
gl :- $, system:last([a|_], _).
gr :- $, system:reverse(_, [a|b]).

main :-
    %% the program's own
    t(length(_, _)), t(last([a], _)), t(reverse([a], _)), t(nth0(0, [a], _)),
    t(nth1(1, [a], _)), t(aggregate_all(count, true, _)),
    %% the system's C, which answers these
    t(system:length([a, b], _)), t(system:last([a, b, c], _)), t(system:reverse([a, b], _)),
    t(system:nth0(1, [a, b], _)), t(system:nth1(1, [a, b], _)),
    t(system:aggregate_all(count, member(_, [a, b]), _)),
    t(system:length(a, _)), t(system:length(_, -1)),
    %% the system's clauses, which answer what its C turns down
    t(len3(_)), t(last3(_)), t(system:reverse(_, [a, b])), t(system:reverse(_, [])),
    t(system:nth0(_, [a, b, c], _)), t(system:nth1(_, [a, b, c], _)),
    t(system:nth0(_, [a, b, a], a)), t(lists:nth1(_, [x, y], _)),
    t(system:aggregate_all(r(count, sum(X)), member(X, [1, 2, 3]), _)),
    t(system:aggregate_all(bag(Y)-max(Y), member(Y, [c, a, b]), _)),
    %% and with no answer
    t(system:nth0(_, [], _)), t(system:reverse(_, [a|b])),
    t(dl(_)), t(gq), t(gn), t(gn2), t(gl), t(gr).
