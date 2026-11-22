%  call_with_depth_limit/3, swipl 9.0.4's (cocolog 3.74.0): COMPAT.md's
%  fifth group of small built-ins, the solutions'. The case holds:
%  - the result: the deepest level the goal's frames reached below the
%    call, 1 at least; depth_limit_exceeded where a frame past the limit
%    was failed and the goal failed with it; a failure where the goal
%    failed short of the limit; its ball thrown again; and the Result
%    given unified last;
%  - the limit: an integer of 0 or more, else swipl's error in
%    system:'$depth_limit'/3's context;
%  - the levels: each frame one below its parent's, a last call's too; a
%    control construct no frame, nor in a clause the goals swipl compiles
%    in place (=/2, ==/2, \==/2, the type tests, arg/3, is/2 of a sum
%    with a small integer), where called as goals of their own they are
%    frames; a meta-call's goal a frame, a structure's goals each one, the
%    structure none;
%  - the builtins that run frames of their own, as deep as swipl's run:
%    findall/3,4, forall/2, aggregate_all/3, with_output_to/2, format/2's
%    ~@; and the predicates swipl writes as clauses where cocolog's C
%    answers, by their arguments: nth0/3, nth1/3, last/2, reverse/2,
%    memberchk/2, sum_list/2, max_list/2, min_list/2, numlist/3,
%    length/2, the declarations, bagof/3, setof/3, must_be/2's raises, a
%    single-sided rule that matches nothing;
%  - setup_call_cleanup/3: its setup a frame below sig_atomic/1's query,
%    `true' none; its goal a meta-call of setup_call_catcher_cleanup/4;
%    its cleanup two below it, failed silently past the limit, the call
%    going on with the depth the cleanup's frame reached -- a cleanup that
%    is a control structure too, and one a cut runs;
%  - the answers: a redo has the limit again, each answer the depth its
%    own search reached since the one before;
%  - nesting: an inner call's own depth, the outer's reached never
%    counting the inner's frames past its own;
%  - iterative deepening, what the predicate is for;
%  - the predicate as predicate_property/2 and current_predicate/1 see it.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.73.2 cocolog had none, and a call raised existence_error.
%  Not here, as not swipl's (COMPAT.md): print_message/2's own frames.
%  Not here, cocolog's own: the limit across a frozen machine (`cocolog
%  step', test/engine.pl), in a thread and a green task (test/thread.pl,
%  test/async.pl).

%% the goals below name a variable to see what a call bound it to
:- style_check(-singleton).
:- use_module(library(lists)).   % cocolint: T1 -- swipl runs this file too, and member/2 is autoloaded there, which a limit would count
:- use_module(library(apply)).   % cocolint: T1 -- swipl runs this file too, and maplist/2 is autoloaded there, which a limit would count
:- use_module(library(aggregate)).   % cocolint: T1 -- swipl runs this file too, and aggregate_all/3 is autoloaded there, which a limit would count
:- use_module(library(error)).

%% a term with its variables named, by a walk of its own
pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

%% how a goal ended under a limit, an error by its formal
r(G, Lim, R) :-
    copy_term(G, G1),
    catch(( call_with_depth_limit(G1, Lim, R0) -> R = R0 ; R = failed ), E, R = caught(E)).
short(caught(error(F, _)), caught(F)) :- !.
short(X, X).

%% each limit from 0 to N, and how the goal ended under each
d(L, G, N) :-
    findall(Lim-S, ( between(0, N, Lim), r(G, Lim, R), short(R, S) ), Rs),
    pv(L-G-Rs), nl.

%% how a goal ended, its bindings or its ball
t(L, G) :-
    catch(( G -> R = yes(G) ; R = no ), E, R = caught(E)),
    % cocolint: C2 -- each ball here is a builtin's or the goal's, whose context names it as swipl's
    (   R = caught(error(F, context(C, _)))
    ->  pv(L-caught(F, C))
    ;   pv(L-R)
    ),
    nl.

%% every answer of a goal, then how it ended
all(L, G) :-
    catch(( G, pv(L-G), nl, fail ; true ), E, ( pv(L-caught(E)), nl )).

