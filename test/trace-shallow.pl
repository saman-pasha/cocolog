%% A shallow backtrack under trace (3.78.5), for test/trace.pl: `\+''s own
%% fail is swipl's C_FAIL, a BODY_FAILED (pl-vmi.c's shallow_backtrack),
%% and where the newest choice point is a jump of the clause that failed --
%% a `;', an if-then-else's else, another `\+''s -- swipl takes it with no
%% Redo. A choice point of another call, or a port printed on the way,
%% makes the backtrack deep, and its Redo is printed. A bare if-then and a
%% bare soft cut make no choice point at all (C_IFTHEN), so their condition
%% failing is no Redo either. Through 3.78.4 each of these printed a Redo of
%% the clause where swipl prints none. A choice point of another call of the
%% same predicate is another frame's (sh33).

sh_p(1).
sh_p(2).
sh_q :- ( \+ atom(a) -> true ).
sh_r :- !.
sh_s :- ( true ; true ).
sh_t(1) :- ( sh_t(0), \+ atom(a) ; true ).
sh_t(0) :- ( true ; true ).

%% `\+ \+ G': the inner `\+''s fail reaches the outer's else
sh1 :- \+ \+ atom(a).
sh2 :- \+ \+ sh_p(_).
sh3 :- \+ \+ (sh_p(X), X > 1).
sh4 :- \+ \+ sh_p(_), atom(b).
sh5 :- \+ (\+ atom(a)), atom(b).
sh6 :- \+ \+ \+ atom(a).
sh7 :- ( \+ \+ atom(a) ), \+ \+ atom(b).
sh8 :- ( sh_p(X), X > 1 ), \+ \+ true.
%% the `\+''s fail reaches a `;', an else, a `\+' of the same clause
sh9 :- ( \+ atom(a) ; true ).
sh10 :- ( \+ atom(a) -> true ; true ).
sh11 :- \+ ( \+ atom(a), true ).
sh12 :- ( \+ atom(a) ; \+ atom(b) ; true ).
sh13 :- ( \+ atom(a) ; \+ atom(b) ), true.
sh14 :- ( ( \+ atom(a) ; fail ) ; true ).
sh15 :- ( sh_p(_) -> \+ atom(a) ; true ) ; true.
%% a call's choice point first is its Redo; one that exited is none
sh16 :- ( sh_p(X), \+ atom(a) ; X = 0 ), X >= 0.
sh17 :- ( member(X, [1,2]), \+ atom(a) ; X = 0 ), X >= 0.
sh18 :- ( sh_r, \+ atom(a) ; true ).
sh19 :- ( sh_s, \+ atom(a) ; true ).
%% a port printed first makes it deep: the program's `fail', a builtin's
sh20 :- ( atom(a), fail ; true ).
sh21 :- \+ \+ fail.
sh22 :- ( \+ fail, atom(x), X = 1, X > 5 ; true ).
%% a bare if-then, a bare soft cut: no choice point, so no Redo
sh23 :- ( sh_p(X), X > 5 -> true ).
sh24 :- ( sh_p(X), X > 5 *-> true ).
sh25 :- ( \+ atom(a) -> true ) ; true.
sh26 :- ( atom(x), ( \+ atom(a) -> true ) ; true ).
sh27 :- ( true ; true ), ( \+ atom(a) -> true ).
sh28 :- sh_q ; true.
sh29 :- ( sh_p(_), ( \+ atom(a) -> true ) ; true ).
sh30 :- ( ( sh_p(X), X > 5 -> true ) ; true ).
%% inside a meta-called structure, the structure's own clause
sh31 :- call(( \+ atom(a) ; true )).
sh32 :- G = ( sh_p(X), \+ atom(a) ; X = 0 ), call(G).
%% the same predicate's other call: its `;' is its frame's, deep
sh33 :- sh_t(1).
%% the frame's own next clause (swipl's CHP_CLAUSE of the frame that
%% failed): taken shallow, no Redo of the call; a choice point of a call
%% before it first, or a port printed, is deep
sh34 :- \+ atom(a).
sh34.
sh_c(X) :- \+ atom(a), X = 1.
sh_c(2).
sh35 :- sh_c(_).
sh_d :- \+ \+ fail.
sh_d.
sh36 :- sh_d.
sh_e :- sh_f, \+ atom(a).
sh_e.
sh_f.
sh_f.
sh37 :- sh_e.
sh_g :- ( \+ atom(a) -> true ).
sh_g.
sh38 :- sh_g.
sh_h :- atom(a), \+ atom(b), \+ atom(a).
sh_h.
sh39 :- sh_h.
sh_i :- sh_p(X), \+ atom(a), X > 5.
sh_i.
sh40 :- sh_i.
%% and in a clause that hides its children: no Redo of its call, nor of
%% the library call a hidden clause's frame is retried inside
:- set_prolog_flag(generate_debug_info, false).
sh_j :- \+ atom(a).
sh_j.
sh_k :- sh_l.
sh_l :- \+ atom(a).
sh_l.
:- set_prolog_flag(generate_debug_info, true).
sh41 :- sh_j.
%% the same predicate's other call keeps a clause choice: its Redo, deep
sh_m(1) :- sh_m(0), \+ atom(a).
sh_m(1).
sh_m(0).
sh_m(0).
sh42 :- sh_m(1).
sh43 :- sh_k.
%% a bare if-then or soft cut before a `;' of the same clause -- no
%% if-then-else, the `,' between: its condition failing deep is deep on
%% to the `;', its Redo printed; failing shallow, shallow
sh44 :- ( ( sh_p(X), X > 5 -> true ), true ; true ).
sh45 :- ( ( \+ atom(a) -> true ), true ; true ).
sh46 :- ( ( sh_p(X), X > 5 *-> true ), true ; true ).
%% another call's choice point a builtin keeps -- arg/3's walk, clause/2's
%% -- taken after a `\+''s fail is the backtrack's first frame: it ends the
%% shallow backtrack, and a deep one into the clause's own `;' after it
%% prints its Redo (the first cut of 3.78.5 left it set and printed none)
sh_u(1, 1).
sh_u(2, 3).
sh47 :- ( arg(N, f(a, b), X), ( N == 1 -> \+ atom(X) ; fail ) ; true ).
sh48 :- ( arg(N, f(a, b), _), ( N == 1 -> \+ atom(a) ; N > 5 ) ; true ).
sh49 :- ( clause(sh_u(A, _), true), ( A == 1 -> \+ atom(a) ; fail ) ; true ).
