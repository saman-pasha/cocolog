%  max_member/2,3 and min_member/2,3 as swipl 9.0.4 writes them
%  (library(lists), single-sided rules): of two elements the order ties,
%  the /3 forms keep the one swipl's keeps -- call(P, H, Max0) keeps Max0,
%  call(P, Min0, H) keeps Min0 -- and a list no rule matches (unbound,
%  partial, or no list) raises existence_error(matching_rule, Goal), the
%  goal and the context named by the predicate or the helper swipl's
%  clause reached: lists:max_member/2, lists:max_member_/3,
%  lists:min_member_/4. Through 3.26.0 the /3 forms asked call(P, Max0, H)
%  and took H, so a tie kept the other element, the /2 forms sorted the
%  list, and each failed or raised msort/2's error where swipl's matches no
%  rule. Run by BOTH SWI-Prolog and cocolog, output compared byte for byte;
%  each line is one of swipl 9.0.4's answers. A culprit is shown as its
%  module and its functor: swipl qualifies a meta-argument (user:le), and
%  cocolog has one namespace (COMPAT.md).

:- use_module(library(lists)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form

le(A, B) :- A =< B.
lt(A, B) :- A < B.
ge(A, B) :- A >= B.
shorter(A, B) :- atom_length(A, LA), atom_length(B, LB), LA =< LB.

%  one answer or none, shown with its value
a(Label, G, V) :-
    (   catch(G, E, true)
    ->  (   var(E)
        ->  format("~w: ~q~n", [Label, V])
        ;   err(Label, E)
        )
    ;   format("~w: fails~n", [Label])
    ).

err(Label, error(existence_error(matching_rule, G), context(C, _))) :- !,
    strip_module(G, M, P),
    functor(P, N, A),
    format("~w: no rule matches ~q, ~q:~q/~q~n", [Label, C, M, N, A]).
err(Label, error(F, Ctx)) :- !,
    ( Ctx = context(C, _) -> true ; C = none ),
    format("~w: ~q in ~q~n", [Label, F, C]).
err(Label, E) :-
    format("~w: ~q~n", [Label, E]).

%  whether the call left a choice point
det(Label, G) :-
    (   call_cleanup(G, Det = yes) -> true ; Det = failed ),
    ( var(Det) -> D = no ; D = Det ),
    format("~w deterministic: ~w~n", [Label, D]).

main :-
    %  ---- ties: which of two elements the order calls equal is kept ----
    a(max_le_tie, max_member(le, M1, [1, 1.0]), M1),
    a(min_le_tie, min_member(le, M2, [1, 1.0]), M2),
    a(max_lt_tie, max_member(lt, M3, [1, 1.0]), M3),
    a(min_lt_tie, min_member(lt, M4, [1, 1.0]), M4),
    a(max_ge_tie, max_member(ge, M5, [2, 2.0, 1]), M5),
    a(min_ge_tie, min_member(ge, M6, [2, 2.0, 1]), M6),
    a(max_tie_three, max_member(le, M7, [1.0, 1, 1.0]), M7),
    a(min_tie_three, min_member(le, M8, [1, 1.0, 1]), M8),
    a(max_shorter, max_member(shorter, M9, [ab, cd, a]), M9),
    a(min_shorter, min_member(shorter, M10, [ab, cd, a, b]), M10),
    a(max_std, max_member(@=<, M11, [1, 1.0, b, a]), M11),
    a(min_std, min_member(@=<, M12, [b, 1, 1.0]), M12),
    %  ---- the standard order, the /2 forms ----
    a(max_2, max_member(M13, [3, 1, 2]), M13),
    a(min_2, min_member(M14, [3, 1, 2]), M14),
    a(max_2_mixed, max_member(M15, [1, b, f(x), 2.0]), M15),
    a(min_2_mixed, min_member(M16, [1, b, f(x), 2.0]), M16),
    a(max_2_one, max_member(M17, [x]), M17),
    a(max_2_given, max_member(3, [3, 1, 2]), yes),
    a(max_2_given_no, max_member(1, [3, 1, 2]), yes),
    a(min_3_given, min_member(le, 1, [3, 1, 2]), yes),
    a(max_3_one, max_member(le, M18, [7]), M18),
    %  ---- an empty list fails ----
    a(max_2_empty, max_member(_, []), none),
    a(min_2_empty, min_member(_, []), none),
    a(max_3_empty, max_member(le, _, []), none),
    a(min_3_empty, min_member(le, _, []), none),
    %  ---- a list no rule matches ----
    a(max_2_unbound, max_member(_, _), none),
    a(min_2_unbound, min_member(_, _), none),
    a(max_3_unbound, max_member(le, _, _), none),
    a(min_3_unbound, min_member(le, _, _), none),
    a(max_2_partial, max_member(_, [a|_]), none),
    a(min_2_partial, min_member(_, [a|_]), none),
    a(max_3_partial, max_member(le, _, [1|_]), none),
    a(min_3_partial, min_member(le, _, [1|_]), none),
    a(max_2_partial2, max_member(_, [a, b|_]), none),
    a(min_3_partial2, min_member(le, _, [2, 1|_]), none),
    a(max_2_atom, max_member(_, foo), none),
    a(min_2_atom, min_member(_, foo), none),
    a(max_3_atom, max_member(le, _, foo), none),
    a(min_3_improper, min_member(le, _, [1|foo]), none),
    %  ---- the order's own errors and failures ----
    a(max_3_unknown, max_member(nosuch, _, [1, 2]), none),
    a(min_3_unknown, min_member(nosuch, _, [1, 2]), none),
    a(max_3_one_unknown, max_member(nosuch, M19, [1]), M19),
    a(max_3_type, max_member(le, _, [1, a]), none),
    %  ---- deterministic, as swipl's rules are ----
    det(max_2, max_member(_, [3, 1, 2])),
    det(min_2, min_member(_, [3, 1, 2])),
    det(max_3, max_member(le, _, [3, 1, 2])),
    det(min_3, min_member(le, _, [3, 1, 2])),
    det(max_2_empty, max_member(_, [])).
