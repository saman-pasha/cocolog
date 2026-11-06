%  get_assoc/3 as swipl's library(assoc) runs it, over swipl's C
%  '$btree_find_node'/5, and current_predicate/1 of a predicate the
%  system defines. The vendored assoc.pl has two get_assoc/3s: the one a
%  `:- if(current_predicate('$btree_find_node'/5))' keeps, which walks the
%  tree in C, and single-sided rules where there is no such predicate.
%  swipl takes the first: a term that is no assoc is type_error(btree, T),
%  a node of any name with five arguments is walked, and a subtree of
%  another name ends the walk. Through 3.30.0 cocolog took the rules: its
%  current_predicate/1 answered for the program's predicates alone, and a
%  term that is no assoc was existence_error(matching_rule, ...).
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  NOT COMPARED, each in COMPAT.md: a place equal to a node's arity, which
%  swipl's check passes and its walk then reads past the term (a
%  segmentation fault, or whatever lies there); current_predicate/1 with a
%  part of its spec unbound, which swipl walks over its system's predicates
%  too, 1278 of them; and a predicate swipl's system holds that cocolog
%  writes as a library's clauses (current_predicate/1 itself).

:- use_module(library(assoc)).   % cocolint: T1 -- swipl runs this file too, and the import is its portable form

pv(T) :- \+ \+ ( term_variables(T, Vs), pv_bind(Vs, 0), print(T) ).
pv_bind([], _).
pv_bind(['$VAR'(N)|Vs], N) :- N1 is N + 1, pv_bind(Vs, N1).

t(G) :-
    catch(( findall(G-D, ( setup_call_cleanup(true, G, D0 = det),
                           ( D0 == det -> D = det ; D = nondet ) ), L),
            pv(G), write(' => '), pv(L), nl ),
          E, ( pv(G), write(' raised '), pv(E), nl )).

h(S) :- write('== '), write(S), nl.

%% a condition the read decides as swipl's: the system's predicate named
%% whole, one no one defines, and one of the program's own above it
:- if(current_predicate('$btree_find_node'/5)).
read_branch(first).
:- else.
read_branch(second).
:- endif.
:- if(current_predicate(atom_length/2)).
read_sys(yes).
:- elif(true).
read_sys(no).
:- endif.
:- if(current_predicate(no_such_pred/7)).
read_none(yes).
:- else.
read_none(no).
:- endif.
:- if(\+ current_predicate(read_branch/1)).
read_own(no).
:- else.
read_own(yes).
:- endif.
:- if(current_predicate(call/1)).
read_construct(yes).
:- else.
read_construct(no).
:- endif.
%% and no answer for a library's predicate the program did not load, nor
%% for a name a call only looked up
:- if(current_predicate(ord_union/3)).
read_library(yes).
:- else.
read_library(no).
:- endif.
:- catch(no_such_called, _, true).
:- if(current_predicate(no_such_called/0)).
read_looked(yes).
:- else.
read_looked(no).
:- endif.

main :- reads, assoc_calls, btree_calls, current_calls, messages.

reads :-
    h(reads),
    t(read_branch(_)), t(read_sys(_)), t(read_none(_)), t(read_own(_)), t(read_construct(_)),
    t(read_library(_)), t(read_looked(_)).

assoc_calls :-
    h(assoc),
    list_to_assoc([m-1, c-2, x-3, a-4, z-5], A0),
    t(get_assoc(m, A0, _)), t(get_assoc(a, A0, _)), t(get_assoc(z, A0, _)),
    t(get_assoc(b, A0, _)), t(get_assoc(y, A0, _)), t(get_assoc(_, A0, _)),
    t(get_assoc(f(x), A0, _)), t(get_assoc(1, A0, _)),
    t(get_assoc(a, t, _)), t(get_assoc(_, t, _)),
    t(get_assoc(a, foo, _)), t(get_assoc(a, _, _)), t(get_assoc(a, 3, _)),
    t(get_assoc(a, 2.5, _)), t(get_assoc(a, [], _)), t(get_assoc(a, '[]', _)),
    t(get_assoc(a, [a], _)), t(get_assoc(a, f(x), _)), t(get_assoc(a, t(a, 1), _)),
    atom_string(abc, S), t(get_assoc(a, S, _)),
    t(get_assoc(a, t(a, 1, <, t, t), _)), t(get_assoc(a, x(a, 1, <, t, t), _)),
    t(get_assoc(b, t(a, 1, <, t, t), _)), t(get_assoc(b, t(a, 1, <, t, foo(z)), _)),
    t(get_assoc(b, t(a, 1, <, t, t(b, 2, <, t, t)), _)),
    t(get_assoc(b, t(a, 1, <, t, x(b, 2, <, t, t)), _)),
    t(get_assoc(b, x(a, 1, <, t, x(b, 2, <, t, t)), _)),
    t(get_assoc(a, t(a, 1, 2, 3), _)), t(get_assoc(a, t(a, 1, 2, 3, 4, 5), _)),
    t(get_assoc(b, t(a, 1, 2, 3, t(b, 2, 3, 4, 5, 6), 9), _)),
    t(get_assoc(1, t(1.0, x, <, t, t), _)), t(get_assoc(1.0, t(1, x, <, t, t), _)),
    t(get_assoc(k, A0, _)), t(put_assoc(k, A0, 9, A1)), put_assoc(k, A0, 9, A1),
    t(get_assoc(k, A1, _)), t(get_assoc(k, A1, 9)), t(get_assoc(k, A1, 8)).

btree_calls :-
    h(btree),
    T = t(m, 1, <, t(c, 2, <, t, t), t(x, 3, <, t, t)),
    t('$btree_find_node'(m, T, 0x010405, _, _)),
    t('$btree_find_node'(c, T, 0x010405, _, _)),
    t('$btree_find_node'(x, T, 0x010405, _, _)),
    t('$btree_find_node'(a, T, 0x010405, _, _)),
    t('$btree_find_node'(d, T, 0x010405, _, _)),
    t('$btree_find_node'(z, T, 0x010405, _, _)),
    t('$btree_find_node'(1, T, 0x010405, _, _)),
    t('$btree_find_node'(f(x), T, 0x010405, _, _)),
    t('$btree_find_node'(m, T, 0x010405, _, <)),
    t('$btree_find_node'(m, T, 0x010405, foo, _)),
    t('$btree_find_node'(m, T, 0x010405, t(_, _, _, _, _), =)),
    t('$btree_find_node'(m, n(l, m, r), 0x020103, _, _)),
    t('$btree_find_node'(a, n(n(t, a, t), m, r), 0x020103, _, _)),
    t('$btree_find_node'(z, n(l, m, n(t, z, t)), 0x020103, _, _)),
    t('$btree_find_node'(z, n(l, m, o(t, z, t)), 0x020103, _, _)),
    t('$btree_find_node'(m, [m|t], 0x010202, _, _)),
    t('$btree_find_node'(m, [a|t], 0x010202, _, _)),
    t('$btree_find_node'(z, [a, b, z], 0x010202, _, _)),
    t('$btree_find_node'(m, T, 0x01010101, _, _)),
    t('$btree_find_node'(m, T, 0x010101, _, _)),
    t('$btree_find_node'(m, T, 4294967295, _, _)),
    t('$btree_find_node'(m, T, 0xFF0101, _, _)),
    t('$btree_find_node'(m, T, 0x01000405, _, _)),
    t('$btree_find_node'(m, T, 0x0100, _, _)),
    t('$btree_find_node'(m, T, 0, _, _)),
    t('$btree_find_node'(m, T, _, _, _)),
    t('$btree_find_node'(m, T, foo, _, _)),
    t('$btree_find_node'(m, T, 1.0, _, _)),
    t('$btree_find_node'(m, T, -1, _, _)),
    t('$btree_find_node'(m, T, 4294967296, _, _)),
    t('$btree_find_node'(m, T, 9223372036854775807, _, _)),
    t('$btree_find_node'(m, foo, 0x010405, _, _)),
    t('$btree_find_node'(m, _, 0x010405, _, _)),
    t('$btree_find_node'(m, [], 0x010202, _, _)),
    t('$btree_find_node'(m, f(x), 0x010405, _, _)),
    t('$btree_find_node'(m, _, foo, _, _)),
    t('$btree_find_node'(m, foo, _, _, _)).

current_calls :-
    h(current),
    t(current_predicate(atom_length/2)), t(current_predicate(atom_length/3)),
    t(current_predicate('$btree_find_node'/5)), t(current_predicate(call/1)),
    t(current_predicate((',')/2)), t(current_predicate((;)/2)), t(current_predicate((->)/2)),
    t(current_predicate(true/0)), t(current_predicate(!/0)), t(current_predicate(fail/0)),
    t(current_predicate(is/2)), t(current_predicate(format/2)), t(current_predicate(msort/2)),
    t(current_predicate(no_such_pred/7)), t(current_predicate(read_branch/1)),
    t(current_predicate(read_branch/2)), t(current_predicate(user:atom_length/2)),
    t(current_predicate(system:atom_length/2)),
    t(current_predicate(ord_union/3)), t(current_predicate(no_such_called/0)),
    t(current_predicate(foo)), t(current_predicate(atom_length/a)),
    t(current_predicate(atom_length/(-1))), t(current_predicate(3:atom_length/2)),
    %% an error names the spec as it came, its qualifiers and an unbound
    %% module unbound; an arity past 2^31 - 1 is no spec
    t(current_predicate(user:1/2)), t(current_predicate(_:1/2)), t(current_predicate(user:foo)),
    t(current_predicate(a:b:1/2)), t(current_predicate(user:foo/a)),
    t(current_predicate(user:foo/(-1))), t(current_predicate(foo/2147483647)),
    t(current_predicate(foo/2147483648)), t(current_predicate(m:x:foo/2147483648)),
    t(current_predicate(_/2147483648)), t(current_predicate(atom_length/9223372036854775807)).

messages :-
    h(messages),
    catch(get_assoc(a, foo, _), E1, ( print_message(error, E1), write(caught), nl )),
    catch(get_assoc(a, _, _), E2, ( print_message(error, E2), write(caught), nl )),
    catch('$btree_find_node'(a, t(a, 1, <, t, t), -1, _, _), E3,
          ( print_message(error, E3), write(caught), nl )).
