%% library(main) -- an entry point for a cocolog program, and its argv.
%%
%%     :- use_module(library(main)).
%%
%%     opt_type(v, verbose, boolean).
%%     opt_type(n, count,   integer).
%%     opt_help(verbose, 'say more').
%%     opt_help(count,   'how many times').
%%
%%     main(Argv) :-
%%         argv_options(Argv, Positional, Options),
%%         ...
%%
%%     $ cocolog -s prog.pl -- -v --count=3 file.pl
%%
%% `-s' IS THE FORM TO USE, AND NOT ONLY BECAUSE IT IS SHORTER. It is
%% `use_module('prog.pl'), main' -- so the program's clauses are MUTED, the
%% way any module's are, and `main' is named for you. `run prog.pl main'
%% CONSULTS instead, and consulting writes through: run a tool that way
%% against a real knowledge base and its own source lands in the database.
%% Measured, with a store either side of it:
%%
%%     $ cocolog --embed KB -s  tool.pl        -> tool_private_fact/1 absent
%%     $ cocolog --embed KB run tool.pl main   -> tool_private_fact(1) stored
%%
%% There is a second reason, and it is this library exactly. `-s' loads the
%% file as a module, so the LIBRARY's main/0 is tried before the file's own
%% clauses -- which is what you want here, because library(main)'s main/0 is
%% the thing that strips the executable and calls your main/1. Under `run'
%% the file's clauses come first, so a program that defined main/0 as well
%% would shadow it. `-s' makes the collision in the next paragraph harmless.
%%
%% THIS IS NOT SWI'S library(main), AND SAYING SO IS THE POINT. It is the
%% same INTERFACE -- main/0, argv_options/3,4, argv_usage/1, and the
%% opt_type/3, opt_help/2, opt_meta/2 protocol a program defines -- written
%% here, because SWI's own file cannot be vendored the way the eight under
%% lib/swipl are. cocolint puts 31 HARD findings to it, and they are not
%% incidental:
%%
%%   11 x X1  string_concat/3, split_string/4, atom_string/2,
%%            number_string/2, term_string/2 ... argv_options/3's whole type
%%            conversion is built on SWI's string type, and cocolog has none.
%%    9 x P1  current_prolog_flag/2 over a flag table cocolog does not keep
%%    6 x H1  halt/0, which reports no solution here rather than exiting
%%    2 x F1  ~t and ~| column directives in the usage formatter
%%    1 x D2  `:- module_transparent', which is not a prefix operator here,
%%            so the file does not even READ
%%    1 x N1  atom//1 collides with the vendored lib/swipl/dcg_basics.pl
%%
%% The first is structural and the rest follow from it. So this file takes
%% the design and none of the code, and every place it deliberately answers
%% differently is written down below rather than left to be discovered.
%%
%% WHAT IT NEEDS FROM THE ENGINE is `current_prolog_flag(argv, V)', which
%% cocolog answers as [Executable|Arguments] -- the arguments being whatever
%% followed `--' on the command line. See lib/library.cicili.

%% ---- the entry point -------------------------------------------------
%%
%% main/0 CALLS main/1 WITH THE ARGUMENTS AND NOT THE EXECUTABLE, which is
%% what SWI's own worked example documents: `main([Arg])' for a program run
%% with one argument. cocolog's argv flag keeps the executable at the head
%% because the flag means "the application name and the arguments"; main/0
%% is where it comes off, so a program written against SWI's example reads
%% the same list here.
%%
%% AND main/0 IS A NAME YOUR PROGRAM PROBABLY ALSO USES. cocolog has one
%% namespace and consult APPENDS, so a file that also defines main/0 ends up
%% with two, and which is tried first depends on HOW IT WAS RUN: `run' puts
%% the file's clauses first, `-s' puts the library's. That is the N1 trap in
%% the dialect card, seen from the inside.
%%
%% THE ANSWER IS TO DEFINE main/1 AND NOT main/0, which is what SWI asks of
%% you anyway. Then there is only ever one main/0 -- this one -- and both
%% spellings do the same thing. `listing(main/0)' shows what is there when
%% you want to check.
main :-
    current_prolog_flag(argv, Argv),
    main_arguments(Argv, Args),
    main(Args).

%% main_arguments(+Argv, -Args) is det.
%% The tail of the argv flag: everything but the executable at its head.
main_arguments([_Exe|Args], Args) :- !.
main_arguments([], []).

%% cli_arguments(-Args) is det.
%% The same list, for a program that wants it without going through main/0.
%% NOT SWI's -- it has no equivalent, because in SWI a script's argv already
%% arrives stripped. Here the head is real and this is the way past it that
%% does not make every caller write the same `[_|Args]' pattern.
cli_arguments(Args) :-
    current_prolog_flag(argv, Argv),
    main_arguments(Argv, Args).

