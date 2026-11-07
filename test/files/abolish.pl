%% abolish/1 and abolish/2 as swipl 9.0.4's (cocolog 3.36.0). Run by
%% test/files.pl beside swipl, the two outputs compared byte for byte; a
%% term's variables are named by pv/1.
%%
%% The predicate goes and its declarations with it: a call of it raises
%% existence_error, current_predicate/1 names it no more and
%% predicate_property/2 answers nothing, whether it was dynamic, a file's
%% own (swipl's `iso' flag being false) or only declared. A call open on it
%% keeps the clauses it began with (the logical update view). An ISO
%% predicate -- a control construct and call/1..8 among them -- is
%% permission_error(modify, static_procedure, PI), a thread_local one
%% permission_error(modify, thread_local_procedure, PI), and any other
%% system predicate, or a library's, is none of the program's, which
%% abolish leaves as it is; one a program file took over (msort/2) is the
%% program's, and its call raises after. The argument is asked as swipl
%% asks it: an atom's qualifiers taken off, the name before the arity, an
%% arity an int holds and not negative.
%%
%% Left out on purpose (COMPAT.md): an arity past 1024, which swipl refuses
%% as max_procedure_arity and cocolog takes; abolish(lists:member/2), which
%% swipl's modules take from lists and cocolog's one namespace reads as
%% member/2; a predicate the program defines under the name of one cocolog
%% writes as a library's clauses (between/3), which swipl's user definition
%% hides and cocolog's joins; and listing/1 of an abolished predicate.

:- dynamic qd/1, qe/1.
:- discontiguous qn/1.
:- thread_local qt/1.
:- public qp/1.
:- multifile qm/1.
qs(1). qs(2).
qd(1). qd(2).
qp(1).
qm(1).
msort(a, b).

pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

t(Label, G) :-
    write(Label), write(': '),
    catch(( G -> R = yes ; R = no ), E, R = caught(E)),
    pv(R), nl.

main :- goes, system, spec, two.

%% the predicate goes, and its declarations with it
goes :-
    t(asserted, (assertz(qa(1)), abolish(qa/1), qa(_))),
    t(asserted_dynamic, (assertz(qa2(1)), abolish(qa2/1), predicate_property(qa2(_), dynamic))),
    t(asserted_current, (assertz(qa3(1)), abolish(qa3/1), current_predicate(qa3/1))),
    t(asserted_again, (assertz(qa4(1)), abolish(qa4/1), assertz(qa4(2)),
                       findall(X4, qa4(X4), L4), pv(L4), write(' '))),
    t(declared_dynamic, (abolish(qd/1), qd(_))),
    t(a_files_own, (abolish(qs/1), qs(_))),
    t(declared_only, (abolish(qe/1), qe(_))),
    t(discontiguous, (abolish(qn/1), qn(_))),
    t(no_properties, (assertz(qr(1)), abolish(qr/1),
                      findall(P, predicate_property(qr(_), P), L5), pv(L5), write(' '))),
    t(never_defined, abolish(nonesuch/3)),
    t(never_defined_after, current_predicate(nonesuch/3)),
    t(retract_after, (assertz(qb(1)), abolish(qb/1), retract(qb(_)))),
    t(clause_after, (assertz(qc(1)), abolish(qc/1), clause(qc(_), _))),
    t(retractall_after, (assertz(qf(1)), abolish(qf/1), retractall(qf(_)),
                         predicate_property(qf(_), dynamic))),
    t(dynamic_after, (assertz(qg(1)), abolish(qg/1), dynamic(qg/1), qg(_))),
    t(asserted_after, (assertz(qd(3)), predicate_property(qd(_), dynamic))),
    t(public_before, predicate_property(qp(_), public)),
    t(public_reset, (abolish(qp/1), assertz(qp(2)), predicate_property(qp(_), public))),
    t(multifile_reset, (abolish(qm/1), assertz(qm(2)), predicate_property(qm(_), multifile))),
    t(multifile_asserted, predicate_property(qm(_), dynamic)),
    t(open_call, (assertz(qo(1)), assertz(qo(2)),
                  findall(X6, (qo(X6), abolish(qo/1)), L6), pv(L6), write(' '))),
    t(open_call_after, qo(_)).

