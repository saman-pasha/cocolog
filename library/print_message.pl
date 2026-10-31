%% library(print_message) -- swipl's print_message/2: a message term turned
%% into lines of text and printed in the shape of its kind.
%%
%% TIER 1 SINCE 2.16.0: lib/library.cicili preloads this file at start-up,
%% as swipl has these predicates without a library, so a program written for
%% swipl calls them as it is.
%%
%%     print_message(+Kind, +Term)           Term's text, printed for Kind
%%     print_message_lines(+Stream, +Prefix, +Lines)
%%                                           Lines with Prefix, or kind(Kind)'s
%%     message_to_string(+Term, -String)     Term's text, as a string
%%
%% THE KINDS are swipl 9.0.4's. error and warning are tagged `ERROR: ' and
%% `Warning: ', informational and information are `% ', and any other kind
%% -- help, query, banner, trace, one of the program's own -- has no prefix
%% at all; silent prints nothing, and informational and banner print nothing
%% while the flag verbose is silent (swipl -q's). Every prefix opens a fresh
%% line (`~N', the console's column, which user_output and user_error share
%% as swipl's do), the prefix is written again after every `nl' of the
%% lines, and the last line ends in a newline unless it is `flush'. A query
%% goes to user_output, everything else to user_error. Printed by a
%% directive of a file being loaded, an error or a warning first names the
%% file and the line (source_location/2):
%%
%%     ERROR: /path/to/file.pl:12:
%%     ERROR:    Type error: `integer' expected, found `a' (an atom)
%%
%% THE TERMS: format(Format, Args) and message_lines(Lines), every ISO and
%% SWI error(Formal, Context) term in swipl's words -- the context's
%% predicate first (`atom_length/2: '), its message last (` (why)') -- and
%% for anything else `Unknown message: ~p'. A program gives a term of its
%% own its text with a grammar rule, prolog:message//1 (and an error's
%% formal term with prolog:error_message//1), and intercepts a message with
%% message_hook(+Term, +Kind, +Lines), which prints nothing more when it
%% succeeds; both are read only where the program defines them.
%%
%%     :- multifile prolog:message//1.
%%     prolog:message(no_such_user(U)) --> [ 'No user called ~w'-[U] ].
%%
%% A LINE is a list of: Format-Args or a plain Format (format/3's), nl,
%% at_same_line (first: no prefix), flush (last: no newline), full_stop,
%% ansi(Attributes, Format, Args) (the format alone), url(File:Line[:Column])
%% and url(URL, Label), and begin/end, which print nothing. A format, and an
%% element of message_lines/1, written "..." is a code list here and a
%% string in swipl, and is its text in both: message_to_string/2 gives it
%% as print_message/2 prints it.
%%
%% NOT swipl's: no `Recursive' backtrace, no 0.1 s wait after a located
%% error, no `Defined at' line for a static procedure, no list of the
%% predicates a misspelled name could have meant (dwim), no thread_message_hook/3,
%% message_property/2 or message_context flag; a debug(Topic) message is
%% printed with `% ', which swipl 9.0.4 raises for; and a stream's
%% location is written as `Stream S:L:C ' with no file name.
%%
%% The wording of the messages is SWI-Prolog's boot/messages.pl (9.0.4),
%% whose terms are:
%%
%%     Copyright (c)  1997-2022, University of Amsterdam, VU University
%%     Amsterdam, CWI Amsterdam, SWI-Prolog Solutions b.v.
%%     All rights reserved.
%%
%%     Redistribution and use in source and binary forms, with or without
%%     modification, are permitted provided that the following conditions
%%     are met:
%%
%%     1. Redistributions of source code must retain the above copyright
%%        notice, this list of conditions and the following disclaimer.
%%     2. Redistributions in binary form must reproduce the above copyright
%%        notice, this list of conditions and the following disclaimer in
%%        the documentation and/or other materials provided with the
%%        distribution.
%%
%%     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
%%     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
%%     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
%%     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
%%     COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
%%     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
%%     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
%%     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
%%     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
%%     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
%%     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%%     POSSIBILITY OF SUCH DAMAGE.
%%
%% Every helper here is named '$pm_...': tier 1's names are global, and a
%% program's own predicate of a helper's name would be shadowed by it.

%% ---- print_message/2 --------------------------------------------------

%% A message printed while the same message is printed -- a message_hook/3
%% that prints its own term -- is said to be recursive, once, as swipl's.
%% The stack of messages in print is a global, set back by hand on every
%% way out (swipl's setup_call_cleanup/3): a b_setval/2 is an nb_setval/2
%% here, and undoes nothing on backtracking. print_message/2 never fails.
print_message(Kind, Term) :-
    (   '$pm_push'(Term, Stack)
    ->  catch(ignore('$pm_guarded'(Kind, Term)), E,
              ('$pm_pop'(Stack), throw(E))),
        '$pm_pop'(Stack)
    ;   Kind \== silent
    ->  format(user_error, 'Recursive ~w message: ~q~n', [Kind, Term])
    ;   true
    ).

'$pm_push'(Term, Messages) :-
    nb_current('$pm_inprint', Messages),
    !,
    \+ ( member(Msg, Messages), Msg =@= Term ),
    nb_setval('$pm_inprint', [Term|Messages]).
'$pm_push'(Term, []) :-
    nb_setval('$pm_inprint', [Term]).

'$pm_pop'(Stack) :-
    nb_setval('$pm_inprint', Stack).

%% Never fails: a term with no text is `Unknown message'.
'$pm_guarded'(Kind, Term) :-
    (   '$pm_translate'(Term, Lines, [])
    ->  (   nonvar(Term),
            current_predicate(message_hook/3),
            call(message_hook, Term, Kind, Lines)
        ->  true
        ;   '$pm_system'(Term, Kind, Lines)
        )
    ;   true
    ).

'$pm_system'(_, silent, _) :- !.
'$pm_system'(_, informational, _) :-
    current_prolog_flag(verbose, silent),
    !.
'$pm_system'(_, banner, _) :-
    current_prolog_flag(verbose, silent),
    !.
'$pm_system'(_, _, []) :- !.
'$pm_system'(Term, Kind, Lines) :-
    flush_output,
    source_location(File, Line),
    Term \= error(syntax_error(_), _),
    '$pm_tag'(Kind, Tag),
    !,
    '$pm_insert_prefix'(Lines, '~N~w:    '-[Tag], PrefixLines),
    '$pm_stream'(Kind, Stream),
    '$pm_lines'(Stream, ['~N~w: '-[Tag], url(File:Line), ':', nl|PrefixLines]).
'$pm_system'(_, Kind, Lines) :-
    '$pm_stream'(Kind, Stream),
    print_message_lines(Stream, kind(Kind), Lines).

'$pm_stream'(query, user_output) :- !.
'$pm_stream'(_, user_error).

'$pm_tag'(error, 'ERROR').
'$pm_tag'(warning, 'Warning').

'$pm_prefix'(debug(_), '~N% ') :- !.
'$pm_prefix'(Kind, Prefix) :-
    '$pm_tag'(Kind, Tag),
    !,
    atomic_list_concat(['~N', Tag, ': '], Prefix).
'$pm_prefix'(informational, '~N% ') :- !.
'$pm_prefix'(information, '~N% ') :- !.
'$pm_prefix'(_, '~N').

%% ---- the lines ---------------------------------------------------------

print_message_lines(Stream, kind(Kind), Lines) :-
    !,
    '$pm_prefix'(Kind, Prefix),
    '$pm_insert_prefix'(Lines, Prefix, PrefixLines),
    '$pm_lines'(Stream, PrefixLines).
print_message_lines(Stream, Prefix, Lines) :-
    '$pm_insert_prefix'(Lines, Prefix, PrefixLines),
    '$pm_lines'(Stream, PrefixLines).

'$pm_insert_prefix'([at_same_line|Lines0], Prefix, Lines) :-
    !,
    '$pm_prefix_nl'(Lines0, Prefix, Lines).
'$pm_insert_prefix'(Lines0, Prefix, [prefix(Prefix)|Lines]) :-
    '$pm_prefix_nl'(Lines0, Prefix, Lines).

'$pm_prefix_nl'([], _, [nl]).
'$pm_prefix_nl'([nl], _, [nl]) :- !.
'$pm_prefix_nl'([flush], _, [flush]) :- !.
'$pm_prefix_nl'([nl|T0], Prefix, [nl, prefix(Prefix)|T]) :-
    !,
    '$pm_prefix_nl'(T0, Prefix, T).
'$pm_prefix_nl'([H|T0], Prefix, [H|T]) :-
    '$pm_prefix_nl'(T0, Prefix, T).

%% The stream is flushed when the lines end, as swipl's: a query printed to
%% user_output is out before what the program prints next.
'$pm_lines'(S, []) :- !, '$pm_flush'(S).
'$pm_lines'(S, [H|T]) :-
    '$pm_element'(S, H),
    '$pm_lines'(S, T).

'$pm_element'(S, full_stop) :- !, '$pm_format'(S, '.', []).
'$pm_element'(S, nl) :- !, '$pm_format'(S, '~n', []).
'$pm_element'(S, prefix(Fmt-Args)) :- !, '$pm_format'(S, Fmt, Args).
'$pm_element'(S, prefix(Fmt)) :- !, '$pm_format'(S, Fmt, []).
'$pm_element'(S, flush) :- !, '$pm_flush'(S).
'$pm_element'(S, Fmt-Args) :- !, '$pm_format'(S, Fmt, Args).
'$pm_element'(S, ansi(_, Fmt, Args)) :- !, '$pm_format'(S, Fmt, Args).
'$pm_element'(S, url(URL)) :- !, '$pm_link'(S, URL).
'$pm_element'(S, url(_, Fmt-Args)) :- !, '$pm_format'(S, Fmt, Args).
'$pm_element'(S, url(_, Fmt)) :- !, '$pm_format'(S, Fmt, []).
'$pm_element'(_, begin(_, _)) :- !.
'$pm_element'(_, end(_)) :- !.
'$pm_element'(S, Fmt) :- '$pm_format'(S, Fmt, []).

%% user_error is unbuffered; user_output is the stdout flush_output/0
%% empties; any other stream is library(stream)'s, whose flush_output/1 is
%% there only when the program loaded it
'$pm_flush'(user_output) :- !, flush_output.
'$pm_flush'(user_error) :- !.
'$pm_flush'(S) :- catch(flush_output(S), error(_, _), true).

'$pm_link'(S, File:Line:Column) :- !, '$pm_format'(S, '~w:~d:~d', [File, Line, Column]).
'$pm_link'(S, File:Line) :- !, '$pm_format'(S, '~w:~d', [File, Line]).
'$pm_link'(S, File) :- '$pm_format'(S, '~w', [File]).

%% A line that will not format says so, and the message goes on.
'$pm_format'(S, Fmt, Args) :-
    catch(format(S, Fmt, Args), error(E, _), '$pm_format_failed'(S, Fmt, Args, E)).

'$pm_format_failed'(S, Fmt, Args, E) :-
    format(S, '~N    [[ EXCEPTION while printing message ~q~n       with arguments ~q:~n       raised: ~q~n    ]]~n',
           [Fmt, Args, E]).

%% ---- message_to_string/2 -----------------------------------------------

message_to_string(Term, Str) :-
    '$pm_translate'(Term, Actions, []),
    !,
    '$pm_actions'(Actions, Fmt, Args),
    format(string(Str), Fmt, Args).

'$pm_actions'([], '', []) :- !.
'$pm_actions'([nl], '', []) :- !.
'$pm_actions'([Term, nl], Fmt, Args) :-
    !,
    '$pm_actions'([Term], Fmt, Args).
'$pm_actions'([nl|T], Fmt, Args) :-
    !,
    '$pm_actions'(T, Fmt0, Args),
    atom_concat('~n', Fmt0, Fmt).
'$pm_actions'([ansi(_, Fmt0, Args0)|Tail], Fmt, Args) :-
    !,
    '$pm_actions'(Tail, Fmt1, Args1),
    '$pm_text'(Fmt0, Fmt00),
    atom_concat(Fmt00, Fmt1, Fmt),
    '$pm_append_args'(Args0, Args1, Args).
'$pm_actions'([url(Pos)|Tail], Fmt, Args) :-
    !,
    '$pm_actions'(Tail, Fmt1, Args1),
    '$pm_url_actions'(url(Pos), Fmt1, Args1, Fmt, Args).
'$pm_actions'([url(URL, Label)|Tail], Fmt, Args) :-
    !,
    '$pm_actions'(Tail, Fmt1, Args1),
    '$pm_url_actions'(url(URL, Label), Fmt1, Args1, Fmt, Args).
'$pm_actions'([Fmt0-Args0|Tail], Fmt, Args) :-
    !,
    '$pm_actions'(Tail, Fmt1, Args1),
    '$pm_text'(Fmt0, Fmt00),
    atom_concat(Fmt00, Fmt1, Fmt),
    '$pm_append_args'(Args0, Args1, Args).
'$pm_actions'([Skip|T], Fmt, Args) :-
    '$pm_action_skip'(Skip),
    !,
    '$pm_actions'(T, Fmt, Args).
'$pm_actions'([Term|Tail], Fmt, Args) :-
    '$pm_text_list'(Term, Text),
    !,
    '$pm_actions'(Tail, Fmt1, Args),
    atom_concat(Text, Fmt1, Fmt).
'$pm_actions'([Term|Tail], Fmt, Args) :-
    atomic(Term),
    !,
    '$pm_actions'(Tail, Fmt1, Args),
    atom_concat(Term, Fmt1, Fmt).
'$pm_actions'([Term|Tail], Fmt, Args) :-
    '$pm_actions'(Tail, Fmt1, Args1),
    atom_concat('~w', Fmt1, Fmt),
    '$pm_append_args'([Term], Args1, Args).

'$pm_action_skip'(at_same_line).
'$pm_action_skip'(flush).
'$pm_action_skip'(begin(_, _)).
'$pm_action_skip'(end(_)).

'$pm_url_actions'(url(File:Line:Column), Fmt1, Args1, Fmt, Args) :-
    !,
    atom_concat('~w:~d:~d', Fmt1, Fmt),
    '$pm_append_args'([File, Line, Column], Args1, Args).
'$pm_url_actions'(url(File:Line), Fmt1, Args1, Fmt, Args) :-
    !,
    atom_concat('~w:~d', Fmt1, Fmt),
    '$pm_append_args'([File, Line], Args1, Args).
'$pm_url_actions'(url(File), Fmt1, Args1, Fmt, Args) :-
    !,
    atom_concat('~w', Fmt1, Fmt),
    '$pm_append_args'([File], Args1, Args).
'$pm_url_actions'(url(_, Label0), Fmt1, Args1, Fmt, Args) :-
    '$pm_text'(Label0, Label),
    atom_concat('~w', Fmt1, Fmt),
    '$pm_append_args'([Label], Args1, Args).

%% A format written "..." is a code list here, where swipl's is a string,
%% and is its text: print_message/2 hands either to format/3 as it is, and
%% message_to_string/2, which joins the formats as atoms, takes the list's
%% atom, never the list written as a term (`[97,126,119]').
'$pm_text'(Text, Atom) :-
    '$pm_text_list'(Text, Atom0),
    !,
    Atom = Atom0.
'$pm_text'(Text, Text).

'$pm_text_list'([C|Cs], Atom) :-
    is_list(Cs),
    (   '$pm_codes'([C|Cs])
    ->  atom_codes(Atom, [C|Cs])
    ;   '$pm_chars'([C|Cs])
    ->  atom_chars(Atom, [C|Cs])
    ).

'$pm_codes'([]).
'$pm_codes'([C|Cs]) :-
    integer(C),
    C >= 0,
    C =< 1114111,
    '$pm_codes'(Cs).

'$pm_chars'([]).
'$pm_chars'([C|Cs]) :-
    atom(C),
    atom_length(C, 1),
    '$pm_chars'(Cs).

'$pm_append_args'(Args0, Args1, Args) :-
    ( is_list(Args0) -> Args01 = Args0 ; Args01 = [Args0] ),
    append(Args01, Args1, Args).

%% ---- the translation ---------------------------------------------------

%% The program's own text first, then swipl's, then `Unknown'.
'$pm_translate'(Term, L, T) :-
    nonvar(Term),
    current_predicate('$prolog_message'/3),
    call('$prolog_message', Term, L, T),
    !.
'$pm_translate'(Term, L, T) :-
    nonvar(Term),
    '$pm_translate2'(Term, L, T),
    !.
'$pm_translate'(Term, ['Unknown exception: ~p'-[Term]|T], T) :-
    nonvar(Term),
    Term = error(_, _),
    !.
'$pm_translate'(Term, ['Unknown message: ~p'-[Term]|T], T).

'$pm_translate2'(Term) -->
    '$pm_prolog_message'(Term).
'$pm_translate2'(error(ISO, SWI)) -->
    '$pm_location'(SWI),
    '$pm_term_message'(ISO),
    '$pm_extra'(SWI).
'$pm_translate2'('$aborted') -->
    [ 'Execution Aborted' ].
'$pm_translate2'(message_lines(Lines), L, T) :-
    '$pm_make_lines'(Lines, L, T).
'$pm_translate2'(format(Fmt, Args)) -->
    [ Fmt-Args ].

'$pm_make_lines'([], T, T) :- !.
'$pm_make_lines'([Last0], ['~w'-[Last]|T], T) :-
    !,
    '$pm_line_text'(Last0, Last).
'$pm_make_lines'([L0|LT], ['~w'-[L], nl|T0], T) :-
    '$pm_line_text'(L0, L),
    '$pm_make_lines'(LT, T0, T).

%% An element of message_lines(Lines) is written with ~w, as swipl's. A
%% "..." is a code list here, written as the text it holds; a list with a
%% code no text has (under 32, but a tab or a line end) stays a list.
'$pm_line_text'(E, A) :-
    E = [_|_],
    '$pm_printable'(E),
    !,
    atom_codes(A, E).
'$pm_line_text'(E, E).

'$pm_printable'([]).
'$pm_printable'([C|Cs]) :-
    integer(C),
    (   C >= 32
    ->  C =< 1114111
    ;   memberchk(C, [9, 10, 13])
    ),
    '$pm_printable'(Cs).

%% The formal term of error(Formal, Context).
'$pm_term_message'(Term, ['Unknown error term: ~p'-[Term]|T], T) :-
    var(Term),
    !.
'$pm_term_message'(Term, L, T) :-
    current_predicate('$prolog_error_message'/3),
    call('$prolog_error_message', Term, L, T),
    !.
'$pm_term_message'(Term, L, T) :-
    '$pm_iso_message'(Term, L, T),
    !.
'$pm_term_message'(Term, L, T) :-
    '$pm_swi_message'(Term, L, T),
    !.
'$pm_term_message'(Term, ['Unknown error term: ~p'-[Term]|T], T).

'$pm_iso_message'(resource_error(Missing)) -->
    [ 'Not enough resources: ~w'-[Missing] ].
'$pm_iso_message'(type_error(evaluable, Actual)) -->
    { callable(Actual) },
    [ 'Arithmetic: `~p'' is not a function'-[Actual] ].
'$pm_iso_message'(type_error(Expected, Actual)) -->
    [ 'Type error: `~w'' expected, found `~p'''-[Expected, Actual] ],
    '$pm_type_comment'(Actual).
'$pm_iso_message'(domain_error(Domain, Actual)) -->
    [ 'Domain error: '-[] ],
    '$pm_domain'(Domain),
    [ ' expected, found `~p'''-[Actual] ].
'$pm_iso_message'(instantiation_error) -->
    [ 'Arguments are not sufficiently instantiated' ].
'$pm_iso_message'(uninstantiation_error(Var)) -->
    [ 'Uninstantiated argument expected, found ~p'-[Var] ].
'$pm_iso_message'(representation_error(What)) -->
    [ 'Cannot represent due to `~w'''-[What] ].
'$pm_iso_message'(permission_error(Action, Type, Object)) -->
    '$pm_permission_error'(Action, Type, Object).
'$pm_iso_message'(evaluation_error(Which)) -->
    [ 'Arithmetic: evaluation error: `~p'''-[Which] ].
'$pm_iso_message'(existence_error(procedure, Proc)) -->
    [ 'Unknown procedure: ~q'-[Proc] ],
    '$pm_unknown_proc'(Proc).
'$pm_iso_message'(existence_error(answer_variable, Var)) -->
    [ '$~w was not bound by a previous query'-[Var] ].
'$pm_iso_message'(existence_error(matching_rule, Goal)) -->
    [ 'No rule matches ~p'-[Goal] ].
'$pm_iso_message'(existence_error(Type, Object)) -->
    [ '~w `~p'' does not exist'-[Type, Object] ].
'$pm_iso_message'(existence_error(Type, Object, In)) -->
    [ '~w `~p'' does not exist in ~p'-[Type, Object, In] ].
'$pm_iso_message'(busy(Type, Object)) -->
    [ '~w `~p'' is busy'-[Type, Object] ].
'$pm_iso_message'(syntax_error(swi_backslash_newline)) -->
    [ 'Deprecated ... \\<newline><white>*.  Use \\c' ].
'$pm_iso_message'(syntax_error(Id)) -->
    [ 'Syntax error: ' ],
    '$pm_syntax_error'(Id).
'$pm_iso_message'(occurs_check(Var, In)) -->
    [ 'Cannot unify ~p with ~p: would create an infinite tree'-[Var, In] ].

'$pm_permission_error'(Action, built_in_procedure, Pred) -->
    { '$pm_user_pi'(Pred, PI) },
    [ 'No permission to ~w built-in predicate `~p'''-[Action, PI] ],
    (   { Action \== export }
    ->  [ nl, 'Use :- redefine_system_predicate(+Head) if redefinition is intended' ]
    ;   []
    ).
'$pm_permission_error'(import_into(Dest), procedure, Pred) -->
    [ 'No permission to import ~p into ~w'-[Pred, Dest] ].
'$pm_permission_error'(Action, static_procedure, Proc) -->
    [ 'No permission to ~w static procedure `~p'''-[Action, Proc] ].
'$pm_permission_error'(input, stream, Stream) -->
    [ 'No permission to read from output stream `~p'''-[Stream] ].
'$pm_permission_error'(output, stream, Stream) -->
    [ 'No permission to write to input stream `~p'''-[Stream] ].
'$pm_permission_error'(input, text_stream, Stream) -->
    [ 'No permission to read bytes from TEXT stream `~p'''-[Stream] ].
'$pm_permission_error'(output, text_stream, Stream) -->
    [ 'No permission to write bytes to TEXT stream `~p'''-[Stream] ].
'$pm_permission_error'(input, binary_stream, Stream) -->
    [ 'No permission to read characters from binary stream `~p'''-[Stream] ].
'$pm_permission_error'(output, binary_stream, Stream) -->
    [ 'No permission to write characters to binary stream `~p'''-[Stream] ].
'$pm_permission_error'(open, source_sink, alias(Alias)) -->
    [ 'No permission to reuse alias "~p": already taken'-[Alias] ].
'$pm_permission_error'(tnot, non_tabled_procedure, Pred) -->
    [ 'The argument of tnot/1 is not tabled: ~p'-[Pred] ].
'$pm_permission_error'(Action, Type, Object) -->
    [ 'No permission to ~w ~w `~p'''-[Action, Type, Object] ].

'$pm_unknown_proc'(_:(^)/2) -->
    !,
    '$pm_unknown_proc'((^)/2).
'$pm_unknown_proc'((^)/2) -->
    !,
    [ nl, '  ^/2 can only appear as the 2nd argument of setof/3 and bagof/3' ].
'$pm_unknown_proc'((:-)/2) -->
    !,
    [ nl, '  Rules must be loaded from a file' ],
    '$pm_faq'('ToplevelMode').
'$pm_unknown_proc'((=>)/2) -->
    !,
    [ nl, '  Rules must be loaded from a file' ],
    '$pm_faq'('ToplevelMode').
'$pm_unknown_proc'((:-)/1) -->
    !,
    [ nl, '  Directives must be loaded from a file' ],
    '$pm_faq'('ToplevelMode').
'$pm_unknown_proc'((?-)/1) -->
    !,
    [ nl, '  ?- is the Prolog prompt' ],
    '$pm_faq'('ToplevelMode').
'$pm_unknown_proc'(Proc) -->
    { '$pm_dwim_predicates'(Proc, Dwims) },
    (   { Dwims \== [] }
    ->  [ nl, '  However, there are definitions for:', nl ],
        '$pm_dwim_message'(Dwims)
    ;   []
    ).

%% the predicates Proc's name is near, as Name/Arity in swipl's order
%% (3.3.0, the engine's `$dwim_predicates'/2): the name is a goal's head,
%% as swipl's dwim_predicate/2 reads it, and its own predicate alone where
%% that is defined -- Name/0 for an atom, foo/1 for `foo(x)' --, else each
%% defined predicate whose name dwim-matches, the system's first. There is
%% one namespace, so a module says nothing. A Proc of neither shape fails,
%% as swipl's does: the message is then the one for anything that does not
%% exist.
'$pm_dwim_predicates'(_:Name/_, Dwims) :-
    !,
    '$pm_dwim_name'(Name, Dwims).
'$pm_dwim_predicates'(Name/_, Dwims) :-
    '$pm_dwim_name'(Name, Dwims).

'$pm_dwim_name'(_:Name, Dwims) :-
    !,
    '$pm_dwim_name'(Name, Dwims).
'$pm_dwim_name'(Name, Dwims) :-
    callable(Name),
    '$dwim_predicates'(Name, Dwims),
    !.
'$pm_dwim_name'(_, []).

'$pm_dwim_message'([]) --> [].
'$pm_dwim_message'([PI|T]) -->
    [ '        ~q'-[PI], nl ],
    '$pm_dwim_message'(T).

'$pm_faq'(Page) -->
    [ nl, '  See FAQ at https://www.swi-prolog.org/FAQ/', Page, '.txt' ].

%% ` (an atom)': what the culprit is, with its article
'$pm_type_comment'(Actual) -->
    { '$pm_type_of'(Actual, Type),
      (   sub_atom(Type, 0, 1, _, First),
          memberchk(First, [a, e, i, o, u])
      ->  Article = an
      ;   Article = a
      )
    },
    [ ' (~w ~w)'-[Article, Type] ].

%% [] is no atom to swipl 7 and later, and is asked about first here
'$pm_type_of'(Term, Type) :-
    (   var(Term)         -> Type = var
    ;   Term == []        -> Type = empty_list
    ;   atom(Term)        -> Type = atom
    ;   integer(Term)     -> Type = integer
    ;   string(Term)      -> Type = string
    ;   rational(Term)    -> Type = rational
    ;   float(Term)       -> Type = float
    ;   is_list(Term)     -> Type = list
    ;   cyclic_term(Term) -> Type = cyclic
    ;   compound(Term)    -> Type = compound
    ;                        Type = unknown
    ).

'$pm_syntax_error'(end_of_clause) -->
    [ 'Unexpected end of clause' ].
'$pm_syntax_error'(end_of_clause_expected) -->
    [ 'End of clause expected' ].
'$pm_syntax_error'(end_of_file) -->
    [ 'Unexpected end of file' ].
'$pm_syntax_error'(end_of_file_in_block_comment) -->
    [ 'End of file in /* ... */ comment' ].
'$pm_syntax_error'(end_of_file_in_quoted(Quote)) -->
    [ 'End of file in quoted ' ],
    '$pm_quoted_type'(Quote).
'$pm_syntax_error'(illegal_number) -->
    [ 'Illegal number' ].
'$pm_syntax_error'(long_atom) -->
    [ 'Atom too long (see style_check/1)' ].
'$pm_syntax_error'(long_string) -->
    [ 'String too long (see style_check/1)' ].
'$pm_syntax_error'(operator_clash) -->
    [ 'Operator priority clash' ].
'$pm_syntax_error'(operator_expected) -->
    [ 'Operator expected' ].
'$pm_syntax_error'(operator_balance) -->
    [ 'Unbalanced operator' ].
'$pm_syntax_error'(quoted_punctuation) -->
    [ 'Operand expected, unquoted comma or bar found' ].
'$pm_syntax_error'(list_rest) -->
    [ 'Unexpected comma or bar in rest of list' ].
'$pm_syntax_error'(cannot_start_term) -->
    [ 'Illegal start of term' ].
'$pm_syntax_error'(punct(Punct, End)) -->
    [ 'Unexpected `~w\' before `~w\''-[Punct, End] ].
'$pm_syntax_error'(undefined_char_escape(C)) -->
    [ 'Unknown character escape in quoted atom or string: `\\~w\''-[C] ].
'$pm_syntax_error'(void_not_allowed) -->
    [ 'Empty argument list "()"' ].
'$pm_syntax_error'(Message) -->
    [ '~w'-[Message] ].

'$pm_quoted_type'('\'') --> [ atom ].
'$pm_quoted_type'('"') --> { current_prolog_flag(double_quotes, Type) }, [ Type-[] ].
'$pm_quoted_type'('`') --> [ codes-[] ].

'$pm_domain'(range(Low, High)) -->
    !,
    [ '[~q..~q]'-[Low, High] ].
'$pm_domain'(Domain) -->
    [ '`~w\''-[Domain] ].

'$pm_swi_message'(io_error(Op, Stream)) -->
    [ 'I/O error in ~w on stream ~p'-[Op, Stream] ].
'$pm_swi_message'(thread_error(TID, false)) -->
    [ 'Thread ~p died due to failure:'-[TID] ].
'$pm_swi_message'(thread_error(TID, exception(Error))) -->
    [ 'Thread ~p died abnormally:'-[TID], nl ],
    '$pm_translate'(Error).
'$pm_swi_message'(shell(execute, Cmd)) -->
    [ 'Could not execute `~w'''-[Cmd] ].
'$pm_swi_message'(shell(signal(Sig), Cmd)) -->
    [ 'Caught signal ~d on `~w'''-[Sig, Cmd] ].
'$pm_swi_message'(format(Fmt, Args)) -->
    [ Fmt-Args ].
'$pm_swi_message'(signal(Name, Num)) -->
    [ 'Caught signal ~d (~w)'-[Num, Name] ].
'$pm_swi_message'(limit_exceeded(Limit, MaxVal)) -->
    [ 'Exceeded ~w limit (~w)'-[Limit, MaxVal] ].
'$pm_swi_message'(goal_failed(Goal)) -->
    [ 'goal unexpectedly failed: ~p'-[Goal] ].
'$pm_swi_message'(shared_object(_Action, Message)) -->
    [ '~w'-[Message] ].
'$pm_swi_message'(system_error(Error)) -->
    [ 'error in system call: ~w'-[Error] ].
'$pm_swi_message'(system_error) -->
    [ 'error in system call' ].
'$pm_swi_message'(failure_error(Goal)) -->
    [ 'Goal failed: ~p'-[Goal] ].
'$pm_swi_message'(timeout_error(Op, Stream)) -->
    [ 'Timeout in ~w from ~p'-[Op, Stream] ].
'$pm_swi_message'(not_implemented(Type, What)) -->
    [ '~w `~p\' is not implemented in this version'-[Type, What] ].
'$pm_swi_message'(format_argument_type(Fmt, Arg)) -->
    [ 'Illegal argument to format sequence ~~~w: ~p'-[Fmt, Arg] ].
'$pm_swi_message'(format(Msg)) -->
    [ 'Format error: ~w'-[Msg] ].
'$pm_swi_message'(duplicate_key(Key)) -->
    [ 'Duplicate key: ~p'-[Key] ].
'$pm_swi_message'(initialization_error(failed, Goal, File:Line)) -->
    !,
    [ url(File:Line), ': ~p: false'-[Goal] ].
'$pm_swi_message'(initialization_error(Error, Goal, File:Line)) -->
    [ url(File:Line), ': ~p '-[Goal] ],
    '$pm_translate'(Error).
'$pm_swi_message'(determinism_error(Goal, det, fail, goal)) -->
    [ 'Goal ~p failed'-[Goal] ].
'$pm_swi_message'(determinism_error(Goal, det, nondet, goal)) -->
    [ 'Goal ~p succeeded with a choice point'-[Goal] ].

%% Where an error was raised, before its text: the context's predicate.
'$pm_location'(X) -->
    { var(X) },
    !.
'$pm_location'(context(Caller, _Msg)) -->
    { ground(Caller) },
    !,
    '$pm_caller'(Caller).
'$pm_location'(file(Path, Line, -1, _CharNo)) -->
    !,
    [ url(Path:Line), ': ' ].
'$pm_location'(file(Path, Line, LinePos, _CharNo)) -->
    [ url(Path:Line:LinePos), ': ' ].
'$pm_location'(stream(Stream, Line, LinePos, _CharNo)) -->
    [ 'Stream ~w:~d:~d '-[Stream, Line, LinePos] ].
'$pm_location'(autoload(File:Line)) -->
    [ url(File:Line), ': ' ].
'$pm_location'(_) -->
    [].

'$pm_caller'(system:'$record_clause'/3) -->
    !,
    [].
'$pm_caller'(Module:Name/Arity) -->
    !,
    (   { \+ '$pm_hidden_module'(Module) }
    ->  [ '~q:~q/~w: '-[Module, Name, Arity] ]
    ;   [ '~q/~w: '-[Name, Arity] ]
    ).
'$pm_caller'(Name/Arity) -->
    [ '~q/~w: '-[Name, Arity] ].
'$pm_caller'(Caller) -->
    [ '~p: '-[Caller] ].

'$pm_hidden_module'(user) :- !.
'$pm_hidden_module'(system) :- !.
'$pm_hidden_module'(M) :-
    atom(M),
    sub_atom(M, 0, _, _, '$').

'$pm_user_pi'(Module:PI, PI) :-
    '$pm_hidden_module'(Module),
    !.
'$pm_user_pi'(PI, PI).

%% What an error says after its text: the context's message.
'$pm_extra'(X) -->
    { var(X) },
    !,
    [].
'$pm_extra'(context(_, Msg)) -->
    { nonvar(Msg),
      Msg \== ''
    },
    !,
    '$pm_comment'(Msg).
'$pm_extra'(string(String, CharPos)) -->
    { sub_string(String, 0, CharPos, _, Before),
      sub_string(String, CharPos, _, 0, After)
    },
    [ nl, '~w'-[Before], nl, '** here **', nl, '~w'-[After] ].
'$pm_extra'(_) -->
    [].

'$pm_comment'(already_from(Module)) -->
    !,
    [ ' (already imported from ~q)'-[Module] ].
'$pm_comment'(directory(_Dir)) -->
    !,
    [ ' (is a directory)' ].
'$pm_comment'(not_a_directory(_Dir)) -->
    !,
    [ ' (is not a directory)' ].
'$pm_comment'(Msg) -->
    [ ' (~w)'-[Msg] ].

%% A few of swipl's own messages a program may print by name.
'$pm_prolog_message'(unhandled_exception(E)) -->
    { nonvar(E) },
    [ 'Unhandled exception: ' ],
    (   '$pm_translate'(E)
    ->  []
    ;   [ '~p'-[E] ]
    ).
'$pm_prolog_message'(goal_failed(Context, Goal)) -->
    [ 'Goal (~w) failed: ~p'-[Context, Goal] ].
'$pm_prolog_message'(initialization_error(_, E, File:Line)) -->
    !,
    [ url(File:Line), ': Initialization goal raised exception:', nl ],
    '$pm_translate'(E).
'$pm_prolog_message'(initialization_error(Goal, E, _)) -->
    [ 'Initialization goal ~p raised exception:'-[Goal], nl ],
    '$pm_translate'(E).
'$pm_prolog_message'(initialization_failure(_Goal, File:Line)) -->
    !,
    [ url(File:Line), ': Initialization goal failed'-[] ].
'$pm_prolog_message'(initialization_failure(Goal, _)) -->
    [ 'Initialization goal failed: ~p'-[Goal] ].
'$pm_prolog_message'(halt) -->
    [ 'halt' ].