%% ---- argv_options/3,4 ------------------------------------------------
%%
%% GUIDED WHEN opt_type/3 IS DEFINED, unguided when it is not -- SWI's own
%% two modes. Unguided means `--name=value' and `--name value' become
%% name(Value) with the value read as a term if it reads as one and left as
%% an atom if it does not, and `--no-name' becomes name(false).
argv_options(Argv, Positional, Options) :-
    argv_options(Argv, Positional, Options, []).

argv_options(Argv, Positional, Options, POptions) :-
    (   opt_types_defined
    ->  opt_guided(Argv, Positional, Options, POptions)
    ;   opt_untyped(Argv, Positional, Options)
    ).

opt_types_defined :-
    catch(opt_type(_, _, _), _, fail),
    !.

%% ---- guided parsing --------------------------------------------------

opt_guided([], [], [], _) :- !.
opt_guided(['--'|Rest], Rest, [], _) :- !.
opt_guided([Arg|Argv], Pos, Opts, PO) :-
    atom_codes(Arg, Codes),
    opt_shape(Codes, Shape),
    !,
    opt_take(Shape, Arg, Argv, Pos, Opts, PO).
opt_guided([Arg|Argv], [Arg|Pos], Opts, PO) :-
    opt_guided(Argv, Pos, Opts, PO).

%% opt_shape(+Codes, -Shape) is semidet.
%% long(Name, Value) / long(Name) / short(Chars). Fails for a positional
%% argument, and deliberately for a bare `-' and for a negative number, so
%% `-1' is an argument and not a bundle of short options named 1.
opt_shape([0'-, 0'-|T], Shape) :-
    T \== [],
    !,
    (   append(NameC, [0'=|ValC], T)
    ->  opt_name_atom(NameC, Name), atom_codes(Value, ValC),
        Shape = long(Name, Value)
    ;   opt_name_atom(T, Name),
        Shape = long(Name)
    ).
opt_shape([0'-|T], short(Chars)) :-
    T \== [],
    \+ opt_numeric(T),
    atom_codes(A, T),
    atom_chars(A, Chars).

opt_numeric([C|_]) :- C >= 0'0, C =< 0'9.
opt_numeric([0'.|_]).

%% A long option's words may be joined with `-' or `_'; opt_type/3 is
%% written with `_', which is SWI's rule and is why this folds one way.
opt_name_atom(Codes, Name) :-
    opt_dash_to_under(Codes, Under),
    atom_codes(Name, Under).

opt_dash_to_under([], []).
opt_dash_to_under([0'-|T], [0'_|U]) :- !, opt_dash_to_under(T, U).
opt_dash_to_under([C|T], [C|U]) :- opt_dash_to_under(T, U).

%% ---- one option, taken ------------------------------------------------

opt_take(long(Name, Value), _Arg, Argv, Pos, [Opt|Opts], PO) :-
    !,
    opt_lookup(Name, OptName, Type),
    opt_convert(Type, Name, Value, Converted),
    Opt =.. [OptName, Converted],
    opt_guided(Argv, Pos, Opts, PO).
%% THE ORDER OF THE NEXT THREE IS SWI'S AND IT MATTERS. A declared boolean
%% is taken first, so an option a program actually NAMES `no_dry_run' wins
%% over reading `--no-dry-run' as the negation of `dry_run'. Only then is
%% the `no_'/`no' prefix tried, and only then a valued option.
opt_take(long(Name), _Arg, Argv, Pos, [Opt|Opts], PO) :-
    opt_lookup_maybe(Name, OptName, Type),
    opt_boolean_type(Type, Value),
    !,
    Opt =.. [OptName, Value],
    opt_guided(Argv, Pos, Opts, PO).
opt_take(long(Name), _Arg, Argv, Pos, [Opt|Opts], PO) :-
    opt_negated(Name, Base),
    opt_lookup_maybe(Base, OptName, Type),
    opt_boolean_type(Type, Default),
    !,
    opt_not(Default, Value),
    Opt =.. [OptName, Value],
    opt_guided(Argv, Pos, Opts, PO).