%% the system's predicates and a library's
system :-
    t(iso, abolish(atom_length/2)),
    t(control, abolish((',')/2)),
    t(true, abolish(true/0)),
    t(call_8, abolish(call/8)),
    t(call_9, abolish(call/9)),
    t(write, abolish(write/1)),
    t(length, abolish(length/2)),
    t(abolish_1, abolish(abolish/1)),
    t(abolish_2, abolish(abolish/2)),
    t(format, abolish(format/2)),
    t(format_on, (format(atom(A1), "~w", [ok]), A1 == ok)),
    t(nb_getval, abolish(nb_getval/2)),
    t(thread_local, abolish(qt/1)),
    t(member, abolish(member/2)),
    t(member_on, member(_, [a])),
    t(member_used, (member(_, [a]), abolish(member/2), member(b, [b]))),
    t(append, (abolish(append/3), append([a], [b], [a, b]))),
    t(taken, (msort(A2, B2), pv(A2-B2), write(' '))),
    t(taken_abolished, abolish(msort/2)),
    t(taken_after, msort([b, a], _)).

%% the argument
spec :-
    t(unbound, abolish(_)),
    t(no_pi, abolish(foo)),
    t(grammar, abolish(foo//1)),
    t(name_unbound, abolish(_/1)),
    t(name_unbound_arity_atom, abolish(_/a)),
    t(name_integer, abolish(1/1)),
    t(name_integer_arity_unbound, abolish(1/_)),
    t(name_compound, abolish(f(x)/1)),
    t(name_no_args, abolish(f()/1)),
    t(name_pi, abolish(foo/1/2)),
    t(nil, abolish([]/1)),
    t(nil_atom, abolish('[]'/1)),
    t(curly, abolish({}/1)),
    t(arity_unbound, abolish(foo/_)),
    t(arity_float, abolish(foo/1.0)),
    t(arity_negative, abolish(foo/(-1))),
    t(arity_least_int, abolish(foo/(-2147483648))),
    t(arity_below_int, abolish(foo/(-2147483649))),
    t(arity_past_int, abolish(foo/2147483648)),
    t(arity_far_past, abolish(foo/1000000000000)),
    t(arity_1024, abolish(foo/1024)),
    t(user, abolish(user:foo/1)),
    t(user_user, abolish(user:user:foo/1)),
    t(lists, abolish(lists:foo/1)),
    t(module_unbound, abolish(_:foo/1)),
    t(module_integer, abolish(3:foo/1)),
    t(both_unbound, abolish(_:_)),
    t(user_unbound, abolish(user:_)),
    t(user_integer, abolish(user:3)),
    t(user_grammar, abolish(user:foo//1)),
    t(user_bracketed, abolish(user:(foo/1))).

%% abolish/2
two :-
    t(two, (assertz(qh(1)), abolish(qh, 1), qh(_))),
    t(two_user, abolish(user:foo, 1)),
    t(two_user_arity_atom, abolish(user:foo, a)),
    t(two_name_pi, abolish(foo/1, x)),
    t(two_name_integer, abolish(1, 1)),
    t(two_name_compound, abolish(f(x), 1)),
    t(two_name_unbound, abolish(_, 1)),
    t(two_module_unbound, abolish(_:foo, 1)),
    t(two_module_integer, abolish(3:foo, 1)),
    t(two_arity_unbound, abolish(foo, _)),
    t(two_arity_atom, abolish(foo, a)),
    t(two_arity_negative, abolish(foo, -1)),
    t(two_arity_past_int, abolish(foo, 2147483648)),
    t(two_arity_far_below, abolish(foo, -1000000000000)),
    t(two_iso, abolish(atom_length, 2)).