f.
f1(_).
g :- f.
h3 :- g.
m(1).
m(2).
loop :- loop.
cnt(0) :- !.
cnt(N) :- N1 is N - 1, cnt(N1).
len([], 0).
len([_|T], N) :- len(T, N0), N is N0 + 1.
%% a last call, which swipl's frame stands one below its parent's for too
acc([], N, N).
acc([_|T], N0, N) :- N1 is N0 + 1, acc(T, N1, N).
%% answers whose searches go to depths of their own
ans(1).
ans(X) :- h3, X = 2.
ans(X) :- g, X = 3.

%% the goals swipl compiles in place in a clause, and those it calls
e1(Y) :- _ is Y + 1.
e2(Y) :- X is Y + 1, X > 0.
e3(Y) :- X is Y + 1, X == 2.
e4(Y) :- X is 1 + Y, X == 2.
e5(Y) :- X is Y - 1, X == 0.
e6(Y) :- X is Y * 1, X == 1.
e7(Y) :- Y == f(a).
e8(Y) :- Y == [].
e9(Y) :- Y == [a].
e10(Y) :- f(Y) = f(1).
e11(Y) :- var(Y), Y = 1.
e12(Y) :- atom(Y).
e13(Y) :- arg(1, Y, A), A == a.
e14(Y) :- arg(1, Y, A), atom(A).
e15(Y) :- Y == 1.5.
e16(Y) :- integer(Y), Y > 0.
e17(Y) :- X = f(Y), X == f(1).
e18(Y) :- \+ Y == 2.
e19(Y) :- ( Y == 1 -> true ; fail ).
e20(Y) :- Y \== 2, number(Y), atomic(Y).
e21(Y) :- callable(Y), compound(Y), nonvar(Y).

%% a search a depth limit makes finite: a path of at most N steps
edge(a, b).
edge(b, c).
edge(c, a).
edge(c, d).
path(X, X, [X]).
path(X, Y, [X|P]) :- edge(X, Z), path(Z, Y, P).
%% the least limit that finds one, each limit a search of its own
deepen(G, D) :-
    between(1, 20, D),
    call_with_depth_limit(G, D, R),
    R \== depth_limit_exceeded,
    !.

%% a property swipl gives a system predicate, less those that move with
%% the build and the file swipl's is read from
pp(H) :-
    findall(P, ( predicate_property(H, P),
                 \+ memberchk(P, [defined, size(_), last_modified_generation(_),
                                  number_of_clauses(_), number_of_rules(_),
                                  file(_), line_count(_)]) ), Ps),
    functor(H, N, A), print(N/A-Ps), nl.

main :-
    results,
    limits,
    levels,
    in_place,
    constructs,
    builtins,
    lists,
    declarations,
    cleanups,
    answers,
    nesting,
    deepening,
    seen.

results :-
    d(r1, true, 2),
    d(r2, f, 2),
    d(r3, g, 3),
    d(r4, fail, 2),
    d(r5, loop, 3),
    d(r6, cnt(5), 7),
    d(r7, throw(boom), 2),
    d(r8, (g, throw(boom)), 3),
    d(r9, undefined_p, 2),
    t(r10, call_with_depth_limit(f, 5, 1)),
    t(r11, call_with_depth_limit(f, 5, 2)),
    t(r12, call_with_depth_limit(loop, 5, depth_limit_exceeded)),
    t(r13, call_with_depth_limit(fail, 5, depth_limit_exceeded)),
    t(r14, call_with_depth_limit(cnt(50), 60, R14)),
    t(r15, call_with_depth_limit(loop, 200, R15)),
    t(r16, call_with_depth_limit(catch(cnt(10), _, true), 3, R16)).