opt_take(long(Name), _Arg, Argv, Pos, [Opt|Opts], PO) :-
    !,
    opt_lookup(Name, OptName, Type),
    opt_value_arg(Name, Argv, Value, Rest),
    opt_convert(Type, Name, Value, Converted),
    Opt =.. [OptName, Converted],
    opt_guided(Rest, Pos, Opts, PO).
%% A BUNDLE IS BOOLEANS AND THEN AT MOST ONE VALUED OPTION, which is the
%% universal short-option rule: -xvf FILE is -x -v -f FILE.
opt_take(short(Chars), _Arg, Argv, Pos, Opts, PO) :-
    opt_bundle(Chars, Argv, Bundle, Rest, PO),
    opt_guided(Rest, Pos, More, PO),
    append(Bundle, More, Opts).

opt_bundle([], Argv, [], Argv, _).
opt_bundle([C|Cs], Argv, [Opt|Opts], Rest, PO) :-
    opt_lookup(C, OptName, Type),
    (   opt_boolean_type(Type, Default)
    ->  Opt =.. [OptName, Default],
        opt_bundle(Cs, Argv, Opts, Rest, PO)
    ;   (   Cs == []
        ->  opt_value_arg(C, Argv, Value, Rest)
        ;   atom_chars(Value, Cs), Rest = Argv
        ),
        opt_convert(Type, C, Value, Converted),
        Opt =.. [OptName, Converted],
        Opts = []
    ).

opt_value_arg(Name, [], _, _) :-
    !,
    opt_error(missing_value(Name)).
opt_value_arg(_, [Value|Rest], Value, Rest).

opt_negated(Name, Base) :-
    atom_concat('no_', Base, Name).
opt_negated(Name, Base) :-
    atom_concat(no, Base, Name),
    Base \== ''.

opt_not(true, false).
opt_not(false, true).

%% ---- the option table -------------------------------------------------

opt_lookup(Spec, Name, Type) :-
    opt_lookup_maybe(Spec, Name, Type),
    !.
opt_lookup(Spec, _, _) :-
    opt_error(unknown_option(Spec)).

opt_lookup_maybe(Spec, Name, Type) :-
    catch(opt_type(Spec, Name, Type), _, fail),
    !.
%% -h, -? and --help are bound to help unless the program binds them
%% itself, which is SWI's rule.
opt_lookup_maybe(Spec, help, boolean) :-
    opt_help_spec(Spec),
    \+ catch(opt_type(_, help, _), _, fail).

opt_help_spec(h).
opt_help_spec(?).
opt_help_spec(help).

opt_boolean_type(boolean, true).
opt_boolean_type(boolean(Default), Default).

%% ---- type conversion --------------------------------------------------
%%
%% NO `string' TYPE, because there is no string. `codes' is the answer and
%% is named for what it gives you: SWI's string(X) becomes codes(X) and the
%% value is a code list, which is what every reader in this repository
%% takes. A program that asks for `string' gets a domain_error naming it,
%% rather than an atom that would work until something concatenated it.
opt_convert(Type, Opt, Value, Out) :-
    (   opt_convert_(Type, Value, Out)
    ->  true
    ;   opt_error(bad_value(Opt, Type, Value))
    ).

opt_convert_(atom, V, V).
opt_convert_(boolean, V, B)         :- opt_bool_atom(V, B).
opt_convert_(boolean(_), V, B)      :- opt_bool_atom(V, B).
opt_convert_(integer, V, N)         :- atom_number(V, N), integer(N).
opt_convert_(float, V, F)           :- atom_number(V, N), opt_as_float(N, F).
opt_convert_(number, V, N)          :- atom_number(V, N).
opt_convert_(nonneg, V, N)          :- atom_number(V, N), integer(N), N >= 0.
opt_convert_(natural, V, N)         :- atom_number(V, N), integer(N), N >= 1.
opt_convert_(between(L, H), V, N)   :- atom_number(V, N0),
                                       opt_between_kind(L, H, N0, N),
                                       N >= L, N =< H.
opt_convert_(oneof(List), V, V)     :- memberchk(V, List).
opt_convert_(codes, V, Cs)          :- atom_codes(V, Cs).
opt_convert_(term, V, T)            :- catch(term_to_atom(T, V), _, fail).
opt_convert_(file, V, V).
opt_convert_(file(Access), V, V)    :- opt_file_access(Access, V).
opt_convert_(directory, V, V).
%% THE DISJUNCTIVE TYPE IS WRITTEN `(integer|atom)', IN PARENTHESES, and
%% that is a real divergence from SWI rather than a style note. cocolog's
%% reader does not take a bare `|' inside an argument list -- `f(a|b)' will
%% not read at all -- and inside parentheses it reads `|' as `;', which is
%% ISO's rule for the bar in a body. So the term this clause matches is
%% `;'/2, and `opt_type(x, n, integer|atom)' without the parentheses is a
%% syntax error in the PROGRAM, before this library is reached. Writing
%% `integer;atom' is the same term and reads too.
opt_convert_(';'(A, B), V, Out)     :- (   opt_convert_(A, V, Out)
                                       ->  true
                                       ;   opt_convert_(B, V, Out)
                                       ).

opt_as_float(N, F) :- F is N * 1.0.

%% between(1, 10) converts as integer; between(0.0, 1.0) as float. SWI's
%% rule is "if either bound is a float, convert as float".
opt_between_kind(L, H, N0, N) :-
    (   (float(L) ; float(H))
    ->  opt_as_float(N0, N)
    ;   integer(N0), N = N0
    ).

%% `-' is the conventional name for standard input or output and is never
%% checked, which is SWI's documented exception.
opt_file_access(_, '-') :- !.
opt_file_access(Access, File) :- access_file(File, Access).

