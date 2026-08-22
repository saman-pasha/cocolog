%  library(lists): membership, appending, selecting and position.
%
%  RUN BY BOTH SWI-PROLOG AND COCOLOG and the output compared. Only what both
%  have may be used, and no compound term may be written -- the two writers
%  space operators differently, so `a-b' would differ on formatting alone.
%  A list IS written: both print `[a,b,c]' the same way.

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

main :-
    %  ---- append ----
    ( append([1,2], [3], A1) -> s(append_fwd, A1) ; s(append_fwd, no) ),
    ( append(A2, [3], [1,2,3]) -> s(append_back, A2) ; s(append_back, no) ),
    ( append([[1,2],[3],[]], A3) -> s(append_2, A3) ; s(append_2, no) ),
    ( append(A4, A5, [x,y]) -> s(append_split_a, A4), s(append_split_b, A5) ; true ),

    %  ---- member and memberchk ----
    yn(member(b, [a,b,c]), member_yes),
    yn(member(z, [a,b,c]), member_no),
    ( member(M1, [p,q]) -> s(member_first, M1) ; true ),
    ( memberchk(M2, [p,q]) -> s(memberchk_binds, M2) ; true ),
    yn(memberchk(q, [p,q]), memberchk_yes),
    yn(memberchk(z, [p,q]), memberchk_no),

    %  ---- select ----
    ( select(b, [a,b,c], S1) -> s(select_rest, S1) ; s(select_rest, no) ),
    ( select(b, [a,b,c], z, S2) -> s(select4, S2) ; s(select4, no) ),
    ( selectchk(a, [a,b,a], S3) -> s(selectchk, S3) ; s(selectchk, no) ),
    ( selectchk(b, [a,b,c], z, S3b) -> s(selectchk4, S3b) ; s(selectchk4, no) ),
    yn(select(z, [a,b], _), select_missing),

    %  ---- set operations ----
    ( subtract([a,b,c,d], [b,d], S4) -> s(subtract, S4) ; true ),
    ( intersection([a,b,c], [b,c,d], S5) -> s(intersection, S5) ; true ),
    ( union([a,b], [b,c], S6) -> s(union, S6) ; true ),
    yn(subset([a,b], [a,b,c]), subset_yes),
    yn(subset([a,z], [a,b,c]), subset_no),
    ( delete([a,b,a,c], a, S7) -> s(delete, S7) ; true ),

    %  ---- position ----
    ( nth0(1, [a,b,c], N1) -> s(nth0_bound, N1) ; s(nth0_bound, no) ),
    ( nth1(1, [a,b,c], N2) -> s(nth1_bound, N2) ; s(nth1_bound, no) ),
    ( nth0(N3, [a,b,c], c) -> s(nth0_search, N3) ; s(nth0_search, no) ),
    ( nth1(N4, [a,b,c], c) -> s(nth1_search, N4) ; s(nth1_search, no) ),
    yn(nth0(9, [a], _), nth0_out_of_range),
    ( nth0(1, [a,b,c], N5, N6) -> s(nth0_4_elem, N5), s(nth0_4_rest, N6) ; true ),
    ( nth1(1, [a,b,c], N7, N8) -> s(nth1_4_elem, N7), s(nth1_4_rest, N8) ; true ),
    ( nth0(N9, [a,b,c], b, NA) -> s(nth0_4_search, N9), s(nth0_4_rest2, NA) ; true ),
    ( last([a,b,c], L1) -> s(last, L1) ; s(last, no) ),
    yn(nextto(a, b, [a,b,c]), nextto_yes),
    yn(nextto(a, c, [a,b,c]), nextto_no),
    yn(prefix([a,b], [a,b,c]), prefix_yes),
    yn(prefix([b], [a,b,c]), prefix_no),
    true.
