%% library(template) -- text with holes, and the clauses that fill them.
%%
%% WHAT IS WORTH CHECKING HERE is not that a value finds its hole. It is
%% the two places a template engine is silently wrong rather than loudly
%% wrong:
%%
%%   * ESCAPING, because the failure is not an error -- it is a page that
%%     says something else at the far end, and the only way to see it is
%%     to put the awkward byte in and read what came out. All three
%%     formats are pinned byte for byte, the apostrophe included (HTML
%%     leaves it alone here);
%%   * REFUSALS, because the alternative to throwing is emitting a page
%%     with an empty hole in it. A missing name in a `if' is false; a
%%     missing name in an output is an error naming the name, and every
%%     syntax error names what it was reading.
%%
%% The rest are the laws a template engine has: a loop's order and its
%% `loop' object, a range's three arities, a query once per solution, a
%% compiled template independent of the context it renders with, and the
%% text conventions the language makes necessary -- a bare code list IS a
%% list, so `str/1' is how text says so, exactly as library(json) has it.
%% This file sets `double_quotes' to atoms AFTER its imports, so the
%% quoted text below is text; the code-list checks use codes explicitly.
%%
%%     cocolog -s test/template.pl        from the checkout root
%%
%% ONE PROCESS FOR ALL THE CHECKS; the stage is this file's own clauses.

:- use_module('test/prelude.pl').
:- use_module(library(template)).
:- set_prolog_flag(double_quotes, atom).

%% the program a query in the page calls
tpl_price(apple, 10).
tpl_price(pear, 20).

main :-
    rendering, paths, escaping, conditions, loops, ranges,
    functions, queries, compiled_and_files, refusals,
    checks_done.

rendered(Template, Format, Context, Got) :-
    answer(template_render(Template, Format, Context, Output), Output, Got).

rendered_file(File, Format, Context, Got) :-
    answer(template_file(File, Format, Context, Output), Output, Got).

%% ---- the surface ------------------------------------------------------
rendering :-
    section('the surface: text, a value, an atom out'),
    rendered('<h1>Hello</h1>', text, [], G01),
    check('text is copied through', G01, '<h1>Hello</h1>'),
    rendered('a {{ name }} b', text, [name=world], G02),
    check('a value takes its hole', G02, 'a world b'),
    rendered('2 + 3', text, [], G03),
    check('a template with no tag is text', G03, '2 + 3'),
    answer(( template_render('x', text, [], Out04),
              ( atom(Out04) -> A04 = atom ; A04 = not_an_atom ) ),
           A04, G04),
    check('the output is an atom', G04, atom),
    rendered([60, 98, 62], text, [], G05),
    check('a code list is a template too', G05, '<b>'),
    answer(template_string('hi {{ x }}', text, [x=there], Out06), Out06, G06),
    check('template_string/4', G06, 'hi there'),
    answer(template_string('{{ x }}', [x=y], Out07), Out07, G07),
    check('template_string/3 defaults to text', G07, 'y').

%% ---- context names ----------------------------------------------------
paths :-
    section('context names and dotted paths'),
    rendered('{{ user.name }} ({{ user.email }})', text,
             [user=obj([name='Bob', email='bob@example.com'])], G11),
    check('a dotted path walks obj/1', G11, 'Bob (bob@example.com)'),
    rendered('{{ user.name }}', text, [user=[name='Ann']], G12),
    check('a plain pair list is a record too', G12, 'Ann'),
    rendered('{{ loop.index }}', text, [loop=obj([index=2])], G13),
    check('a dotted path can start at a name the context carries', G13, '2'),
    rendered('{{ missing }}', text, [], G14),
    check('a missing name in an output is an error', G14,
          error(template_error(undefined(missing)))),
    rendered('{{ user.age }}', text, [user=obj([name='x'])], G15),
    check('a missing field names the field and the value', G15,
          error(template_error(no_field(age, obj([name=x]))))).

