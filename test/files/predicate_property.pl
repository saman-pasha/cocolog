%  predicate_property/2, swipl 9.0.4's (cocolog 3.41.0). The case holds:
%  - the program's own predicates of every kind -- consulted, dynamic,
%    declared and nothing else, discontiguous, multifile, public,
%    module_transparent, meta_predicate, thread_local, volatile, a
%    non-terminal, single-sided, under generate_debug_info false, asserted,
%    a module's the program loaded (ppm.pl, test/files.pl's fixture) and a
%    system name the program defines itself -- their whole walk, less what
%    describes how swipl stores a predicate, the file named by its base;
%  - the system's and the libraries' predicates, less what each says of its
%    own implementation (interpreted or foreign, the clause counts, the file
%    and the line): built_in, imported_from, transparent, meta_predicate,
%    nodebug, noprofile, ssu and iso;
%  - a head that is no callable term, a property of none, a name nothing
%    defines, the qualifiers, implementation_module(M), and the program's
%    own predicates that have a property, the head unbound;
%  - where a predicate's first clause stands, file/1 and line_count/1, after
%    an asserta/1, an assertz/1 and a retract of the first, in a multifile
%    predicate's two files, and in a file read again as it changes; and the
%    meta_predicate declaration an abolish/1 takes.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%  Through 3.40.0 cocolog answered a system or library predicate's walk as
%  its own (no imported_from, iso, meta_predicate; built_in for a library's
%  C, none for a library's clauses), none of the program's file, line,
%  meta_predicate or ssu, and raised type_error(callable, H) of a head that
%  is no callable term.
%
%  Not here (COMPAT.md): the walk of an unbound head, which swipl's makes of
%  the library and system predicates the program's clauses call too; the
%  hooks swipl declares dynamic in user; `foreign' of a predicate cocolog
%  writes in C where swipl writes it in Prolog (length/2, findall/3, ','/2),
%  and the clause counts of a library's predicate cocolog writes otherwise;
%  the file of a clause abolish/1 took, which swipl's names until its
%  clause collector reclaims the clause.

%% the libraries cocolog always has, which swipl loads when asked
:- use_module(library(dcg/basics)).
:- use_module(library(dcg/high_order)).
:- use_module(library(ugraphs)).  % cocolint: T1 -- swipl loads it here too
%% a module of the program's (test/files.pl's fixture)
:- use_module(ppm).

:- dynamic dyn/1.
dyn(1).
dyn(2) :- true.
:- dynamic declared_only/2.
:- discontiguous disc/1.
:- multifile multi/1.
multi(a).
:- public pub/0.
pub.
:- module_transparent mt/1.
mt(G) :- call(G).
:- meta_predicate mp(0, ?), mq(+, -), mr(:, ^, //).
mp(G, _) :- call(G).
mq(X, X).
mr(_, _, _).
:- thread_local tl/1.
:- volatile vol/1.
vol(x).
stat(a).
stat(b) :- stat(a).
stat(c).
greet --> [hello], world.
%% (world/2 is no rule to swipl's count, its body moved into its head:
%% COMPAT.md, number_of_rules/1)
world --> [world].
ssu(X), X > 0 => true.
ssu(_) => fail.
disc(1).
:- set_prolog_flag(generate_debug_info, false).
hidden(X) :- stat(X).
:- set_prolog_flag(generate_debug_info, true).
shown(X) :- hidden(X).
%% a system predicate's name the program defines itself, which swipl lets a
%% user file do where it is not ISO
atomic_list_concat(a, b, c).
%% the edges of file/1 and line_count/1
:- dynamic ea/1, eb/1, ec/1, ed/1.
ea(1).
eb(1).
ec(1).
ec(2).
ed(1).
:- meta_predicate em(0).
em(G) :- call(G).
%% a predicate whose first clause an included file holds names that file,
%% and the one after the include the including file again
:- include(pinc).
pi_after(1).

%% the walk, less what describes how swipl stores a predicate
walk(H) :-
    findall(P, ( predicate_property(H, P), \+ storage(P) ), Ps0),
    maplist(base, Ps0, Ps),
    functor(H, N, A),
    format("~q: ~q~n", [N/A, Ps]).
storage(size(_)).
storage(last_modified_generation(_)).
storage(indexed(_)).
base(file(F), file(B)) :- !, file_base_name(F, B).
base(P, P).

%% a system or library predicate: what both say alike (COMPAT.md)
sys(H) :-
    findall(P, ( predicate_property(H, P), \+ storage(P), \+ sys_own(P) ), Ps),
    functor(H, N, A),
    format("~q: ~q~n", [N/A, Ps]).
sys_own(file(_)).
sys_own(line_count(_)).
sys_own(number_of_clauses(_)).
sys_own(number_of_rules(_)).
sys_own(interpreted).
sys_own(foreign).

t(Name, G) :-
    (   catch(G, E, true)
    ->  (   var(E) -> R = yes ; E = error(F, _) -> R = caught(F) ; R = caught(E) )
    ;   R = no
    ),
    format("~w: ~q~n", [Name, R]).

main :-
    own,
    system,
    library,
    modes,
    edges,
    library_files.

own :-
    format("=== own~n"),
    forall(member(H, [stat(_), dyn(_), declared_only(_, _), disc(_), multi(_), pub, mt(_),
                      mp(_, _), mq(_, _), mr(_, _, _), tl(_), vol(_), greet(_, _), ssu(_),
                      hidden(_), shown(_), atomic_list_concat(_, _, _), ppm_a(_), ppm_g(_, _)]),
           walk(H)),
    assertz(ra(1)),
    walk(ra(_)).

system :-
    format("=== system~n"),
    forall(member(H, [true, fail, !, (_, _), (_ ; _), (_ -> _), \+ _, call(_), call(_, _),
                      call(_, _, _, _), catch(_, _, _), throw(_), findall(_, _, _), forall(_, _),
                      between(_, _, _), atom_length(_, _), atom_concat(_, _, _),
                      sub_atom(_, _, _, _, _), length(_, _), msort(_, _), sort(_, _, _, _),
                      keysort(_, _), format(_), format(_, _), format(_, _, _), assertz(_),
                      retract(_), clause(_, _), nb_getval(_, _), writeln(_), print(_),
                      numbervars(_, _, _), numbervars(_, _, _, _), setof(_, _, _), bagof(_, _, _),
                      phrase(_, _), phrase(_, _, _), print_message(_, _), current_op(_, _, _),
                      succ(_, _), plus(_, _, _), char_type(_, _), copy_term(_, _),
                      atom_to_term(_, _, _), memberchk(_, _), compound_name_arity(_, _, _),
                      string_concat(_, _, _), setup_call_cleanup(_, _, _), once(_), ignore(_),
                      not(_), halt, halt(_), trace, notrace]),
           sys(H)).

library :-
    format("=== library~n"),
    forall(member(H, [member(_, _), append(_, _, _), append(_, _), nth0(_, _, _), nth1(_, _, _),
                      last(_, _), sum_list(_, _), max_list(_, _), list_to_set(_, _),
                      maplist(_, _), maplist(_, _, _), foldl(_, _, _, _), include(_, _, _),
                      aggregate_all(_, _, _), list_to_assoc(_, _), put_assoc(_, _, _, _),
                      pairs_keys(_, _), ord_union(_, _, _), ord_subtract(_, _, _), must_be(_, _),
                      is_of_type(_, _), digits(_, _, _), sequence(_, _, _, _), top_sort(_, _),
                      listing(_), portray_clause(_)]),
           sys(H)).

modes :-
    format("=== modes~n"),
    t(int_head, predicate_property(1, _)),
    t(int_head_bound, predicate_property(1, dynamic)),
    t(qual_int, predicate_property(user:1, _)),
    t(unknown_property, predicate_property(stat(_), foo)),
    t(unknown_head, predicate_property(no_such_thing(_), _)),
    t(unknown_head_defined, predicate_property(no_such_thing(_), defined)),
    t(qual_user, predicate_property(user:stat(_), static)),
    t(qual_var, predicate_property(_:stat(_), static)),
    t(clauses_bound, predicate_property(stat(_), number_of_clauses(3))),
    t(clauses_wrong, predicate_property(stat(_), number_of_clauses(2))),
    forall(member(H, [stat(_), dyn(_), member(_, _), atom_length(_, _), findall(_, _, _),
                      numbervars(_, _, _), no_such_thing(_), ssu(_), ppm_a(_)]),
           ( functor(H, N, A),
             (   predicate_property(H, implementation_module(M)) -> true ; M = none ),
             format("implementation_module ~q: ~q~n", [N/A, M]) )),
    findall(N/A, ( predicate_property(H, dynamic), functor(H, N, A), own(N/A) ), Ds0),
    msort(Ds0, Ds),
    format("dynamic: ~q~n", [Ds]),
    findall(N/A, ( predicate_property(H, meta_predicate(_)), functor(H, N, A), own(N/A) ), Ms0),
    msort(Ms0, Ms),
    format("meta_predicate: ~q~n", [Ms]),
    findall(S, predicate_property(mr(_, _, _), meta_predicate(S)), Ss),
    format("mr spec: ~q~n", [Ss]),
    t(built_in_own, predicate_property(stat(_), built_in)),
    t(built_in_sys, predicate_property(atom_length(_, _), built_in)),
    t(built_in_taken, predicate_property(atomic_list_concat(_, _, _), built_in)),
    t(iso_sys, predicate_property(atom_length(_, _), iso)),
    t(iso_own, predicate_property(stat(_), iso)),
    t(ssu_own, predicate_property(ssu(_), ssu)),
    t(nodebug_hidden, predicate_property(hidden(_), nodebug)),
    t(nodebug_shown, predicate_property(shown(_), nodebug)),
    t(transparent_mq, predicate_property(mq(_, _), transparent)),
    t(imported_ppm, predicate_property(ppm_a(_), imported_from(ppm))),
    %% foreign where both write the predicate in C, and interpreted where
    %% both write it in Prolog (COMPAT.md has where they differ)
    t(foreign_between, predicate_property(between(_, _, _), foreign)),
    t(foreign_atom_length, predicate_property(atom_length(_, _), foreign)),
    t(foreign_member, predicate_property(member(_, _), foreign)),
    t(interpreted_member, predicate_property(member(_, _), interpreted)),
    t(interpreted_between, predicate_property(between(_, _, _), interpreted)),
    t(clauses_between, predicate_property(between(_, _, _), number_of_clauses(_))),
    t(foreign_own, predicate_property(stat(_), foreign)),
    t(no_more_after_last, ( predicate_property(stat(_), P), P == defined )).

own(N/A) :-
    member(N/A, [dyn/1, declared_only/2, tl/1, ra/1, mp/2, mq/2, mr/3, mt/1, stat/1]).

%% where a predicate's first clause stands, and its meta arguments
fl(H) :-
    functor(H, N, A),
    ( predicate_property(H, file(F)) -> file_base_name(F, B) ; B = none ),
    ( predicate_property(H, line_count(L)) -> true ; L = none ),
    ( predicate_property(H, meta_predicate(M)) -> true ; M = none ),
    format("~q: ~q ~q ~q~n", [N/A, B, L, M]).

edges :-
    format("=== edges~n"),
    %% a clause put first that no file read: swipl's names the file of the
    %% first clause in the chain, which a retract leaves there
    asserta(ea(0)), fl(ea(_)), retract(ea(0)), fl(ea(_)),
    assertz(eb(9)), fl(eb(_)),
    retract(ec(1)), fl(ec(_)),
    retract(ed(1)), fl(ed(_)),
    %% a multifile predicate: its first file's
    consult(pa), consult(pb), fl(pm(_)),
    %% a file read again: its first clause where it stands now, and none once
    %% the file defines it no more
    consult(pc), fl(pc(_)),
    rename_file('pc.v2.pl', 'pc.pl'), consult(pc), fl(pc(_)),
    rename_file('pc.v3.pl', 'pc.pl'), consult(pc), fl(pc(_)),
    %% abolish/1 takes the declaration with the clauses
    fl(pi_inc(_)), fl(pi_after(_)),
    abolish(em/1), fl(em(_)), assertz(em(x)),
    ( predicate_property(em(_), meta_predicate(S)) -> true ; S = none ),
    format("em/1 asserted after its abolish/1: ~q~n", [S]).

%% a library's first clause in its file: cocolog's lib/swipl/ holds swipl's
%% files as they are, so their lines agree, and their names but the two DCG
%% libraries' (dcg_basics.pl, swipl's dcg/basics.pl); a library compiled
%% into cocolog, as library(lists) is, has no file (COMPAT.md)
library_files :-
    format("=== library files~n"),
    forall(member(H, [list_to_assoc(_, _), put_assoc(_, _, _, _), pairs_keys(_, _),
                      ord_union(_, _, _), ord_subtract(_, _, _), top_sort(_, _),
                      aggregate(_, _, _), foreach(_, _)]),
           fl(H)),
    forall(member(H, [digits(_, _, _), sequence(_, _, _, _)]),
           ( functor(H, N, A),
             ( predicate_property(H, line_count(L)) -> true ; L = none ),
             format("~q: line ~q~n", [N/A, L]) )).
