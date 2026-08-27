%% LIBRARY 13 -- library(xml): an element tree, and back
%%
%%     ./cocolog run tutorials/library/13-xml.pl main
%%
%% TIER 2: `use_module(library(xml))'. Clauses only.
%%
%%     xml_codes(+Tree, -Codes)     xml_parse(+Text, -Element)
%%     xml_atom(+Tree, -Atom)       xml_parse(+Text, -Element, +Options)
%%     xml_write(+Tree)             xml_input(-Element)//
%%     xml_content(+Node)//
%%
%% THE TREE IS SWI's, so a document read by any sgml-shaped parser is one
%% this can write back:
%%
%%     element(Name, [Name=Value, ...], Children)
%%
%% and a child is an element, an atom or number (text), `cdata/1',
%% `comment/1', `pi/1', or `raw/1' -- the fire escape, written verbatim.
%%
%% ---- THERE IS NO DTD, AND THAT IS THE XXE ANSWER ---------------------
%%
%% The parser SKIPS the DOCTYPE -- internal subset and all -- and has no
%% code that could open a file or a socket. The whole external-entity
%% family is structurally impossible rather than defended against. An
%% entity a DOCTYPE declared is therefore never defined, so `&whatever;'
%% is an error naming it: the parser cannot know what it expands to and
%% will not guess.
%%
%% INDENTING ONLY WHERE IT CANNOT CHANGE THE DOCUMENT. Whitespace between
%% elements is CONTENT in XML, so `indent(N)' breaks up an element whose
%% children are ALL elements and leaves MIXED content on one line.

:- use_module(library(xml)).

main :-
    format("~n-- writing~n"),
    xml_atom(element(p, [], ['a < b & c']), A1),
    must('text is escaped, markup is not', A1, '<p>a &lt; b &amp; c</p>'),
    xml_atom(element(br, [], []), A2),
    must('an empty element closes itself', A2, '<br/>'),
    xml_atom(element(a, [href='x?a=1&b=2'], ['go']), A3),
    must('and an attribute value too', A3, '<a href="x?a=1&amp;b=2">go</a>'),
    xml_atom([element(a, [], []), element(b, [], [])], A4),
    must('a list at the TOP is a fragment', A4, '<a/><b/>'),

    format("~n-- a child is never a list; str/1 is how you mean text~n"),
    xml_atom(element(p, [], [str("hi")]), A5),
    must('str/1 from codes', A5, '<p>hi</p>'),
    (   catch(xml_atom(element(p, [], ["hi"]), _), error(type_error(_, _), _), true)
    ->  L = refused ; L = accepted ),
    must('a bare code list among the children', L, refused),

    format("~n-- indenting: element-only content only~n"),
    xml_atom(element(r, [], [element(a, [], []), element(b, [], [])]), P1,
             [indent(2)]),
    atomic_list_concat(Ls1, '\n', P1), length(Ls1, N1),
    must('all-element children are broken up', N1, 4),
    xml_atom(element(m, [], [element(a, [], []), 'text']), P2, [indent(2)]),
    must('MIXED content stays on one line', P2, '<m><a/>text</m>'),
    format("   Because a newline between two elements is a whitespace~n"),
    format("   node a schema-aware reader ignores, and a newline beside~n"),
    format("   text is DATA. The library will not edit your document.~n"),

    format("~n-- the header and a doctype, when you want them~n"),
    xml_atom(element(r, [], []), P3, [header(true)]),
    sub_atom(P3, 0, 5, _, Head),
    must('header(true)', Head, '<?xml'),

    format("~n-- the two payloads that can end their own container~n"),
    xml_atom(element(d, [], [cdata('a ]]> b')]), C1),
    must(']]> inside CDATA is SPLIT, not refused', C1,
         '<d><![CDATA[a ]]]]><![CDATA[> b]]></d>'),
    (   catch(xml_atom(element(d, [], [comment('a--b')]), _),
              error(domain_error(_, _), _), true)
    ->  C2 = refused ; C2 = accepted ),
    must('-- inside a comment IS refused', C2, refused),
    format("   Because XML 1.0 forbids it outright with no escape, and~n"),
    format("   `]]>' has one: end the section and reopen it. Repair what~n"),
    format("   can be repaired; refuse what cannot.~n"),

    format("~n-- reading~n"),
    xml_parse('<a href="x">go</a>', T1),
    must('xml_parse/2 answers the ROOT element', T1,
         element(a, [href=x], [go])),
    xml_parse('<a t="1&amp;2">a &lt; b</a>', T2),
    must('entities are resolved', T2, element(a, [t='1&2'], ['a < b'])),
    xml_parse('<p>&#65;&#x42;</p>', T3),
    must('numeric references, either spelling', T3, element(p, [], ['AB'])),
    xml_parse('<d>x<![CDATA[a<b]]>y</d>', T4),
    must('CDATA comes back as TEXT, merged with its neighbours', T4,
         element(d, [], ['xa<by'])),
    format("   Because to XML that is what it IS: a spelling of character~n"),
    format("   data, not a kind of node.~n"),

    format("~n-- the prologue is skipped, and so is its DOCTYPE~n"),
    xml_parse('<?xml version="1.0"?><!DOCTYPE r [<!ENTITY e "x">]><r/>', T5),
    must('a declaration and an internal subset', T5, element(r, [], [])),
    (   catch(xml_parse('<!DOCTYPE r [<!ENTITY e "x">]><r>&e;</r>', _),
              error(syntax_error(_), _), true)
    ->  X = refused ; X = accepted ),
    must('and the entity it declared is STILL unknown', X, refused),
    format("   No DTD is read, so no entity but the five predefined~n"),
    format("   exists, and nothing here can open a file or a socket.~n"),

    format("~n-- space(remove), and what it will NOT remove~n"),
    xml_parse('<r>\n  <a/>\n</r>', T6, [space(remove)]),
    must('an indented document comes back as its tree', T6,
         element(r, [], [element(a, [], [])])),
    xml_parse('<p>  hi  </p>', T7, [space(remove)]),
    must('but text with anything else in it is untouched', T7,
         element(p, [], ['  hi  '])),

    format("~n-- what it refuses, and what it names~n"),
    catch(xml_parse('<a></b>', _), error(syntax_error(W1), _), true),
    must('a mismatched end tag names BOTH', W1, mismatched_end_tag(a, b)),
    catch(xml_parse('<a><b></a>', _), error(syntax_error(W2), _), true),
    must('...and an unclosed element', W2, mismatched_end_tag(b, a)),

    format("~n-- THE ROUND TRIP~n"),
    Tree = element(r, [a='1&2'], [element(c, [], ['x < y']), 'tail']),
    xml_atom(Tree, Once), xml_parse(Once, Back), xml_atom(Back, Twice),
    must('write, read, write again', Once, Twice),
    format("~ndone~n").

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