limits :-
    t(l1, call_with_depth_limit(f, -1, R1)),
    t(l2, call_with_depth_limit(f, a, R2)),
    t(l3, call_with_depth_limit(f, _, R3)),
    t(l4, call_with_depth_limit(f, 1.5, R4)),
    t(l5, call_with_depth_limit(f, 9223372036854775807, R5)),
    t(l6, call_with_depth_limit(f, 4611686018427387904, R6)),
    t(l7, call_with_depth_limit(_, 5, R7)),
    t(l8, call_with_depth_limit(1, 5, R8)),
    t(l9, call_with_depth_limit(atom_length(_, _), 5, R9)),
    t(l10, call_with_depth_limit(atom_length(1, N10), 5, R10)),
    d(l11, atom_length(_, _), 1).

levels :-
    d(v1, len([a,b,c], _), 6),
    d(v2, acc([a,b,c], 0, _), 6),
    d(v3, h3, 4),
    d(v4, (f, g, h3), 4),
    d(v5, call(h3), 5),
    d(v6, call(call(h3)), 6),
    d(v7, f1(x), 2).

in_place :-
    forall(member(G, [e1(1), e2(1), e3(1), e4(1), e5(1), e6(1), e7(f(a)), e8([]),
                      e9([a]), e10(1), e11(_), e12(a), e13(f(a)), e14(f(a)),
                      e15(1.5), e16(1), e17(1), e18(1), e19(1), e20(1), e21(f(a))]),
           d(i, G, 3)),
    d(i1, (X1 = 1), 2),
    d(i2, (a == a), 2),
    d(i3, atom(a), 2),
    d(i4, (X4 is 1 + 1), 2),
    d(i5, arg(1, f(a), _), 2).

constructs :-
    forall(member(G, [once(f), once((f, f)), ignore(f), ignore((f, f)), \+ \+ f,
                      call(f), call((f, f)), call(call(f)), catch(f, _, true),
                      catch((f, f), _, true), catch(throw(x), _, f),
                      catch(throw(x), _, (f, f)), not(fail), not((fail, f)),
                      (f -> f ; f), call((f -> f ; f)), (f *-> g ; f), user:f,
                      user:(f, f), call(user:(f, f)), @(f, user), $(f), call($(f)),
                      call(undefined_q), (fail ; g), (g ; f), forall(m(_), g)]),
           d(c, G, 5)).

builtins :-
    forall(member(G, [aggregate_all(count, f, _), aggregate_all(count, g, _),
                      aggregate_all(sum(1), f, _), aggregate_all(max(1), f, _),
                      aggregate_all(min(1), f, _), aggregate_all(bag(x), f, _),
                      aggregate_all(set(x), f, _), aggregate_all(max(1, w), f, _),
                      aggregate_all(r(count, sum(1)), f, _),
                      with_output_to(string(_), f), with_output_to(string(_), (f, f)),
                      with_output_to(string(_), fail), format(atom(_), '~@', [f]),
                      format(atom(_), '~@', [(f, f)]), forall(f, f), forall((f, f), f),
                      forall(f, (f, f)), forall(g, true), findall(x, f, _),
                      findall(x, (f, f), _), findall(x, f, _, []), findall(x, g, _),
                      bagof(x, f, _), setof(x, f, _), bagof(X^x, f1(X), _),
                      bagof(X-Y, member(X-Y, [1-a, 2-b, 1-c]), _),
                      setof(X, member(X, [c, a, b, a]), _),
                      length([a], _), length(_, 2), nb_setval(k, 1), format(''),
                      atom_length(a, _), succ(1, _), msort([b, a], _),
                      sort(0, @>=, [1, 2], _), between(1, 2, _), maplist(f1, [a, b]),
                      foldl([_, A0, A0]>>true, [a], 0, _), call([X1]>>f1(X1), a)]),
           d(b, G, 9)),
    %% library(error)'s raises, each through its raiser, as swipl's
    forall(member(G, [must_be(integer, a), must_be(integer, _), must_be(positive_integer, -1),
                      must_be(positive_integer, a), must_be(list, [a|b]),
                      must_be(list(integer), [1, a]), must_be(boolean, x),
                      must_be(oneof([a, b]), c), must_be(var, a), must_be(acyclic, _),
                      must_be(nosuchtype, a), is_of_type(integer, a), must_be(callable, 3),
                      must_be(atom, f(x))]),
           d(e, G, 9)),
    %% aggregate_all/3's general clause, the library's own (3.75.0):
    %% count(T) a term of templates, and a bag or a set over T^G
    forall(member(G, [aggregate_all(count(X2), member(X2, [a]), _),
                      aggregate_all(count(_), fail, _), aggregate_all(count(X3), f1(X3), _),
                      aggregate_all(count(f(_)), f, _), aggregate_all(count(1), f, _),
                      aggregate_all(count(X4), X4^f1(X4), _),
                      aggregate_all(count(X5), (f1(X5), g), _),
                      aggregate_all(r(count(_), sum(1)), f, _),
                      aggregate_all(bag(X6), X6^f1(X6), _),
                      aggregate_all(set(X7), Y7^member(X7-Y7, [a-1, a-2]), _),
                      aggregate_all(bag(X8), _:(X8^f1(X8)), _),
                      aggregate_all(bag(X9), X9^Y9^member(X9-Y9, [a-1]), _),
                      aggregate_all(bag(X10), X10^g, _), aggregate_all(set(x), _^g, _),
                      %% a spec or a goal refused, by the raiser's frames
                      aggregate_all(foo, f, _), aggregate_all([], f, _), aggregate_all(1, f, _),
                      aggregate_all(_, f, _), aggregate_all(count(a, b), f, _),
                      aggregate_all(sum(_), 3, _), aggregate_all(bag(_), 3, _),
                      aggregate_all(count, _, _), aggregate_all(max(_), f, _),
                      aggregate_all(max(x, _), f, _),
                      %% the specific clauses over several answers
                      aggregate_all(count, member(_, [a, b]), _),
                      aggregate_all(sum(X11), member(X11, [1, 2]), _),
                      aggregate_all(max(X12), member(X12, [1, 3, 2]), _),
                      aggregate_all(min(X13, W13), member(X13-W13, [2-a, 1-b]), _),
                      aggregate_all(max(X14, W14), member(X14-W14, [1-a, 3-b]), _)]),
           d(a, G, 9)).

