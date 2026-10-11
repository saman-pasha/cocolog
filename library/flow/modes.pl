%% library(flowchart), part: the hand-kept table of tests and of every
%% builtin's modes and determinism.

%% open/3 and read_term/3 below, in the table of calls the engine refuses,
%% are library(stream)'s
:- use_module(library(stream)).

flow_test('<', 2).
flow_test('>', 2).
flow_test('=<', 2).
flow_test('>=', 2).
flow_test('=:=', 2).
flow_test('=\\=', 2).
flow_test('==', 2).
flow_test('\\==', 2).
flow_test('@<', 2).
flow_test('@>', 2).
flow_test('@=<', 2).
flow_test('@>=', 2).
flow_test('\\=', 2).
flow_test(var, 1).
flow_test(nonvar, 1).
flow_test(atom, 1).
flow_test(number, 1).
flow_test(integer, 1).
flow_test(float, 1).
flow_test(atomic, 1).
flow_test(compound, 1).
flow_test(callable, 1).
flow_test(is_list, 1).
flow_test(ground, 1).
flow_test(string, 1).

%% THE HAND-KEPT TABLE: a builtin's or a library predicate's argument modes
%% and determinism, a line per way of calling it, as SWI's manual lists
%% them. det never fails; semidet may fail and leaves no choice; nondet may
%% leave one. A call takes the first line its modes meet (flow_mode_for/5)
%% and else the first line, CHECKING what that line would produce: a det
%% builtin handed its output already bound only compares, and can fail. F1
%% makes the table complete against the engine's own builtin table; the
%% prototype carries what charts usually meet.
flow_mode(is, 2, ['-', '+'], det).
flow_mode(succ, 2, ['?', '?'], semidet).
flow_mode(plus, 3, ['?', '?', '?'], semidet).
flow_mode(functor, 3, ['+', '-', '-'], det).
flow_mode(functor, 3, ['-', '+', '+'], det).
flow_mode(arg, 3, ['+', '+', '?'], semidet).
flow_mode('=..', 2, ['+', '-'], det).
flow_mode('=..', 2, ['-', '+'], det).
flow_mode(copy_term, 2, ['+', '-'], det).
flow_mode(term_variables, 2, ['+', '-'], det).
flow_mode(atom_codes, 2, ['+', '-'], det).
flow_mode(atom_codes, 2, ['-', '+'], det).
flow_mode(atom_chars, 2, ['+', '-'], det).
flow_mode(atom_chars, 2, ['-', '+'], det).
flow_mode(char_code, 2, ['+', '-'], det).
flow_mode(char_code, 2, ['-', '+'], det).
flow_mode(atom_length, 2, ['+', '-'], det).
flow_mode(atom_number, 2, ['+', '-'], semidet).
flow_mode(atom_number, 2, ['-', '+'], det).
flow_mode(number_codes, 2, ['+', '-'], det).
flow_mode(number_codes, 2, ['-', '+'], det).
flow_mode(atom_concat, 3, ['+', '+', '-'], det).
flow_mode(atom_concat, 3, ['?', '?', '?'], semidet).
flow_mode(sub_atom, 5, ['+', '?', '?', '?', '?'], nondet).
flow_mode(atomic_list_concat, 2, ['+', '-'], det).
flow_mode(atomic_list_concat, 3, ['+', '+', '-'], det).
flow_mode(atomic_list_concat, 3, ['-', '+', '+'], det).
flow_mode(upcase_atom, 2, ['+', '-'], det).
flow_mode(term_to_atom, 2, ['+', '-'], det).
flow_mode(term_to_atom, 2, ['-', '+'], det).
flow_mode(format, 1, ['+'], det).
flow_mode(format, 2, ['+', '+'], det).
flow_mode(format, 3, ['+', '+', '+'], det).
flow_mode(write, 1, ['+'], det).
flow_mode(print, 1, ['+'], det).
flow_mode(writeln, 1, ['+'], det).
flow_mode(write_canonical, 1, ['+'], det).
flow_mode(nl, 0, [], det).
flow_mode(tab, 1, ['+'], det).
flow_mode(read_term, 3, ['+', '-', '+'], det).
flow_mode(read, 1, ['-'], det).
flow_mode(assertz, 1, ['+'], det).
flow_mode(asserta, 1, ['+'], det).
flow_mode(assert, 1, ['+'], det).
flow_mode(retract, 1, ['?'], semidet).
flow_mode(retractall, 1, ['?'], det).
flow_mode(nb_setval, 2, ['+', '+'], det).
flow_mode(nb_getval, 2, ['+', '-'], det).
flow_mode(b_setval, 2, ['+', '+'], det).
flow_mode(b_getval, 2, ['+', '-'], det).
flow_mode(length, 2, ['+', '-'], det).
flow_mode(length, 2, ['-', '+'], det).
flow_mode(length, 2, ['+', '+'], semidet).
flow_mode(length, 2, ['?', '?'], nondet).
flow_mode(between, 3, ['+', '+', '?'], nondet).
flow_mode(msort, 2, ['+', '-'], det).
flow_mode(sort, 2, ['+', '-'], det).
flow_mode(sort, 4, ['+', '+', '+', '-'], det).
flow_mode(keysort, 2, ['+', '-'], det).
flow_mode(member, 2, ['?', '+'], nondet).
flow_mode(memberchk, 2, ['?', '+'], semidet).
flow_mode(append, 3, ['?', '?', '?'], nondet).
flow_mode(append, 2, ['+', '-'], det).
flow_mode(reverse, 2, ['+', '-'], det).
flow_mode(nth0, 3, ['?', '+', '?'], nondet).
flow_mode(nth1, 3, ['?', '+', '?'], nondet).
flow_mode(last, 2, ['+', '-'], semidet).
flow_mode(sum_list, 2, ['+', '-'], det).
flow_mode(max_list, 2, ['+', '-'], semidet).
flow_mode(min_list, 2, ['+', '-'], semidet).
flow_mode(numlist, 3, ['+', '+', '-'], det).
flow_mode(list_to_set, 2, ['+', '-'], det).
flow_mode(delete, 3, ['+', '+', '-'], det).
flow_mode(subtract, 3, ['+', '+', '-'], det).
flow_mode(select, 3, ['?', '?', '?'], nondet).
flow_mode(exclude, 3, [':', '+', '-'], det).
flow_mode(include, 3, [':', '+', '-'], det).
flow_mode(maplist, 2, [':', '?'], semidet).
flow_mode(maplist, 3, [':', '?', '?'], semidet).
flow_mode(maplist, 4, [':', '?', '?', '?'], semidet).
flow_mode(foldl, 4, [':', '+', '+', '-'], semidet).
flow_mode(flatten, 2, ['+', '-'], det).
flow_mode(halt, 0, [], det).
flow_mode(halt, 1, ['+'], det).
flow_mode(get_time, 1, ['-'], det).
flow_mode(statistics, 2, ['+', '-'], det).
flow_mode(garbage_collect, 0, [], det).
flow_mode(list_to_assoc, 2, ['+', '-'], det).
flow_mode(put_assoc, 4, ['+', '+', '+', '-'], det).
flow_mode(get_assoc, 3, ['+', '+', '?'], semidet).
flow_mode(pairs_keys_values, 3, ['+', '-', '-'], det).
flow_mode(pairs_keys_values, 3, ['-', '+', '+'], det).
flow_mode(read_file_to_codes, 2, ['+', '-'], det).
flow_mode(open, 3, ['+', '+', '-'], det).
flow_mode(open, 4, ['+', '+', '-', '+'], det).
flow_mode(close, 1, ['+'], det).
flow_mode(codes_lines, 2, ['+', '-'], det).
flow_mode(codes_lines, 2, ['-', '+'], det).

