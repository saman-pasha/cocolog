%  bagof/3 and setof/3, and the grouping that makes them different predicates
%  from findall/3. Run by BOTH SWI-Prolog and cocolog, output compared.
%
%  THEY BACKTRACK. `bagof(X, p(X,Y), L)' answers once per distinct binding of
%  Y -- the goal's FREE variables, being those that appear in the goal, do not
%  appear in the template, and were not quantified away with `^'. That is the
%  whole of the difference, and it is why `findall' plus a sort is not these.
%
%  AND THEY FAIL ON NO SOLUTIONS, where findall answers [].

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

p(1,a). p(2,b). p(3,a). p(1,c).
q(1). q(2).
r(x, 1, one). r(x, 2, two). r(y, 3, three).

main :-
    %  ---- a ground witness: one group, no backtracking ----
    ( bagof(X1, p(X1,a), A1) -> s(ground_witness, A1) ; s(ground_witness, failed) ),

    %  ---- ^ quantifies the witness away, so it is one group again ----
    ( bagof(X2, Y2^p(X2,Y2), A2) -> s(caret, A2) ; s(caret, failed) ),
    ( bagof(X3, Y3^Z3^r(Y3,X3,Z3), A3) -> s(caret_twice, A3) ; s(caret_twice, failed) ),

    %  ---- everything in the template: no free variables at all ----
    ( bagof(X4-Y4, p(X4,Y4), A4) -> s(all_in_template, A4) ; true ),

    %  ---- THE GROUPING: one answer per witness, in witness order ----
    ( findall(Y5-L5, bagof(X5, p(X5,Y5), L5), A5) -> s(groups, A5) ; true ),
    ( findall(K6-L6, bagof(V6, (q(K6), V6 is K6 * 10), L6), A6) -> s(computed_groups, A6) ; true ),
    ( findall(W7-L7, bagof(N7, Z7^r(W7,N7,Z7), L7), A7) -> s(three_arg_groups, A7) ; true ),

    %  ---- no solutions is a FAILURE, not [] ----
    yn(bagof(X8, p(X8,zzz), _), no_solutions),
    ( findall(X9, bagof(X9, fail, _), A9) -> s(bagof_of_fail, A9) ; true ),
    %  findall over a failing goal answers [] and so SUCCEEDS once -- the
    %  outer findall therefore collects one solution. Its value is an unbound
    %  variable, whose name every Prolog numbers differently, so what is
    %  written is how many there were.
    ( findall(XA, findall(XA, fail, _), AA), length(AA, NA) -> s(findall_of_fail_count, NA) ; true ),

    %  ---- setof sorts and removes duplicates within each group ----
    ( setof(XB, p(XB,a), AB) -> s(setof_group, AB) ; true ),
    ( setof(XC, YC^p(XC,YC), AC) -> s(setof_caret, AC) ; true ),
    ( findall(YD-LD, setof(XD, p(XD,YD), LD), AD) -> s(setof_groups, AD) ; true ),
    ( setof(XE, member(XE,[c,a,b,a]), AE) -> s(setof_sorts, AE) ; true ),
    ( bagof(XF, member(XF,[c,a,b,a]), AF) -> s(bagof_keeps_order, AF) ; true ),
    ( setof(XG-YG, p(XG,YG), AG) -> s(setof_pairs, AG) ; true ),

    %  ---- keysort/2, which the grouping is built on ----
    ( keysort([b-1,a-2,b-3,a-4], AH) -> s(keysort, AH) ; true ),
    ( keysort([], AI) -> s(keysort_empty, AI) ; true ),

    %  ---- findall must leave no bindings behind, which is what made the
    %  ---- grouping wrong until it did
    ( findall(XJ, p(XJ,YJ), AJ), AJ = [_|_], ( var(YJ) -> s(findall_leaves_free, yes) ; s(findall_leaves_free, no) ) -> true ; true ),
    ( findall(XK, p(XK,_), AK) -> s(findall_all, AK) ; true ),
    true.
