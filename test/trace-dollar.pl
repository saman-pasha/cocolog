%% A predicate whose name begins with `$' under trace (3.78.3), for
%% test/trace.pl: no port, as none of swipl's is -- its resetProcedure()
%% sets TRACE_ME on no such predicate, a program's own among them -- and
%% what it calls asked as any call's is, so a program's `$' predicate hides
%% nothing. A retry inside one is the Redo swipl's dbgRedoFrame finds: the
%% library call it is in, where its caller hides its children, and none
%% where its caller hides nothing.

'$dx'(1).
'$dx'(2).
'$dy' :- atom(a).
'$dz'(X) :- dp(X).
dp(1).
dp(2).
dw(X) :- '$dx'(X).

%% no port, and what it calls the program's
dl1 :- '$dx'(_), '$dy'.
%% its retry is no Redo: of itself, nor of the call it is in
dl2 :- '$dx'(X), X > 1.
dl3 :- dw(X), X > 1.
%% a call it makes is retried as its own
dl4 :- '$dz'(X), X > 1.
%% a builtin's own `$' predicate, called by the program
dl5 :- '$skip_list'(_, [a], _).
%% setup_call_cleanup/3's setup and cleanup, queries of their own: the `$'
%% call no port, what it calls one
dl6 :- setup_call_cleanup('$dy', true, '$dy').

%% a library's `$' helper: a retry inside it is the Redo of the library
%% call the program made, once that has exited
:- set_prolog_flag(generate_debug_info, false).
dn(X) :- '$dn'(X).
'$dn'(1).
'$dn'(2).
dm(X) :- '$dm'(X).
'$dm'(X) :- dn2(X).
dn2(1).
dn2(2).
:- set_prolog_flag(generate_debug_info, true).
dl7 :- dn(X), X > 1.
dl8 :- dm(X), X > 1.
%% and called by the program: no port, and its retry no Redo
dl9 :- '$dn'(X), X > 1.
dl10 :- dv(X), X > 1.
dv(X) :- '$dn'(X).