%% ---- the rest of the engine's C builtins, so every one has a line ------
%% (test/flowchart.pl holds the table to the generated list of them).
%% findall/3,4, forall/2, aggregate_all/3 and =/2 are walked by the
%% analysis itself; their lines are here for completeness.
flow_mode((=), 2, ['?', '?'], semidet).
flow_mode(findall, 3, ['?', ':', '-'], det).
flow_mode(findall, 4, ['?', ':', '-', '?'], det).
flow_mode(forall, 2, [':', ':'], semidet).
flow_mode(aggregate_all, 3, ['+', ':', '-'], semidet).
flow_mode(compare, 3, ['-', '+', '+'], det).
flow_mode(compare, 3, ['+', '+', '+'], semidet).
flow_mode(unify_with_occurs_check, 2, ['?', '?'], semidet).
flow_mode(call_limited, 3, [':', '+', '-'], semidet).
flow_mode(call_metered, 4, [':', '+', '-', '-'], det).
flow_mode(with_output_to, 2, ['+', ':'], semidet).
flow_mode(char_type, 2, ['+', '+'], semidet).
flow_mode(char_type, 2, ['?', '?'], nondet).
flow_mode(code_type, 2, ['+', '+'], semidet).
flow_mode(code_type, 2, ['?', '?'], nondet).
flow_mode(downcase_atom, 2, ['+', '-'], det).
flow_mode(number_chars, 2, ['+', '-'], det).
flow_mode(number_chars, 2, ['-', '+'], det).
flow_mode(atom_string, 2, ['+', '-'], det).
flow_mode(atom_string, 2, ['-', '+'], det).
flow_mode(number_string, 2, ['-', '+'], det).
flow_mode(string_chars, 2, ['+', '-'], det).
flow_mode(string_chars, 2, ['-', '+'], det).
flow_mode(string_codes, 2, ['+', '-'], det).
flow_mode(string_codes, 2, ['-', '+'], det).
flow_mode(string_to_atom, 2, ['+', '-'], det).
flow_mode(string_to_atom, 2, ['-', '+'], det).
flow_mode(string_concat, 3, ['+', '+', '-'], det).
flow_mode(string_length, 2, ['+', '-'], det).
flow_mode(string_lower, 2, ['+', '-'], det).
flow_mode(string_upper, 2, ['+', '-'], det).
flow_mode(split_string, 4, ['+', '+', '+', '-'], det).
flow_mode(term_string, 2, ['+', '-'], det).
flow_mode(term_string, 2, ['-', '+'], det).
flow_mode(text_concat, 3, ['+', '+', '-'], det).
flow_mode(text_concat, 3, ['?', '?', '?'], nondet).
flow_mode(write_term, 2, ['+', '+'], det).
flow_mode(writeq, 1, ['+'], det).
flow_mode(flush_output, 0, [], det).
flow_mode(listing, 0, [], det).
flow_mode(listing, 1, ['+'], det).
flow_mode(op, 3, ['+', '+', '+'], det).
flow_mode(current_prolog_flag, 2, ['+', '-'], semidet).
flow_mode(current_prolog_flag, 2, ['?', '?'], nondet).
flow_mode(abolish, 1, ['+'], det).
flow_mode((dynamic), 1, ['+'], det).
flow_mode(ensure_loaded, 1, ['+'], det).
flow_mode(use_module, 1, ['+'], det).
flow_mode(use_module, 2, ['+', '+'], det).
flow_mode(prewarm, 1, ['+'], det).
flow_mode(trace, 0, [], det).
flow_mode(notrace, 0, [], det).
flow_mode(getenv, 2, ['+', '-'], semidet).
flow_mode(setenv, 2, ['+', '+'], det).
flow_mode(unsetenv, 1, ['+'], det).
flow_mode(working_directory, 2, ['-', '?'], det).
flow_mode(absolute_file_name, 2, ['+', '-'], det).
flow_mode(is_absolute_file_name, 1, ['+'], semidet).
flow_mode(expand_file_name, 2, ['+', '-'], det).
flow_mode(exists_file, 1, ['+'], semidet).
flow_mode(exists_directory, 1, ['+'], semidet).
flow_mode(access_file, 2, ['+', '+'], semidet).
flow_mode(same_file, 2, ['+', '+'], semidet).
flow_mode(size_file, 2, ['+', '-'], det).
flow_mode(time_file, 2, ['+', '-'], det).
flow_mode(read_link, 3, ['+', '-', '-'], semidet).
flow_mode(directory_files, 2, ['+', '-'], det).
flow_mode(make_directory, 1, ['+'], semidet).      % fails on a name already taken
flow_mode(delete_directory, 1, ['+'], det).
flow_mode(delete_file, 1, ['+'], det).
flow_mode(rename_file, 2, ['+', '+'], det).
flow_mode(tmp_file, 2, ['+', '-'], det).
flow_mode(write_file_from_codes, 2, ['+', '+'], det).
flow_mode(append_file_from_codes, 2, ['+', '+'], det).
flow_mode(vacuum_kb, 0, [], det).
flow_mode(vacuum_kb, 1, ['+'], det).
flow_mode(zigurat_begin, 0, [], det).
flow_mode(zigurat_commit, 0, [], det).
flow_mode(zigurat_rollback, 0, [], det).
flow_mode(zigurat_auto_commit, 1, ['+'], det).
flow_mode(zigurat_isolation, 1, ['+'], det).
flow_mode(zigurat_transaction_id, 1, ['-'], det).
flow_mode(zigurat_compile, 1, ['+'], det).
flow_mode(zigurat_call, 2, ['+', '?'], semidet).
flow_mode(zigurat_call, 3, ['+', '+', '?'], semidet).

