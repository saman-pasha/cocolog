%  current_predicate/1 named whole, as swipl's asks it of user's module:
%  a predicate of swipl's system is user's through its import of system
%  -- between/3, sub_atom/5 and bagof/3 among them, which cocolog writes
%  as a library's clauses -- and a library module's export is user's once
%  the program imported it: use_module/1,2 with its import list or its
%  except/1, ensure_loaded/1, autoload/2's list, a list of files,
%  consult/1, `[File]', load_files/2 with its imports(I), as a directive
%  or as a goal, and predicate_property/2 of a head it names, whose
%  define_or_generate/1 autoloads the head (but for visible, undefined,
%  iso, built_in, autoload(_) and implementation_module(_)), of user's
%  module and no other. A load that fails imports nothing. Through 3.41.0
%  cocolog answered its own way: a C row yes, aggregate_all/3 and nth0/3
%  before any load among them, and a library's clauses no, between/3 and
%  member/2 after use_module(library(lists)) among them; and consult/1,
%  `[File]' and load_files/2 of library(error), library(listing) and the
%  two DCG libraries raised existence_error.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  NOT COMPARED, each in COMPAT.md: a library's export the program CALLED
%  without loading its library, which swipl's autoload imports at the call
%  and cocolog does not (so nothing here calls an export before it asks of
%  it); `PI as Name' in an import list, which cocolog cannot rename; a
%  qualified spec, which cocolog asks as user's (lists:append/3 before
%  swipl has read library(lists), system:append/3, a module no one made);
%  and the hooks swipl's user module declares (term_expansion/2,
%  file_search_path/2, message_hook/3).

:- use_module([library(pairs)]).   % cocolint: T1 -- swipl runs this file too, and the import is what it tests
:- use_module(library(ordsets), [ord_union/3, ord_subtract/3]).   % cocolint: T1 -- swipl runs this file too, and the import is what it tests
:- use_module(library(ugraphs), except([vertices/2])).   % cocolint: T1 -- swipl runs this file too, and the import is what it tests
:- autoload(library(assoc), [list_to_assoc/2]).
:- autoload(library(yall)).
:- ensure_loaded(library(dcg/basics)).

:- dynamic d/1.

%% the read's own question, before main runs
:- if(current_predicate(between/3)).
r(between, yes).
:- else.
r(between, no).
:- endif.
:- if(current_predicate(append/3)).
r(append, yes).
:- else.
r(append, no).
:- endif.
:- if(current_predicate(pairs_keys/2)).
r(pairs_keys, yes).
:- else.
r(pairs_keys, no).
:- endif.
:- if(current_predicate(list_to_assoc/2)).
r(list_to_assoc, yes).
:- else.
r(list_to_assoc, no).
:- endif.
:- if(current_predicate(put_assoc/4)).
r(put_assoc, yes).
:- else.
r(put_assoc, no).
:- endif.

h(S) :- nl, write('== '), write(S), nl.

t(PI) :- ( current_predicate(PI) -> R = yes ; R = no ), writeq(PI-R), nl.

ts([]).
ts([PI|PIs]) :- t(PI), ts(PIs).

g(G) :- ( catch(G, _, fail) -> R = yes ; R = no ), \+ \+ ( numbervars(G, 0, _), print(G-R) ), nl.

main :- reads, system, before, directives, goals, props, loads, own.

reads :-
    h(reads),
    r(between, A), writeq(between-A), nl,
    r(append, B), writeq(append-B), nl,
    r(pairs_keys, C), writeq(pairs_keys-C), nl,
    r(list_to_assoc, D), writeq(list_to_assoc-D), nl,
    r(put_assoc, E), writeq(put_assoc-E), nl.

%% swipl's system's, which cocolog writes as a library's clauses, then a
%% few it writes in C, and a name no one defines
system :-
    h(system),
    ts([between/3, sub_atom/5, atom_concat/3, string_concat/3, sub_string/5,
        bagof/3, setof/3, phrase/2, phrase/3, call_dcg/3, apply/2, numbervars/3,
        setup_call_cleanup/3, setup_call_catcher_cleanup/4, call_cleanup/2,
        keysort/2, current_op/3, current_predicate/1, predicate_property/2,
        retractall/1, strip_module/3, print_message/2, print_message_lines/3,
        message_to_string/2, compound_name_arity/3, compound_name_arguments/3,
        consult/1, load_files/2, absolute_file_name/2, absolute_file_name/3,
        file_base_name/2, file_directory_name/2, file_name_extension/3,
        prolog_to_os_filename/2, expand_file_search_path/2,
        prolog_load_context/2, term_string/3, expand_term/2, expand_goal/2,
        dcg_translate_rule/2, string_code/3, copy_term_nat/2, atom_prefix/2,
        (public)/1, (volatile)/1, (thread_local)/1, (module_transparent)/1,
        (non_terminal)/1, (thread_initialization)/1,
        atom_length/2, format/2, msort/2, call/3, (\+)/1, (',')/2, (!)/0,
        no_such_pred/9]).

%% a library's exports the program has not imported, its C rows among them
before :-
    h(before),
    ts([append/3, member/2, last/2, reverse/2, nth0/3, nth1/3, sum_list/2,
        aggregate_all/3, aggregate_all/4, maplist/3, foldl/4, include/3,
        listing/0, listing/1, portray_clause/1, must_be/2, type_error/2,
        is_of_type/2, (>>)/2, put_assoc/4, ord_memberchk/2]).

%% what the directives above imported
directives :-
    h(directives),
    ts([pairs_keys/2, pairs_values/2, transpose_pairs/2,
        ord_union/3, ord_subtract/3, ord_memberchk/2,
        edges/2, top_sort/2, vertices/2,
        list_to_assoc/2, put_assoc/4,
        blanks/2, digits/3, integer/3]).

%% what the program's goals import, and a load that fails imports nothing
goals :-
    h(goals),
    g(use_module(library(lists), [append/3])),
    ts([append/3, member/2, last/2]),
    g(use_module(library(apply))),
    ts([maplist/3, foldl/4, partition/4]),
    g(ensure_loaded(library(aggregate))),
    ts([aggregate_all/3, aggregate_all/4]),
    g(use_module(library(lists), except([last/2, nth1/3]))),
    ts([member/2, nth0/3, last/2, nth1/3, reverse/2]),
    g(use_module(library(listing))),
    ts([listing/0, listing/1, portray_clause/1]),
    g(use_module(library(error))),
    ts([must_be/2, type_error/2, is_of_type/2]),
    g(use_module([library(yall), library(ugraphs)])),
    ts([(>>)/2, vertices/2]),
    catch(use_module(library(no_such_library)), _, true),
    t(no_such_library_pred/0).

%% predicate_property/2 of a head names it, but for six properties, and of
%% user's module alone
props :-
    h(props),
    g(predicate_property(ord_memberchk(_, _), visible)), t(ord_memberchk/2),
    g(predicate_property(ord_memberchk(_, _), iso)), t(ord_memberchk/2),
    g(predicate_property(ord_memberchk(_, _), built_in)), t(ord_memberchk/2),
    g(predicate_property(ord_memberchk(_, _), undefined)), t(ord_memberchk/2),
    g(predicate_property(ord_memberchk(_, _), implementation_module(_))), t(ord_memberchk/2),
    g(predicate_property(ordsets:ord_disjoint(_, _), defined)), t(ord_disjoint/2),
    g(predicate_property(ord_memberchk(_, _), defined)), t(ord_memberchk/2),
    g(predicate_property(user:ord_subset(_, _), static)), t(ord_subset/2),
    g(predicate_property(system:ord_seteq(_, _), defined)), t(ord_seteq/2),
    g(predicate_property(list_to_ord_set(_, _), no_such_property)), t(list_to_ord_set/2),
    g(once(predicate_property(ord_add_element(_, _, _), _))), t(ord_add_element/3),
    g(predicate_property(put_assoc(_, _, _, _), dynamic)), t(put_assoc/4).

%% consult/1, `[File]' and load_files/2 of a library import it as
%% use_module/1 does, or what load_files/2's imports(List) lists, a library
%% cocolog carries elsewhere among them
loads :-
    h(loads),
    g(load_files(library(assoc), [imports([get_assoc/3])])),
    ts([get_assoc/3, empty_assoc/1]),
    g(consult(library(ordsets))),
    ts([ord_intersection/3, ord_union/2]),
    g([library(dcg/high_order)]),
    ts([sequence/5, optional/4]),
    g(load_files(library(lists), [])),
    ts([last/2, nth1/3]),
    g(load_files(library(assoc), [if(not_loaded)])),
    ts([empty_assoc/1, del_assoc/4]),
    catch(consult(library(no_such_library)), _, true),
    t(no_such_library_pred/0).

%% the program's own, whatever its name
own :-
    h(own),
    ts([t/1, ts/1, d/1, main/0, no_such_own/0]).
