%% LIBRARY 14 -- library(html): a page as a term
%%
%%     ./cocolog run tutorials/library/14-html.pl main
%%
%% TIER 2: `use_module(library(html))'. Clauses only, and it STANDS ON
%% library(xml) by name -- `xml_escaped//1', `xml_text_codes/2' -- rather
%% than by copy. cocolog has one namespace, which is what makes that work;
%% a private copy of an escaper is how two escapers end up disagreeing
%% about the apostrophe.
%%
%%     html_codes(+Tree, -Codes)    html_parse(+Text, -Nodes)
%%     html_atom(+Tree, -Atom)      html_parse(+Text, -Nodes, +Options)
%%     html_write(+Tree)            html_input(-Nodes)//
%%     html_content(+Node)//
%%
%% IT ANSWERS A LIST where `xml_parse/2' answers one element, because XML
%% requires exactly one root and HTML does not -- and a list is what
%% `html_codes/2' takes at the top, so the two compose with no wrapper.
%%
%% ---- WHERE IT DIFFERS FROM XML, AND WHY ------------------------------
%%
%%     <br> not <br/>       void elements close by being themselves, and
%%                          giving one children is an error
%%     `--' in a comment    legal here, refused in XML: HTML5's tokenizer
%%                          ends on `-->' and nothing else
%%     no `indent' option   whitespace between two INLINE elements is a
%%                          rendered space, so an indenter here would be
%%                          a renderer that quietly edits
%%     an unknown entity    comes back as TEXT, where XML refuses it --
%%                          which is what makes `AT&T' render as `AT&T'
%%     a bare attribute     `checked' is HTML's minimised form
%%
%% ---- IT IS NOT AN HTML5 TREE BUILDER, and says so --------------------
%%
%% No implied <html>/<head>/<body>, no foster parenting, no adoption
%% agency. A half tree builder is worse than none: it produces a tree that
%% looks right and quietly is not the one a browser built. What it DOES
%% handle is the part that differs in documents people write -- void
%% elements, raw text, optional end tags, misnested end tags, case, and a
%% `<' that begins no tag.

:- use_module(library(html)).

main :-
    format("~n-- writing~n"),
    html_atom(element(p, [class=note], ['a < b']), A1),
    must('text and attributes escaped', A1, '<p class="note">a &lt; b</p>'),
    html_atom(element(br, [], []), A2),
    must('a void element does NOT self-close', A2, '<br>'),
    html_atom(element(input, [type=checkbox, checked], []), A3),
    must('a bare attribute is the minimised form', A3,
         '<input type="checkbox" checked>'),
    (   catch(html_atom(element(br, [], ['x']), _), error(domain_error(_, _), _), true)
    ->  V = refused ; V = accepted ),
    must('giving a void element children', V, refused),

    format("~n-- a whole page, with its doctype~n"),
    html_atom([element(html, [],
                [element(body, [], [element(p, [], ['hi'])])])],
              Page, [doctype(true)]),
    must('doctype(true)', Page,
         '<!DOCTYPE html>\n<html><body><p>hi</p></body></html>'),

    format("~n-- raw text, and the one security-shaped check in these three~n"),
    html_atom(element(script, [], [str("if (a < b) f();")]), S1),
    must('a script is NOT escaped', S1, '<script>if (a < b) f();</script>'),
    format("   Because `a < b' must reach the JavaScript parser as~n"),
    format("   `a < b'. Escaping would break every script ever written.~n"),
    (   catch(html_atom(element(script, [], [str("x = '</script>'")]), _),
              error(domain_error(_, _), _), true)
    ->  S2 = refused ; S2 = accepted ),
    must('but a </script inside one', S2, refused),
    format("   That is the one place escaping is NOT the answer, so the~n"),
    format("   end tag is the whole risk -- and it is checked by name,~n"),
    format("   case-insensitively, because the tokenizer is.~n"),

    format("~n-- reading~n"),
    html_parse('<DIV CLASS="x">hi</DIV>', T1),
    must('names are downcased', T1, [element(div, [class=x], [hi])]),
    html_parse('<input type=checkbox checked>', T2),
    must('unquoted and bare attributes', T2,
         [element(input, [type=checkbox, checked], [])]),
    html_parse('<p>a < b</p>', T3),
    must('a < that begins no tag is TEXT', T3, [element(p, [], ['a < b'])]),
    html_parse('<p>AT&T</p>', T4),
    must('and an unknown entity is text too', T4,
         [element(p, [], ['AT&T'])]),
    html_parse('<p>a &amp; b</p>', T5),
    must('a known one is still resolved', T5, [element(p, [], ['a & b'])]),

    format("~n-- the tags people do not close~n"),
    html_parse('<ul><li>one<li>two</ul>', T6),
    must('<li> closes an open <li>', T6,
         [element(ul, [], [element(li, [], [one]), element(li, [], [two])])]),
    html_parse('<p>one<p>two', T7),
    must('a block element closes an open paragraph', T7,
         [element(p, [], [one]), element(p, [], [two])]),
    html_parse('<table><tr><td>1<td>2</table>', T8),
    must('<td> and <tr> close each other', T8,
         [element(table, [],
            [element(tr, [], [element(td, [], ['1']), element(td, [], ['2'])])])]),
    html_parse('<div><span>x</div>', T9),
    must('a misnested end tag closes what it NAMES', T9,
         [element(div, [], [element(span, [], [x])])]),
    html_parse('<p>x</p></div><p>y</p>', T10),
    must('and a stray end tag is discarded', T10,
         [element(p, [], [x]), element(p, [], [y])]),

    format("~n-- script and textarea, read the way they were written~n"),
    html_parse('<script>if (a < b) f("</b>");</script>', T11),
    must('a script is read verbatim', T11,
         [element(script, [], ['if (a < b) f("</b>");'])]),
    html_parse('<textarea>a &amp; b</textarea>', T12),
    must('textarea resolves entities but nests nothing', T12,
         [element(textarea, [], ['a & b'])]),

    format("~n-- THE ROUND TRIP~n"),
    Tree = [element(html, [],
             [element(body, [lang=en],
               [element(p, [], ['a < b & c']), element(br, [], [])])])],
    html_atom(Tree, Once), html_parse(Once, Back), html_atom(Back, Twice),
    must('write, read, write again', Once, Twice),

    format("~n-- and JSON inside a page, which is where the two meet~n"),
    format("   See tutorials/library/12-json: the writer refuses a body~n"),
    format("   that could close the script, so anything that got written~n"),
    format("   can be read back.~n~n"),
    format("done~n").

%% ---- the two helpers every lesson here carries ------------------------
%% REPEATED ON PURPOSE, in every file. A tutorial you can copy anywhere and
%% run is worth six duplicated lines; a tutorial that needs a support
%% library beside it is a tutorial that stops working the moment it is
%% moved.
show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

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
