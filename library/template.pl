%% cocolog -- library(template): text with holes, and the clauses that fill them.
%%
%% A TEMPLATE IS TEXT PLUS FOUR TAGS. The text is copied through; a tag is
%% evaluated and its answer written, escaped for the format:
%%
%%     {{ expression }}                 a value
%%     {% if expression %} ... {% else %} ... {% endif %}
%%     {% for X in expression %} ... {% endfor %}
%%     {% query Goal, ... %} ... {% endquery %}
%%     {# a comment #}
%%
%% `if' takes an optional `else'; `for' gives the body a `loop' object with
%% `index' (1 up), `index0' (0 up), `first', `last' and `length'. A `query'
%% is a conjunction of goals in the template's own term syntax -- a variable
%% is a capitalised name, a bare lowercase name is an atom -- and its
%% variables are in the body's context, for every solution:
%%
%%     {% query member(X, [1, 2, 3]) %}<li>{{ X }}</li>{% endquery %}
%%
%% A goal may end `Var is Expression', the one operator a query knows:
%%
%%     {% query member(X, [1, 2, 3]), Y is X * 2 %}{{ Y }}{% endquery %}
%%
%% THE FORMAT SAYS HOW A VALUE IS ESCAPED, never how it is written:
%%
%%     text    copied as it stands (the default)
%%     html    & < > " escaped
%%     xml     the same
%%     json    " \ and the control characters escaped, so a value can sit
%%             inside the JSON string the template itself writes
%%
%% A value is an atom, a number, a string or a code list of text; anything
%% else is written as a Prolog term. `str(X)' says a CODE LIST is text, the
%% same convention library(json) uses, because a bare list is a list:
%%
%%     Ctx = [title=str("My Page")]     % "My Page" is a code list here
%%     Ctx = [title='My Page']          % ... and this is an atom
%%
%% `upper', `lower', `trim', `length', `join', `range' and `default' are
%% the functions an expression can call.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%   template_render(+Template, +Context, -Output)
%%   template_render(+Template, +Format, +Context, -Output)
%%   template_string(+String, +Context, -Output)
%%   template_string(+String, +Format, +Context, -Output)
%%   template_file(+File, +Context, -Output)
%%   template_file(+File, +Format, +Context, -Output)
%%   template_compile(+Text, -Compiled)
%%   template_parse(+Text, -Nodes)
%%
%% Template and String are an atom, a string or a code list; File is read
%% with read_file_to_codes/2. Output is an ATOM. A compiled template is
%% `tpl_compiled(Nodes)' and template_render/3,4 takes it as it takes text,
%% so a page rendered a thousand times is parsed once:
%%
%%     template_compile(Text, T), template_render(T, html, Ctx, Out)
%%
%% Context is a list of Name=Value pairs. A dotted path walks records --
%% `user.name', `loop.last' -- where a record is `obj(Pairs)' or a plain
%% list of pairs. `true', `false', `no' and `null' are the literals their
%% names say; a value is false in an `if' when it is one of those, `[]',
%% the empty atom, or the number zero. A MISSING NAME IS FALSE IN A
%% CONDITION and an error in an output: `{% if user %}' asks whether there
%% is one, while `{{ user }}' names a bug.
%%
%% ERRORS ARE THROWN, naming the term: template_error(undefined(Name)),
%% template_error(no_field(Field, Value)), template_error(unknown_function
%% (Name/Arity)), template_error(not_a_list(Value)), template_error(
%% not_a_collection(Value)), template_error(not_a_number(Value)),
%% template_error(not_an_integer(Value)), template_error(not_text(Value)),
%% template_error(zero_step), template_error(unknown_format(Format)) and
%% template_error(syntax(Reason)).
%%
%% WHY CLAUSES: a template is two grammars -- the tags, and the expressions
%% inside them -- and Prolog is a parser that does not have to be taught
%% about choice. It is also the same language the value expressions live
%% in, so a query goal is a term the reader already knows how to call.
%%
%% EVERY PREDICATE IS `template_'-PREFIXED, helpers, nonterminals and the
%% AST functors (`tpl_'-prefixed) included: cocolog has ONE namespace.

%% ---- the surface ------------------------------------------------------

template_render(Template, Format, Context, Output) :-
    template_check_format(Format),
    template_nodes_of(Template, Nodes),
    template_render_nodes(Nodes, Context, Format, Codes, []),
    atom_codes(Output, Codes).

template_render(Template, Context, Output) :-
    template_render(Template, text, Context, Output).

template_string(String, Format, Context, Output) :-
    template_render(String, Format, Context, Output).

template_string(String, Context, Output) :-
    template_render(String, Context, Output).

template_file(File, Format, Context, Output) :-
    read_file_to_codes(File, Codes),
    template_render(Codes, Format, Context, Output).

template_file(File, Context, Output) :-
    template_file(File, text, Context, Output).

template_compile(Text, tpl_compiled(Nodes)) :-
    template_parse(Text, Nodes).

template_parse(Text, Nodes) :-
    template_text(Text, Codes),
    template_parse_seq(Codes, [], Nodes, Stop, Rest),
    (   Stop == eof, Rest == []
    ->  true
    ;   throw(template_error(syntax(unexpected_end)))
    ).

template_check_format(Format) :-
    (   memberchk(Format, [text, html, xml, json])
    ->  true
    ;   throw(template_error(unknown_format(Format)))
    ).

%% A template is text: an atom, a string, or the codes themselves. A code
%% list is what `read_file_to_codes/2' answers and what every document
%% library in the tree takes, so nothing is converted on the way in.
template_text(Text, Codes) :-
    (   atom(Text)
    ->  atom_codes(Text, Codes)
    ;   string(Text)
    ->  string_codes(Text, Codes)
    ;   is_list(Text)
    ->  Codes = Text
    ;   throw(template_error(not_text(Text)))
    ).

template_nodes_of(tpl_compiled(Nodes), Nodes) :- !.
template_nodes_of(Text, Nodes) :- template_parse(Text, Nodes).

%% ---- the tag parser ---------------------------------------------------
%%
%% parse_seq reads nodes until the codes end or a tag whose keyword is in
%% Stops stands ready. A stop is `stop(Keyword)' and the codes after its
%% `%}'; the caller decides which construct it closes. Every failure the
%% READER can meet is a throw, because a template that cannot be read is
%% not a template that merely failed.

template_parse_seq([], _, [], eof, []).
template_parse_seq([123, 37 | Codes], Stops, Nodes, Stop, Rest) :-    % {%
    !,
    template_tag(Codes, Keyword, Args, After),
    (   memberchk(Keyword, Stops)
    ->  (   Args == []
        ->  true
        ;   throw(template_error(syntax(tag_takes_no_argument(Keyword))))
        ),
        Nodes = [],
        Stop = stop(Keyword),
        Rest = After
    ;   Keyword == if
    ->  template_parse_if(Args, After, Node, Rest0),
        Nodes = [Node | More],
        template_parse_seq(Rest0, Stops, More, Stop, Rest)
    ;   Keyword == for
    ->  template_parse_for(Args, After, Node, Rest0),
        Nodes = [Node | More],
        template_parse_seq(Rest0, Stops, More, Stop, Rest)
    ;   Keyword == query
    ->  template_parse_query(Args, After, Node, Rest0),
        Nodes = [Node | More],
        template_parse_seq(Rest0, Stops, More, Stop, Rest)
    ;   throw(template_error(syntax(unexpected_tag(Keyword))))
    ).
template_parse_seq([123, 123 | Codes], Stops, [tpl_out(Expr) | More], Stop, Rest) :-  % {{
    !,
    (   template_until([125, 125], Codes, ExprCodes, After)
    ->  true
    ;   throw(template_error(syntax(unclosed('{{'))))
    ),
    template_expression(ExprCodes, Expr),
    template_parse_seq(After, Stops, More, Stop, Rest).
template_parse_seq([123, 35 | Codes], Stops, Nodes, Stop, Rest) :-        % {#
    !,
    (   template_until([35, 125], Codes, _, After)
    ->  true
    ;   throw(template_error(syntax(unclosed('{#'))))
    ),
    template_parse_seq(After, Stops, Nodes, Stop, Rest).
template_parse_seq(Codes, Stops, [tpl_text(Text) | More], Stop, Rest) :-
    Codes \== [],
    template_text_run(Codes, Text, After),
    template_parse_seq(After, Stops, More, Stop, Rest).

template_tag(Codes, Keyword, Args, After) :-
    (   template_until([37, 125], Codes, Content, After0)
    ->  true
    ;   throw(template_error(syntax(unclosed('{%'))))
    ),
    template_trim(Content, Trimmed),
    (   Trimmed == []
    ->  throw(template_error(syntax(empty_tag)))
    ;   template_ident(Trimmed, Keyword, Rest0)
    ->  template_trim(Rest0, Args),
        After = After0
    ;   atom_codes(What, Trimmed),
        throw(template_error(syntax(bad_tag(What))))
    ).

template_parse_if(Args, After, Node, Rest) :-
    template_expression(Args, Cond),
    template_parse_seq(After, [else, endif], Then, Stop1, R1),
    (   Stop1 == stop(else)
    ->  template_parse_seq(R1, [endif], Else, Stop2, R2),
        (   Stop2 == stop(endif)
        ->  Rest = R2
        ;   throw(template_error(syntax(unclosed(if))))
        )
    ;   Stop1 == stop(endif)
    ->  Else = [],
        Rest = R1
    ;   throw(template_error(syntax(unclosed(if))))
    ),
    Node = tpl_if(Cond, Then, Else).

template_parse_for(Args, After, Node, Rest) :-
    template_for_args(Args, Var, Expr),
    template_parse_seq(After, [endfor], Body, Stop, R1),
    (   Stop == stop(endfor)
    ->  Rest = R1
    ;   throw(template_error(syntax(unclosed(for))))
    ),
    Node = tpl_for(Var, Expr, Body).

template_parse_query(Args, After, Node, Rest) :-
    template_query_args(Args, Vars, Goals),
    template_parse_seq(After, [endquery], Body, Stop, R1),
    (   Stop == stop(endquery)
    ->  Rest = R1
    ;   throw(template_error(syntax(unclosed(query))))
    ),
    Node = tpl_query(Vars, Goals, Body).

template_for_args(Codes, Var, Expr) :-
    (   template_ident(Codes, Var, R0)
    ->  true
    ;   throw(template_error(syntax(for_wants_a_variable)))
    ),
    (   template_word(R0, in, R1)
    ->  true
    ;   throw(template_error(syntax(for_wants_in)))
    ),
    template_expression(R1, Expr).

%% A run of text ends at the first `{{', `{%' or `{#'. A `{' that begins
%% none of them is text, which is what lets a page hold one.
template_text_run([], [], []).
template_text_run([123, 123 | Rest], [], [123, 123 | Rest]) :- !.
template_text_run([123, 37 | Rest], [], [123, 37 | Rest]) :- !.
template_text_run([123, 35 | Rest], [], [123, 35 | Rest]) :- !.
template_text_run([C | Cs], [C | Ts], Rest) :-
    template_text_run(Cs, Ts, Rest).

%% Codes up to Delim, and the codes after it. Fails when Delim is never
%% met; every caller owes the reader a throw naming what it was reading.
template_until(Delim, Codes, Before, After) :-
    (   template_prefix(Codes, Delim, After0)
    ->  Before = [],
        After = After0
    ;   Codes = [C | Rest]
    ->  Before = [C | More],
        template_until(Delim, Rest, More, After)
    ).

template_prefix(Codes, [], Codes).
template_prefix([C | Cs], [C | Ps], Rest) :-
    template_prefix(Cs, Ps, Rest).

%% ---- the expression parser -------------------------------------------
%%
%% Precedence, loosest first: or, and, not and unary minus, comparisons
%% (one, never chained), + -, * /, and a primary -- a number, a quoted
%% atom, a list, a parenthesised expression, a dotted path, or a call.

template_expression(Codes, Expr) :-
    (   template_expr_or(Codes, Expr0, Rest)
    ->  true
    ;   throw(template_error(syntax(wants_an_expression)))
    ),
    template_skip_space(Rest, R2),
    (   R2 == []
    ->  Expr = Expr0
    ;   atom_codes(What, R2),
        throw(template_error(syntax(unexpected(What))))
    ).

template_expr_or(Codes, Expr, Rest) :-
    template_expr_and(Codes, A, R0),
    template_expr_or_rest(R0, A, Expr, Rest).

template_expr_or_rest(Codes, A, Expr, Rest) :-
    (   template_word(Codes, or, R0)
    ->  template_expr_and(R0, B, R1),
        template_expr_or_rest(R1, tpl_or(A, B), Expr, Rest)
    ;   Expr = A,
        Rest = Codes
    ).

template_expr_and(Codes, Expr, Rest) :-
    template_expr_unary(Codes, A, R0),
    template_expr_and_rest(R0, A, Expr, Rest).

template_expr_and_rest(Codes, A, Expr, Rest) :-
    (   template_word(Codes, and, R0)
    ->  template_expr_unary(R0, B, R1),
        template_expr_and_rest(R1, tpl_and(A, B), Expr, Rest)
    ;   Expr = A,
        Rest = Codes
    ).

template_expr_unary(Codes, Expr, Rest) :-
    (   template_word(Codes, not, R0)
    ->  template_expr_unary(R0, E, Rest),
        Expr = tpl_not(E)
    ;   template_skip_space(Codes, [45 | R0])
    ->  template_expr_unary(R0, E, Rest),
        Expr = tpl_neg(E)
    ;   template_expr_cmp(Codes, Expr, Rest)
    ).

template_expr_cmp(Codes, Expr, Rest) :-
    template_expr_add(Codes, A, R0),
    (   template_cmp_op(R0, Op, R1)
    ->  template_expr_add(R1, B, R2),
        Expr = tpl_cmp(Op, A, B),
        Rest = R2
    ;   Expr = A,
        Rest = R0
    ).

template_cmp_op(Codes, Op, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [61, 61 | R]
    ->  Op = '==', Rest = R
    ;   C0 = [33, 61 | R]
    ->  Op = '!=', Rest = R
    ;   C0 = [60, 61 | R]
    ->  Op = '<=', Rest = R
    ;   C0 = [62, 61 | R]
    ->  Op = '>=', Rest = R
    ;   C0 = [60 | R]
    ->  Op = '<', Rest = R
    ;   C0 = [62 | R]
    ->  Op = '>', Rest = R
    ).

template_expr_add(Codes, Expr, Rest) :-
    template_expr_mul(Codes, A, R0),
    template_expr_add_rest(R0, A, Expr, Rest).

template_expr_add_rest(Codes, A, Expr, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [43 | R]
    ->  template_expr_mul(R, B, R1),
        template_expr_add_rest(R1, tpl_arith('+', A, B), Expr, Rest)
    ;   C0 = [45 | R]
    ->  template_expr_mul(R, B, R1),
        template_expr_add_rest(R1, tpl_arith('-', A, B), Expr, Rest)
    ;   Expr = A,
        Rest = Codes
    ).

template_expr_mul(Codes, Expr, Rest) :-
    template_expr_primary(Codes, A, R0),
    template_expr_mul_rest(R0, A, Expr, Rest).

template_expr_mul_rest(Codes, A, Expr, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [42 | R]
    ->  template_expr_primary(R, B, R1),
        template_expr_mul_rest(R1, tpl_arith('*', A, B), Expr, Rest)
    ;   C0 = [47 | R]
    ->  template_expr_primary(R, B, R1),
        template_expr_mul_rest(R1, tpl_arith('/', A, B), Expr, Rest)
    ;   Expr = A,
        Rest = Codes
    ).

template_expr_primary(Codes, Expr, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [40 | R0]                                    % (
    ->  (   template_expr_or(R0, E, R1)
        ->  true
        ;   throw(template_error(syntax(wants_an_expression)))
        ),
        template_skip_space(R1, R2),
        (   R2 = [41 | R3]
        ->  Expr = E,
            Rest = R3
        ;   throw(template_error(syntax(unclosed_parenthesis)))
        )
    ;   C0 = [91 | R0]                                    % [
    ->  template_expr_bracket_list(R0, Items, R1),
        Expr = tpl_list(Items),
        Rest = R1
    ;   C0 = [39 | R0]                                    % '
    ->  (   template_quoted(R0, 39, Atom, R1)
        ->  Expr = tpl_lit(Atom),
            Rest = R1
        ;   throw(template_error(syntax(unclosed_quote)))
        )
    ;   C0 = [34 | R0]                                    % "
    ->  (   template_quoted(R0, 34, Atom, R1)
        ->  Expr = tpl_lit(Atom),
            Rest = R1
        ;   throw(template_error(syntax(unclosed_quote)))
        )
    ;   C0 = [C | _],
        template_digit(C)
    ->  template_number_literal(C0, N, R1),
        Expr = tpl_lit(N),
        Rest = R1
    ;   C0 = [C | _],
        template_ident_start(C)
    ->  template_name_expression(C0, Expr, Rest)
    ;   throw(template_error(syntax(wants_an_expression)))
    ).

template_expr_bracket_list(Codes, Items, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [93 | R]
    ->  Items = [],
        Rest = R
    ;   template_expr_list(C0, 93, Items, Rest)
    ).

template_expr_list(Codes, Close, [E | Es], Rest) :-
    (   template_expr_or(Codes, E, R0)
    ->  true
    ;   throw(template_error(syntax(wants_an_expression)))
    ),
    template_skip_space(R0, R1),
    (   R1 = [44 | R2]
    ->  template_expr_list(R2, Close, Es, Rest)
    ;   R1 = [Close | R3]
    ->  Es = [],
        Rest = R3
    ;   throw(template_error(syntax(wants_a_close_parenthesis)))
    ).

%% A name is a function call when `(' follows it, a dotted path when a
%% field does, and otherwise a path of one name -- `true' and `false'
%% being the literals they spell.
template_name_expression(Codes, Expr, Rest) :-
    template_ident(Codes, Name, R0),
    template_skip_space(R0, R1),
    (   R1 = [40 | R2]
    ->  template_call_args(R2, Args, R3),
        Expr = tpl_call(Name, Args),
        Rest = R3
    ;   template_path_fields(R1, [Name], Path0, Rest0),
        reverse(Path0, Path),
        Rest = Rest0,
        (   Path == [true]
        ->  Expr = tpl_lit(true)
        ;   Path == [false]
        ->  Expr = tpl_lit(false)
        ;   Expr = tpl_path(Path)
        )
    ).

template_path_fields(Codes, Acc, Fields, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [46 | R0],
        R0 = [C | _],
        template_ident_start(C)
    ->  template_ident(R0, Field, R1),
        template_path_fields(R1, [Field | Acc], Fields, Rest)
    ;   Fields = Acc,
        Rest = Codes
    ).

template_call_args(Codes, Args, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [41 | R]
    ->  Args = [],
        Rest = R
    ;   template_expr_list(C0, 41, Args, Rest)
    ).

%% A numeral: digits, an optional fraction and an optional exponent. The
%% dot is taken only when a digit follows, so `loop.index' is a path.
template_number_literal(Codes, N, Rest) :-
    template_digits(Codes, Int, R0),
    (   R0 = [46, C | R1],
        template_digit(C)
    ->  template_digits([C | R1], Frac, R2),
        append(Int, [46 | Frac], Base),
        template_number_exponent(R2, Base, NumCodes, Rest)
    ;   template_number_exponent(R0, Int, NumCodes, Rest)
    ),
    number_codes(N, NumCodes).

template_number_exponent(Codes, Base, NumCodes, Rest) :-
    (   Codes = [E | R0],
        (E =:= 101 ; E =:= 69)
    ->  (   R0 = [S | R1],
            (S =:= 43 ; S =:= 45)
        ->  Sign = [S],
            R2 = R1
        ;   Sign = [],
            R2 = R0
        ),
        R2 = [C | _],
        template_digit(C)
    ->  template_digits(R2, Digits, Rest),
        append(Base, [E | Sign], Head),
        append(Head, Digits, NumCodes)
    ;   NumCodes = Base,
        Rest = Codes
    ).

template_digits([C | Cs], [C | Ds], Rest) :-
    template_digit(C),
    !,
    template_digits(Cs, Ds, Rest).
template_digits(Cs, [], Cs).

template_digit(C) :-
    C >= 48,
    C =< 57,
    !.

%% A quoted atom, in either quote. A doubled quote is the quote itself,
%% as Prolog reads it; a backslash escape is the character it names.
template_quoted(Codes, Quote, Atom, Rest) :-
    template_quoted_codes(Codes, Quote, Chars, Rest),
    atom_codes(Atom, Chars).

template_quoted_codes([Q, Q | Rest], Q, [Q | More], R) :-
    !,
    template_quoted_codes(Rest, Q, More, R).
template_quoted_codes([Q | Rest], Q, [], Rest) :-
    !.
template_quoted_codes([92, C | Rest], Q, [D | More], R) :-
    !,
    template_char_escape(C, D),
    template_quoted_codes(Rest, Q, More, R).
template_quoted_codes([C | Rest], Q, [C | More], R) :-
    template_quoted_codes(Rest, Q, More, R).

template_char_escape(110, 10).   % n
template_char_escape(114, 13).   % r
template_char_escape(116, 9).    % t
template_char_escape(92, 92).    % backslash
template_char_escape(39, 39).    % '
template_char_escape(34, 34).    % "
template_char_escape(C, C).

%% ---- the query parser -------------------------------------------------
%%
%% A query is a conjunction of terms; a capitalised or underscored name is
%% a variable of the query, a lowercase one is an atom, and the variables
%% are collected by name so the body can read them.

template_query_args(Codes, Vars, Goals) :-
    template_skip_space(Codes, C0),
    (   C0 == []
    ->  throw(template_error(syntax(wants_a_query)))
    ;   true
    ),
    (   template_query_goals(C0, [], Vars, Goals, Rest)
    ->  true
    ;   throw(template_error(syntax(wants_a_query)))
    ),
    template_skip_space(Rest, R2),
    (   R2 == []
    ->  true
    ;   atom_codes(What, R2),
        throw(template_error(syntax(unexpected(What))))
    ).

template_query_goals(Codes, V0, Vars, Goal, Rest) :-
    template_query_term(Codes, T, V0, V1, R0),
    template_skip_space(R0, R1),
    (   template_word(R1, is, R2)
    ->  (   template_expr_or(R2, Expr, R3)
        ->  true
        ;   throw(template_error(syntax(wants_an_expression)))
        ),
        template_query_arith(Expr, V1, Arithmetic),
        G = is(T, Arithmetic),
        template_skip_space(R3, R4)
    ;   G = T,
        R4 = R1
    ),
    (   R4 = [44 | R5]
    ->  template_query_goals(R5, V1, Vars, G2, Rest),
        Goal = (G, G2)
    ;   Goal = G,
        Vars = V1,
        Rest = R4
    ).

%% The right of `is' is our expression tree, read into a Prolog arithmetic
%% term over the query's own variables.
template_query_arith(tpl_lit(N), _, N) :-
    number(N),
    !.
template_query_arith(tpl_path([Name]), Vars, Var) :-
    !,
    (   memberchk(Name = Var0, Vars)
    ->  Var = Var0
    ;   throw(template_error(undefined(Name)))
    ).
template_query_arith(tpl_arith(Op, A, B), Vars, Term) :-
    !,
    template_query_arith(A, Vars, AT),
    template_query_arith(B, Vars, BT),
    Term =.. [Op, AT, BT].
template_query_arith(tpl_neg(A), Vars, Term) :-
    !,
    template_query_arith(A, Vars, AT),
    Term =.. ['-', AT].
template_query_arith(Expr, _, _) :-
    throw(template_error(syntax(not_arithmetic(Expr)))).

template_query_term(Codes, Term, V0, Vars, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [91 | R0]                                  % [
    ->  template_query_list(R0, Term, V0, Vars, Rest)
    ;   C0 = [39 | R0]                                  % '
    ->  (   template_quoted(R0, 39, Atom, R1)
        ->  Term = Atom,
            Vars = V0,
            Rest = R1
        ;   throw(template_error(syntax(unclosed_quote)))
        )
    ;   C0 = [34 | R0]                                  % "
    ->  (   template_quoted(R0, 34, Atom, R1)
        ->  Term = Atom,
            Vars = V0,
            Rest = R1
        ;   throw(template_error(syntax(unclosed_quote)))
        )
    ;   C0 = [45 | R0],
        R0 = [C | _],
        template_digit(C)
    ->  template_number_literal(R0, N0, R1),
        Term is -N0,
        Vars = V0,
        Rest = R1
    ;   C0 = [C | _],
        template_digit(C)
    ->  template_number_literal(C0, N, R1),
        Term = N,
        Vars = V0,
        Rest = R1
    ;   C0 = [C | _],
        template_ident_start(C)
    ->  template_query_name(C0, Term, V0, Vars, Rest)
    ;   throw(template_error(syntax(wants_a_term)))
    ).

template_query_name(Codes, Term, V0, Vars, Rest) :-
    Codes = [C | _],
    template_ident(Codes, Name, R0),
    template_skip_space(R0, R1),
    (   R1 = [40 | R2]                                  % (
    ->  template_query_call_args(R2, Args, V0, Vars, R3),
        Term =.. [Name | Args],
        Rest = R3
    ;   template_query_var_start(C)
    ->  template_query_var(Name, V0, Vars, Term),
        Rest = R1
    ;   Term = Name,
        Vars = V0,
        Rest = R1
    ).

template_query_var_start(C) :-
    (   C >= 65,
        C =< 90
    ;   C =:= 95
    ),
    !.

template_query_var('_', V0, V0, _) :-
    !.
template_query_var(Name, V0, Vars, Var) :-
    (   memberchk(Name = V, V0)
    ->  Var = V,
        Vars = V0
    ;   Vars = [Name = Var | V0]
    ).

template_query_list(Codes, List, V0, Vars, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [93 | R]                                   % ]
    ->  List = [],
        Vars = V0,
        Rest = R
    ;   template_query_term(C0, T, V0, V1, R0),
        template_skip_space(R0, R1),
        (   R1 = [44 | R2]
        ->  template_query_list(R2, Ts, V1, Vars, R3),
            List = [T | Ts],
            Rest = R3
        ;   R1 = [93 | R3]
        ->  List = [T],
            Vars = V1,
            Rest = R3
        ;   throw(template_error(syntax(wants_a_close_bracket)))
        )
    ).

template_query_call_args(Codes, Args, V0, Vars, Rest) :-
    template_skip_space(Codes, C0),
    (   C0 = [41 | R]                                   % )
    ->  Args = [],
        Vars = V0,
        Rest = R
    ;   template_query_term(C0, T, V0, V1, R0),
        template_skip_space(R0, R1),
        (   R1 = [44 | R2]
        ->  template_query_call_args(R2, Ts, V1, Vars, R3),
            Args = [T | Ts],
            Rest = R3
        ;   R1 = [41 | R3]
        ->  Args = [T],
            Vars = V1,
            Rest = R3
        ;   throw(template_error(syntax(wants_a_close_parenthesis)))
        )
    ).

%% ---- the renderer -----------------------------------------------------

template_render_nodes([], _, _) --> [].
template_render_nodes([Node | Nodes], Context, Format) -->
    template_render_node(Node, Context, Format),
    template_render_nodes(Nodes, Context, Format).

template_render_node(tpl_text(Codes), _, _) -->
    template_put_codes(Codes).
template_render_node(tpl_out(Expr), Context, Format) -->
    { template_eval(Expr, Context, Value) },
    template_put_value(Value, Format).
template_render_node(tpl_if(Cond, Then, Else), Context, Format) -->
    (   { template_holds(Cond, Context) }
    ->  template_render_nodes(Then, Context, Format)
    ;   template_render_nodes(Else, Context, Format)
    ).
template_render_node(tpl_for(Var, Expr, Body), Context, Format) -->
    {   template_eval(Expr, Context, Value),
        template_iterable(Value, Items),
        length(Items, Count)
    },
    template_render_for(Items, 1, Count, Var, Body, Context, Format).
template_render_node(tpl_query(Vars, Goal, Body), Context, Format) -->
    { findall(Binds, (call(Goal), template_query_binds(Vars, Binds)), Solutions) },
    template_render_query(Solutions, Body, Context, Format).

template_put_codes([]) --> [].
template_put_codes([C | Cs]) --> [C], template_put_codes(Cs).

template_put_value(Value, Format) -->
    { template_value_codes(Value, Codes) },
    template_escape(Format, Codes).

template_iterable(Value, Items) :-
    (   is_list(Value)
    ->  Items = Value
    ;   throw(template_error(not_a_list(Value)))
    ).

template_render_for([], _, _, _, _, _, _) --> [].
template_render_for([X | Xs], Index, Count, Var, Body, Context, Format) -->
    {   Index0 is Index - 1,
        (Index =:= 1 -> First = true ; First = false),
        (Index =:= Count -> Last = true ; Last = false),
        Loop = obj([index=Index, index0=Index0, first=First,
                    last=Last, length=Count]),
        WithLoop = [Var=X, loop=Loop | Context],
        Next is Index + 1
    },
    template_render_nodes(Body, WithLoop, Format),
    template_render_for(Xs, Next, Count, Var, Body, Context, Format).

template_render_query([], _, _, _) --> [].
template_render_query([Binds | More], Body, Context, Format) -->
    { append(Binds, Context, WithBinds) },
    template_render_nodes(Body, WithBinds, Format),
    template_render_query(More, Body, Context, Format).

template_query_binds([], []).
template_query_binds([Name = Value | More], Binds) :-
    (   var(Value)
    ->  Binds = Rest
    ;   atom_chars(Name, [95 | _])
    ->  Binds = Rest
    ;   Binds = [Name = Value | Rest]
    ),
    template_query_binds(More, Rest).

%% ---- escaping ---------------------------------------------------------

template_escape(text, Codes) --> template_put_codes(Codes).
template_escape(html, Codes) --> template_escape_html(Codes).
template_escape(xml, Codes) --> template_escape_html(Codes).
template_escape(json, Codes) --> template_escape_json(Codes).

%% `& < > "' are the five that change an HTML or XML document's meaning;
%% the apostrophe is left alone because the lesson says so. Both formats
%% share the escaper, as library(html) shares library(xml)'s.
%%
%% The terminals are written as codes, never as "..." strings: a library is
%% read under whatever `double_quotes' the caller has set, and a string that
%% became an atom would be a missing nonterminal at render time. Each
%% specific clause is CUT, or the catch-all after it would also match and a
%% render would answer several different escapements on backtracking.
template_escape_html([]) --> [].
template_escape_html([38 | Cs]) --> !, [38, 97, 109, 112, 59], template_escape_html(Cs).
template_escape_html([60 | Cs]) --> !, [38, 108, 116, 59], template_escape_html(Cs).
template_escape_html([62 | Cs]) --> !, [38, 103, 116, 59], template_escape_html(Cs).
template_escape_html([34 | Cs]) --> !, [38, 113, 117, 111, 116, 59], template_escape_html(Cs).
template_escape_html([C | Cs]) --> [C], template_escape_html(Cs).

%% JSON escapes the quote, the backslash and the controls; a control with
%% no letter of its own is `\u00XX', which is what a JSON reader expects.
template_escape_json([]) --> [].
template_escape_json([34 | Cs]) --> !, [92, 34], template_escape_json(Cs).
template_escape_json([92 | Cs]) --> !, [92, 92], template_escape_json(Cs).
template_escape_json([10 | Cs]) --> !, [92, 110], template_escape_json(Cs).
template_escape_json([13 | Cs]) --> !, [92, 114], template_escape_json(Cs).
template_escape_json([9 | Cs]) --> !, [92, 116], template_escape_json(Cs).
template_escape_json([C | Cs]) -->
    { C < 32 },
    !,
    template_json_control(C),
    template_escape_json(Cs).
template_escape_json([C | Cs]) --> [C], template_escape_json(Cs).

template_json_control(C) -->
    {   (C < 16 -> High is 48, Low is C ; High is 49, Low is C - 16),
        template_hex_digit(Low, Hex)
    },
    [92, 117, 48, 48, High, Hex].

template_hex_digit(D, Hex) :-
    (   D < 10
    ->  Hex is 48 + D
    ;   Hex is 87 + D
    ).

%% ---- values and expressions -------------------------------------------

template_value_codes(str(X), Codes) :-
    !,
    template_text_codes_of(X, Codes).
template_value_codes(Value, Codes) :-
    (   atom(Value)
    ->  atom_codes(Value, Codes)
    ;   number(Value)
    ->  number_codes(Value, Codes)
    ;   string(Value)
    ->  string_codes(Value, Codes)
    ;   term_to_atom(Value, Atom),
        atom_codes(Atom, Codes)
    ).

%% `str(X)' is the one place a code list is promised to be text.
template_text_codes_of(X, Codes) :-
    (   atom(X)
    ->  atom_codes(X, Codes)
    ;   string(X)
    ->  string_codes(X, Codes)
    ;   number(X)
    ->  number_codes(X, Codes)
    ;   is_list(X)
    ->  Codes = X
    ;   throw(template_error(not_text(X)))
    ).

template_eval(tpl_lit(Value), _, Value) :- !.
template_eval(tpl_list(Exprs), Context, Values) :-
    !,
    template_eval_list(Exprs, Context, Values).
template_eval(tpl_path(Path), Context, Value) :-
    !,
    template_path_value(Path, Context, Value).
template_eval(tpl_call(Name, Args), Context, Value) :-
    !,
    template_call(Name, Args, Context, Value).
template_eval(tpl_not(Expr), Context, Value) :-
    !,
    (   template_holds(Expr, Context)
    ->  Value = false
    ;   Value = true
    ).
template_eval(tpl_and(A, B), Context, Value) :-
    !,
    (   template_holds(A, Context),
        template_holds(B, Context)
    ->  Value = true
    ;   Value = false
    ).
template_eval(tpl_or(A, B), Context, Value) :-
    !,
    (   template_holds(A, Context)
    ->  Value = true
    ;   template_holds(B, Context)
    ->  Value = true
    ;   Value = false
    ).
template_eval(tpl_cmp(Op, A, B), Context, Value) :-
    !,
    template_eval(A, Context, AV),
    template_eval(B, Context, BV),
    (   template_cmp(Op, AV, BV)
    ->  Value = true
    ;   Value = false
    ).
template_eval(tpl_arith(Op, A, B), Context, Value) :-
    !,
    template_eval(A, Context, AV),
    template_eval(B, Context, BV),
    template_require_number(AV),
    template_require_number(BV),
    Expression =.. [Op, AV, BV],
    Value is Expression.
template_eval(tpl_neg(Expr), Context, Value) :-
    !,
    template_eval(Expr, Context, V),
    template_require_number(V),
    Value is -V.

template_eval_list([], _, []).
template_eval_list([E | Es], Context, [V | Vs]) :-
    template_eval(E, Context, V),
    template_eval_list(Es, Context, Vs).

template_path_value([Name | Fields], Context, Value) :-
    template_lookup(Name, Context, V0),
    template_fields(Fields, V0, Value).

template_lookup(Name, Context, Value) :-
    (   memberchk(Name = Value, Context)
    ->  true
    ;   throw(template_error(undefined(Name)))
    ).

template_fields([], Value, Value) :- !.
template_fields([Field | Fields], V0, Value) :-
    (   V0 = obj(Pairs)
    ->  true
    ;   is_list(V0)
    ->  Pairs = V0
    ;   throw(template_error(no_field(Field, V0)))
    ),
    (   memberchk(Field = Next, Pairs)
    ->  true
    ;   throw(template_error(no_field(Field, V0)))
    ),
    template_fields(Fields, Next, Value).

%% A condition is an expression asked whether it is true; a missing name
%% makes it false rather than an error, because that is what `if' is for.
template_holds(Expr, Context) :-
    catch(template_eval(Expr, Context, Value),
          template_error(undefined(_)),
          fail),
    template_truth(Value).

template_truth(Value) :-
    (   Value == false
    ;   Value == no
    ;   Value == null
    ;   Value == []
    ;   Value == ''
    ;   number(Value), Value =:= 0
    ),
    !,
    fail.
template_truth(_).

template_cmp('==', A, B) :- !, template_same(A, B).
template_cmp('!=', A, B) :- !, \+ template_same(A, B).
template_cmp('<', A, B) :-
    !, template_require_number(A), template_require_number(B), A < B.
template_cmp('<=', A, B) :-
    !, template_require_number(A), template_require_number(B), A =< B.
template_cmp('>', A, B) :-
    !, template_require_number(A), template_require_number(B), A > B.
template_cmp('>=', A, B) :-
    !, template_require_number(A), template_require_number(B), A >= B.

template_same(A, B) :-
    (   number(A), number(B)
    ->  A =:= B
    ;   A == B
    ).

template_require_number(Value) :-
    (   number(Value)
    ->  true
    ;   throw(template_error(not_a_number(Value)))
    ).

template_require_integer(Value) :-
    (   integer(Value)
    ->  true
    ;   throw(template_error(not_an_integer(Value)))
    ).

%% ---- functions --------------------------------------------------------
%%
%% `default' is first because its first argument must not be evaluated
%% before it can be found missing.

template_call(default, [Expr, Fallback], Context, Value) :-
    !,
    (   catch(template_eval(Expr, Context, V0),
              template_error(undefined(_)),
              fail)
    ->  Value = V0
    ;   template_eval(Fallback, Context, Value)
    ).
template_call(Name, ArgExprs, Context, Value) :-
    template_eval_list(ArgExprs, Context, Args),
    template_function(Name, Args, Value).

template_function(str, [X], str(X)) :-
    !.
template_function(upper, [X], Value) :-
    !,
    template_text_atom(X, Atom),
    upcase_atom(Atom, Value).
template_function(lower, [X], Value) :-
    !,
    template_text_atom(X, Atom),
    downcase_atom(Atom, Value).
template_function(trim, [X], Value) :-
    !,
    template_text_atom(X, Atom),
    atom_codes(Atom, Codes),
    template_trim(Codes, Trimmed),
    atom_codes(Value, Trimmed).
template_function(length, [X], Value) :-
    !,
    template_length(X, Value).
template_function(join, [List, Sep], Value) :-
    !,
    (   is_list(List)
    ->  true
    ;   throw(template_error(not_a_list(List)))
    ),
    template_text_atom(Sep, SepAtom),
    template_text_atoms(List, Atoms),
    atomic_list_concat(Atoms, SepAtom, Value).
template_function(range, [N], Value) :-
    !,
    template_require_integer(N),
    template_range_list(0, N, 1, Value).
template_function(range, [A, B], Value) :-
    !,
    template_require_integer(A),
    template_require_integer(B),
    template_range_list(A, B, 1, Value).
template_function(range, [A, B, Step], Value) :-
    !,
    template_require_integer(A),
    template_require_integer(B),
    template_require_integer(Step),
    (   Step =:= 0
    ->  throw(template_error(zero_step))
    ;   template_range_list(A, B, Step, Value)
    ).
template_function(Name, Args, _) :-
    length(Args, Arity),
    throw(template_error(unknown_function(Name/Arity))).

template_length(X, N) :-
    (   is_list(X)
    ->  length(X, N)
    ;   atom(X)
    ->  atom_length(X, N)
    ;   string(X)
    ->  string_length(X, N)
    ;   X = str(Text)
    ->  template_text_codes_of(Text, Codes),
        length(Codes, N)
    ;   throw(template_error(not_a_collection(X)))
    ).

template_text_atom(X, Atom) :-
    (   atom(X)
    ->  Atom = X
    ;   number(X)
    ->  number_codes(X, Codes),
        atom_codes(Atom, Codes)
    ;   string(X)
    ->  string_codes(X, Codes),
        atom_codes(Atom, Codes)
    ;   X = str(Text)
    ->  template_text_codes_of(Text, Codes),
        atom_codes(Atom, Codes)
    ;   throw(template_error(not_text(X)))
    ).

template_text_atoms([], []).
template_text_atoms([X | Xs], [Atom | Atoms]) :-
    template_text_atom(X, Atom),
    template_text_atoms(Xs, Atoms).

template_range_list(Lo, Hi, Step, List) :-
    (   Step > 0
    ->  (   Lo < Hi
        ->  List = [Lo | Rest],
            Next is Lo + Step,
            template_range_list(Next, Hi, Step, Rest)
        ;   List = []
        )
    ;   (   Lo > Hi
        ->  List = [Lo | Rest],
            Next is Lo + Step,
            template_range_list(Next, Hi, Step, Rest)
        ;   List = []
        )
    ).

%% ---- tokens -----------------------------------------------------------

template_skip_space([C | Cs], Rest) :-
    C =< 32,
    !,
    template_skip_space(Cs, Rest).
template_skip_space(Cs, Cs).

template_trim(Codes, Trimmed) :-
    template_trim_left(Codes, A),
    reverse(A, R),
    template_trim_left(R, B),
    reverse(B, Trimmed).

template_trim_left([C | Cs], Rest) :-
    C =< 32,
    !,
    template_trim_left(Cs, Rest).
template_trim_left(Cs, Cs).

template_ident(Codes, Name, Rest) :-
    template_skip_space(Codes, [C | Cs]),
    template_ident_start(C),
    template_ident_rest(Cs, More, Rest),
    atom_codes(Name, [C | More]).

template_ident_start(C) :-
    C >= 65,
    C =< 90,
    !.
template_ident_start(C) :-
    C >= 97,
    C =< 122,
    !.
template_ident_start(95) :- !.

template_ident_code(C) :-
    template_ident_start(C),
    !.
template_ident_code(C) :-
    C >= 48,
    C =< 57,
    !.

template_ident_rest([C | Cs], [C | More], Rest) :-
    template_ident_code(C),
    !,
    template_ident_rest(Cs, More, Rest).
template_ident_rest(Cs, [], Cs).

%% A word is a name with no name character after it, so `or' is the
%% operator in `a or b' and part of `orange' in neither.
template_word(Codes, Word, Rest) :-
    template_skip_space(Codes, C0),
    atom_codes(Word, WordCodes),
    template_prefix(C0, WordCodes, R0),
    (   R0 = [C | _]
    ->  \+ template_ident_code(C)
    ;   true
    ),
    Rest = R0.