%% ---- escaping ---------------------------------------------------------
escaping :-
    section('what a format escapes'),
    rendered('<p>{{ text }}</p>', html, [text='<b>&"x"</b>'], G21),
    check('html escapes & < > "', G21,
          '<p>&lt;b&gt;&amp;&quot;x&quot;&lt;/b&gt;</p>'),
    rendered('<p>{{ text }}</p>', html, [text='don''t'], G22),
    check('...and leaves the apostrophe alone', G22, '<p>don''t</p>'),
    rendered('<tag>{{ value }}</tag>', xml, [value='A & B < C'], G23),
    check('xml escapes the same three', G23, '<tag>A &amp; B &lt; C</tag>'),
    rendered('"{{ text }}"', json, [text='a "b" \\ c'], G24),
    check('json escapes the quote and the backslash', G24,
          '"a \\"b\\" \\\\ c"'),
    rendered('{{ str([10]) }}{{ str([9]) }}{{ str([1]) }}', json, [], G25),
    check('json writes newline, tab and a control as escapes', G25,
          '\\n\\t\\u0001'),
    rendered('{{ text }}', text, [text='<b>'], G26),
    check('the text format escapes nothing', G26, '<b>'),
    rendered('café', text, [], G27),
    check('text past ASCII passes through', G27, 'café'),
    answer(findall(O28, template_render('<p>{{ x }}</p>', html,
                                        [x='<&'], O28), Os28), Os28, G28),
    check('a render has ONE answer, never an escapement per solution', G28,
          ['<p>&lt;&amp;</p>']).

%% ---- conditions -------------------------------------------------------
conditions :-
    section('if, else and the truth of a value'),
    rendered('{% if logged_in %}in{% else %}out{% endif %}', text,
             [logged_in=true], G31),
    check('true takes the then branch', G31, 'in'),
    rendered('{% if logged_in %}in{% else %}out{% endif %}', text,
             [logged_in=false], G32),
    check('false takes the else branch', G32, 'out'),
    rendered('{% if user %}in{% else %}out{% endif %}', text, [], G33),
    check('a name the context lacks is false in a condition', G33, 'out'),
    rendered('{% if n %}in{% else %}out{% endif %}', text, [n=0], G34),
    check('zero is false', G34, 'out'),
    rendered('{% if xs %}in{% else %}out{% endif %}', text, [xs=[]], G35),
    check('the empty list is false', G35, 'out'),
    rendered('{% if xs %}in{% else %}out{% endif %}', text, [xs=[a]], G36),
    check('a nonempty list is true', G36, 'in'),
    rendered('{% if not missing %}no{% endif %}', text, [], G37),
    check('not of a missing name is true', G37, 'no'),
    rendered('{% if n > 3 %}big{% else %}small{% endif %}', text, [n=5], G38),
    check('a comparison decides', G38, 'big'),
    rendered('{% if a and b %}both{% else %}not{% endif %}', text,
             [a=true, b=false], G39),
    check('and is and', G39, 'not'),
    rendered('{% if a or b %}either{% endif %}', text, [a=false, b=true], G310),
    check('or is or', G310, 'either'),
    rendered('{{ 2 + 3 * 4 }} {{ (2 + 3) * 4 }}', text, [], G311),
    check('arithmetic keeps its precedence', G311, '14 20'),
    rendered('{{ 1 == 1.0 }} {{ 2 != 3 }}', text, [], G312),
    check('numbers compare by value', G312, 'true true'),
    rendered('{% if 1 < 2 and 2 >= 2 %}yes{% endif %}', text, [], G313),
    check('every comparison holds', G313, 'yes').

