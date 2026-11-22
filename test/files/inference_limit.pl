%  call_with_inference_limit/3, swipl 9.0.4's (cocolog 3.73.0): COMPAT.md's
%  fifth group of small built-ins, the solutions'. The case holds:
%  - the result: `!' where the goal succeeded leaving no choice point,
%    `true' where it left one, each answer as the goal gives it,
%    inference_limit_exceeded where the goal ran out, a failure where it
%    failed, its ball thrown again, and the Result given unified last;
%  - the limit: an integer of 0 or more, else swipl's error in
%    system:'$inference_limit'/2's context; a goal of no inference at
%    0, the inline goals of a clause or a control structure spending
%    nothing, a goal meta-called on its own a call;
%  - the limit is a solution's: a redo into the goal has the limit again;
%  - it raises once: a catch inside the goal takes the ball, and the goal
%    runs on with no limit; any raise of inference_limit_exceeded is the
%    call's to take, a program's throw/1 of it too;
%  - nesting: an inner call's lower limit is the one in force, a higher
%    one leaves the outer's, whose raise the inner call takes, and the
%    outer's limit put back raises at the next call that is not the
%    limit's own; on a redo the inner call's limit replaces the outer's
%    until the goal's next exit;
%  - the goal's own errors, named as swipl's catch/3 names them;
%  - the goal under findall/3, forall/2, \+, setup_call_cleanup/3 and a
%    cut after an answer;
%  - determinism as the caller sees it: call_cleanup/2's Det, $/1 and
%    a guard;
%  - the predicate as predicate_property/2, current_predicate/1 and
%    clause/2 see it.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.72.0 cocolog had none, and a call raised existence_error.
%  The inferences a goal spends are each system's own count -- a
%  construct is a step in cocolog and an instruction in swipl, and an
%  is/2 an inference in cocolog that swipl's compiler puts into the
%  clause's code: cnt(100) below counts 204 in cocolog and 102 in swipl
%  -- so every limit here is far from both counts, but the small ones the
%  two agree on.
%  Not here, cocolog's own: the limit across a frozen machine (`cocolog
%  step', test/engine.pl) and in a thread and a green task
%  (test/thread.pl, test/async.pl).

%% the goals below name a variable to see what a call bound it to
:- style_check(-singleton).
:- use_module(library(lists)).   % cocolint: T1 -- swipl runs this file too, and member/2 is autoloaded there, which a limit would charge for

%% a term with its variables named, by a walk of its own
pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

%% how a goal ended, with its bindings; an error by its formal and the
%% predicate its context names
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

%% the properties swipl's predicate_property/2 gives a system predicate,
%% less those that move with the build and the file swipl's is read from
pp(H) :-
    findall(P, ( predicate_property(H, P),
                 \+ memberchk(P, [defined, size(_), last_modified_generation(_),
                                  number_of_clauses(_), number_of_rules(_),
                                  file(_), line_count(_)]) ), Ps),
    functor(H, N, A), print(N/A-Ps), nl.

loop :- loop.
cnt(0) :- !.
cnt(N) :- N1 is N - 1, cnt(N1).
m(X) :- member(X, [a,b,c]).
f.
%% a recursion whose every level spends free steps beside its counted ones
eqs(0) :- !.
eqs(N) :- N1 is N - 1, X = f(N), X = f(_), eqs(N1).

%% an inner call's redo, whose limit replaces the outer's until the
%% goal's next exit: the outer's put back there has passed
redo :-
    call_with_inference_limit(( member(X, [1,2,3]), ( X == 2 -> cnt(5000) ; true ) ),
                              1000000, R),
    pv(inner(X, R)), nl,
    X == 3.
%% ...and what the goal does under the inner limit after it has spent more
%% than the outer's left: it runs on, and writes
redo_w :-
    call_with_inference_limit(( member(X, [1,2,3]), ( X == 2 -> cnt(5000), write(w2), nl ; true ) ),
                              1000000, R),
    pv(inner(X, R)), nl,
    X == 3.

%% a goal whose second answer costs more than its first: a redo's limit is
%% its own, the redo's few steps beside it
sol(1).
sol(2) :- f, f, f.
sol(3) :- f.

%% a clause guarded by $/0 whose limited goal leaves a choice point, and
%% one whose goal leaves none
gq :- $, call_with_inference_limit(member(_, [a,b]), 1000, _), true.
gr :- $, call_with_inference_limit(member(_, [a]), 1000, _), true.

main :-
    results,
    limits,
    solutions,
    goals,
    nesting,
    inside,
    determinism,
    seen.