%% the line a call takes: the first whose modes it meets (a bound argument
%% meets + or ?, a free one - or ?), else the first line, which then only
%% checks where it would have produced -- det becomes semidet
flow_mode_for(N, A, Ms, DMs, Det) :-
    (   flow_mode(N, A, DMs, Det), flow_modes_meet(Ms, DMs) -> true
    ;   flow_mode(N, A, DMs, Det0), flow_modes_meet_loosely(Ms, DMs)
    ->  (   Det0 == det, flow_partial_output(Ms, DMs) -> Det = semidet ; Det = Det0 )
    ;   flow_mode(N, A, DMs, Det0), !,
        (   Det0 == det -> Det = semidet ; Det = Det0 )
    ).

%% a partly bound argument may be what either side of a line needs: G =..
%% [C, W] with W free is the (-, +) line, its list a proper one. Where it
%% stands for an output the answer is unified with it, which can fail:
%% A =.. [K, which(W, C)] tests what A is
flow_modes_meet_loosely([], []).
flow_modes_meet_loosely([M|Ms], [D|Ds]) :-
    (   flow_mode_meets(M, D) -> true ; M == '?' ), !,
    flow_modes_meet_loosely(Ms, Ds).

flow_modes_meet([], []).
flow_modes_meet([M|Ms], [D|Ds]) :-
    flow_mode_meets(M, D), !,
    flow_modes_meet(Ms, Ds).