%% ---- loops ------------------------------------------------------------
loops :-
    section('for and the loop object'),
    rendered('{% for x in xs %}{{ x }}{% endfor %}', text, [xs=[a,b,c]], G41),
    check('a list is walked in order', G41, 'abc'),
    rendered('{% for x in xs %}{{ loop.index }}:{{ x }} {% endfor %}', text,
             [xs=[a,b]], G42),
    check('loop.index counts from one', G42, '1:a 2:b '),
    rendered('{% for x in xs %}{{ loop.index0 }}{% endfor %}', text,
             [xs=[a,b]], G43),
    check('loop.index0 counts from zero', G43, '01'),
    rendered('{% for x in xs %}{% if loop.first %}F{% endif %}{{ x }}{% if loop.last %}L{% endif %}{% endfor %}',
             text, [xs=[a,b]], G44),
    check('first and last are where they say', G44, 'FabL'),
    rendered('{% for x in xs %}{{ loop.length }}{% endfor %}', text,
             [xs=[a,b]], G45),
    check('length is the count', G45, '22'),
    rendered('{% for row in rows %}[{% for cell in row %}{{ cell }}{% endfor %}]{% endfor %}',
             text, [rows=[[1,2],[3,4]]], G46),
    check('loops nest', G46, '[12][34]'),
    rendered('{% for item in items %}{{ item.name }}{% endfor %}', text,
             [items=[obj([name='a']), obj([name='b'])]], G47),
    check('a loop variable can be a record', G47, 'ab'),
    rendered('{% for x in 5 %}x{% endfor %}', text, [], G48),
    check('a for wants a list', G48, error(template_error(not_a_list(5)))).

%% ---- ranges -----------------------------------------------------------
ranges :-
    section('range'),
    rendered('{% for i in range(3) %}{{ i }}{% endfor %}', text, [], G51),
    check('range(N) is 0..N-1', G51, '012'),
    rendered('{% for i in range(1, 4) %}{{ i }}{% endfor %}', text, [], G52),
    check('range(A, B) starts at A', G52, '123'),
    rendered('{% for i in range(0, 10, 2) %}{{ i }}{% endfor %}', text, [], G53),
    check('range(A, B, Step) steps', G53, '02468'),
    rendered('{% for i in range(3, 0, -1) %}{{ i }}{% endfor %}', text, [], G54),
    check('a negative step counts down', G54, '321'),
    rendered('{% for i in range(2, 2) %}{{ i }}{% endfor %}', text, [], G55),
    check('an empty range renders nothing', G55, ''),
    rendered('{% for i in range(0, 4, 0) %}{{ i }}{% endfor %}', text, [], G56),
    check('a zero step is an error', G56, error(template_error(zero_step))),
    rendered('{{ range(1, 4) }}', text, [], G57),
    check('a range outside a loop is a list', G57, '[1,2,3]'),
    rendered('{% for i in range(1.5) %}{{ i }}{% endfor %}', text, [], G58),
    check('a range wants integers', G58,
          error(template_error(not_an_integer(1.5)))).

%% ---- functions --------------------------------------------------------
functions :-
    section('the functions an expression can call'),
    rendered('{{ upper(name) }} {{ lower(name) }}', text, [name='Alice'], G61),
    check('upper and lower', G61, 'ALICE alice'),
    rendered('{{ length(xs) }} {{ length(name) }} {{ length(str([1,2])) }}',
             text, [xs=[a,b,c], name=four], G62),
    check('length of a list, an atom and a str', G62, '3 4 2'),
    rendered('{{ join(xs, "-") }}', text, [xs=[a,b,c]], G63),
    check('join', G63, 'a-b-c'),
    rendered('{{ trim(text) }}', text, [text='  hi  '], G64),
    check('trim', G64, 'hi'),
    rendered('{{ default(missing, "fallback") }} {{ default(name, "fallback") }}',
             text, [name=given], G65),
    check('default on a missing name and a present one', G65, 'fallback given'),
    rendered('{{ upper(str([104,105])) }}', text, [], G66),
    check('str/1 says a code list is text', G66, 'HI'),
    rendered('{{ nope(1) }}', text, [], G67),
    check('an unknown function names its arity', G67,
          error(template_error(unknown_function(nope/1)))),
    rendered('{{ upper(xs) }}', text, [xs=[a]], G68),
    check('a text function refuses a list', G68,
          error(template_error(not_text([a])))),
    rendered('{{ 10 / 4 }}', text, [], G69),
    check('division is arithmetic', G69, '2.5').

