%% trace-library.pl -- the program library calls are traced over, held to
%% SWI by test/trace.pl (3.27.0). A library predicate a program's clause
%% calls is a port of its own, and what it calls is no port -- its
%% helpers, the builtins they call -- but a program's predicate called back
%% (max_member/3's order, forall/2's action): swipl's isDebugFrame. A retry
%% inside one is the Redo of the library call the program made, once that
%% has exited (swipl's dbgRedoFrame). trace-diff.pl takes swipl's module
%% qualifiers off (lists:member), so the goals compare as cocolog writes
%% them.

%% a library call, then a goal that fails into it
p(X) :- member(X, [1, 2]), X > 1.
q(L) :- append(L, _, [a, b]), L = [_].
r(N) :- nth0(N, [a, b], b).
s(L) :- length(L, 2).
t(L) :- last([1, 2], L).
u(X) :- between(1, 3, X), X > 2.
v(S) :- msort([b, a], S).

%% a library call that calls the program back, or starts a search
a(X) :- findall(Y, member(Y, [1, 2]), X).
b(M) :- max_member(lt, M, [1, 2, 3]).
lt(X, Y) :- X < Y.
c :- forall(member(X, [1]), d(X)).
d(_).
e(L) :- sum_list([1, 2], L).
f(S) :- list_to_set([a, a], S).
g(P) :- permutation([1, 2], P).
h(X) :- phrase(hh(X), [a]).
hh(a) --> [a].

%% a system predicate cocolog writes as clauses, which swipl's C or boot
%% files define: its own call is a port, what its clauses call none
w(B) :- file_base_name('a/b.pl', B).
ld :- load_files([], []).

%% every answer of a library call failed past: its Redos, its last
%% answer's quiet end, and append/3's last retry, whose heads all fail,
%% said as its Redo and its Fail
m5 :- member(X, [1, 2]), X > 5.
a5 :- append(X, _, [1, 2]), X = [9].
b5 :- between(1, 2, X), X > 5.
n5 :- nth0(I, [a, b], _), I > 5.
s5 :- select(X, [1, 2], _), X > 5.
md(X) :- member(X, [1, 2]).
u5 :- md(X), X > 5.

%% a library clause whose body is `fail' (max_member/2's rule for an empty
%% list): swipl's compiler makes it no call, and cocolog's construct is no
%% port inside a library's clause
xm(X) :- max_member(X, []).

%% retract/1 and clause/2 walk the clauses that stood when they began
%% (3.28.0): a retry is the call's Redo, each answer an Exit
:- dynamic(rq/1).
rq(1).
rq(2).
rq(3).
rt(X) :- retract(rq(X)), X > 1.
ct(X) :- clause(rq(X), true), X > 2.

%% generate_debug_info false: what this file defines from here on hides its
%% children as a library's predicates do, until the flag is true again --
%% its own call is a port, nothing it calls is
:- set_prolog_flag(generate_debug_info, false).
%% a directive's goal under the flag: cocolog reads its libraries at a
%% `run' file's first one, inside this read, each library with the flag its
%% own -- or library(pairs)' pairs_keys/2 would hide what it calls from
%% f/1's trace
:- true.
nd(X) :- nd2(X), X > 1.
nd2(X) :- member(X, [1, 2]).
%% a predicate's first clause decides, and a clause of its read with the
%% flag true later does not undo it (swipl's assert_term)
:- discontiguous(kd/1).
kd(X) :- nd2(X).
%% the flag set by a goal is the same flag, true here and false below
:- true, set_prolog_flag(generate_debug_info, true).
ud(X) :- nd(X).
kd(9).
:- true, set_prolog_flag(generate_debug_info, false).
gd(X) :- nd2(X).
%% a walk hidden in a call that hides its children: its retry is that
%% call's Redo, once it has exited
nr(X) :- retract(rq(X)).
:- set_prolog_flag(generate_debug_info, true).
vd(X) :- gd(X).
ur(X) :- nr(X), X > 1.
%% and false again to the end: the file's end puts the flag back, so a file
%% read after this one is the program's (test/trace.pl, the second file)
:- set_prolog_flag(generate_debug_info, false).
%% what a clause under the flag runs in place is no port either: its `true'
%% and its `fail', a builtin under a qualifier and one of no arguments
nt :- true, fail.
nq(X) :- system:atom_length(abc, X).
nn :- nl.
