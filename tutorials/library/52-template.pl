%% LIBRARY 52 -- library(template): text with holes, and the clauses that fill them
%%
%%     ./cocolog run tutorials/library/52-template.pl main
%%
%% TIER 2: `use_module(library(template))', clauses in library/template.pl.
%%
%%     template_render(+Template, +Context, -Output)
%%     template_render(+Template, +Format, +Context, -Output)
%%     template_string(+String, +Context, -Output)      and /4
%%     template_file(+File, +Context, -Output)          and /4
%%     template_compile(+Text, -Compiled)
%%     template_parse(+Text, -Nodes)
%%
%% A TEMPLATE IS TEXT PLUS FOUR TAGS:
%%
%%     {{ expression }}                 a value, escaped for the format
%%     {% if expression %} ... {% else %} ... {% endif %}
%%     {% for X in expression %} ... {% endfor %}
%%     {% query Goal, ... %} ... {% endquery %}
%%     {# a comment #}
%%
%% The format is text (the default), html, xml or json. `if' has an
%% optional else; `for' puts a `loop' object in the body with index (1 up),
%% index0 (0 up), first, last and length; `range(N)', `range(A, B)' and
%% `range(A, B, Step)' are the list a loop counts over; `upper', `lower',
%% `trim', `length', `join', `default' and `str' are the functions an
%% expression can call.
%%
%% THIS LESSON SETS `double_quotes' TO ATOMS after its imports, because
%% cocolog's default is codes: under that default `"My Page"' is a list of
%% numbers, and the library follows library(json)'s rule that a bare LIST
%% IS A LIST -- `str("My Page")' is how text from a code list says so. A
%% file that leaves the default alone writes `'My Page'' or `str("...")';
%% this one reads `"..."' as an atom and says so once, at the top.
%%
%% THE OUTPUT IS AN ATOM. `template_file/3,4' reads the file with
%% read_file_to_codes/2 and renders it; `template_compile/2' parses once,
%% and a compiled template renders as often as its context changes.

:- use_module(library(template)).
:- set_prolog_flag(double_quotes, atom).

%% the program a query in the page calls
city(paris, 'France').
city(tokyo, 'Japan').
city(lima, 'Peru').

main :-
    lesson_values,
    lesson_records,
    lesson_escaping,
    lesson_conditions,
    lesson_loops,
    lesson_ranges,
    lesson_functions,
    lesson_queries,
    lesson_page,
    lesson_errors,
    format("done~n").

%% ---- values -----------------------------------------------------------
lesson_values :-
    format("~n-- text with holes~n"),
    render("<h1>Hello, World!</h1>", text, [], H1),
    must('a template with no tag is plain text', H1, "<h1>Hello, World!</h1>"),
    render("<h1>{{ title }}</h1>", html, [title="My Page"], H2),
    must('a name is replaced by its value', H2, "<h1>My Page</h1>"),
    render("<p>{{ name }} is {{ age }}</p>", html,
           [name="Alice", age=30], H3),
    must('several holes, and a number', H3, "<p>Alice is 30</p>"),
    render("{{ 2 + 3 * 4 }}", text, [], H4),
    must('an expression is computed', H4, "14"),
    render("{{ salutation }}!", text, [salutation="Hi"], H5),
    must('the text format adds nothing', H5, "Hi!").

%% ---- records ----------------------------------------------------------
lesson_records :-
    format("~n-- a context is a list of Name=Value, and a value can be a record~n"),
    render("<p>{{ user.name }} ({{ user.email }})</p>", html,
           [user=obj([name="Bob", email="bob@example.com"])], R1),
    must('a dotted path walks obj/1', R1, "<p>Bob (bob@example.com)</p>"),
    render("<p>{{ user.name }}</p>", html, [user=[name="Ann"]], R2),
    must('a plain pair list is a record too', R2, "<p>Ann</p>"),
    render("{% if user %}Hello, {{ user.name }}{% else %}Please log in{% endif %}",
           html, [], R3),
    must('a name the context lacks is FALSE in a condition', R3, "Please log in"),
    must_raise('...but a missing name in an output is an error',
               template_render("{{ missing }}", text, [], _),
               template_error(undefined(missing))).

%% ---- escaping ---------------------------------------------------------
lesson_escaping :-
    format("~n-- the format says how a value is escaped~n"),
    render("<p>{{ text }}</p>", html,
           [text="<script>alert('XSS')</script>"], E1),
    must('html escapes & < > " and not the apostrophe', E1,
         "<p>&lt;script&gt;alert('XSS')&lt;/script&gt;</p>"),
    render("<tag>{{ value }}</tag>", xml, [value="A & B < C"], E2),
    must('xml escapes the same three', E2, "<tag>A &amp; B &lt; C</tag>"),
    render('{"text": "{{ value }}"}', json, [value='He said "Hello"'], E3),
    must('json escapes the quote and the backslash', E3,
         '{"text": "He said \\"Hello\\""}'),
    render("{{ str([10]) }}", json, [], E4),
    must('a newline in json is the two characters \\n', E4, "\\n"),
    render("{{ text }}", text, [text="<b>bold</b>"], E5),
    must('the text format escapes nothing', E5, "<b>bold</b>").

%% ---- conditions -------------------------------------------------------
lesson_conditions :-
    format("~n-- if, else, and what counts as true~n"),
    render("{% if logged_in %}Welcome back!{% else %}Please log in.{% endif %}",
           text, [logged_in=true], C1),
    must('true takes the then branch', C1, "Welcome back!"),
    render("{% if logged_in %}Welcome back!{% else %}Please log in.{% endif %}",
           text, [logged_in=false], C2),
    must('false takes the else branch', C2, "Please log in."),
    render("{% if n > 3 %}large{% else %}small{% endif %}", text, [n=5], C3),
    must('a comparison decides', C3, "large"),
    render("{% if admin and active %}full{% else %}limited{% endif %}", text,
           [admin=true, active=false], C4),
    must('and needs both', C4, "limited"),
    render("{% if admin or owner %}full{% endif %}", text,
           [admin=false, owner=true], C5),
    must('or needs one', C5, "full"),
    render("{% if not banned %}allowed{% endif %}", text, [banned=false], C6),
    must('not flips the truth', C6, "allowed"),
    render("{% if user %}{% if user.admin %}admin{% else %}user{% endif %}{% endif %}",
           text, [user=obj([admin=true])], C7),
    must('conditions nest', C7, "admin").

%% ---- loops ------------------------------------------------------------
lesson_loops :-
    format("~n-- for, and the loop object~n"),
    render("<ul>{% for item in items %}<li>{{ item }}</li>{% endfor %}</ul>",
           text, [items=["Apple", "Banana", "Orange"]], L1),
    must('a list is walked in order', L1,
         "<ul><li>Apple</li><li>Banana</li><li>Orange</li></ul>"),
    render("{% for item in items %}{{ loop.index }}:{{ item }} {% endfor %}",
           text, [items=["First", "Second"]], L2),
    must('loop.index counts from one', L2, "1:First 2:Second "),
    render("{% for x in xs %}{% if loop.first %}[{% endif %}{{ x }}{% if loop.last %}]{% endif %}{% endfor %}",
           text, [xs=[a, b, c]], L3),
    must('loop.first and loop.last mark the ends', L3, "[abc]"),
    render("{% for row in rows %}({% for cell in row %}{{ cell }}{% endfor %}){% endfor %}",
           text, [rows=[[1, 2], [3, 4]]], L4),
    must('loops nest', L4, "(12)(34)").

%% ---- ranges -----------------------------------------------------------
lesson_ranges :-
    format("~n-- range: counting without a list in the context~n"),
    render("{% for i in range(3) %}{{ i }} {% endfor %}", text, [], R1),
    must('range(N) is 0 to N-1', R1, "0 1 2 "),
    render("{% for i in range(1, 4) %}{{ i }} {% endfor %}", text, [], R2),
    must('range(A, B) starts at A', R2, "1 2 3 "),
    render("{% for i in range(0, 10, 2) %}{{ i }} {% endfor %}", text, [], R3),
    must('range(A, B, Step) steps', R3, "0 2 4 6 8 "),
    render("{% for i in range(3, 0, -1) %}{{ i }} {% endfor %}", text, [], R4),
    must('a negative step counts down', R4, "3 2 1 "),
    render("{% for i in range(1, 6) %}{{ i }}{% if not loop.last %}, {% endif %}{% endfor %}",
           text, [], R5),
    must('a range and loop.last write a list', R5, "1, 2, 3, 4, 5").

%% ---- functions --------------------------------------------------------
lesson_functions :-
    format("~n-- the functions an expression can call~n"),
    render("{{ upper(name) }} {{ lower(name) }}", text, [name="Alice"], F1),
    must('upper and lower', F1, "ALICE alice"),
    render("{{ length(items) }}", text, [items=[1, 2, 3]], F2),
    must('length of a list', F2, "3"),
    render("{{ join(items, '-') }}", text, [items=[a, b, c]], F3),
    must('join', F3, "a-b-c"),
    render("{{ trim(text) }}", text, [text="  padded  "], F4),
    must('trim', F4, "padded"),
    render("{{ default(nickname, name) }}", text, [name="Alice"], F5),
    must('default takes the fallback when the name is missing', F5, "Alice"),
    render("{{ default(nickname, name) }}", text,
           [nickname="Al", name="Alice"], F6),
    must('...and the value when there is one', F6, "Al"),
    render("{{ upper(str([104, 105])) }}", text, [], F7),
    must('str/1 says a code list is text', F7, "HI").

%% ---- queries ----------------------------------------------------------
lesson_queries :-
    format("~n-- query: the program in the page~n"),
    render("{% query member(X, [1, 2, 3]) %}{{ X }}{% endquery %}", text, [], Q1),
    must('a query renders once per solution', Q1, "123"),
    render("<ul>{% query city(C, N) %}<li>{{ C }}: {{ N }}</li>{% endquery %}</ul>",
           text, [], Q2),
    must('a query calls the program''s own predicates', Q2,
         "<ul><li>paris: France</li><li>tokyo: Japan</li><li>lima: Peru</li></ul>"),
    render("{% query member(X, [1, 2, 3]), Y is X * 2 %}{{ Y }} {% endquery %}",
           text, [], Q3),
    must('is computes over a query variable', Q3, "2 4 6 "),
    render("{% query member(X, []) %}{{ X }}{% endquery %}", text, [], Q4),
    must('no solution renders nothing', Q4, ""),
    render("{% query member(_X, [a, b]) %}.{% endquery %}", text, [], Q5),
    must('an underscored variable stays out of the body', Q5, "..").

%% ---- a page -----------------------------------------------------------
lesson_page :-
    format("~n-- a compiled page, and a template from a file~n"),
    Page = "<!DOCTYPE html>
<html><head><title>{{ page.title }}</title></head>
<body>
<h1>{{ page.title }}</h1>
{% if user %}<p>Welcome, {{ user.name }}!</p>{% else %}<p>Please log in.</p>{% endif %}
<ul>{% query city(C, N) %}<li>{{ C }} - {{ N }}</li>{% endquery %}</ul>
<p>{% for i in range(1, 4) %}{{ i }}{% if not loop.last %}, {% endif %}{% endfor %}</p>
</body></html>",
    template_compile(Page, Compiled),
    render(Compiled, html, [page=obj([title="My Store"]),
                            user=obj([name="Alice"])], P1),
    text_has('the compiled page names its title', P1, "<h1>My Store</h1>"),
    text_has('...welcome the user', P1, "<p>Welcome, Alice!</p>"),
    text_has('...lists the cities by query', P1, "<li>paris - France</li>"),
    text_has('...and counts with a range', P1, "<p>1, 2, 3</p>"),
    render(Compiled, html, [page=obj([title="My Store"])], P2),
    text_has('the same compiled page, another context', P2,
             "<p>Please log in.</p>"),
    tmp_file(lesson52, File),
    atom_codes("<p>Hello, {{ name }}.</p>", FileCodes),
    write_file_from_codes(File, FileCodes),
    template_file(File, html, [name="Ann"], FromFile),
    must('a template read from a file', FromFile, "<p>Hello, Ann.</p>"),
    delete_file(File).

%% ---- errors -----------------------------------------------------------
lesson_errors :-
    format("~n-- a mistake is named, not turned into an empty page~n"),
    must_raise('an unknown function names its arity',
               template_render("{{ nope(1) }}", text, [], _),
               template_error(unknown_function(nope/1))),
    must_raise('a for wants a list',
               template_render("{% for x in 5 %}x{% endfor %}", text, [], _),
               template_error(not_a_list(5))),
    must_raise('an unclosed tag says which one',
               template_render("a {{ b", text, [], _),
               template_error(syntax(unclosed('{{')))),
    must_raise('an unknown format is refused before parsing',
               template_render("x", banana, [], _),
               template_error(unknown_format(banana))).

%% ---- the helpers every lesson here carries -----------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth the five duplicated lines.

render(Template, Format, Context, Output) :-
    template_render(Template, Format, Context, Output).

must_raise(What, Goal, Ball) :-
    (   catch(Goal, Caught, true)
    ->  ( var(Caught) -> Got = no_error ; Got = Caught )
    ;   Got = failed
    ),
    must(What, Got, Ball).

text_has(What, Text, Needle) :-
    (   atom_codes(Text, Codes),
        atom_codes(Needle, NeedleCodes),
        append(_, Rest, Codes),
        append(NeedleCodes, _, Rest)
    ->  format("     ok: ~w~n", [What])
    ;   format("     ~w: ~w does not hold ~w~n", [What, Text, Needle]),
        fail
    ).

%% `must/3' IS WHY THESE FILES ARE TESTS. Every claim a lesson makes is a
%% goal that has to hold: get it wrong and `main' FAILS, loudly, naming
%% both answers. A tutorial that prints whatever it computed is a tutorial
%% that goes quietly wrong the day the language changes underneath it.
must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