%% ---- queries ----------------------------------------------------------
queries :-
    section('query: the program in the page'),
    rendered('{% query member(X, [1, 2, 3]) %}{{ X }}{% endquery %}',
             text, [], G71),
    check('a query renders once per solution', G71, '123'),
    rendered('{% query tpl_price(Item, Price) %}{{ Item }}={{ Price }} {% endquery %}',
             text, [], G72),
    check('a query calls the program''s own predicates', G72,
          'apple=10 pear=20 '),
    rendered('{% query member(X, [1, 2, 3]), Y is X * 2 %}{{ Y }} {% endquery %}',
             text, [], G73),
    check('is computes over a query variable', G73, '2 4 6 '),
    rendered('{% query member(X, []) %}{{ X }}{% endquery %}', text, [], G74),
    check('no solution renders nothing', G74, ''),
    rendered('{% query member(_X, [a, b]) %}x{% endquery %}', text, [], G75),
    check('an underscored variable is not put in the context', G75, 'xx'),
    rendered('{% query tpl_price(I, P) %}{{ I }}{% endquery %}',
             text, [I=outer], G76),
    check('a query variable shadows a context name', G76, 'applepear'),
    rendered('{% query var(X) %}{{ X }}{% endquery %}', text, [], G77),
    check('an unbound query variable is not in the body', G77,
          error(template_error(undefined('X')))),
    rendered('{% query %}x{% endquery %}', text, [], G78),
    check('a query tag with no goal is refused', G78,
          error(template_error(syntax(wants_a_query)))).

%% ---- compiled templates and files -------------------------------------
compiled_and_files :-
    section('compile once, render often; and a file'),
    template_compile('{{ x }}', T80),
    rendered(T80, text, [x=one], G80),
    rendered(T80, text, [x=two], G81),
    check('a compiled template renders with each context', G80-G81, one-two),
    tmp_file(cocolog_template_test, File82),
    atom_codes('Hi {{ name }}', Codes82),
    write_file_from_codes(File82, Codes82),
    rendered_file(File82, text, [name='Ann'], G82),
    check('template_file/4 reads and renders', G82, 'Hi Ann'),
    answer(template_file(File82, [name='Bo'], Out83), Out83, G83),
    check('template_file/3 defaults to text', G83, 'Hi Bo'),
    delete_file(File82).

%% ---- refusals ---------------------------------------------------------
refusals :-
    section('what is refused, and by name'),
    rendered('x', banana, [], G91),
    check('an unknown format', G91,
          error(template_error(unknown_format(banana)))),
    rendered('a {{ b', text, [], G92),
    check('an unclosed tag', G92,
          error(template_error(syntax(unclosed('{{'))))),
    rendered('a {% if true %}b', text, [], G93),
    check('an unclosed if', G93, error(template_error(syntax(unclosed(if))))),
    rendered('{% endfor %}', text, [], G94),
    check('a closing tag with no opening', G94,
          error(template_error(syntax(unexpected_tag(endfor))))),
    rendered('{{ 1 + }}', text, [], G95),
    check('an expression that ends early', G95,
          error(template_error(syntax(wants_an_expression)))),
    rendered(42, text, [], G96),
    check('a template that is not text', G96,
          error(template_error(not_text(42)))),
    rendered('{# note', text, [], G97),
    check('an unclosed comment', G97,
          error(template_error(syntax(unclosed('{#'))))),
    rendered('{% for x items %}x{% endfor %}', text, [], G98),
    check('a for without in', G98,
          error(template_error(syntax(for_wants_in)))),
    rendered('a{# note #}b', text, [], G99),
    check('a comment renders nothing', G99, 'ab'),
    rendered('a { b } c', text, [], G910),
    check('a lone brace is text', G910, 'a { b } c').
