%% What each builtin raises, and the predicate its error names -- held to
%% swipl 9.0.4 (cocolog 3.0.0).
%%
%% swipl raises a builtin's error as error(Formal, context(system:Name/Arity,
%% _)): the context names the predicate that raised, and print_message/2
%% writes `Name/Arity: ' before the message from it. Through 2.16.1 every
%% core builtin of cocolog left the context unbound, so no message named a
%% predicate, and many raised another error than swipl's, or failed where it
%% raises. Each builtin here is called twice: with a compound in every
%% argument, and with every argument unbound. A line is the goal as it
%% ended, then yes, no, failed or the ball, every variable written `_'.
%%
%% Left out, and why: cocolog's own text_concat/3, append_file_from_codes/2
%% and write_file_from_codes/2, which swipl 9.0.4 has not;
%% current_prolog_flag(_, _) and get_time(_), whose first answers are each
%% system's own; the writers, term_to_atom/2 and term_string/2 of an
%% unbound term, which write the variable's name; and last(_, _), which
%% fails here where swipl answers [_] (stated in STATUS.md, 3.0.0).

:- set_prolog_flag(double_quotes, codes).

e(G) :-
    (   catch(( G -> R = yes ; R = no ), E, R = E) -> true ; R = failed ),
    copy_term(G-R, G2-R2),
    term_variables(G2-R2, Vs), maplist(=('$VAR'('_')), Vs),
    print(G2), write('  ==>  '), print(R2), nl.

main :- forall(p(G), e(G)).