results :-
    t(r1, call_with_inference_limit(true, 1000, R1)),
    t(r2, call_with_inference_limit(fail, 1000, R2)),
    t(r3, call_with_inference_limit(loop, 1000, R3)),
    t(r4, call_with_inference_limit(cnt(10), 1000, R4)),
    t(r5, call_with_inference_limit(cnt(100000), 1000, R5)),
    all(r6, call_with_inference_limit(m(X6), 1000, R6)),
    all(r7, call_with_inference_limit(member(X7, [a,b]), 1000, R7)),
    all(r8, call_with_inference_limit(between(1, 3, X8), 1000, R8)),
    all(r9, call_with_inference_limit((X9 = 1 ; X9 = 2), 1000, R9)),
    t(r10, call_with_inference_limit(throw(boom), 1000, R10)),
    t(r11, call_with_inference_limit(throw(inference_limit_exceeded), 1000, R11)),
    t(r12, call_with_inference_limit(throw(error(type_error(a, b), _)), 1000, R12)),
    t(r13, call_with_inference_limit(true, 1000, !)),
    t(r14, call_with_inference_limit(true, 1000, true)),
    t(r15, call_with_inference_limit(m(X15), 1000, !)),
    t(r16, call_with_inference_limit(m(X16), 1000, true)),
    t(r17, call_with_inference_limit(loop, 1000, true)),
    t(r18, call_with_inference_limit(loop, 1000, inference_limit_exceeded)),
    t(r19, call_with_inference_limit(eqs(400), 1000, R19)).

limits :-
    t(l1, call_with_inference_limit(true, -1, R1)),
    t(l2, call_with_inference_limit(true, a, R2)),
    t(l3, call_with_inference_limit(true, _, R3)),
    t(l4, call_with_inference_limit(true, 1.5, R4)),
    t(l5, call_with_inference_limit(true, f(1), R5)),
    t(l6, call_with_inference_limit(loop, -1, R6)),
    t(l7, call_with_inference_limit(true, 0, R7)),
    t(l8, call_with_inference_limit(true, 1, R8)),
    t(l9, call_with_inference_limit(f, 0, R9)),
    t(l10, call_with_inference_limit(f, 1, R10)),
    t(l11, call_with_inference_limit((true, true), 0, R11)),
    t(l12, call_with_inference_limit((true, true), 1, R12)),
    t(l13, call_with_inference_limit((f, f), 1, R13)),
    t(l14, call_with_inference_limit(X14 = 1, 0, R14)),
    t(l15, call_with_inference_limit(X15 = 1, 1, R15)),
    t(l16, call_with_inference_limit(call(f), 1, R16)),
    t(l17, call_with_inference_limit(call(f), 2, R17)),
    t(l18, call_with_inference_limit(fail, 0, R18)),
    t(l19, call_with_inference_limit(true, 9223372036854775807, R19)),
    t(l20, call_with_inference_limit(false, 0, R20)),
    t(l21, call_with_inference_limit((f, false), 1000, R21)).

solutions :-
    all(s1, call_with_inference_limit((member(X1, [1,2,3]), cnt(300)), 1000, R1)),
    all(s2, call_with_inference_limit((member(X2, [1,2,3]), cnt(100000)), 1000, R2)),
    all(s3, call_with_inference_limit((member(X3, [1,2,3]), ( X3 == 2 -> cnt(100000) ; true )), 1000, R3)),
    all(s4, call_with_inference_limit((member(X4, [1,2,3]), ( X4 == 2 -> throw(oops) ; true )), 1000, R4)),
    all(s5, call_with_inference_limit((member(X5, [1,2,3]), X5 > 1), 1000, R5)),
    all(s6, call_with_inference_limit((between(1, 3, X6), X6 > 2), 1000, R6)),
    t(s7, findall(X7-R7, call_with_inference_limit(member(X7, [a,b,c]), 1000, R7), L7)),
    t(s8, (call_with_inference_limit(member(X8, [a,b]), 1000, R8), X8 == b)),
    t(s9, (call_with_inference_limit(member(X9, [a,b]), 1000, R9), !, cnt(5000))),
    all(s10, call_with_inference_limit(sol(X10), 1, R10)),
    all(s11, call_with_inference_limit(sol(X11), 2, R11)).

goals :-
    t(g1, call_with_inference_limit(foo_undefined, 100000000, R1)),
    t(g2, call_with_inference_limit(3, 1000, R2)),
    t(g3, call_with_inference_limit(_, 1000, R3)),
    t(g4, call_with_inference_limit(user:loop, 1000, R4)),
    t(g5, call_with_inference_limit(lists:member(a, [a]), 1000, R5)),
    t(g6, call_with_inference_limit((fail ; true), 1000, R6)),
    t(g7, call_with_inference_limit(\+ fail, 1000, R7)).

