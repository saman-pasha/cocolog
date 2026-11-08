%  What the builtins ask of their arguments, as swipl 9.0.4 asks it
%  (cocolog 3.47.0), from a scan of every builtin over odd arguments: the
%  list's end inside a control structure; setup_call_cleanup/3's cleanup
%  asked before its goal, and run for a goal that is none; forall/2's
%  condition run before its action is asked; functor/3's name asked before
%  its arity; current_op/3's priority 0; string_bytes/3's encoding [];
%  aggregate_all/3's template []; dcg_translate_rule/2 of a clause that can
%  be none; meta_predicate/1 at []; redefine_system_predicate/1 taking
%  user's definition away; expand_term/2 over lists; and term_string/3's
%  options merged as swipl merges them.
:- set_prolog_flag(double_quotes, codes).
:- dynamic rd/1, rd2/0.

out(T) :-
    \+ \+ ( numbervars(T, 0, _), print(T) ), nl.

t(G) :-
    catch(( G -> out(yes) ; out(no) ), E, out(caught(E))).

spec(H) :-
    ( predicate_property(H, meta_predicate(S)) -> out(S) ; out(none) ).

m1(_). m2(_). m3(_).

term_expansion(tx, [(q --> r), s, [s2]]).
term_expansion(tp, [s|_]).

main :-
    nil_goals, cleanups, foralls, functors, ops, encodings, aggregates,
    dcgs, metas, redefines, expands, term_strings, options_last.

%% the list's end is no goal inside a structure, which swipl compiles before
%% it runs any of it; alone, its qualifiers off, it is []/0 called
nil_goals :-
    t(call((true, []))), t(call(([], true))), t(call(\+ [])), t(call($([]))),
    t(call(([] -> true))), t(call((true -> []))), t(call((true ; []))),
    t(call(([] *-> true))), t(call(@([], user))), t(call((true, user:[]))),
    t(call(\+ user:[])), t(call(user:[])), t(call([])), t(once([])),
    t(findall(x, (true, []), _)), t(forall(true, (true, []))),
    t(aggregate_all(count, (true, []), _)),
    t(with_output_to(codes(_), (true, []))), t(with_output_to(codes(_), [])).

%% the cleanup asked before the goal, `[]' no goal there, and a goal that is
%% none an exception the cleanup runs for
cleanups :-
    t(setup_call_cleanup(true, 1, _)), t(setup_call_cleanup(true, _, 1)),
    t(setup_call_cleanup(true, true, 1)), t(setup_call_cleanup(true, true, [])),
    t(call_cleanup(1, _)), t(call_cleanup(_, 1)), t(call_cleanup(_, [])),
    t(setup_call_catcher_cleanup(true, 1, _, _)),
    t(setup_call_catcher_cleanup(true, true, _, 1)),
    t(setup_call_cleanup(true, 1, out(c1))), t(setup_call_cleanup(true, _, out(c2))),
    t(setup_call_catcher_cleanup(true, foo:1, X, out(c3(X)))),
    t(setup_call_cleanup(true, (true, 1), out(c4))),
    t(setup_call_cleanup(true, nope, out(c5))),
    t(setup_call_cleanup(fail, _, 1)), t(setup_call_cleanup(_, true, 1)),
    t(call_cleanup([], true)).

%% the condition runs first: an action that is no goal raises once the
%% condition has an answer, and not at all where it has none
foralls :-
    t(forall(fail, _)), t(forall(fail, 1)), t(forall(true, _)), t(forall(true, 1)),
    t(forall(nope, _)), t(forall(1, _)), t(forall(_, 1)),
    t(forall(member(X, [1, 2]), ( out(x(X)), X < 2 ))),
    t(forall(( out(cond), fail ), _)), t(forall(( out(cond2) ; out(cond3) ), 1)),
    t(forall([], true)), t(forall(true, [])).

%% the name asked before the arity
functors :-
    t(functor(_, f(x), _)), t(functor(_, [a|b], _)), t(functor(_, "ab", _)),
    t(functor(_, f(x), a)), t(functor(_, f(x), -1)), t(functor(_, _, 1)),
    t(functor(_, a, _)), t(functor(_, 1.5, _)), t(functor(T, a, 2)), out(T).

ops :-
    t(current_op(0, _, _)), t(current_op(-1, _, _)), t(current_op(1201, _, _)),
    t(current_op(a, _, _)), t(current_op(1, fx, $)), t(current_op(0, xfx, foo)).

encodings :-
    t(string_bytes(_, _, [])), t(string_bytes(abc, _, [])),
    t(string_bytes(_, _, '[]')), t(string_bytes(abc, _, 1)), t(string_bytes(abc, _, _)).

aggregates :-
    t(aggregate_all([], true, _)), t(aggregate_all('[]', true, _)),
    t(aggregate_all(1, true, _)), t(aggregate_all(foo, true, _)),
    t(aggregate_all(count, [], _)).

%% the clause wanted can be one only as `_ :- _' or unbound
dcgs :-
    t(dcg_translate_rule(_, a)), t(dcg_translate_rule(_, [])), t(dcg_translate_rule(_, f(x))),
    t(dcg_translate_rule(_, (x :- y))), t(dcg_translate_rule(_, (x :- y, z))),
    t(dcg_translate_rule(_, _)), t(dcg_translate_rule((a --> b), (a(_, _) :- _))).

