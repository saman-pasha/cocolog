%  print_message/2 and its kin (cocolog 2.16.0), held to swipl 9.0.4.
%  Run by BOTH SWI-Prolog and cocolog, output compared byte for byte.
%
%  The kinds and their prefixes, the elements a line is made of, the fresh
%  line (`~N') over the column user_output and user_error share, the file
%  and line a directive's error or warning names, prolog:message//1,
%  prolog:error_message//1 and message_hook/3, and the flag verbose.
%  Everything is written to user_error but the query kind, which swipl and
%  cocolog both flush when its lines end: the runner reads the two streams
%  through one pipe, and swipl buffers user_output by the line where
%  cocolog buffers it by the block (a difference older than this case).
%
%  swipl runs this file under -q, which sets verbose to silent, so the
%  first directive sets it to normal for both.

:- set_prolog_flag(verbose, normal).

%% A directive's error and warning name this file and the directive's line;
%% no other kind does, and nothing printed after the load does.
:- print_message(error, format('in a directive ~w', [x])).
:- print_message(warning, format('two~nlines', [])).
:- print_message(warning, message_lines([one, two])).
:- print_message(informational, format('info in a directive', [])).
:- print_message(help, format('help in a directive', [])).
:- print_message(error, error(type_error(integer, a), context(foo/2, _))).
:- print_message(error, error(syntax_error(operator_expected), _)).
:- source_location(F, L), file_base_name(F, B), format(user_error, 'loading ~w, line ~w~n', [B, L]).
:- format(user_error, 'partial', []), print_message(warning, format('after partial', [])).
:- initialization(print_message(error, format('in initialization/1', []))).

:- multifile prolog:message//1.
prolog:message(pm_hello(X)) --> [ 'Hello ~w'-[X], nl, 'second line' ].
prolog:message(pm_quoted(X)) --> [ 'Quoted: ~q'-[X] ].
%% "..." is a string in swipl and a code list in cocolog: text in both
prolog:message(pm_codes(X)) --> [ "codes ~w"-[X], nl, "and text" ].
prolog:message(pm_url) --> [ url('http://e.org/', "a label"), ' ', ansi(bold, "b ~w", [1]) ].
:- multifile prolog:error_message//1.
prolog:error_message(pm_formal(X)) --> [ 'My formal ~w'-[X] ].
:- multifile user:message_hook/3.
:- dynamic user:message_hook/3.
user:message_hook(pm_intercept(X), Kind, Lines) :-
    format(user_error, 'hooked ~w ~w ~q~n', [X, Kind, Lines]).

main :-
    pm_kinds,
    pm_lines,
    pm_columns,
    pm_hooks,
    pm_verbose,
    pm_located.

pm_kinds :-
    forall(member(K, [error, warning, informational, information, silent,
                      help, banner, trace, pm_own_kind]),
           ( format(user_error, '[~w]~n', [K]),
             print_message(K, format('hello ~w', [x])) )),
    format(user_error, '[query]~n', []),
    print_message(query, format('to user_output ~w', [y])),
    format(user_error, '[after query]~n', []).

pm_lines :-
    format(user_error, '[lines]~n', []),
    print_message(error, format('a~nb', [])),
    print_message(error, message_lines(['line one', 'line two'])),
    print_message(error, message_lines([])),
    print_message(warning, message_lines(['~w and ~q'-[a, 'B c'], nl, plain, full_stop])),
    print_message(warning, message_lines([at_same_line, 'no prefix', nl, 'then prefix'])),
    print_message(warning, message_lines(['ends in flush', flush])),
    format(user_error, '~n', []),
    print_message(warning, message_lines([ansi(bold, 'ansi ~w', [x])])),
    print_message(warning, message_lines([url('/tmp/f.pl':3), ' and ', url('/tmp/f.pl':3:7)])),
    print_message(warning, message_lines([url('http://example.org/', 'a label'),
                                          begin(warning, ctx), end(ctx)])),
    print_message_lines(user_error, 'PFX ', ['a ~w'-[1], nl, b]),
    print_message_lines(user_error, kind(warning), ['w ~w'-[2]]),
    print_message_lines(user_error, kind(informational), ['i ~w'-[3], nl, i2]),
    message_to_string(pm_hello(2), S1), format(user_error, '~q~n', [S1]),
    message_to_string(format('f ~w', [z]), S2), format(user_error, '~q~n', [S2]),
    message_to_string(error(type_error(integer, a), context(foo/2, _)), S3),
    format(user_error, '~q~n', [S3]),
    message_to_string(format("c ~w", [1]), S4), format(user_error, '~q~n', [S4]),
    message_to_string(pm_codes(2), S5), format(user_error, '~q~n', [S5]),
    message_to_string(message_lines(["lines text", [1, 2, 3], [x, y]]), S6),
    format(user_error, '~q~n', [S6]),
    print_message(warning, pm_codes(3)),
    print_message(warning, message_lines(["printed text", [1, 2]])),
    message_to_string(pm_url, S7), format(user_error, '~q~n', [S7]),
    print_message(warning, pm_url).

pm_columns :-
    format(user_error, '[columns]~n', []),
    format(user_error, 'partial', []),
    print_message(warning, format('after partial', [])),
    format(user_output, 'out partial', []),
    print_message(warning, format('after out partial', [])),
    format(user_error, 'x~Ny~Nz~n', []),
    format(user_error, '~Nfresh~n', []),
    format(atom(A), 'p~Nq~N', []), format(user_error, '~q~n', [A]),
    format(atom(B), '~Nr', []), format(user_error, '~q~n', [B]),
    with_output_to(string(S), ( write(r), format('~Ns', []) )),
    format(user_error, '~q~n', [S]),
    %% a capture begins at its own column 0, the console's line open or not
    format(user_error, 'mid', []),
    with_output_to(string(S2), format('~Ncap', [])),
    format(user_error, '~N~q~n', [S2]).

pm_hooks :-
    format(user_error, '[hooks]~n', []),
    print_message(error, pm_hello(1)),
    print_message(warning, pm_quoted('A b')),
    print_message(error, error(pm_formal(7), context(foo/1, _))),
    print_message(informational, pm_intercept(9)),
    print_message(error, pm_intercept(f(x))),
    print_message(silent, pm_intercept(quiet)),
    print_message(error, pm_unknown(bar, s, 'A b')),
    print_message(error, error(foo, bar)),
    print_message(error, [not, a, message]).

pm_verbose :-
    format(user_error, '[verbose]~n', []),
    current_prolog_flag(verbose, V0), format(user_error, 'verbose is ~w~n', [V0]),
    set_prolog_flag(verbose, silent),
    current_prolog_flag(verbose, V1), format(user_error, 'verbose is ~w~n', [V1]),
    print_message(informational, format('not printed', [])),
    print_message(banner, format('not printed either', [])),
    print_message(information, format('information is printed', [])),
    print_message(warning, format('a warning is printed', [])),
    set_prolog_flag(verbose, normal),
    print_message(informational, format('printed again', [])).

pm_located :-
    format(user_error, '[located]~n', []),
    print_message(error, format('in main', [])),
    (   source_location(_, _)
    ->  format(user_error, 'a location~n', [])
    ;   format(user_error, 'no location~n', [])
    ).
