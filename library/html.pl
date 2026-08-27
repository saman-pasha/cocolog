%% library(html) -- an element tree as HTML text.
%%
%% EVERY PREDICATE IS `html_'-PREFIXED, helpers and nonterminals included,
%% for the reason library(http) spells out at length: cocolog has ONE
%% namespace, a library's private names are everybody's, and the first
%% clash is silent.
%%
%% IT STANDS ON library(xml) AND SAYS SO. The tree is the same
%% `element(Name, Attributes, Children)', and the escaping, the text
%% extraction and the NUL check are `xml_escaped//1', `xml_text_codes/2'
%% and `xml_no_nul/2' -- called by name, not copied. That is what one
%% namespace is FOR: the thing a second library needs is already loaded
%% and already tested, and a private copy of an escaper is how two
%% escapers end up disagreeing about the apostrophe.
%%
%% WHAT IS NOT THE SAME, and each of the four is a real difference between
%% the two languages rather than a convenience:
%%
%%   VOID ELEMENTS CLOSE THEMSELVES BY BEING THEMSELVES. `<br>' is a
%%   complete element in HTML and `<br/>' is the XML spelling of it; both
%%   parse, but the trailing slash means nothing in HTML and reads as a
%%   mistake. The fifteen void elements are listed below, and giving one
%%   children is an ERROR -- `<br>text</br>' is not markup that means
%%   anything, and a serialiser that wrote it would be inventing a shape
%%   the parser will silently rearrange.
%%
%%   `script' AND `style' HOLD RAW TEXT. Their content is not escaped --
%%   escaping it would break every script ever written, because `a < b'
%%   must reach the JavaScript parser as `a < b'. The one thing that CAN
%%   go wrong there is the end tag: a `</script' anywhere inside, in any
%%   case, ends the element early and turns the rest of the script into
%%   markup, which is the shape of a stored-XSS bug. So that is refused,
%%   by name, at the call site. It is the only place in these three
%%   libraries where a security-shaped hazard is checked, because it is the
%%   only place where correct escaping is *not* the answer.
%%
%%   THERE IS NO `indent' OPTION, and that is deliberate rather than
%%   unfinished. library(xml) will indent an element whose children are all
%%   elements, because a whitespace node between elements is what a
%%   schema-aware reader already ignores. HTML has no such rule: whitespace
%%   between two inline elements is a RENDERED SPACE, so
%%   `<span>a</span><span>b</span>' and the same thing across two lines are
%%   different pages. An indenter here would be a renderer that quietly
%%   edits. If you want readable output, put the newlines in as content,
%%   where you can see them.
%%
%%   A BARE ATTRIBUTE IS LEGAL. `checked' with no value is HTML's
%%   minimised form and means exactly what `checked="checked"' means;
%%   library(xml) refuses it because XML has no minimised form at all.
%%
%% ---- THE TREE --------------------------------------------------------
%%
%%     element(Name, Attributes, Children)
%%
%%     Attributes  `Name=Value', `Name-Value', or a bare `Name'
%%     Children    an atom or number  text, escaped
%%                 element(_, _, _)   a nested element
%%                 str(Text)          text from a CODE LIST -- see below
%%                 comment(Text)      <!-- Text -->
%%                 raw(Text)          verbatim, NOT escaped: the fire escape
%%
%% A CHILD IS NEVER A LIST, for the reason library(xml) gives at length:
%% cocolog has no string type, `"hello"' IS a list of codes, and guessing
%% is how `element(p, [], ["hello"])' silently becomes a row of numbers.
%% `str/1' is how you write text you are holding as codes. A list at the
%% TOP is a fragment, because a document has no text at its outermost
%% level and there the reading is unambiguous.
%%
%% `cdata/1' IS REFUSED rather than passed through. HTML5 has no CDATA
%% sections outside foreign content, so `<![CDATA[...]]>' in an HTML
%% document is parsed as a bogus comment and its content vanishes. A term
%% written for library(xml) and handed to this one gets an error naming
%% the node, which is the moment to notice.
%%
%% ---- OPTIONS ---------------------------------------------------------
%%
%%     doctype(true)    <!DOCTYPE html> in front
%%     doctype(Text)    <!DOCTYPE Text>, for a legacy one

