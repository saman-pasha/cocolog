%  The text print_message/2 gives an error term (cocolog 2.16.0), held to
%  swipl 9.0.4. Run by BOTH SWI-Prolog and cocolog, output compared byte for
%  byte.
%
%  Each term is ISO's error(Formal, Context) or one of SWI's own, and the
%  text is boot/messages.pl's: the context's predicate first (`foo/2: '),
%  the formal term's words, and the context's message last (` (why)'). A
%  string is made with atom_string/2 rather than written in double quotes:
%  a double-quoted literal is a code list in cocolog and a string in swipl.

em(1, error(instantiation_error, _)).
em(2, error(uninstantiation_error(a), _)).
em(3, error(type_error(integer, a), _)).
em(4, error(type_error(integer, f(x)), _)).
em(5, error(type_error(callable, 3), _)).
em(6, error(domain_error(not_less_than_zero, -1), _)).
em(7, error(existence_error(procedure, foo/2), _)).
em(8, error(existence_error(procedure, foo/2), foo/2)).
em(9, error(existence_error(stream, s), _)).
em(10, error(existence_error(source_sink, 'nofile.pl'), _)).
em(11, error(permission_error(modify, static_procedure, foo/1), _)).
em(12, error(representation_error(max_arity), _)).
em(13, error(evaluation_error(zero_divisor), _)).
em(14, error(evaluation_error(undefined), _)).
em(15, error(evaluation_error(float_overflow), _)).
em(16, error(evaluation_error(int_overflow), _)).
em(17, error(resource_error(memory), _)).
em(18, error(syntax_error(operator_expected), _)).
em(19, error(type_error(integer, a), context(foo/2, _))).
em(20, error(type_error(integer, a), context(_, 'some message'))).
em(21, error(type_error(integer, a), context(foo/2, 'some message'))).
em(22, error(type_error(integer, a), context(system:atom_length/2, _))).
em(23, error(foo, _)).
em(24, error(existence_error(foo, bar), _)).
em(25, error(permission_error(open, source_sink, '/x'), context(open/4, 'No such file or directory'))).
em(26, error(type_error(evaluable, foo/0), context(system:(is)/2, _))).
em(27, error(domain_error(foo, bar), context(_, _))).
em(28, error(system_error(boom), _)).
em(29, error(type_error(list, [a|b]), _)).
em(30, error(existence_error(procedure, lists:foo/2), lists:foo/2)).
em(31, error(type_error(text, f(x)), _)).
em(32, error(resource_error(knowledge_base), context(foo/1, why))).
em(33, error(evaluation_error(undefined), context(system:(/)/2, _))).
em(34, error(type_error(atom, 1.5), _)).
em(35, error(type_error(integer, 'A b'), _)).
em(36, error(existence_error(variable, 'X'), _)).
em(37, error(permission_error(create, array, foo), _)).
em(38, error(representation_error(character_code), _)).
em(39, error(type_error(integer, []), _)).
em(40, error(domain_error(non_empty_list, []), context(max_list/2, _))).

main :-
    forall(em(N, E), ( format(user_error, '[~w]~n', [N]), print_message(error, E) )),
    format(user_error, '[a string]~n', []),
    atom_string(str, S),
    print_message(error, error(type_error(integer, S), _)),
    format(user_error, '[a string context]~n', []),
    atom_string('foo ( . ', T),
    print_message(error, error(syntax_error(cannot_start_term), string(T, 6))),
    format(user_error, '[as a warning]~n', []),
    print_message(warning, error(type_error(integer, a), context(foo/2, _))),
    format(user_error, '[as a string]~n', []),
    message_to_string(error(existence_error(procedure, foo/2), foo/2), M),
    format(user_error, '~q~n', [M]).