lists :-
    forall(member(G, [nth0(0, [a,b,c], _), nth0(2, [a,b,c], _), nth0(5, [a,b,c], _),
                      nth0(-1, [a], _), nth0(3, [a|_], _), nth0(0, _, _),
                      nth0(a, [x], _), nth0(10, [a,b,c,d,e,f,g,h,i,j,k,l], _),
                      nth0(0, [a,b], b), nth0(_, [a], a), nth1(1, [a,b,c], _),
                      nth1(3, [a,b,c], _), nth1(0, [a], _), nth1(4, [a|_], _),
                      nth1(1, [a], b), nth1(_, [a,b], b), last([], _), last([a], _),
                      last([a,b,c], _), last([a,b|foo], _), last([a,b], c), last([a|_], _),
                      reverse([], _), reverse([a], _), reverse([a,b,c], _),
                      reverse([a,b,c], [_]), reverse([a,b|foo], _), reverse(foo, _),
                      reverse([a,b,c], [c,b,a]), reverse([a,b], [a,b,c]), reverse(_, [a]),
                      memberchk(a, [a]), memberchk(c, [a,b,c]), memberchk(z, [a,b]),
                      memberchk(a, [b|_]), memberchk(a, [b,c|_]), memberchk(_, _),
                      sum_list([], _), sum_list([1], _), sum_list([1,2,3], _),
                      sum_list([1,a,3], _), sum_list([1,2|_], _), sum_list([1|foo], _),
                      sum_list(foo, _), sum_list([1+1,2], _), max_list([], _),
                      max_list([1,2,3], _), max_list([1,a,3], _), max_list(foo, _),
                      min_list([1,2,3], _), min_list([3,a], _), numlist(1, 1, _),
                      numlist(1, 5, _), numlist(3, 1, _), numlist(a, 1, _),
                      numlist(_, 1, _), numlist(1, 3, [1,2,4]), numlist(1, 2, foo),
                      length([a|T], T), length(foo, 1), length(_, -1)]),
           d(s, G, 7)).

