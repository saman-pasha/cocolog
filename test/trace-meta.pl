%% call/1 of a control structure under trace (3.78.4), for test/trace.pl:
%% swipl's I_USERCALL compiles a structure into a clause of its own and
%% runs it in a `'<meta-call>'/1' frame -- a level below the call, no port,
%% and hiding nothing -- so the structure's parts stand a level deeper than
%% the call would, a builtin among them is a port (in a library's clause
%% too), and a retry of a `;' in it is no Redo. Its qualifiers, each an
%% atom, come off first, and a variable goal is call/1 of it. forall/2
%% meta-calls its condition and its action, and setup_call_cleanup/3's
%% frame its goal, the same way. Through 3.78.3 cocolog's call/1 ran the
%% structure at the call's own level, and in a library's clause hid its
%% builtins.
%%
%% Not here: call/N's structure, which swipl calls as boot/init.pl's
%% control predicate -- `','/2' a port, the meta-call inside it -- and
%% findall/3's and aggregate_all/3's goals, which swipl's clauses run
%% frames deeper (COMPAT.md, the trace row; test/trace.pl's own lines).

%% the store's first predicate, under `run' the file's first: one that hides
%% its children, which a meta-call frame must not be read as (its frame
%% names no predicate, `coco_trace_meta'; with predicate 0 named, mt8's and
%% mt37's member/2 lost its Redo)
:- set_prolog_flag(generate_debug_info, false).
mt_h0.
:- set_prolog_flag(generate_debug_info, true).

mt_p(1).
mt_p(2).

%% a conjunction, a disjunction, an if-then-else: the parts a level deeper
mt1 :- G = (atom(a), atom(b)), call(G).
mt2 :- call((mt_p(X), X > 1)).
mt3 :- G = (fail ; atom(c)), call(G).
mt4 :- G = (atom(a) -> atom(b) ; fail), call(G).
%% the clause goes on at its own level after the structure
mt5 :- call((atom(a), mt_p(X))), X > 1.
%% a cut in the structure is the structure's
mt6 :- G = (mt_p(X), !, X > 0), call(G).
%% `\+', a library predicate and call/1 inside one
mt7 :- G = (\+ fail, atom(a)), call(G).
mt8 :- G = (member(X, [1,2]), X > 1), call(G).
mt9 :- G = (call((atom(a), atom(b))), atom(c)), call(G).
%% a choice point the structure leaves, retried from the clause after it
mt10 :- G = (mt_p(X), X > 1), call(G), atom(z).
mt11 :- G = (mt_p(X) -> X > 0 ; true), call(G).
mt12 :- G = (mt_p(X) *-> X > 1 ; true), call(G).
mt13 :- call((mt_p(X), X > 1)), !.
mt14 :- G = (mt_p(X), X > 5), \+ call(G).
mt15 :- G = (mt_p(X) -> true ; true), call(G), X > 1.
mt16 :- call((mt_p(X) ; X = 3)), X > 2.
mt17 :- G = (atom(a), (mt_p(X), X > 1)), call(G).
mt18 :- call((mt_p(X), call((mt_p(Y), Y > X)))).
mt19 :- G = (\+ atom(b)), call(G).
mt20 :- G = (\+ atom(a) ; atom(b)), call(G).
%% a variable goal is call/1 of it, in `\+' and a condition too
mt21 :- G = (atom(a), atom(b)), G.
mt22 :- G = (mt_p(X), X > 1), G.
mt23 :- G = (mt_p(X), X > 5), \+ G.
mt24 :- G = (mt_p(X), X > 1), ( G -> true ; true ).
%% under its qualifiers
mt25 :- call(user:(mt_p(X), X > 1)).
mt26 :- G = user:(atom(a), atom(b)), call(G).
mt27 :- call(lists:(mt_p(X), X > 1)).
mt28 :- call(user:user:(atom(a) ; atom(b))).
%% setup_call_cleanup/3's goal, its frame's meta-call
mt29 :- setup_call_cleanup(true, (atom(a), atom(b)), true).
%% forall/2's condition and action, each meta-called
mt30 :- forall((mt_p(X), X > 0), atom(x)).
mt31 :- forall(mt_p(X), (atom(x), X > 0)).
mt32 :- forall((mt_p(X), X > 0), (atom(x), X > 0)).
mt33 :- forall((mt_p(X), X > 1), atom(x)).
mt34 :- forall(user:(mt_p(X), X > 0), atom(x)).

%% a cut in the structure leaves its frame, and a `;' retried after the cut
%% is still no Redo
mt40 :- call((mt_p(X), !, (X > 5 ; true))).
mt41 :- G = (mt_p(X), !, (fail ; X > 0)), call(G).
mt42 :- call((mt_p(_), !, (fail ; atom(a)))), atom(b).
mt43 :- call((!, (fail ; true))).

%% in a library's clause: the structure's builtins are ports, and its `;'
%% retried no Redo
:- set_prolog_flag(generate_debug_info, false).
mt_l(X) :- G = (mt_p(X), X > 0), call(G).
mt_n(X) :- call((mt_p(X), X > 1)).
mt_o(X) :- G = (member(X, [1,2]), X > 1), call(G).
mt_q :- G = (fail ; atom(c)), call(G).
:- set_prolog_flag(generate_debug_info, true).
mt35 :- mt_l(_).
mt36 :- mt_n(_).
mt37 :- mt_o(_).
mt38 :- mt_q.
mt39 :- mt_l(X), X > 1.
