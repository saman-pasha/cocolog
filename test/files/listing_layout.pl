%  listing/1 and portray_clause/1: the layout swipl gives a clause.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
:- dynamic d1/1.
:- multifile m1/1.
:- thread_local tl/1.
:- public pub/1.
:- volatile vol/1.

p_fact(a).
p_fact(b).
p_rule(A) :- q(A), r(A).
p_ops(A) :- A = alpha+beta*gamma, A \= -1, A =.. [foo, bar].
p_nested(A) :- (aa(A) ; bb(A)), (cc(A) -> dd(A) ; ee(A)).
p_ite(A) :- (aa(A) -> bb(A) ; cc(A)).
p_not(A) :- \+(aa(A), bb(A)).
p_long(A) :- aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa(A), bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb(A).
p_findall(A) :- findall(B, (qq(B), rr(B)), A).
p_call :- call((aa, bb)).
p_call_long :- call((long_predicate_one, long_predicate_two, long_predicate_three, long_predicate_four)).
p_wrap(A) :- some_predicate(argument_one(A), argument_two(A), argument_three(A), argument_four(A)).
p_wrap_list :- long_list([element_one, element_two, element_three, element_four, element_five, element_six]).
p_cut :- aa, !, bb.
p_true :- true.
p_empty.
p_list([a, b, c|_]).
p_curly({a, b}).
d1(x).
m1(z).
tl(y).
pub(p).
vol(v).
main :-
    forall(member(N, [p_fact/1,p_rule/1,p_ops/1,p_nested/1,p_ite/1,p_not/1,p_long/1,
                      p_findall/1,p_call/0,p_call_long/0,p_wrap/1,p_wrap_list/0,
                      p_cut/0,p_true/0,p_empty/0,p_list/1,p_curly/1,d1/1,m1/1,tl/1,pub/1,vol/1]),
           (format("~n=== listing ~w ===~n", [N]), listing(N))),
    format("~n=== portray_clause ===~n"),
    portray_clause((pc_fact(a))),
    portray_clause((pc_rule(A) :- qq(A), rr(A))),
    portray_clause((pc_nested(A) :- (aa(A) ; bb(A)), (cc(A) -> dd(A) ; ee(A)))),
    portray_clause((pc_ite(A) :- (aa(A) -> bb(A) ; cc(A)))),
    portray_clause((pc_not(A) :- \+(aa(A), bb(A)))),
    portray_clause((pc_findall(A) :- findall(B, (qq(B), rr(B)), A))),
    portray_clause((pc_call :- call((aa, bb)))),
    portray_clause((pc_cut :- aa, !, bb)),
    portray_clause((pc_true :- true)),
    portray_clause((pc_empty)),
    portray_clause((pc_list([a, b, c|_]))),
    portray_clause((pc_curly({a, b}))),
    portray_clause((pc_wrap(A) :- some_predicate(argument_one(A), argument_two(A), argument_three(A), argument_four(A)))),
    portray_clause(A),
    true.