flow_mode_meets(_, '?').
flow_mode_meets(_, ':').
flow_mode_meets('+', '+').
flow_mode_meets('-', '-').


%% CALLS THE ENGINE REFUSES. Each row says that Name/Arity raises an error
%% when it runs with every argument at Positions unbound --
%% instantiation_error, or type_error where cocolog says so -- whatever
%% the others hold, and Example is such a call: test/flowchart.pl calls
%% every Example and requires the error. A call of one of these whose
%% arguments there are free on every path to it is an instantiation
%% finding. The mode table's `+' above says INPUT, which is not the same
%% thing: write(X) and format(F, X) take an unbound X and print it.
flow_raises_unbound(atom_length, 2, [1], atom_length(_, 3)).
flow_raises_unbound(atom_codes, 2, [1, 2], atom_codes(_, _)).
flow_raises_unbound(atom_chars, 2, [1, 2], atom_chars(_, _)).
flow_raises_unbound(char_code, 2, [1, 2], char_code(_, _)).
flow_raises_unbound(number_codes, 2, [1, 2], number_codes(_, _)).
flow_raises_unbound(atom_number, 2, [1, 2], atom_number(_, _)).
flow_raises_unbound(atom_string, 2, [1, 2], atom_string(_, _)).
flow_raises_unbound(number_string, 2, [1, 2], number_string(_, _)).
flow_raises_unbound(string_codes, 2, [1, 2], string_codes(_, _)).
flow_raises_unbound(string_chars, 2, [1, 2], string_chars(_, _)).
flow_raises_unbound(string_to_atom, 2, [1, 2], string_to_atom(_, _)).
flow_raises_unbound(term_to_atom, 2, [1, 2], term_to_atom(_, _)).
flow_raises_unbound(upcase_atom, 2, [1], upcase_atom(_, 'X')).
flow_raises_unbound(succ, 2, [1, 2], succ(_, _)).
flow_raises_unbound(plus, 3, [1, 2], plus(_, _, 3)).
flow_raises_unbound(plus, 3, [2, 3], plus(1, _, _)).
flow_raises_unbound(plus, 3, [1, 3], plus(_, 1, _)).
flow_raises_unbound(atom_concat, 3, [1, 3], atom_concat(_, a, _)).
flow_raises_unbound(atom_concat, 3, [2, 3], atom_concat(a, _, _)).
flow_raises_unbound(string_concat, 3, [1, 3], string_concat(_, "a", _)).
flow_raises_unbound(string_concat, 3, [2, 3], string_concat("a", _, _)).
flow_raises_unbound(sub_atom, 5, [1], sub_atom(_, 0, 1, _, _)).
flow_raises_unbound(sub_string, 5, [1], sub_string(_, 0, 1, _, _)).
flow_raises_unbound(split_string, 4, [1], split_string(_, "", "", _)).
flow_raises_unbound(functor, 3, [1, 3], functor(_, f, _)).
flow_raises_unbound(functor, 3, [1, 2], functor(_, _, 2)).
flow_raises_unbound(arg, 3, [1], arg(_, f(a), _)).
flow_raises_unbound(arg, 3, [2], arg(1, _, _)).
flow_raises_unbound((=..), 2, [1, 2], _ =.. _).
flow_raises_unbound(atomic_list_concat, 2, [1], atomic_list_concat(_, abc)).
flow_raises_unbound(atomic_list_concat, 3, [1, 3], atomic_list_concat(_, '-', _)).
flow_raises_unbound(msort, 2, [1], msort(_, _)).
flow_raises_unbound(sort, 2, [1], sort(_, _)).
flow_raises_unbound(keysort, 2, [1], keysort(_, _)).
flow_raises_unbound(nb_getval, 2, [1], nb_getval(_, _)).
flow_raises_unbound(nb_setval, 2, [1], nb_setval(_, 1)).
flow_raises_unbound(format, 1, [1], format(_)).
flow_raises_unbound(format, 2, [1], format(_, [])).
flow_raises_unbound(format, 3, [2], format(atom(_), _, [])).
flow_raises_unbound(tab, 1, [1], tab(_)).
flow_raises_unbound(op, 3, [1], op(_, xfx, foo)).
flow_raises_unbound(op, 3, [2], op(700, _, foo)).
flow_raises_unbound(open, 3, [1], open(_, read, _)).
flow_raises_unbound(exists_file, 1, [1], exists_file(_)).
flow_raises_unbound(exists_directory, 1, [1], exists_directory(_)).
flow_raises_unbound(read_term, 3, [1], read_term(_, _, [])).
flow_raises_unbound(read_file_to_codes, 2, [1], read_file_to_codes(_, _)).
flow_raises_unbound(between, 3, [1], between(_, 3, _)).
flow_raises_unbound(between, 3, [2], between(1, _, _)).
flow_raises_unbound(numlist, 3, [1], numlist(_, 3, _)).
flow_raises_unbound(numlist, 3, [2], numlist(1, _, _)).
flow_raises_unbound(char_type, 2, [1], char_type(_, alpha)).
flow_raises_unbound(code_type, 2, [1], code_type(_, alpha)).
flow_raises_unbound(throw, 1, [1], throw(_)).
flow_raises_unbound(assertz, 1, [1], assertz(_)).
flow_raises_unbound(asserta, 1, [1], asserta(_)).
flow_raises_unbound(assert, 1, [1], assert(_)).
flow_raises_unbound(retract, 1, [1], retract(_)).

%% ARITHMETIC evaluates every variable in an expression: is/2's second
%% argument, and both sides of a comparison
flow_evaluates(is, 2, [2]).
flow_evaluates('<', 2, [1, 2]).
flow_evaluates('>', 2, [1, 2]).
flow_evaluates('=<', 2, [1, 2]).
flow_evaluates('>=', 2, [1, 2]).
flow_evaluates('=:=', 2, [1, 2]).
flow_evaluates('=\\=', 2, [1, 2]).

flow_partial_output(['?'|_], ['-'|_]) :- !.
flow_partial_output([_|Ms], [_|Ds]) :- flow_partial_output(Ms, Ds).