nesting :-
    t(n1, call_with_inference_limit(call_with_inference_limit(loop, 1000, I1), 100000, R1)),
    t(n2, call_with_inference_limit(call_with_inference_limit(loop, 100000, I2), 1000, R2)),
    t(n3, call_with_inference_limit((call_with_inference_limit(loop, 100000, I3), cnt(10)), 1000, R3)),
    t(n4, call_with_inference_limit((call_with_inference_limit(loop, 100000, I4), true), 1000, R4)),
    t(n5, call_with_inference_limit((cnt(300), call_with_inference_limit(cnt(100), 100000, I5)), 1000, R5)),
    t(n6, call_with_inference_limit(call_with_inference_limit(cnt(300), 100, I6), 1000, R6)),
    t(n7, call_with_inference_limit((call_with_inference_limit(cnt(300), 100, I7), cnt(300)), 1000, R7)),
    t(n8, call_with_inference_limit((call_with_inference_limit(cnt(300), 100, I8), cnt(100000)), 1000, R8)),
    t(n9, call_with_inference_limit(call_with_inference_limit(loop, 0, I9), 1000, R9)),
    t(n10, call_with_inference_limit((call_with_inference_limit(loop, 1000, I10), loop), 2000, R10)),
    t(n11, call_with_inference_limit(call_with_inference_limit(true, 5, I11), 10, R11)),
    t(n12, call_with_inference_limit(call_with_inference_limit(fail, 10, I12), 1000, R12)),
    t(n13, call_with_inference_limit(call_with_inference_limit(throw(x), 10, I13), 1000, R13)),
    t(n14, call_with_inference_limit(redo, 1000, R14)),
    t(n15, call_with_inference_limit(call_with_inference_limit(call_with_inference_limit(loop, 100000, I15a), 100000, I15b), 1000, R15)),
    t(n16, call_with_inference_limit(call_with_inference_limit(cnt(1000), 100000, I16), 1000, R16)),
    t(n17, call_with_inference_limit((call_with_inference_limit(fail, 10, I17) ; cnt(100)), 1000, R17)),
    t(n18, call_with_inference_limit(redo_w, 1000, R18)).

inside :-
    t(i1, call_with_inference_limit(catch(loop, E1, true), 1000, R1)),
    t(i2, call_with_inference_limit((catch(loop, E2, true), cnt(10)), 1000, R2)),
    t(i3, call_with_inference_limit(catch(loop, error(E3, _), true), 1000, R3)),
    t(i4, catch(call_with_inference_limit(loop, 1000, R4), E4, true)),
    t(i5, call_with_inference_limit(setup_call_cleanup(true, loop, (write(cleanup), nl)), 1000, R5)),
    t(i6, call_with_inference_limit(\+ loop, 1000, R6)),
    t(i7, call_with_inference_limit(findall(X7, between(1, inf, X7), _), 1000, R7)),
    t(i8, call_with_inference_limit(forall(member(_, [1,2,3]), cnt(100000)), 1000, R8)),
    t(i9, call_with_inference_limit(findall(Y9, member(Y9, [1,2]), L9), 1000, R9)),
    t(i10, call_with_inference_limit(findall(Y10, (member(Y10, [1,2]), cnt(100)), L10), 1000, R10)),
    t(i11, call_with_inference_limit(forall(member(_, [1,2,3]), cnt(10)), 1000, R11)),
    t(i12, call_with_inference_limit(catch(throw(inference_limit_exceeded), E12, true), 1000, R12)),
    t(i13, call_with_inference_limit((findall(X13, catch(loop, X13, true), L13), cnt(10)), 1000, R13)),
    t(i14, call_with_inference_limit((with_output_to(string(S14), catch(loop, E14, true)), cnt(10)), 1000, R14)),
    t(i15, call_with_inference_limit(findall(N15, (between(1, 3, N15), eqs(100)), L15), 1000, R15)),
    t(i16, call_with_inference_limit(with_output_to(string(S16), (write(a), loop)), 1000, R16)).

determinism :-
    t(d1, (call_cleanup(call_with_inference_limit(member(X1, [a]), 1000, R1), D1 = det), D1 == det)),
    t(d2, (call_cleanup(call_with_inference_limit(member(X2, [a,b]), 1000, R2), D2 = det), var(D2))),
    t(d3, catch($(call_with_inference_limit(member(X3, [a,b]), 1000, R3)), E3, true)),
    t(d4, catch($(call_with_inference_limit(member(X4, [a]), 1000, R4)), E4, true)),
    t(d5, catch(gq, E5, true)),
    t(d6, catch(gr, E6, true)),
    t(d7, (call_cleanup(call_with_inference_limit(loop, 1000, R7), D7 = det), D7 == det)).

seen :-
    pp(call_with_inference_limit(_, _, _)),
    t(c1, current_predicate(call_with_inference_limit/3)),
    %% its clause's first goal sets the limit from its second argument
    (   clause(call_with_inference_limit(_, B2, _), Body2),
        Body2 = (First2, _), First2 = '$inference_limit'(L2, _), L2 == B2
    ->  print(c2-yes)
    ;   print(c2-no)
    ),
    nl.
