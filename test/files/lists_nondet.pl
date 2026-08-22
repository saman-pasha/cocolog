%  library(lists): the part that could NOT be written in C.
%
%  member/2, select/3, append/3 and permutation/2 each answer many times, and
%  a module's C half cannot -- it has no access to the choice stack. They are
%  clauses in the module's Coco half, where the engine provides the choice
%  points, and this file is what proves the choice points are really there.
%
%  There is no findall/3 in cocolog, so a solution is reached by backtracking
%  PAST the earlier ones: `select(X, [a,b,c], R), X == c' can only succeed
%  after select/3 has answered twice and been rejected twice.

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

main :-
    %  ---- member/2 reaches every element, in order ----
    ( member(X1, [a,b,c]), X1 == a -> s(member_1st, X1) ; s(member_1st, no) ),
    ( member(X2, [a,b,c]), X2 == b -> s(member_2nd, X2) ; s(member_2nd, no) ),
    ( member(X3, [a,b,c]), X3 == c -> s(member_3rd, X3) ; s(member_3rd, no) ),
    yn((member(X4, [a,b,c]), X4 == d), member_4th),

    %  ---- select/3 backtracks over the whole list ----
    ( select(Y1, [a,b,c], R1), Y1 == c -> s(select_last, R1) ; s(select_last, no) ),
    ( select(a, [a,b,a], R2), R2 == [a,b] -> s(select_second_a, R2) ; s(select_second_a, no) ),

    %  ---- append/3 splits every way ----
    ( append(P1, S1, [1,2,3]), S1 == [] -> s(append_all_left, P1) ; s(append_all_left, no) ),
    ( append(P2, S2, [1,2,3]), P2 == [1,2] -> s(append_mid, S2) ; s(append_mid, no) ),

    %  ---- permutation/2 reaches a permutation far from the first ----
    ( permutation([1,2,3], Q1), Q1 == [3,2,1] -> s(permutation_last, Q1) ; s(permutation_last, no) ),
    yn(permutation([1,2], [2,1]), permutation_check),
    yn(permutation([1,2], [1,3]), permutation_no),

    %  ---- nth0/3 enumerates when the index is free ----
    ( nth0(I1, [a,b,c], c) -> s(nth0_enumerate, I1) ; s(nth0_enumerate, no) ),
    ( nth0(I2, [a,b,c,b], b), I2 == 3 -> s(nth0_second_b, I2) ; s(nth0_second_b, no) ),

    %  ---- and cut inside the library does not leak out ----
    %  memberchk/2 is semidet, so backtracking into it must find nothing more
    yn((memberchk(Z1, [a,b]), Z1 == b), memberchk_is_semidet),

    %  ---- max_member/3 and min_member/3 take a closure: call/N ----
    ( max_member(shorter, M1, [abc, a, ab]) -> s(max_by_pred, M1) ; s(max_by_pred, no) ),
    ( min_member(shorter, M2, [abc, a, ab]) -> s(min_by_pred, M2) ; s(min_by_pred, no) ),
    true.

%  `shorter(A, B)' is true when B should beat A. Ordinary Prolog, called
%  through call/3 by max_member/3.
shorter(A, B) :- atom_length(A, LA), atom_length(B, LB), LB > LA.