opt_bool_atom(true, true).      opt_bool_atom('True', true).
opt_bool_atom('TRUE', true).    opt_bool_atom(on, true).
opt_bool_atom('On', true).      opt_bool_atom('ON', true).
opt_bool_atom('1', true).
opt_bool_atom(false, false).    opt_bool_atom('False', false).
opt_bool_atom('FALSE', false).  opt_bool_atom(off, false).
opt_bool_atom('Off', false).    opt_bool_atom('OFF', false).
opt_bool_atom('0', false).

%% ---- what is NOT here: defaults ---------------------------------------
%%
%% AN OPTION THE USER DID NOT PASS IS ABSENT, and nothing is invented for
%% it. That is SWI's behaviour and it is the right one: the `Default' in
%% `boolean(Default)' is the value used WHEN THE FLAG IS GIVEN -- so that
%% `boolean(false)' means `-x' turns something OFF -- and it is not a
%% fallback for absence. A library that filled one in would make
%% `memberchk(verbose(true), Opts)' true for every run of a program nobody
%% passed -v to, which is worse than useless because it looks like it works.
%%
%% So the program supplies its own fallback, and can still tell "not given"
%% from "given the default":
%%
%%     ( memberchk(count(N), Opts) -> true ; N = 1 )
%%
%% This was written the other way first and the test caught it.

%% ---- unguided parsing -------------------------------------------------

opt_untyped([], [], []).
opt_untyped(['--'|Rest], Rest, []) :- !.
opt_untyped([Arg|Argv], Pos, Opts) :-
    atom_codes(Arg, Codes),
    opt_shape(Codes, long(Name, Value)),
    !,
    opt_loose(Value, V),
    Opt =.. [Name, V],
    Opts = [Opt|Rest],
    opt_untyped(Argv, Pos, Rest).
opt_untyped([Arg|Argv], Pos, Opts) :-
    atom_codes(Arg, Codes),
    opt_shape(Codes, long(Name0)),
    !,
    (   opt_negated(Name0, Base)
    ->  Opt =.. [Base, false], Rest = Argv
    ;   Argv = [Value|Rest0], \+ opt_is_option(Value)
    ->  opt_loose(Value, V), Opt =.. [Name0, V], Rest = Rest0
    ;   Opt =.. [Name0, true], Rest = Argv
    ),
    Opts = [Opt|Tail],
    opt_untyped(Rest, Pos, Tail).
opt_untyped([Arg|Argv], [Arg|Pos], Opts) :-
    opt_untyped(Argv, Pos, Opts).

opt_is_option(A) :- atom_codes(A, Cs), opt_shape(Cs, _).

%% A number stays a number and everything else stays the atom it was. NOT
%% term_to_atom/2 on everything: `--name foo(1' would raise where the user
%% meant the atom, and an unguided parse has no type to justify that.
opt_loose(V, N) :- atom_number(V, N), !.
opt_loose(V, V).

%% ---- usage ------------------------------------------------------------
%%
%% NO ~t OR ~| -- cocolog refuses the column directives by name (F1 in the
%% dialect card), so the columns here are computed and written. That is the
%% documented fix for the trap, and this is what it looks like.
argv_usage(_Level) :-
    argv_usage_header,
    findall(row(Left, Help),
            ( opt_type(Spec, Name, Type),
              opt_row(Spec, Name, Type, Left, Help)
            ),
            Rows0),
    opt_dedup_rows(Rows0, [], Rows),
    opt_widest(Rows, 0, W),
    opt_write_rows(Rows, W),
    argv_usage_footer.

argv_usage_header :-
    (   catch(opt_help(help(header), H), _, fail)
    ->  format("~w~n~n", [H])
    ;   true
    ),
    (   catch(opt_help(help(usage), U), _, fail)
    ->  format("Usage: ~w~n~n", [U])
    ;   format("Options:~n")
    ).

argv_usage_footer :-
    (   catch(opt_help(help(footer), F), _, fail)
    ->  format("~n~w~n", [F])
    ;   true
    ).

opt_row(Spec, Name, Type, Left, Help) :-
    opt_flag_text(Spec, Flag),
    (   opt_boolean_type(Type, _)
    ->  Left = Flag
    ;   opt_meta_of(Name, Type, Meta),
        atomic_list_concat([Flag, ' ', Meta], Left)
    ),
    (   catch(opt_help(Name, Help), _, fail) -> true ; Help = '' ).

opt_flag_text(Spec, Flag) :-
    atom_length(Spec, 1),
    !,
    atom_concat('-', Spec, Flag).
opt_flag_text(Spec, Flag) :-
    opt_under_to_dash(Spec, Dashed),
    atom_concat('--', Dashed, Flag).

opt_under_to_dash(A, B) :-
    atom_codes(A, Cs),
    opt_u2d(Cs, Ds),
    atom_codes(B, Ds).

opt_u2d([], []).
opt_u2d([0'_|T], [0'-|D]) :- !, opt_u2d(T, D).
opt_u2d([C|T], [C|D]) :- opt_u2d(T, D).

%% The placeholder is the type's functor name in upper case, which is where
%% the FILE in `-f FILE' comes from -- SWI's rule, and opt_meta/2 overrides.
opt_meta_of(Name, _Type, Meta) :-
    catch(opt_meta(Name, Meta), _, fail),
    !.
opt_meta_of(_, Type, Meta) :-
    (   compound(Type) -> functor(Type, F, _) ; F = Type ),
    upcase_atom(F, Meta).

opt_dedup_rows([], _, []).
opt_dedup_rows([row(L, H)|T], Seen, Out) :-
    (   memberchk(L, Seen)
    ->  Out = Rest, Seen1 = Seen
    ;   Out = [row(L, H)|Rest], Seen1 = [L|Seen]
    ),
    opt_dedup_rows(T, Seen1, Rest).

opt_widest([], W, W).
opt_widest([row(L, _)|T], W0, W) :-
    atom_length(L, N),
    (   N > W0 -> W1 = N ; W1 = W0 ),
    opt_widest(T, W1, W).

opt_write_rows([], _).
opt_write_rows([row(L, H)|T], W) :-
    atom_length(L, N),
    Pad is W - N + 2,
    opt_spaces(Pad, S),
    format("  ~w~w~w~n", [L, S, H]),
    opt_write_rows(T, W).

opt_spaces(N, '') :- N =< 0, !.
opt_spaces(N, S) :-
    length(Cs, N),
    opt_all_space(Cs),
    atom_codes(S, Cs).

opt_all_space([]).
opt_all_space([0' |T]) :- opt_all_space(T).

%% ---- errors -----------------------------------------------------------
%%
%% THEY THROW, and the term names the option. A command line that is wrong
%% is wrong before the program has done anything, and the one thing worse
%% than stopping is carrying on with an option the user did not mean.
opt_error(unknown_option(Spec)) :-
    throw(error(domain_error(cli_option, Spec), _)).
opt_error(missing_value(Name)) :-
    throw(error(existence_error(cli_option_value, Name), _)).
opt_error(bad_value(Opt, Type, Value)) :-
    throw(error(type_error(Type, Value), context(Opt, _))).
