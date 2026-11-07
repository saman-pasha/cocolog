%  listing/1's argument, as swipl 9.0.4's listing_/2 and '$find_predicate'/2
%  read it (cocolog 3.37.0): what a spec names, the clauses a head picks,
%  a list of specs, Name//Arity, the system's predicates, a module's, the
%  qualifiers, a module's own predicates, and the errors. Run by BOTH
%  SWI-Prolog and cocolog, output compared byte for byte; lsm.pl and lsn.pl,
%  the modules, are the runner's fixtures (test/files.pl).
%
%  A clause's variables are named as listing/1 names them, `A', `B', ...,
%  so that swipl's, which restores the file's names, writes the same.
%  Every spec that names nothing is far from every name a predicate has
%  (`qqqqqq'), and every arity two from any of its name: swipl offers to
%  correct a near one, and asks on its terminal. Not here (COMPAT.md): a
%  module qualifier is no module to a name in cocolog's one namespace
%  (`lists:zz' lists zz/1, where swipl's has none), a system predicate
%  swipl defines in Prolog (format/1, dynamic/1) is a foreign one, a
%  library's clauses are cocolog's own, and a module's own predicates are
%  written in the store's order where swipl's walks its procedure table --
%  so lsn has one, and user's are held to pieces of their text.

:- use_module(lsm).
:- use_module(lsn).
:- dynamic zq/1, 'z q'/1, 'don''t'/2.
:- discontiguous zdis/1.
:- multifile zmul/1.
:- public zpub/1.

zz(1).
zz(2) :- zq(2).
zz(A, B, C) :- C is A+B.
yy(a, b).
yy(c, d).
'z q'(1).
greet --> [hello].
qs(a) => true.
qs(A), integer(A) => true.
msort(a, b).
'$hid'(1).

pv(T) :-
    \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

%% each listing straight to the output, then how its goal ended
t(Label, G) :-
    format("~n=== ~w~n", [Label]),
    catch(( G -> R = yes ; R = no ), E, R = caught(E)),
    pv(R), nl.

%% a listing's text, and for each piece whether it holds it: each piece is
%% built at run time, so that no clause of this file holds it whole
lt(Label, G, Pieces) :-
    format("~n=== ~w~n", [Label]),
    with_output_to(string(S), G),
    forall(member(P, Pieces),
           ( atomic_list_concat(P, A),
             ( sub_string(S, _, _, _, A) -> R = yes ; R = no ),
             print(R), nl )).

main :- errors, lists, heads, names, systems, decls, modules,
        qualifiers, module_lists, pieces.

%% what names nothing, and what names no predicate at all
errors :-
    t(atom_unknown, listing(qqqqqq)),
    t(pi_unknown, listing(qqqqqq/3)),
    t(head_unknown, listing(qqqqqq(1))),
    t(name_a_number, listing(3/1)),
    t(name_a_compound, listing(f(x)/1)),
    t(an_integer, listing(3)),
    t(a_float, listing(1.5)),
    t(a_var_term, listing('$VAR'(1))),
    t(arity_negative, listing(zz/(-1))),
    t(arity_negative_unknown, listing(qqqqqq/(-1))),
    t(arity_negative_no_atom, listing(3/(-1))),
    t(arity_negative_unbound, listing(_/(-1))),
    t(dcg_arity_negative, listing(qqqqqq//(-3))),
    t(dcg_arity_negative_unbound, listing(_//(-3))),
    t(dcg_arity_an_atom, listing(zz//a)),
    t(qualified_unknown, listing(foo:qqqqqq)),
    t(qualified_by_a_number, listing(1:zz/1)),
    t(qualified_by_a_term, listing(f(a):zz/1)),
    t(public_alone, listing(zpub/1)).

%% a list is each of its specs, in order, and stops at the first error
lists :-
    t(empty, listing([])),
    t(two, listing([zz/1, yy/2])),
    t(nested, listing([[yy/2]])),
    t(qualified_element, listing([user:yy/2])),
    t(qualified_list, listing(user:[yy(c, _)])),
    t(stops_at_unknown, listing([yy/2, qqqqqq/3])),
    t(an_integer_element, listing([3])).

%% a head lists the clauses whose head unifies with it, and binds nothing
heads :-
    t(head_first, listing(yy(c, _))),
    t(head_unbound_after, (listing(yy(c, Q)), var(Q))),
    t(head_none, listing(yy(e, _))),
    t(head_static_none, listing(zz(3))),
    t(head_dynamic_none, listing(zq(7))),
    t(head_rule, listing(zz(2))),
    t(head_ssu, listing(qs(a))),
    t(head_ssu_guard, listing(qs(7))),
    t(head_three, listing(zz(1, _, _))).

%% a name, its arities, a grammar rule's, a qualifier, quoted names
names :-
    t(atom_every_arity, listing(zz)),
    t(arity_unbound, listing(zz/_)),
    t(dcg, listing(greet//0)),
    t(dcg_unbound, listing(greet//_)),
    t(dcg_evaluated, listing(zz//(-1))),
    t(qualified_user, listing(user:yy/2)),
    t(qualified_var, listing(_:yy/2)),
    t(quoted_name, listing('z q'/1)),
    t(quoted_quote, listing('don''t'/2)).

%% the system's: a foreign line, its module left off in its own context,
%% and a system name the program defines said so
systems :-
    t(foreign, listing(atom_length/2)),
    t(foreign_head, listing(atom_length(_, _))),
    t(cut, listing(!/0)),
    t(true, listing(true/0)),
    t(write, listing(write/1)),
    t(nb_current, listing(nb_current/2)),
    t(between, listing(between/3)),
    t(atom_concat, listing(atom_concat/3)),
    t(format, listing(format/2)),
    t(system_context, listing(system:atom_length/2)),
    t(overruled, listing(msort/2)).

%% what a declaration alone makes
decls :-
    t(dynamic_empty, listing(zq/1)),
    t(discontiguous_alone, listing(zdis/1)),
    t(multifile_alone, listing(zmul/1)),
    t(dynamic_quoted, listing('z q')).

%% a module's predicate is written with its module, unless the listing is
%% that module's own
modules :-
    t(module_pred, listing(mp/1)),
    t(module_own_context, listing(lsm:mp/1)),
    t(module_head, listing(mp(2))),
    t(module_dynamic, listing(md/1)).

%% a variable qualifier is every module and ends the qualifiers -- what it
%% qualifies is the spec as it stands -- and a predicate's module is written
%% unless it is the listing's, user's too, the system's under a variable none
qualifiers :-
    t(var_then_user, listing(_:user:yy/2)),
    t(var_then_module, listing(_:lsm:mp/1)),
    t(var_element, listing([_:yy/2])),
    t(user_then_var_element, listing([user:_:yy/2])),
    t(var_element_nested, listing([[_:yy/2]])),
    t(var_element_module, listing([_:mp/1])),
    t(user_in_module, listing(lsm:[user:yy/2])),
    t(user_decl_in_module, listing(lsm:[user:zq/1])),
    t(user_note_in_module, listing(lsm:[user:msort/2])),
    t(foreign_var_context, listing(_:atom_length/2)),
    t(foreign_var_context_list, listing(_:[atom_length/2])),
    t(foreign_var_element, listing([_:atom_length/2])).

%% an unbound spec is its module's own predicates (swipl's list_module/2, a
%% blank line before each), and an element `M:_' M's as `_/_' finds them
module_lists :-
    t(module_unbound, listing(lsn:_)),
    t(module_unbound_element, listing(lsn:[_])),
    t(module_none, listing(foo:_)),
    t(element_module_unbound, listing([lsm:_])),
    t(element_lsn_unbound, listing([lsn:_])),
    t(module_arity, listing(lsm:_/1)),
    t(element_module_arity, listing([lsm:_/1])),
    t(module_dcg_arity, listing(lsm:_//(-1))),
    t(module_name, listing(lsn:np)),
    t(module_head_element, listing([lsn:np(_)])),
    t(module_list_arity, listing(lsn:[_/1])).

%% user's own predicates, listing/0's, and every module's: the program's,
%% a module's left to it, no name of `$' -- and no library's: cocolog's
%% async_workers/1 is clauses, which swipl has nowhere
pieces :-
    lt(user_own, listing(user:_),
       [['yy(a, ', 'b).'], [lsm, :, 'mp(1)'], ['mp(', '1).'], ['np(', '1).'],
        ['''$', 'hid''(1)']]),
    lt(listing_0, listing, [['yy(a, ', 'b).'], ['mp(', '1).'], ['''$', 'hid''(1)']]),
    lt(unbound, listing(_), [['yy(a, ', 'b).'], ['np(', '1).']]),
    lt(every_module, listing(_:_),
       [['yy(a, ', 'b).'], [lsm, :, 'mp(1)'], ['mp(', '1).'], ['np(', '1).'],
        ['''$', 'hid''(1)'], [async_, 'workers(']]).