p(<(f(x),f(x))).
p(<(_,_)).
p(=..(f(x),f(x))).
p(=..(_,_)).
p(=(f(x),f(x))).
p(=(_,_)).
p(=:=(f(x),f(x))).
p(=:=(_,_)).
p(=<(f(x),f(x))).
p(=<(_,_)).
p(==(f(x),f(x))).
p(==(_,_)).
p(=@=(f(x),f(x))).
p(=@=(_,_)).
p(=\=(f(x),f(x))).
p(=\=(_,_)).
p(>(f(x),f(x))).
p(>(_,_)).
p(>=(f(x),f(x))).
p(>=(_,_)).
p(@<(f(x),f(x))).
p(@<(_,_)).
p(@=<(f(x),f(x))).
p(@=<(_,_)).
p(@>(f(x),f(x))).
p(@>(_,_)).
p(@>=(f(x),f(x))).
p(@>=(_,_)).
p(\=(f(x),f(x))).
p(\=(_,_)).
p(\==(f(x),f(x))).
p(\==(_,_)).
p(\=@=(f(x),f(x))).
p(\=@=(_,_)).
p(abolish(f(x))).
p(abolish(_)).
p(absolute_file_name(f(x),f(x))).
p(absolute_file_name(_,_)).
p(access_file(f(x),f(x))).
p(access_file(_,_)).
p(acyclic_term(f(x))).
p(acyclic_term(_)).
p(aggregate_all(f(x),f(x),f(x))).
p(aggregate_all(_,_,_)).
p(arg(f(x),f(x),f(x))).
p(arg(_,_,_)).
p(assert(f(x))).
p(assert(_)).
p(asserta(f(x))).
p(asserta(_)).
p(assertz(f(x))).
p(assertz(_)).
p(atom(f(x))).
p(atom(_)).
p(atom_chars(f(x),f(x))).
p(atom_chars(_,_)).
p(atom_codes(f(x),f(x))).
p(atom_codes(_,_)).
p(atom_length(f(x),f(x))).
p(atom_length(_,_)).
p(atom_number(f(x),f(x))).
p(atom_number(_,_)).
p(atom_string(f(x),f(x))).
p(atom_string(_,_)).
p(atom_to_term(f(x),f(x),f(x))).
p(atom_to_term(_,_,_)).
p(atomic(f(x))).
p(atomic(_)).
p(atomic_concat(f(x),f(x),f(x))).
p(atomic_concat(_,_,_)).
p(atomic_list_concat(f(x),f(x))).
p(atomic_list_concat(_,_)).
p(atomic_list_concat(f(x),f(x),f(x))).
p(atomic_list_concat(_,_,_)).
p(atomics_to_string(f(x),f(x))).
p(atomics_to_string(_,_)).
p(atomics_to_string(f(x),f(x),f(x))).
p(atomics_to_string(_,_,_)).
p(b_getval(f(x),f(x))).
p(b_getval(_,_)).
p(b_setval(f(x),f(x))).   % cocolint: G1 -- the case asks its error, not what it keeps
p(b_setval(_,_)).   % cocolint: G1 -- the case asks its error, not what it keeps
p(callable(f(x))).
p(callable(_)).
p(char_code(f(x),f(x))).
p(char_code(_,_)).
p(char_type(f(x),f(x))).
p(char_type(_,_)).
p(code_type(f(x),f(x))).
p(code_type(_,_)).
p(compare(f(x),f(x),f(x))).
p(compare(_,_,_)).
p(compound(f(x))).
p(compound(_)).
p(copy_term(f(x),f(x))).
p(copy_term(_,_)).
p(current_prolog_flag(f(x),f(x))).   % cocolint: P1 -- the case asks the error a compound flag raises
p(cyclic_term(f(x))).
p(cyclic_term(_)).
p(delete_directory(f(x))).
p(delete_directory(_)).
p(delete_file(f(x))).
p(delete_file(_)).
p(dynamic(f(x))).
p(dynamic(_)).
p(directory_files(f(x),f(x))).
p(directory_files(_,_)).
p(downcase_atom(f(x),f(x))).
p(downcase_atom(_,_)).
p(exists_directory(f(x))).
p(exists_directory(_)).
p(exists_file(f(x))).
p(exists_file(_)).
p(expand_file_name(f(x),f(x))).
p(expand_file_name(_,_)).
p(findall(f(x),f(x),f(x))).
p(findall(_,_,_)).
p(findall(f(x),f(x),f(x),f(x))).
p(findall(_,_,_,_)).
p(float(f(x))).
p(float(_)).
p(forall(f(x),f(x))).
p(forall(_,_)).
p(format(f(x))).
p(format(_)).
p(format(f(x),f(x))).
p(format(_,_)).
p(format(f(x),f(x),f(x))).
p(format(_,_,_)).
p(functor(f(x),f(x),f(x))).
p(functor(_,_,_)).
p(get_string_code(f(x),f(x),f(x))).
p(get_string_code(_,_,_)).
p(get_time(f(x))).
p(getenv(f(x),f(x))).
p(getenv(_,_)).
p(ground(f(x))).
p(ground(_)).
p(integer(f(x))).
p(integer(_)).
p(is(f(x),f(x))).
p(is(_,_)).
p(is_absolute_file_name(f(x))).
p(is_absolute_file_name(_)).
p(is_list(f(x))).
p(is_list(_)).
p(last(f(x),f(x))).
p(length(f(x),f(x))).
p(length(_,_)).
p(make_directory(f(x))).
p(make_directory(_)).
p(memberchk(f(x),f(x))).
p(memberchk(_,_)).
p(msort(f(x),f(x))).
p(msort(_,_)).
p(nb_current(f(x),f(x))).
p(nb_current(_,_)).
p(nb_getval(f(x),f(x))).
p(nb_getval(_,_)).
p(nb_setarg(f(x),f(x),f(x))).
p(nb_setarg(_,_,_)).
p(nb_setval(f(x),f(x))).
p(nb_setval(_,_)).
p(nonvar(f(x))).
p(nonvar(_)).
p(nth0(f(x),f(x),f(x))).
p(nth0(_,_,_)).
p(nth1(f(x),f(x),f(x))).
p(nth1(_,_,_)).
p(number(f(x))).
p(number(_)).
p(number_chars(f(x),f(x))).
p(number_chars(_,_)).
p(number_codes(f(x),f(x))).
p(number_codes(_,_)).
p(number_string(f(x),f(x))).
p(number_string(_,_)).
p(op(f(x),f(x),f(x))).
p(op(_,_,_)).
p(plus(f(x),f(x),f(x))).
p(plus(_,_,_)).
p(print(f(x))).
p(random_property(f(x))).
p(random_property(_)).
p(rational(f(x))).
p(rational(_)).
p(rational(f(x),f(x),f(x))).
p(rational(_,_,_)).
p(rename_file(f(x),f(x))).
p(rename_file(_,_)).
p(retract(f(x))).
p(retract(_)).
p(reverse(f(x),f(x))).
p(reverse(_,_)).
p(same_file(f(x),f(x))).
p(same_file(_,_)).
p(set_prolog_flag(f(x),f(x))).
p(set_prolog_flag(_,_)).
p(set_random(f(x))).
p(set_random(_)).
p(setarg(f(x),f(x),f(x))).
p(setarg(_,_,_)).
p(setenv(f(x),f(x))).
p(setenv(_,_)).
p(size_file(f(x),f(x))).
p(size_file(_,_)).
p(sort(f(x),f(x))).
p(sort(_,_)).
p(sort(f(x),f(x),f(x),f(x))).
p(sort(_,_,_,_)).
p(source_location(f(x),f(x))).
p(source_location(_,_)).
p(split_string(f(x),f(x),f(x),f(x))).
p(split_string(_,_,_,_)).
p(statistics(f(x),f(x))).
p(statistics(_,_)).
p(string(f(x))).
p(string(_)).
p(string_bytes(f(x),f(x),f(x))).
p(string_bytes(_,_,_)).
p(string_chars(f(x),f(x))).
p(string_chars(_,_)).
p(string_codes(f(x),f(x))).
p(string_codes(_,_)).
p(string_length(f(x),f(x))).
p(string_length(_,_)).
p(string_lower(f(x),f(x))).
p(string_lower(_,_)).
p(string_to_atom(f(x),f(x))).
p(string_to_atom(_,_)).
p(string_upper(f(x),f(x))).
p(string_upper(_,_)).
p(subsumes_term(f(x),f(x))).
p(subsumes_term(_,_)).
p(succ(f(x),f(x))).
p(succ(_,_)).
p(tab(f(x))).
p(tab(_)).
p(term_string(f(x),f(x))).
p(term_string(f(x),f(x),f(x))).
p(term_string(_,_,_)).
p(term_to_atom(f(x),f(x))).
p(term_variables(f(x),f(x))).
p(term_variables(_,_)).
p(text_to_string(f(x),f(x))).
p(text_to_string(_,_)).
p(time_file(f(x),f(x))).
p(time_file(_,_)).
p(tmp_file(f(x),f(x))).
p(tmp_file(_,_)).
p(unify_with_occurs_check(f(x),f(x))).
p(unify_with_occurs_check(_,_)).
p(unsetenv(f(x))).
p(unsetenv(_)).
p(upcase_atom(f(x),f(x))).
p(upcase_atom(_,_)).
p(var(f(x))).
p(var(_)).
p(with_output_to(f(x),f(x))).
p(with_output_to(_,_)).
p(write(f(x))).
p(write_canonical(f(x))).   % cocolint: W1 -- f(x) holds no operator, which both write alike
p(write_term(f(x),f(x))).
p(write_term(_,_)).
p(writeln(f(x))).
p(writeq(f(x))).

%% the control constructs a goal is handed to, each called as a term: a goal
%% that is no goal is the construct's own error. Written into a clause's body
%% the same goals name '<meta-call>'/1 here, where swipl names the construct
%% or the clause's predicate; and call/1 names itself, where swipl names
%% call/1 directly under catch/3 and '<meta-call>'/1 in a goal like e/1's,
%% which it compiles into a clause (both stated in STATUS.md, 3.0.0)
p(once(1)).
p(once(_)).
p(ignore(1)).
p(ignore(_)).
p(not(1)).
p(not(_)).
p(\+ _).
p(catch(_, foo, true)).
p(catch(1, foo, true)).
p(throw(_)).
