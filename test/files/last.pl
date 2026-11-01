%  last/2 in every mode: swipl 9.0.4's library(lists) clause,
%
%      last([X|Xs], Last) :- last_(Xs, X, Last).
%      last_([], Last, Last).
%      last_([X|Xs], _, Last) :- last_(Xs, X, Last).
%
%  Run by BOTH SWI-Prolog and cocolog, output compared. A proper list is
%  cocolog's C row and answers once; a partial list, an unbound one among
%  them, enumerates, answer by answer in the clause's order -- the shortest
%  list first, the last element always the one Last names (3.0.1; through
%  3.0.0 cocolog failed there). Anything else -- the empty list, an atom,
%  `[a|foo]' -- fails, in both, with no error.
%
%  An answer is printed with its variables named A, B, ... in the order
%  term_variables/2 meets them, so the two systems' own names for a fresh
%  variable never reach the comparison (cocolog has no numbervars/3).

s(Label, Value) :- write(Label), write(=), print(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

%  the answers of Goal, each Template as it stood with its variables named
answers(Label, Template, Goal) :-
    findall(Template, Goal, Ts),
    named(Ts),
    s(Label, Ts).

named(T) :- term_variables(T, Vs), named_(Vs, 0).
named_([], _).
named_(['$VAR'(N)|Vs], N) :- N1 is N + 1, named_(Vs, N1).

%  each answer printed as it comes, before the next is asked for: the
%  enumeration is a choice point the engine goes back into, and the cut
%  after the length limit is the only thing that ends it
one_by_one(Label, Template, Goal, Max) :-
    (   call(Goal), length(Template, N),
        copy_term(Template, Shown), named(Shown),
        write(Label), write(' '), write(N), write(': '), print(Shown), nl,
        N >= Max, !
    ;   true
    ).

main :-
    %  ---- a proper list: one answer, the last element ----
    ( last([a,b,c], L1) -> s(proper, L1) ; s(proper, no) ),
    ( last([a], L2) -> s(proper_one, L2) ; s(proper_one, no) ),
    answers(proper_all, X3, last([a,b,c], X3)),
    answers(proper_vars, L4-X4, ( L4 = [a,_,_], last(L4, X4) )),
    yn(last([a,b,c], c), proper_check_yes),
    yn(last([a,b,c], b), proper_check_no),
    answers(proper_nested, X5, last([[a],[b,c]], X5)),

    %  ---- no list: fails, and nothing raises ----
    yn(last([], _), empty),
    yn(last(foo, _), atom),
    yn(last('[]', _), quoted_nil),
    yn(last([a|foo], _), improper),
    yn(last([a,b|c], _), improper_two),
    yn(last(f(a, []), _), compound),
    yn(last(1, _), number),

    %  ---- an unbound list: [X], [_, X], [_, _, X], ... ----
    answers(unbound_five, L6-X6, ( last(L6, X6), length(L6, N6), ( N6 >= 5 -> ! ; true ) )),
    answers(unbound_bound_last, L7, ( last(L7, z), length(L7, N7), ( N7 >= 4 -> ! ; true ) )),
    one_by_one(unbound, L8, last(L8, _), 4),
    ( last(L9, X9), L9 = [a,b] -> s(unbound_then_bound, X9) ; s(unbound_then_bound, no) ),
    ( last(L10, X10), L10 = [p,q,r,s] -> s(unbound_then_bound4, L10-X10) ; s(unbound_then_bound4, no) ),
    ( last(L11, x), length(L11, 3) -> named(L11), s(unbound_length_after, L11) ; true ),

    %  ---- a partial list: [a|T] is T = [], T = [_], ... ----
    answers(partial_five, T12-X12, ( last([a|T12], X12), length(T12, N12), ( N12 >= 4 -> ! ; true ) )),
    answers(partial_two, T13-X13, ( last([a,b|T13], X13), length(T13, N13), ( N13 >= 3 -> ! ; true ) )),
    answers(partial_bound_last, T14, ( last([a|T14], z), length(T14, N14), ( N14 >= 3 -> ! ; true ) )),
    answers(partial_same_last, T15, ( last([a|T15], a), length(T15, N15), ( N15 >= 2 -> ! ; true ) )),
    answers(partial_head_is_last, H16-T16, ( last([H16|T16], H16), length(T16, N16), ( N16 >= 2 -> ! ; true ) )),
    answers(partial_shared, L17, ( L17 = [A17,_|T17], last(L17, A17), length(T17, N17), ( N17 >= 2 -> ! ; true ) )),
    one_by_one(partial, T18, last([a|T18], _), 3),
    ( last([a|T19], X19), T19 = [b,c] -> s(partial_then_bound, X19) ; s(partial_then_bound, no) ),
    ( last([a,b|T20], c), length(T20, 2) -> named(T20), s(partial_length_after, T20) ; true ),

    %  ---- counted: the first six lengths, in order, none left out ----
    answers(lengths, N21, ( last(L21, _), length(L21, N21), ( N21 >= 6 -> ! ; true ) )),
    answers(partial_lengths, N22, ( last([a,b|T22], _), length(T22, N22), ( N22 >= 5 -> ! ; true ) )),

    %  ---- inside the other library predicates that call it ----
    ( max_member(M23, [b,c,a]) -> s(max_member, M23) ; s(max_member, no) ),
    true.
