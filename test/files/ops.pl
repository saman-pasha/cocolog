%  op/3 and current_op/3. Run by BOTH SWI-Prolog and cocolog, output compared.
%
%  A DIRECTIVE, and it has to be: a declaration takes effect for the REST OF
%  THE FILE, so the clauses below are parsed with these in force.

:- op(700, xfx, ===>).
:- op(200, xfy, knows).
:- op(900, fy, very).
:- op(400, yfx, [under, over]).

s(Label, Value) :- write(Label), write(=), write(Value), nl.
yn(Goal, Label) :- ( call(Goal) -> s(Label, yes) ; s(Label, no) ).

rule(a ===> b).
rule(b ===> c).

main :-
    %  ---- the reader uses them ----
    ( X1 = (a ===> b), X1 = (P1 ===> Q1) -> s(infix_left, P1), s(infix_right, Q1) ; true ),
    ( X2 = (very a), X2 = (very Z2) -> s(prefix, Z2) ; s(prefix, failed) ),
    ( X3 = (a knows (b knows c)), X3 = (A3 knows B3) -> s(xfy_left, A3), s(xfy_right, B3) ; true ),
    %  a list of names in one declaration
    ( X4 = (a under b over c), X4 = (L4 over R4) -> s(yfx_left, L4), s(yfx_right, R4) ; true ),
    %  and the clauses in this file were parsed with them
    ( findall(R5, rule(R5), L5) -> s(clauses, L5) ; true ),

    %  ---- the writer uses them too ----
    write(a ===> b), nl,
    writeq(very a), nl,
    write(a under b over c), nl,

    %  ---- current_op/3 ----
    ( current_op(P6, T6, ===>) -> s(cur_prec, P6), s(cur_type, T6) ; s(cur, failed) ),
    ( current_op(P7, T7, very) -> s(cur_pre_prec, P7), s(cur_pre_type, T7) ; true ),
    ( current_op(P8, T8, under) -> s(from_list_prec, P8), s(from_list_type, T8) ; true ),
    %  the built-in table is there too
    ( current_op(P9, T9, ',') -> s(builtin_comma_prec, P9), s(builtin_comma_type, T9) ; true ),
    ( current_op(PA, TA, is) -> s(builtin_is_prec, PA), s(builtin_is_type, TA) ; true ),
    yn(current_op(_, _, nosuchoperator), unknown),
    %  THE ORDER OF SOLUTIONS IS NOT SPECIFIED, so anything that could see more
    %  than one is sorted before it is compared
    ( findall(PB-TB, current_op(PB, TB, -), LB), msort(LB, LBs) -> s(minus_both, LBs) ; true ),
    ( findall(NC, current_op(200, xfy, NC), LC), msort(LC, LCs) -> s(all_200_xfy, LCs) ; true ),

    %  ---- priority 0 takes one away ----
    ( op(0, xfy, knows) -> s(removed, ok) ; s(removed, failed) ),
    yn(current_op(_, _, knows), knows_after_removal),
    true.