declarations :-
    forall(member(G, [dynamic(dq1/1), dynamic([dq2/1, dq3/1]), dynamic((dq4/1, dq5/1)),
                      dynamic(user:dq6/1), dynamic(_), dynamic(foo), dynamic([]),
                      dynamic([dq7/1|_]), dynamic(dq8/a), discontiguous(dq9/1),
                      multifile(dq10/1), public(dq11/1), module_transparent(dq12/1),
                      volatile(dq13/1), thread_local(dq14/1), meta_predicate(dq15(0)),
                      public([dq16/1, dq17/1])]),
           d(x, G, 11)).

cleanups :-
    forall(member(G, [setup_call_cleanup(true, f, true), setup_call_cleanup(true, f, g),
                      setup_call_cleanup(true, g, f), setup_call_cleanup(g, f, f),
                      setup_call_cleanup(true, fail, g), setup_call_cleanup(true, throw(x), g),
                      setup_call_cleanup(true, m(_), g), call_cleanup(g, g),
                      call_cleanup(m(_), g), call_cleanup(fail, g),
                      setup_call_cleanup(true, (f, f), g), setup_call_cleanup(true, f, fail),
                      setup_call_cleanup(true, f, throw(y)), setup_call_cleanup(h3, h3, h3)]),
           d(u, G, 7)),
    forall(member(G, [setup_call_cleanup(true, fail, (g, g)), setup_call_cleanup(true, throw(x), (g, g)),
                      setup_call_cleanup(true, f, (g ; g)), setup_call_cleanup(true, f, \+ fail),
                      setup_call_cleanup(true, f, call(g)), setup_call_cleanup(true, f, (h3, h3)),
                      setup_call_cleanup(true, f, (h3 -> h3 ; h3)), setup_call_cleanup(true, f, once(h3)),
                      setup_call_cleanup(h3, f, (g, h3)), call_cleanup(member(_, [1]), (h3, g)),
                      ( setup_call_cleanup(true, member(_, [1,2]), (g, h3)), ! ),
                      setup_call_catcher_cleanup(true, throw(y), C, ( C = exception(_) -> h3 ; g ))]),
           d(v, G, 8)).

answers :-
    all(a1, call_with_depth_limit(ans(_), 10, _)),
    all(a2, call_with_depth_limit(ans(_), 3, _)),
    all(a3, call_with_depth_limit(ans(_), 2, _)),
    all(a4, call_with_depth_limit(member(_, [a,b,c]), 5, _)),
    all(a5, call_with_depth_limit(member(_, [a,b,c]), 1, _)),
    all(a6, call_with_depth_limit(between(1, 3, _), 1, _)),
    all(a7, call_with_depth_limit(m(_), 1, _)),
    all(a8, (call_with_depth_limit(ans(X8), 10, R8), X8 == 3)),
    all(a9, call_with_depth_limit(path(a, d, _), 5, _)).

nesting :-
    all(n1, call_with_depth_limit(call_with_depth_limit(h3, 10, _), 10, _)),
    all(n2, call_with_depth_limit(call_with_depth_limit(h3, 1, _), 10, _)),
    all(n3, call_with_depth_limit(call_with_depth_limit(h3, 10, _), 2, _)),
    all(n4, call_with_depth_limit((call_with_depth_limit(h3, 10, _), h3), 10, _)),
    all(n5, call_with_depth_limit(call_with_depth_limit(ans(_), 10, _), 10, _)),
    all(n6, call_with_depth_limit(call_with_depth_limit(cnt(20), 5, _), 30, _)),
    all(n7, call_with_depth_limit(findall(R7, call_with_depth_limit(h3, 10, R7), _), 20, _)).

deepening :-
    t(p1, deepen(path(a, d, P1), D1)),
    t(p2, deepen(path(a, a, P2), D2)),
    t(p3, deepen(path(b, d, P3), D3)),
    t(p4, deepen(cnt(12), D4)).

seen :-
    pp(call_with_depth_limit(_, _, _)),
    t(q1, current_predicate(call_with_depth_limit/3)),
    t(q2, predicate_property(call_with_depth_limit(_, _, _), meta_predicate(M2))).