:- use_module(library(lists)).
:- use_module(library(xml)).

%% ---- the entry points ------------------------------------------------

%% html_codes(+Tree, -Codes) is det.
html_codes(Tree, Codes) :- html_codes(Tree, Codes, []).

%% html_codes(+Tree, -Codes, +Options) is det.
html_codes(Tree, Codes, Options) :-
    phrase(html_document(Tree, Options), Codes).

%% html_atom(+Tree, -Atom) is det.
html_atom(Tree, Atom) :- html_atom(Tree, Atom, []).

html_atom(Tree, Atom, Options) :-
    html_codes(Tree, Codes, Options),
    atom_codes(Atom, Codes).

%% html_write(+Tree) is det.
html_write(Tree) :- html_write(Tree, []).

html_write(Tree, Options) :-
    html_codes(Tree, Codes, Options),
    format("~s", [Codes]).

%% html_content(+Node)// is det.
%% One node, or a list of them, for a caller already building codes with a
%% grammar of its own -- a page assembling its own body, most often.
html_content(Node) --> html_fragment(Node).

%% ---- the document ----------------------------------------------------

html_document(Tree, Options) -->
    html_doctype(Options),
    html_fragment(Tree).

html_doctype(Options) --> { memberchk(doctype(D), Options), D \== false }, !,
    { ( D == true -> Text = html ; Text = D ) },
    "<!DOCTYPE ", { xml_text_codes(Text, Cs) }, xml_raw(Cs), ">\n".
html_doctype(_) --> [].

html_fragment(V) --> { var(V) }, !,
    { throw(error(instantiation_error, html_codes/2)) }.
html_fragment([]) --> !, [].
html_fragment([K|Ks]) --> !, html_nodes([K|Ks]).
html_fragment(Node) --> html_node(Node).

html_nodes([]) --> [].
html_nodes([K|Ks]) --> html_node(K), html_nodes(Ks).

%% ---- one node --------------------------------------------------------

html_node(V) --> { var(V) }, !,
    { throw(error(instantiation_error, html_codes/2)) }.
html_node(element(Name, Attrs, Kids)) --> !, html_element(Name, Attrs, Kids).
html_node(comment(Text)) --> !, html_comment(Text).
html_node(raw(Text)) --> !, { xml_text_codes(Text, Cs) }, xml_raw(Cs).
html_node(str(Text)) --> !, { xml_text_codes(Text, Cs) }, xml_escaped(Cs).
html_node(L) --> { is_list(L) }, !,
    { throw(error(type_error(html_node, L), html_codes/2)) }.
html_node(Text) --> { atomic(Text) }, !,
    { xml_text_codes(Text, Cs) }, xml_escaped(Cs).
html_node(T) --> { throw(error(type_error(html_node, T), html_codes/2)) }.

%% ---- an element ------------------------------------------------------

html_element(Name, Attrs, Kids) --> { html_void(Name) }, !,
    { (   Kids == []
      ->  true
      ;   throw(error(domain_error(html_empty_content, element(Name, Attrs, Kids)),
                      html_codes/2))
      ) },
    "<", html_name(Name), html_attributes(Attrs), ">".
html_element(Name, Attrs, Kids) --> { html_raw_text(Name) }, !,
    "<", html_name(Name), html_attributes(Attrs), ">",
    html_script_body(Name, Kids),
    "</", html_name(Name), ">".
html_element(Name, Attrs, Kids) -->
    "<", html_name(Name), html_attributes(Attrs), ">",
    html_nodes(Kids),
    "</", html_name(Name), ">".

html_name(Name) --> { xml_text_codes(Name, Cs) }, xml_raw(Cs).

