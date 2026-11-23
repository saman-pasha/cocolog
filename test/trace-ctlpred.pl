%% The control predicates under trace (3.78.6), for test/trace.pl: where
%% swipl calls `,'/2, `;'/2, `->'/2, `*->'/2, `\+'/1, $/1 or call/1 as a
%% predicate -- call/N's closure, a setup or a cleanup of
%% setup_call_cleanup/3, with_output_to/2's goal, format/2's `~@' -- it
%% calls boot/init.pl's clause of it, a port whose body meta-calls the
%% structure, its parts a `'<meta-call>'/1' frame below it. Its Call shows
%% the arguments as the caller gave them, its Exit said of user. A goal C
%% runs (with_output_to/2's, `~@''s) stands two below its builtin, under
%% callProlog()'s own frame. Through 3.78.5 call/N ran the structure in
%% place, a setup's and a cleanup's helper was no port, and
%% with_output_to/2's goal stood one below.

ct_a.
ct_b.
ct_m(1).
ct_m(2).

%% call/N of a control construct
ct1 :- call(',', ct_a, ct_b).
ct2 :- call(;, ct_a, ct_b).
ct3 :- G = ','(ct_a), call(G, ct_b).
ct4 :- call(->, ct_a, ct_b).
ct5 :- call(\+, fail).
ct6 :- call(',', ct_a, fail) ; true.
ct7 :- call(;, fail, ct_b).
ct8 :- call(*->, ct_a, ct_b).
ct9 :- call(;, ct_a, ct_b), fail.
ct10 :- call(\+, ct_a).
ct11 :- call(',', ct_m(X), X > 1).
ct12 :- call(',', ct_a, !), fail.
ct13 :- call(->, ct_m(X), X > 1).
ct14 :- call(',', user:ct_a, ct_b).
ct15 :- call(user:(','), ct_a, ct_b).
ct16 :- call(;, ct_a, ct_b) ; true.
ct17 :- call(\+, \+ ct_a).
ct18 :- call($, ct_a).
ct19 :- call(',', ct_m(X), X > 1), !.
ct20 :- call(',', (ct_a ; ct_b), ct_b).
ct21 :- G = ','(ct_a), call(G, (ct_b, ct_a)).
ct22 :- call(;, ct_m(X), ct_b), X > 1.
%% a setup and a cleanup
ct23 :- setup_call_cleanup((ct_a, ct_b), true, (ct_a, ct_b)).
ct24 :- setup_call_cleanup(ct_a, true, ct_b).
ct25 :- setup_call_cleanup(true, fail, (ct_a ; ct_b)) ; true.
ct26 :- setup_call_cleanup((ct_a ; ct_b), true, true).
ct27 :- setup_call_cleanup(call(ct_a), true, true).
ct28 :- setup_call_cleanup(true, true, call(ct_a)).
ct29 :- setup_call_cleanup(true, true, user:ct_a).
ct30 :- setup_call_cleanup(true, true, (ct_a -> ct_b)).
ct31 :- setup_call_cleanup(user:(ct_a, ct_b), true, true).
ct32 :- setup_call_cleanup(true, ct_m(_), (ct_a, ct_b)).
ct33 :- setup_call_cleanup($(ct_a), true, true).
ct34 :- setup_call_cleanup(call(true), true, call(true)).
ct35 :- setup_call_cleanup(true, true, call(fail)).
ct36 :- setup_call_cleanup((member(X, [1, 2]), X > 1), true, true).
%% with_output_to/2's goal and format/2's `~@'
ct37 :- with_output_to(string(_), (ct_a, ct_b)).
ct38 :- with_output_to(string(_), ct_a).
ct39 :- with_output_to(string(_), (ct_a ; ct_b)).
ct40 :- with_output_to(string(_), \+ fail).
ct41 :- with_output_to(string(_), call(ct_a)).
ct42 :- with_output_to(string(_), ct_m(X)), X > 1.
ct43 :- with_output_to(string(_), (ct_m(X), X > 1)).
ct44 :- with_output_to(string(_), user:ct_a).
ct45 :- with_output_to(string(_), fail) ; true.
ct46 :- with_output_to(string(_), $(ct_a)).
ct47 :- with_output_to(string(_), (member(X, [1]), write(X))).
ct48 :- with_output_to(string(_), (fail ; member(_, [1]))).
ct49 :- format(atom(_), '~@', [(ct_a, ct_b)]).
ct50 :- format(atom(_), '~@', [ct_a]).
ct51 :- format(atom(_), '~@', [(fail ; true)]).
%% call/1 of $/1, which swipl compiles into a `'<meta-call>'/1' as it
%% compiles a structure
ct52 :- G = $(ct_a), call(G).
%% held by the helper's ports alone: setup_call_cleanup/3's own Exit shows
%% its goals as written, where swipl's shows them said of user
%% (`setup_call_cleanup(user:(\+fail), user:true, user:true)')
ct53 :- setup_call_cleanup(\+ fail, true, true).
ct54 :- setup_call_cleanup(true, true, \+ fail).