%% the list's end names no predicate the declaration can look up: the goal
%% fails there, the heads before it declared
metas :-
    t(meta_predicate([])), t(meta_predicate((m1(0), []))), spec(m1(_)),
    t(meta_predicate(([], m2(0)))), spec(m2(_)),
    t(meta_predicate((m3(0), foo:[]))), spec(m3(_)),
    t(meta_predicate('[]'(0))), t(meta_predicate('[]')), t(meta_predicate(user:[])).

%% user's definition taken away before the mark, as abolish/1 takes it
redefines :-
    assertz(rd(1)), assertz(rd2),
    t(redefine_system_predicate(rd(_))), t(rd(_)), t(predicate_property(rd(_), dynamic)),
    t(assertz(rd(2))), t(rd(X)), out(X),
    t(redefine_system_predicate(user:rd2)), t(rd2),
    t(redefine_system_predicate(nothing_here(_))), t(redefine_system_predicate(_)),
    t(redefine_system_predicate(1)), t(redefine_system_predicate(msort(_, _))),
    t(msort([b, a], M)), out(M).

%% a list is its terms, each expanded as a term is, a list in it spliced; a
%% partial or improper one a type error
expands :-
    t(expand_term([(a --> b)], X1)), out(X1),
    t(expand_term([(c --> d), (c --> e)], X2)), out(X2),
    t(expand_term(tx, X3)), out(X3),
    t(expand_term([tx], X4)), out(X4),
    t(expand_term([[a], [], [b, [c]]], X5)), out(X5),
    t(expand_term([a|_], _)), t(expand_term([a|b], _)), t(expand_term(tp, _)),
    t(expand_term([], X6)), out(X6), t(expand_term(f([a|_]), X7)), out(X7).

%% options with no quoted(_) merged as swipl's '$merge_options'/3 merges
%% them, its put_dict/3 taking the list for a dict
term_strings :-
    T = f('A', [1, 2, 3, 4]),
    t(term_string(T, S1, [foo])), t(term_string(T, S2, [f(a, b)])),
    t(term_string(T, S3, [1])), t(term_string(T, S4, [k = v])), out(S4),
    t(term_string(T, S5, [k - v])), out(S5), t(term_string(T, S6, [k:v])), out(S6),
    t(term_string(T, S7, [ignore_ops(true), ignore_ops(false)])),
    t(term_string(T, S8, [quoted = false])), out(S8),
    t(term_string(T, S9, [1 = a])), t(term_string(T, S10, [f(_) = a])),
    t(term_string(T, S11, [_ = a])), t(term_string(T, S12, [quoted(false), foo])),
    t(term_string(T, S13, [quoted(false)])), out(S13),
    t(term_string(T, S14, [foo, quoted(true)])), t(term_string(T, S15, [a|b])),
    out([S1, S2, S3, S7, S9, S10, S11, S12, S14, S15]).

w(T, O) :- catch(( write_term(T, O), nl ), E, out(caught(E))).

%% an option said twice is its last, the write's and the read's; and a
%% read takes Name = Value as the write does
options_last :-
    w('A'+'b c', [quoted(true), quoted(false)]), w('A'+'b c', [quoted(false), quoted(true)]),
    w(a+b, [ignore_ops(true), ignore_ops(false)]), w(a+b, [ignore_ops(false), ignore_ops(true)]),
    w('$VAR'(1), [numbervars(true), numbervars(false)]),
    w('$VAR'(1), [numbervars(false), numbervars(true)]),
    w(f(X1), [variable_names(['X'=X1]), variable_names(['Y'=X1])]),
    w('A', [quoted = true, quoted = false]),
    format("~W~n", ['A', [quoted(true), quoted(false)]]),
    t(term_string('A', S2, [quoted(false), quoted(true)])), out(S2),
    t(term_string('A', S2b, [quoted(true), quoted(false)])), out(S2b),
    t(read_term_from_atom('f(X)', R3, [quoted = false])), out(R3),
    t(read_term_from_atom('f(X)', R4, [foo = bar, baz(1)])), out(R4),
    t(read_term_from_atom('f(X)', R5, [variable_names = V5])), out(R5-V5),
    t(read_term_from_atom('f(X)', R6, [variable_names = V6, variable_names(W6)])), out(R6-V6-W6),
    t(read_term_from_atom('f(X)', R7, [variable_names(W7), variable_names = V7])), out(R7-V7-W7),
    t(read_term_from_atom('f(X)', _, [1 = a])), t(read_term_from_atom('f(X)', _, [_ = a])),
    t(read_term_from_atom('f(X)', _, [f(a) = b])), t(read_term_from_atom('f(X)', _, [f(a, b)])),
    t(term_string(R8, "g(A)", [variable_names = V8])), out(R8-V8).