%% THE FIFTEEN, from the HTML Living Standard's own list. `<param>' and
%% `<track>' are in it although both are deprecated: a document being
%% written back out should come back as it went in.
html_void(area).
html_void(base).
html_void(br).
html_void(col).
html_void(embed).
html_void(hr).
html_void(img).
html_void(input).
html_void(link).
html_void(meta).
html_void(param).
html_void(source).
html_void(track).
html_void(wbr).

html_raw_text(script).
html_raw_text(style).

%% ---- raw text, and the one check that is not escaping ----------------
%%
%% THE CONTENT GOES OUT UNTOUCHED and it has to: escaping `<' inside a
%% script would hand the JavaScript parser `&lt;'. The end tag is the whole
%% risk, and `</script' ANYWHERE in the text ends the element -- the HTML
%% tokenizer does not care whether it is inside a string or a comment, and
%% `var s = "</script>"' is the classic way a page tears in half.
%%
%% IT IS CASE-INSENSITIVE because the tokenizer is: `</ScRiPt' closes it
%% just as well, so a check that only looked for lower case would be a
%% check that can be walked around.
html_script_body(Name, Kids) -->
    { html_script_codes(Kids, Cs),
      atom_codes(Name, NameCs),
      (   html_has_end_tag(Cs, NameCs)
      ->  throw(error(domain_error(html_raw_text, Name), html_codes/2))
      ;   true
      ) },
    xml_raw(Cs).

html_script_codes([], []) :- !.
html_script_codes([One], Cs) :- !, xml_text_codes(One, Cs).
html_script_codes(Kids, _) :-
    throw(error(domain_error(html_raw_text_content, Kids), html_codes/2)).

html_has_end_tag([0'<, 0'/|Rest], NameCs) :- html_name_prefix(NameCs, Rest), !.
html_has_end_tag([_|Cs], NameCs) :- html_has_end_tag(Cs, NameCs).

html_name_prefix([], _).
html_name_prefix([N|Ns], [C|Cs]) :-
    html_downcase(N, D),
    html_downcase(C, D),
    html_name_prefix(Ns, Cs).

html_downcase(C, D) :- C >= 0'A, C =< 0'Z, !, D is C + 32.
html_downcase(C, C).

%% ---- attributes ------------------------------------------------------

html_attributes([]) --> [].
html_attributes([A|As]) --> " ", html_attribute(A), html_attributes(As).

html_attribute(V) --> { var(V) }, !,
    { throw(error(instantiation_error, html_codes/2)) }.
html_attribute(Name=Value) --> !, html_attribute_pair(Name, Value).
html_attribute(Name-Value) --> !, html_attribute_pair(Name, Value).
%% THE MINIMISED FORM, and the reason it is last: an atom matches the two
%% clauses above only if it is `=' or `-' applied to something, which it is
%% not, so a bare `checked' falls through to here and nothing else does.
html_attribute(Name) --> { atom(Name) }, !, html_name(Name).
html_attribute(A) --> { throw(error(type_error(html_attribute, A), html_codes/2)) }.

html_attribute_pair(Name, Value) -->
    html_name(Name), "=\"",
    { xml_text_codes(Value, Cs) }, xml_escaped_attr(Cs),
    "\"".

%% ---- comments --------------------------------------------------------
%%
%% `--' IS ALLOWED HERE and refused by library(xml). HTML5's comment
%% tokenizer ends on `-->' and nothing else, so a double hyphen inside one
%% is ordinary text; XML 1.0 forbids it outright. What IS refused is a
%% `-->' in the payload, for the same reason as `</script' above: it ends
%% the comment early and the rest becomes markup.
html_comment(Text) -->
    { xml_text_codes(Text, Cs),
      (   html_has_comment_end(Cs)
      ->  throw(error(domain_error(html_comment, Text), html_codes/2))
      ;   true
      ) },
    "<!--", xml_raw(Cs), "-->".

html_has_comment_end([0'-, 0'-, 0'>|_]) :- !.
html_has_comment_end([_|Cs]) :- html_has_comment_end(Cs).
