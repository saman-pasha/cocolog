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
%%   mistake. The fourteen void elements are listed below, and giving one
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

%% THE ONLY IMPORT, because library(xml) is the only thing here that has to
%% be loaded. `lists' is TIER 1 -- registered before the first goal runs --
%% so `append/3' and `memberchk/2' are already there, and asking for them
%% is a directive that does nothing. library(json) and library(xml) import
%% nothing at all for the same reason.
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

%% THE FOURTEEN, from the HTML Living Standard's own list. `<param>' and
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

%% ======================================================================
%% ---- READING: HTML text as an element tree ---------------------------
%% ======================================================================
%%
%%     html_parse(+Text, -Nodes)            Text is codes OR an atom
%%     html_parse(+Text, -Nodes, +Options)
%%     html_input(-Nodes)//                 the nonterminal
%%
%% IT ANSWERS A LIST, where `xml_parse/2' answers one element, and the
%% difference is the languages': XML requires exactly one root and HTML
%% does not. A list is also what `html_codes/2' takes at the top, so the
%% two compose without a wrapper.
%%
%% ---- WHAT IT IS, AND WHAT IT IS NOT ----------------------------------
%%
%% IT IS NOT AN HTML5 TREE BUILDER, and saying so is the point of this
%% paragraph. The standard's algorithm is a tokenizer, an insertion-mode
%% state machine, the adoption agency for misnested formatting, foster
%% parenting for content stranded in a table, and implied `<html>',
%% `<head>' and `<body>' around everything. That is thousands of lines and
%% a conformance suite, and a HALF one is worse than none: it produces a
%% tree that looks right and is quietly not the one a browser built.
%%
%% WHAT IT DOES HANDLE is the part that actually differs from XML in
%% documents people write:
%%
%%   * VOID ELEMENTS have no children and need no end tag;
%%   * `script' AND `style' HOLD RAW TEXT, read verbatim to their own end
%%     tag -- a `<' inside a script is not markup;
%%   * `textarea' AND `title' hold escapable raw text: no nesting, but
%%     entities are resolved;
%%   * OPTIONAL END TAGS close themselves. `<li>' closes an open `<li>',
%%     `<tr>' closes an open `<td>', a block element closes an open `<p>'
%%     -- the table is `html_closes/2' and it is the whole of the implied
%%     -end-tag handling;
%%   * A MISNESTED END TAG closes what it names. `</div>' with a `<span>'
%%     still open closes the span and then the div, which is what every
%%     browser does and what XML would refuse outright;
%%   * NAMES ARE DOWNCASED, because HTML's are case-insensitive and
%%     `<DIV>' and `<div>' are the same element;
%%   * ATTRIBUTE VALUES may be double-quoted, single-quoted, unquoted, or
%%     ABSENT -- `checked' comes back as the bare atom the writer takes;
%%   * `<' THAT IS NOT MARKUP IS TEXT. `a < b' outside a tag is three
%%     characters, not a broken start tag, because that is how it renders.
%%
%% WHAT IT DOES NOT DO: no implied html/head/body, no foster parenting, no
%% adoption agency, no `<p>` auto-closing at the end of an enclosing block
%% beyond what `html_closes/2' names. Feed it a document written by a
%% person or by `html_codes/2' and it gives you that document's tree; feed
%% it something a browser has to repair and you will get the tree as
%% written, not the tree as rendered.
%%
%% ---- ENTITIES, AND THE ONE PLACE THIS DIFFERS FROM library(xml) ------
%%
%% An UNKNOWN entity comes back as TEXT, character for character, where
%% library(xml) refuses it. That is not laxity, it is the two languages
%% again: XML has a DTD and an undeclared entity is an error the spec
%% names, while HTML has a fixed table of some two thousand names and a
%% browser leaves anything not in it as literal text -- which is what
%% makes `AT&T' render as `AT&T' on every page that ever wrote it that
%% way. The names known here are the five XML predefined plus `nbsp' and
%% `copy', and numeric references in both spellings.
%%
%% ---- OPTIONS ---------------------------------------------------------
%%
%%     space(preserve)   every text node is kept -- the default
%%     space(remove)     text nodes that are ENTIRELY whitespace are
%%                       dropped

%% ---- the entry points ------------------------------------------------

%% html_parse(+Text, -Nodes) is det.
html_parse(Text, Nodes) :- html_parse(Text, Nodes, []).

%% html_parse(+Text, -Nodes, +Options) is det.
html_parse(Text, Nodes, Options) :-
    html_in_codes(Text, Cs),
    phrase(html_top(Nodes, Options), Cs).

%% html_input(-Nodes)// is det.
html_input(Nodes) --> html_top(Nodes, []).

html_in_codes(Text, Cs) :- is_list(Text), !, Cs = Text.
html_in_codes(Text, Cs) :- atom(Text), !, atom_codes(Text, Cs).
html_in_codes(Text, _) :- throw(error(type_error(html_text, Text), html_parse/2)).

%% THE TOP LEVEL HAS NO PARENT, so nothing can close it and a stray end
%% tag has nothing to match. `''' is that absent parent: `html_closes/2'
%% is never true of it, so the implied-end path cannot fire here, and an
%% end tag that reaches this level is DISCARDED rather than reported --
%% which is what a browser does with `</div>' in a document that never
%% opened one.
html_top(Nodes, Options) -->
    html_kids_in('', Kids, Stop, Options),
    html_top_rest(Stop, Kids, Nodes, Options).

html_top_rest(eof, Kids, Kids, _) --> [].
html_top_rest(done, Kids, Kids, _) --> [].
html_top_rest(closed, Kids, Kids, _) --> [].
html_top_rest(end(_), Kids, Nodes, Options) -->
    html_end_tag_in(_),
    html_top(More, Options),
    { append(Kids, More, Nodes) }.

%% ---- children, and the four ways a run of them can stop ---------------
%%
%%     done     this element's own end tag was read and consumed
%%     closed   a start tag implied the end of this element -- NOTHING was
%%              consumed, and the caller will read that tag as a sibling
%%     end(X)   an end tag for an ANCESTOR is next, and not consumed: each
%%              level checks whether X is its own name, and the one that
%%              matches eats it
%%     eof      the input ran out with this element still open
%%
%% `closed' AND `end(X)' ARE DIFFERENT ON PURPOSE and conflating them is
%% the bug this shape exists to avoid: `end(X)' propagates up until
%% somebody consumes the tag, so an implied close -- which has no tag --
%% would propagate for ever.

html_kids_in(Parent, Kids, Stop, Options) -->
    html_chars_in(Cs),
    html_peek_what(What),
    html_kids_step(What, Parent, Cs, Kids, Stop, Options).

html_kids_step(eof, _, Cs, Kids, eof, Options) --> !,
    { html_text_node(Cs, Options, Kids, []) }.
html_kids_step(end(Name), Parent, Cs, Kids, Stop, Options) --> !,
    (   { Name == Parent }
    ->  html_end_tag_in(_), { Stop = done }
    ;   { Stop = end(Name) }
    ),
    { html_text_node(Cs, Options, Kids, []) }.
html_kids_step(comment, Parent, Cs, Kids, Stop, Options) --> !,
    "<!--", html_comment_body(T),
    html_kids_in(Parent, Rest, Stop, Options),
    { html_text_node(Cs, Options, Kids, [comment(T)|Rest]) }.
html_kids_step(bogus, Parent, Cs, Kids, Stop, Options) --> !,
    html_bogus_skip,
    html_kids_in(Parent, Rest, Stop, Options),
    { html_text_node(Cs, Options, Kids, Rest) }.
html_kids_step(start(Name), Parent, Cs, Kids, Stop, Options) -->
    { html_closes(Name, Parent) }, !,
    { Stop = closed, html_text_node(Cs, Options, Kids, []) }.
html_kids_step(start(_), Parent, Cs, Kids, Stop, Options) --> !,
    html_element_in(E, Options, Inner),
    html_kids_after(Inner, Parent, Rest, Stop, Options),
    { html_text_node(Cs, Options, Kids, [E|Rest]) }.

html_kids_after(done, Parent, Rest, Stop, Options) --> !,
    html_kids_in(Parent, Rest, Stop, Options).
html_kids_after(closed, Parent, Rest, Stop, Options) --> !,
    html_kids_in(Parent, Rest, Stop, Options).
html_kids_after(eof, _, [], eof, _) --> !, [].
html_kids_after(end(X), Parent, [], Stop, _) -->
    (   { X == Parent }
    ->  html_end_tag_in(_), { Stop = done }
    ;   { Stop = end(X) }
    ).

html_text_node([], _, Kids, Kids) :- !.
html_text_node(Cs, Options, Kids, Tail) :-
    (   memberchk(space(remove), Options),
        html_all_space(Cs)
    ->  Kids = Tail
    ;   html_atom_of(Cs, A),
        Kids = [A|Tail]
    ).

html_all_space([]).
html_all_space([C|Cs]) :- html_ws_code(C), html_all_space(Cs).

html_ws_code(0' ).
html_ws_code(0'\t).
html_ws_code(0'\n).
html_ws_code(0'\r).
html_ws_code(0'\f).

html_ws_in --> [C], { html_ws_code(C) }, !, html_ws_in.
html_ws_in --> [].

%% ---- what comes next -------------------------------------------------
%%
%% A `<' THAT IS NOT FOLLOWED BY A NAME IS TEXT, which is the clause that
%% makes `a < b' work in a paragraph. Browsers do the same, and a parser
%% that treated it as a broken tag would swallow the rest of the document
%% looking for a `>'.

html_peek_what(W, S, S) :- html_what(S, W).

html_what([], eof) :- !.
html_what([0'<, 0'!, 0'-, 0'-|_], comment) :- !.
html_what([0'<, 0'!|_], bogus) :- !.
html_what([0'<, 0'?|_], bogus) :- !.
html_what([0'<, 0'/|S], end(Name)) :- html_tag_name_at(S, Name), !.
html_what([0'<|S], start(Name)) :- html_tag_name_at(S, Name), !.
html_what(_, text).

html_tag_name_at(S, Name) :-
    html_name_codes(S, Cs, _),
    Cs = [First|_],
    html_letter(First),
    html_downcase_codes(Cs, Low),
    atom_codes(Name, Low).

html_name_codes([C|Cs], [C|Ns], Rest) :- html_name_code(C), !, html_name_codes(Cs, Ns, Rest).
html_name_codes(S, [], S).

html_name_code(C) :- C > 0x20, \+ html_name_stop(C).

html_name_stop(0'<).
html_name_stop(0'>).
html_name_stop(0'/).
html_name_stop(0'=).
html_name_stop(0'").
html_name_stop(0'').

html_letter(C) :- C >= 0'a, C =< 0'z, !.
html_letter(C) :- C >= 0'A, C =< 0'Z.

html_downcase_codes([], []).
html_downcase_codes([C|Cs], [D|Ds]) :- html_downcase(C, D), html_downcase_codes(Cs, Ds).

%% ---- an element ------------------------------------------------------

html_element_in(element(Name, Attrs, Kids), Options, Inner) -->
    [0'<], html_name_in(NameCs),
    { html_downcase_codes(NameCs, Low), atom_codes(Name, Low) },
    html_attrs_in(Attrs),
    html_tag_close(Shape),
    html_element_body(Shape, Name, Kids, Options, Inner).

html_name_in([C|Cs]) --> [C], { html_name_code(C) }, !, html_name_more(Cs).
html_name_in(_, Rest, _) :- html_oops('a tag name', Rest).

html_name_more([C|Cs]) --> [C], { html_name_code(C) }, !, html_name_more(Cs).
html_name_more([]) --> [].

html_tag_close(empty) --> "/>", !.
html_tag_close(open) --> [0'>], !.
html_tag_close(_, Rest, _) :- html_oops('the end of the start tag', Rest).

%% A VOID ELEMENT IS DONE AT ITS START TAG, whether or not the author
%% wrote the XML slash. `<br>' and `<br/>' are the same element and an
%% end tag for either is a stray one, discarded where it surfaces.
html_element_body(_, Name, [], _, done) --> { html_void(Name) }, !.
html_element_body(empty, _, [], _, done) --> !.
html_element_body(open, Name, Kids, _, done) --> { html_raw_text(Name) }, !,
    html_raw_until(Name, Cs),
    { html_raw_kids(Cs, Kids) }.
html_element_body(open, Name, Kids, _, done) --> { html_escapable(Name) }, !,
    html_raw_until(Name, Cs),
    { html_decode(Cs, Text), html_raw_kids(Text, Kids) }.
html_element_body(open, Name, Kids, Options, Inner) -->
    html_kids_in(Name, Kids, Inner, Options).

html_raw_kids([], []) :- !.
html_raw_kids(Cs, [A]) :- html_atom_of(Cs, A).

%% ---- raw text --------------------------------------------------------
%%
%% READ VERBATIM TO THE MATCHING END TAG, and the match is
%% CASE-INSENSITIVE because the HTML tokenizer is: `</ScRiPt>' ends a
%% script just as well as `</script>'. This is the reading half of the
%% check `html_codes/2' makes on the way out -- the writer refuses to EMIT
%% a `</script' inside a script, and this is why that matters.

html_raw_until(Name, []) --> html_raw_end(Name), !.
html_raw_until(Name, [C|Cs]) --> [C], !, html_raw_until(Name, Cs).
html_raw_until(Name, _, Rest, _) :- html_oops(unclosed_element(Name), Rest).

html_raw_end(Name) --> "</", html_name_in(Cs), html_ws_in, [0'>],
    { html_downcase_codes(Cs, Low), atom_codes(Name, Low) }.

%% ---- attributes ------------------------------------------------------

html_attrs_in(Attrs) --> html_ws_in, html_attrs_more(Attrs).

html_attrs_more([]) --> html_peek_tag_close, !.
html_attrs_more([A|As]) --> html_attr_in(A), html_ws_in, html_attrs_more(As).

html_peek_tag_close([0'>|S], [0'>|S]).
html_peek_tag_close([0'/, 0'>|S], [0'/, 0'>|S]).
html_peek_tag_close([], []).

%% A BARE ATTRIBUTE COMES BACK BARE, which is exactly the term the writer
%% emits minimised. `checked=""' is a different term and stays one: the
%% two mean the same thing to HTML, and turning one into the other would
%% be the parser editing the document.
html_attr_in(Attr) -->
    html_name_in(NameCs),
    { html_downcase_codes(NameCs, Low), atom_codes(Name, Low) },
    html_ws_in,
    html_attr_value(Name, Attr).

html_attr_value(Name, Name=Value) --> [0'=], !, html_ws_in,
    html_attvalue_in(Cs), { html_decode(Cs, Decoded), html_atom_of(Decoded, Value) }.
html_attr_value(Name, Name) --> [].

html_attvalue_in(Cs) --> [Q], { Q == 0'" ; Q == 0'' }, !, html_quoted_in(Q, Cs).
html_attvalue_in(Cs) --> html_unquoted_in(Cs).

html_quoted_in(Q, []) --> [Q], !.
html_quoted_in(Q, [C|Cs]) --> [C], !, html_quoted_in(Q, Cs).
html_quoted_in(_, _, Rest, _) :- html_oops('the closing quote of the attribute value', Rest).

%% AN UNQUOTED VALUE ENDS AT WHITESPACE OR `>', which is the tokenizer's
%% rule and the reason `<a href=/x/y>' works at all.
html_unquoted_in([C|Cs]) --> [C], { html_unquoted_code(C) }, !, html_unquoted_in(Cs).
html_unquoted_in([]) --> [].

html_unquoted_code(C) :- \+ html_ws_code(C), C =\= 0'>, C =\= 0'<, C =\= 0'".

%% ---- character data --------------------------------------------------

html_chars_in(Out) --> html_peek_markup, !, { Out = [] }.
html_chars_in([]) --> html_peek_eof, !.
html_chars_in(Out) --> [0'&], !, html_entity_in(A), html_chars_in(B),
    { append(A, B, Out) }.
html_chars_in([C|Cs]) --> [C], !, html_chars_in(Cs).

html_peek_markup(S, S) :- html_what(S, W), W \== text, W \== eof.
html_peek_eof([], []).

%% ---- entities --------------------------------------------------------
%%
%% AN UNKNOWN NAME IS TEXT. See the note at the top: HTML's table has some
%% two thousand names in it, a browser leaves anything not in the table as
%% literal characters, and that is what makes `AT&T' render as `AT&T'. The
%% ampersand is emitted and the reader carries on from the next byte, so
%% nothing is consumed and nothing is lost.
html_entity_in([0'&]) --> "amp;", !.
html_entity_in([0'<]) --> "lt;", !.
html_entity_in([0'>]) --> "gt;", !.
html_entity_in([0'"]) --> "quot;", !.
html_entity_in([0'']) --> "apos;", !.
html_entity_in([0xC2, 0xA0]) --> "nbsp;", !.
html_entity_in([0xC2, 0xA9]) --> "copy;", !.
html_entity_in(Cs) --> [0'#], !, html_charref_in(Cs).
html_entity_in([0'&]) --> [].

%% A NUMERIC REFERENCE THAT WILL NOT READ IS ALSO TEXT, for the same
%% reason: `&#' followed by something that is not a number is two
%% characters somebody typed, not a document to reject.
html_charref_in(Cs) --> [0'x], html_hex_in(0, 0, N), [0';], !, { html_utf8(N, Cs) }.
html_charref_in(Cs) --> [0'X], html_hex_in(0, 0, N), [0';], !, { html_utf8(N, Cs) }.
html_charref_in(Cs) --> html_dec_in(0, 0, N), [0';], !, { html_utf8(N, Cs) }.
html_charref_in([0'&, 0'#]) --> [].

html_hex_in(Acc, _, N) --> [C], { html_hex(C, D) }, !,
    { A is Acc * 16 + D }, html_hex_in(A, 1, N).
html_hex_in(N, 1, N) --> [].

html_dec_in(Acc, _, N) --> [C], { code_type(C, digit) }, !,
    { A is Acc * 10 + (C - 0'0) }, html_dec_in(A, 1, N).
html_dec_in(N, 1, N) --> [].

html_hex(C, N) :- C >= 0'0, C =< 0'9, !, N is C - 0'0.
html_hex(C, N) :- C >= 0'a, C =< 0'f, !, N is C - 0'a + 10.
html_hex(C, N) :- C >= 0'A, C =< 0'F, !, N is C - 0'A + 10.

%% `html_decode/2' RESOLVES ENTITIES IN A RUN ALREADY COLLECTED, which is
%% what an attribute value and an escapable-raw-text element need: both
%% are read to a delimiter first and decoded afterwards, because the
%% delimiter search must not stop at an `&'.
html_decode(Cs, Out) :- phrase(html_decode_run(Out), Cs).

html_decode_run([]) --> html_peek_eof, !.
html_decode_run(Out) --> [0'&], !, html_entity_in(A), html_decode_run(B),
    { append(A, B, Out) }.
html_decode_run([C|Cs]) --> [C], !, html_decode_run(Cs).

%% ---- comments and the things that are skipped ------------------------

html_comment_body(Text) --> html_comment_codes(Cs), { html_atom_of(Cs, Text) }.

%% AN UNCLOSED COMMENT RUNS TO THE END OF THE INPUT rather than throwing,
%% which is the tokenizer's own rule and a mercy: a document whose last
%% comment is missing its `-->' is one a browser still renders, and
%% refusing the whole file over it helps nobody.
html_comment_codes([]) --> "-->", !.
html_comment_codes([]) --> html_peek_eof, !.
html_comment_codes([C|Cs]) --> [C], !, html_comment_codes(Cs).

%% `<!DOCTYPE ...>' AND `<?...>' ARE DROPPED. Neither is a node in this
%% tree -- the writer emits the doctype from an option, not from the
%% children -- and a processing instruction is not HTML at all.
html_bogus_skip --> [0'>], !.
html_bogus_skip --> html_peek_eof, !.
html_bogus_skip --> [_], !, html_bogus_skip.

%% ---- the tables ------------------------------------------------------
%%
%% `html_closes(New, Open)': seeing a start tag `New' while `Open' is the
%% element being filled means `Open' ends here. It is the whole of the
%% implied-end-tag handling, written as a table rather than as conditions
%% inside the parser, so that adding a case is adding a line.

html_closes(li, li).
html_closes(dt, dt).
html_closes(dt, dd).
html_closes(dd, dd).
html_closes(dd, dt).
html_closes(option, option).
html_closes(optgroup, option).
html_closes(optgroup, optgroup).
html_closes(td, td).
html_closes(td, th).
html_closes(th, td).
html_closes(th, th).
html_closes(tr, td).
html_closes(tr, th).
html_closes(tr, tr).
html_closes(tbody, td).
html_closes(tbody, th).
html_closes(tbody, tr).
html_closes(tbody, thead).
html_closes(tbody, tbody).
html_closes(tfoot, td).
html_closes(tfoot, th).
html_closes(tfoot, tr).
html_closes(tfoot, tbody).
html_closes(head, head).
html_closes(body, head).
%% A BLOCK ELEMENT CLOSES AN OPEN PARAGRAPH, which is the one implied end
%% tag people meet daily: `<p>one<p>two' is two paragraphs and always was.
html_closes(New, p) :- html_block(New).

html_block(address).
html_block(article).
html_block(aside).
html_block(blockquote).
html_block(details).
html_block(div).
html_block(dl).
html_block(fieldset).
html_block(figcaption).
html_block(figure).
html_block(footer).
html_block(form).
html_block(h1).
html_block(h2).
html_block(h3).
html_block(h4).
html_block(h5).
html_block(h6).
html_block(header).
html_block(hr).
html_block(main).
html_block(menu).
html_block(nav).
html_block(ol).
html_block(p).
html_block(pre).
html_block(section).
html_block(table).
html_block(ul).

html_escapable(textarea).
html_escapable(title).

%% ---- the leftovers ---------------------------------------------------

html_end_tag_in(Name) -->
    "</", html_name_in(Cs), html_ws_in, [0'>], !,
    { html_downcase_codes(Cs, Low), atom_codes(Name, Low) }.
html_end_tag_in(_, Rest, _) :- html_oops('a well-formed end tag', Rest).

html_atom_of(Cs, Atom) :- html_no_nul(Cs, Cs), atom_codes(Atom, Cs).

html_no_nul([], _).
html_no_nul([C|Cs], Whole) :-
    (   C =:= 0
    ->  html_oops('text with no NUL in it -- an atom stops there', Whole)
    ;   html_no_nul(Cs, Whole)
    ).

html_oops(What, Rest) :-
    html_snippet(Rest, 40, Cs),
    atom_codes(Where, Cs),
    throw(error(syntax_error(What), html_at(Where))).

html_snippet(_, 0, []) :- !.
html_snippet([], _, []) :- !.
html_snippet([C|Cs], N, Out) :-
    (   C =:= 0
    ->  Out = []
    ;   Out = [C|Rest], M is N - 1, html_snippet(Cs, M, Rest)
    ).

%% RFC 3629 again, for the numeric character references. library(xml)'s
%% copy carries the note about why this is duplicated and the escapers are
%% not: an escaper encodes a policy, which drifts; this is a fixed
%% transform, which cannot.
html_utf8(0, [0xEF, 0xBF, 0xBD]) :- !.
html_utf8(C, [C]) :- C < 0x80, !.
html_utf8(C, [A, B]) :- C < 0x800, !,
    A is 0xC0 \/ (C >> 6), B is 0x80 \/ (C /\ 0x3F).
html_utf8(C, [A, B, D]) :- C < 0x10000, !,
    A is 0xE0 \/ (C >> 12), B is 0x80 \/ ((C >> 6) /\ 0x3F), D is 0x80 \/ (C /\ 0x3F).
html_utf8(C, [A, B, D, E]) :-
    A is 0xF0 \/ (C >> 18), B is 0x80 \/ ((C >> 12) /\ 0x3F),
    D is 0x80 \/ ((C >> 6) /\ 0x3F), E is 0x80 \/ (C /\ 0x3F).

%% ======================================================================
%% ---- CSS: the style half of the same documents -----------------------
%%
%% CSS lives inside HTML twice -- a <style> element's raw text, and a
%% style="..." attribute's declaration list -- which is why the parser
%% for it lives HERE and not in a fourth library: the input is what
%% html_parse/2 just handed you. Both ways, the family's way:
%%
%%     css_parse(Text, Stylesheet)          Text is codes OR an atom
%%     css_declarations(Text, Decls)        a style="..." fragment
%%     css_codes(Stylesheet, Codes)         the writer answers CODES
%%     css_atom(Stylesheet, Atom)
%%     css_write(Stylesheet)
%%     css_declarations_codes(Decls, Codes) the attribute half, out
%%     css_declarations_atom(Decls, Atom)
%%
%% ---- THE TERMS -------------------------------------------------------
%%
%%     Stylesheet    a LIST of items
%%     rule(Selectors, Decls)     Selectors: one atom per comma-separated
%%                                selector, whitespace collapsed;
%%                                Decls: the declarations
%%     at(Name, Prelude)          @import ...;  @charset ...;  -- an
%%                                at-rule that ends in a semicolon
%%     at(Name, Prelude, Items)   @media ... { rules }  -- the block
%%                                holds nested items
%%     at(Name, Prelude, decls(Decls))
%%                                @font-face { ... }  @page { ... } --
%%                                the block holds DECLARATIONS, decided
%%                                by name (css_decl_at/1), because a
%%                                font-face body has no selectors to read
%%     Declaration   Prop-Value           color-red
%%                   Prop-important(Value)  ... !important, surfaced
%%
%% Properties fold to lower case (they are case-insensitive) EXCEPT
%% custom properties: `--Main-Color' is case-SENSITIVE by spec and is
%% kept as written. Values are kept VERBATIM, trimmed at the ends --
%% `1px  solid  red' keeps its spacing, because a value's internal
%% shape is the author's. Selectors have their whitespace runs
%% collapsed to one space (`a  >  b' and `a > b' are the same
%% selector), outside strings.
%%
%% WHAT THE SCANNER RESPECTS, because splitting without respecting it
%% is how `url(data:;base64,...)' loses its tail: strings in both
%% quotes with backslash escapes, parentheses and brackets nested to
%% any depth -- a `;' or `,' or `}' inside any of them is content, not
%% structure. Comments are stripped everywhere OUTSIDE strings (each
%% becomes one space, so `a/**/b' does not fuse).
%%
%% WHAT THIS IS NOT, stated the way html_parse states it: not a value
%% parser (a length, a color and a calc() all come back as the atom
%% they were written as -- typing values is a project of its own), not
%% a selector-tree builder (a selector is one trimmed atom, not a
%% combinator term), and not error-recovering (real CSS parsers skip a
%% bad declaration and carry on; this one THROWS naming it, because a
%% stylesheet that half-parses into a term is a document that means
%% something else three days later).
%%
%% THEY THROW RATHER THAN GUESS, all the family's reasons: a
%% declaration with no colon names its text; an unclosed string,
%% comment or block says which; a selector written with a raw `{' or
%% top-level `,', a value with a top-level `;', a property with
%% whitespace in it are refused ON THE WAY OUT too -- the writer
%% checks with the same scanner, so nothing it emits can reparse into
%% a different stylesheet. The round trip is the real test, and
%% test/serialize.sh runs it.

%% ---- the entry points ------------------------------------------------

%% css_parse(+Text, -Stylesheet) is det.
css_parse(Text, Sheet) :-
    css_in_codes(Text, Cs),
    phrase(css_sheet_in(Sheet, eof), Cs).

%% css_declarations(+Text, -Decls) is det.  The style="..." half.
css_declarations(Text, Ds) :-
    css_in_codes(Text, Cs),
    phrase(css_decls_in(Ds, eof), Cs).

%% css_codes(+Stylesheet, -Codes) is det.
css_codes(Sheet, Codes) :- phrase(css_items_out(Sheet), Codes).

css_atom(Sheet, Atom) :- css_codes(Sheet, Codes), atom_codes(Atom, Codes).

css_write(Sheet) :- css_codes(Sheet, Codes), format("~s", [Codes]).

css_declarations_codes(Ds, Codes) :- phrase(css_decls_out(Ds), Codes).

css_declarations_atom(Ds, Atom) :-
    css_declarations_codes(Ds, Codes), atom_codes(Atom, Codes).

css_in_codes(V, _) :- var(V), !,
    throw(error(instantiation_error, css_parse/2)).
css_in_codes(Text, Cs) :- atom(Text), !, atom_codes(Text, Cs).
css_in_codes(Cs, Cs) :- is_list(Cs), !.
css_in_codes(T, _) :- throw(error(type_error(css_text, T), css_parse/2)).

%% THE TWO BY-NAME BLOCKS: their bodies are declarations, and reading
%% them as rules would eat `font-family: serif;' hunting for a `{'.
css_decl_at('font-face').
css_decl_at(page).

%% ---- the writer ------------------------------------------------------

css_items_out(V) --> { var(V) }, !,
    { throw(error(instantiation_error, css_codes/2)) }.
css_items_out([]) --> !, [].
css_items_out([I]) --> !, css_item_out(I).
css_items_out([I|Is]) --> !, css_item_out(I), "\n", css_items_out(Is).
css_items_out(T) -->
    { throw(error(type_error(css_stylesheet, T), css_codes/2)) }.

css_item_out(V) --> { var(V) }, !,
    { throw(error(instantiation_error, css_codes/2)) }.
css_item_out(rule(Sels, Ds)) --> !,
    css_selectors_out(Sels), css_block_decls(Ds).
css_item_out(at(Name, Prelude)) --> !,
    "@", css_at_name_out(Name), css_prelude_out(Prelude), ";".
css_item_out(at(Name, Prelude, decls(Ds))) --> !,
    "@", css_at_name_out(Name), css_prelude_out(Prelude),
    css_block_decls(Ds).
css_item_out(at(Name, Prelude, Items)) --> { is_list(Items) }, !,
    "@", css_at_name_out(Name), css_prelude_out(Prelude),
    css_block_items(Items).
css_item_out(T) -->
    { throw(error(type_error(css_item, T), css_codes/2)) }.

css_block_decls([]) --> !, " { }".
css_block_decls(Ds) --> " { ", css_decls_out(Ds), " }".

css_block_items([]) --> !, " { }".
css_block_items(Items) --> " {\n", css_items_out(Items), "\n}".

css_selectors_out(V) --> { var(V) }, !,
    { throw(error(instantiation_error, css_codes/2)) }.
css_selectors_out([S]) --> !, css_selector_out(S).
css_selectors_out([S|Ss]) --> !, css_selector_out(S), ", ",
    css_selectors_out(Ss).
css_selectors_out(T) -->
    { throw(error(type_error(css_selectors, T), css_codes/2)) }.

css_selector_out(S) -->
    { xml_text_codes(S, Cs) },
    { Cs == [] -> throw(error(domain_error(css_selector, S), css_codes/2))
    ; true },
    { css_check_out(Cs, [comma, semi, brace, lbrace], css_selector, S) },
    xml_raw(Cs).

css_prelude_out('') --> !, [].
css_prelude_out(P) -->
    { xml_text_codes(P, Cs),
      css_check_out(Cs, [semi, brace, lbrace], css_prelude, P) },
    " ", xml_raw(Cs).

css_at_name_out(N) -->
    { xml_text_codes(N, Cs),
      (   Cs \== [], css_ident_all(Cs)
      ->  true
      ;   throw(error(domain_error(css_at_name, N), css_codes/2))
      ) },
    xml_raw(Cs).

css_decls_out(V) --> { var(V) }, !,
    { throw(error(instantiation_error, css_codes/2)) }.
css_decls_out([]) --> !, [].
css_decls_out([D]) --> !, css_decl_out(D).
css_decls_out([D|Ds]) --> !, css_decl_out(D), "; ", css_decls_out(Ds).
css_decls_out(T) -->
    { throw(error(type_error(css_declarations, T), css_codes/2)) }.

css_decl_out(V) --> { var(V) }, !,
    { throw(error(instantiation_error, css_codes/2)) }.
css_decl_out(P-important(V)) --> !,
    css_prop_out(P), ": ", css_value_out(V), " !important".
css_decl_out(P-V) --> !,
    css_prop_out(P), ": ", css_value_out(V).
css_decl_out(T) -->
    { throw(error(type_error(css_declaration, T), css_codes/2)) }.

css_prop_out(P) -->
    { xml_text_codes(P, Cs),
      (   Cs \== [], css_prop_ok(Cs)
      ->  true
      ;   throw(error(domain_error(css_property, P), css_codes/2))
      ) },
    xml_raw(Cs).

css_prop_ok([]).
css_prop_ok([C|Cs]) :-
    \+ html_ws_code(C), \+ css_prop_bad(C), css_prop_ok(Cs).

css_prop_bad(0':).
css_prop_bad(0';).
css_prop_bad(0'{).
css_prop_bad(0'}).
css_prop_bad(0'().
css_prop_bad(0')).
css_prop_bad(0'[).
css_prop_bad(0']).
css_prop_bad(0'").
css_prop_bad(0'\').
css_prop_bad(0',).
css_prop_bad(0'!).

css_value_out(V) -->
    { xml_text_codes(V, Cs),
      css_check_out(Cs, [semi, brace, lbrace], css_value, V) },
    xml_raw(Cs).

%% THE WRITER CHECKS WITH THE READER'S OWN SCANNER: the codes must
%% scan to their end without hitting any of the named stops at the top
%% level -- so a `;' inside url(...) passes and a bare one is refused,
%% by the same rule the parser will read it back with.
css_check_out(Cs, Stops, What, Orig) :-
    (   phrase(css_scan([eof|Stops], _, Stop), Cs, _),
        Stop == eof
    ->  true
    ;   throw(error(domain_error(What, Orig), css_codes/2))
    ).

css_ident_all([]).
css_ident_all([C|Cs]) :- css_ident_code(C), css_ident_all(Cs).

%% ---- the reader ------------------------------------------------------

css_sheet_in(Items, End) -->
    css_ws_in,
    (   css_sheet_end(End)
    ->  { Items = [] }
    ;   css_eof
    ->  { css_unclosed(block) }
    ;   css_item_in(I),
        { Items = [I|Rest] },
        css_sheet_in(Rest, End)
    ).

css_sheet_end(eof) --> css_eof.
css_sheet_end(brace) --> "}".

css_item_in(I) --> "@", !, css_at_in(I).
css_item_in(rule(Sels, Ds)) -->
    css_scan([lbrace, semi, eof], Cs, Stop),
    { (   Stop == lbrace
      ->  true
      ;   css_trim(Cs, T), atom_codes(A, T),
          throw(error(domain_error(css_rule, A), css_parse/2))
      ) },
    { css_split_selectors(Cs, Sels) },
    css_decls_in(Ds, brace).

css_at_in(I) -->
    css_ident_in(NCs),
    { (   NCs == []
      ->  throw(error(domain_error(css_at_name, '@'), css_parse/2))
      ;   true
      ) },
    { css_lower(NCs, LCs), atom_codes(Name, LCs) },
    css_scan([lbrace, semi, eof], PCs, Stop),
    { css_trim(PCs, PT), atom_codes(Prelude, PT) },
    css_at_body(Stop, Name, Prelude, I).

%% an @import at the very end of the file may drop its semicolon; a
%% browser takes it, so this does
css_at_body(semi, Name, Prelude, at(Name, Prelude)) --> !.
css_at_body(eof,  Name, Prelude, at(Name, Prelude)) --> !.
css_at_body(lbrace, Name, Prelude, I) -->
    (   { css_decl_at(Name) }
    ->  css_decls_in(Ds, brace), { I = at(Name, Prelude, decls(Ds)) }
    ;   css_sheet_in(Items, brace), { I = at(Name, Prelude, Items) }
    ).

css_decls_in(Ds, End) -->
    css_ws_in,
    (   css_decl_end(End)
    ->  { Ds = [] }
    ;   css_eof
    ->  { css_unclosed(block) }
    ;   ";"
    ->  css_decls_in(Ds, End)                       % an empty declaration
    ;   css_decl_in(D, End, More),
        { Ds = [D|Rest] },
        (   { More == done }
        ->  { Rest = [] }
        ;   css_decls_in(Rest, End)
        )
    ).

css_decl_end(eof) --> css_eof.
css_decl_end(brace) --> "}".

css_decl_in(P-VOut, End, More) -->
    css_scan([colon, semi, brace, eof], PCs, StopP),
    { css_trim(PCs, PT) },
    { (   StopP == colon, PT \== []
      ->  true
      ;   atom_codes(A, PT),
          throw(error(domain_error(css_declaration, A), css_parse/2))
      ) },
    { css_prop_case(PT, P) },
    css_scan([semi, brace, eof], VCs, StopV),
    { css_decl_more(StopV, End, More) },
    { css_trim(VCs, VT), css_unimportant(VT, VOut) }.

css_decl_more(semi, _, more) :- !.
css_decl_more(brace, brace, done) :- !.
css_decl_more(eof, eof, done) :- !.
css_decl_more(brace, eof, _) :-
    throw(error(domain_error(css_declaration, '}'), css_parse/2)).
css_decl_more(eof, brace, _) :- css_unclosed(block).

%% `!important', case-insensitive, optional whitespace around the `!'
%% -- surfaced as important(Value), never left inside the value text
css_unimportant(VT, Out) :-
    reverse(VT, R0), css_drop_ws(R0, R1),
    (   css_ci_prefix("tnatropmi", R1, R2),
        css_drop_ws(R2, R3), R3 = [0'!|R4]
    ->  reverse(R4, V0), css_trim(V0, V1),
        atom_codes(V, V1), Out = important(V)
    ;   atom_codes(V, VT), Out = V
    ).

css_ci_prefix([], R, R).
css_ci_prefix([P|Ps], [C|Cs], R) :-
    (   C >= 0'A, C =< 0'Z -> L is C + 32 ; L = C ),
    L =:= P,
    css_ci_prefix(Ps, Cs, R).

%% properties fold to lower case -- EXCEPT custom properties, which
%% are case-sensitive by spec and keep their spelling
css_prop_case(PT, P) :-
    (   PT = [0'-, 0'-|_] -> Cs = PT ; css_lower(PT, Cs) ),
    atom_codes(P, Cs).

css_lower([], []).
css_lower([C|Cs], [L|Ls]) :-
    (   C >= 0'A, C =< 0'Z -> L is C + 32 ; L = C ),
    css_lower(Cs, Ls).

%% ---- selectors: split on top-level commas, collapse the whitespace --

css_split_selectors(Cs, Sels) :- phrase(css_selsplit(Sels), Cs).

css_selsplit(Out) -->
    css_scan([comma, eof], Part, Stop),
    { css_collapse(Part, CP), css_trim(CP, T) },
    { (   T == []
      ->  throw(error(domain_error(css_selector, ''), css_parse/2))
      ;   true
      ) },
    { atom_codes(Sel, T) },
    (   { Stop == comma }
    ->  { Out = [Sel|Rest] }, css_selsplit(Rest)
    ;   { Out = [Sel] }
    ).

%% whitespace runs become one space -- outside strings, whose content
%% is the author's to the character
css_collapse([], []).
css_collapse([C|Cs], [0' |Out]) :- html_ws_code(C), !,
    css_drop_ws(Cs, Cs1), css_collapse(Cs1, Out).
css_collapse([Q|Cs], [Q|Out]) :- ( Q =:= 0'" ; Q =:= 0'\' ), !,
    css_copy_str(Q, Cs, Cs1, Out, Out1), css_collapse(Cs1, Out1).
css_collapse([C|Cs], [C|Out]) :- css_collapse(Cs, Out).

css_copy_str(Q, [Q|Cs], Cs, [Q|T], T) :- !.
css_copy_str(Q, [0'\\, D|Cs], Cs1, [0'\\, D|Out], T) :- !,
    css_copy_str(Q, Cs, Cs1, Out, T).
css_copy_str(Q, [C|Cs], Cs1, [C|Out], T) :- !,
    css_copy_str(Q, Cs, Cs1, Out, T).
css_copy_str(_, [], _, _, _) :- css_unclosed(string).

%% ---- the scanner every half stands on --------------------------------
%%
%% Reads codes until one of the named stops at the TOP LEVEL, copying
%% strings verbatim, nesting through (...) and [...], stripping
%% comments to a single space. The stop code is consumed and named;
%% `eof' is a stop only when asked for, and hitting the end any other
%% way is an unclosed-input error rather than a truncated answer.

css_scan(Stops, Cs, Stop) -->
    (   css_eof
    ->  { (   memberchk(eof, Stops)
          ->  Cs = [], Stop = eof
          ;   css_unclosed(input)
          ) }
    ;   [C],
        css_scan_c(C, Stops, Cs, Stop)
    ).

css_scan_c(C, Stops, Cs, Stop) -->
    { css_stop_code(C, S), memberchk(S, Stops) }, !,
    { Cs = [], Stop = S }.
css_scan_c(0'/, Stops, Cs, Stop) --> "*", !,
    css_comment_skip,
    { Cs = [0' |Cs1] },
    css_scan(Stops, Cs1, Stop).
css_scan_c(Q, Stops, Cs, Stop) --> { Q =:= 0'" ; Q =:= 0'\' }, !,
    { Cs = [Q|Cs0] },
    css_str_in(Q, Cs0, Cs1),
    css_scan(Stops, Cs1, Stop).
css_scan_c(0'(, Stops, Cs, Stop) --> !,
    { Cs = [0'(|CsA] },
    css_scan([rparen], Inner, _),
    { append(Inner, [0')|Cs1], CsA) },
    css_scan(Stops, Cs1, Stop).
css_scan_c(0'[, Stops, Cs, Stop) --> !,
    { Cs = [0'[|CsA] },
    css_scan([rbracket], Inner, _),
    { append(Inner, [0']|Cs1], CsA) },
    css_scan(Stops, Cs1, Stop).
css_scan_c(C, Stops, [C|Cs], Stop) -->
    css_scan(Stops, Cs, Stop).

css_stop_code(0'{, lbrace).
css_stop_code(0'}, brace).
css_stop_code(0';, semi).
css_stop_code(0':, colon).
css_stop_code(0',, comma).
css_stop_code(0'), rparen).
css_stop_code(0'], rbracket).

css_str_in(Q, Cs, Rest) -->
    (   css_eof
    ->  { css_unclosed(string) }
    ;   [C],
        (   { C =:= Q }
        ->  { Cs = [C|Rest] }
        ;   { C =:= 0'\\ }
        ->  (   css_eof
            ->  { css_unclosed(string) }
            ;   [D], { Cs = [C, D|Cs1] }, css_str_in(Q, Cs1, Rest)
            )
        ;   { Cs = [C|Cs1] }, css_str_in(Q, Cs1, Rest)
        )
    ).

css_comment_skip --> "*/", !.
css_comment_skip --> [_], !, css_comment_skip.
css_comment_skip --> { css_unclosed(comment) }.

%% whitespace AND comments, between tokens
css_ws_in --> [C], { html_ws_code(C) }, !, css_ws_in.
css_ws_in --> "/*", !, css_comment_skip, css_ws_in.
css_ws_in --> [].

css_ident_in([C|Cs]) --> [C], { css_ident_code(C) }, !, css_ident_in(Cs).
css_ident_in([]) --> [].

css_ident_code(C) :- C >= 0'a, C =< 0'z, !.
css_ident_code(C) :- C >= 0'A, C =< 0'Z, !.
css_ident_code(C) :- C >= 0'0, C =< 0'9, !.
css_ident_code(0'-).

css_eof([], []).

css_drop_ws([C|Cs], Out) :- html_ws_code(C), !, css_drop_ws(Cs, Out).
css_drop_ws(Cs, Cs).

css_trim(Cs, T) :-
    css_drop_ws(Cs, C1),
    reverse(C1, R), css_drop_ws(R, R1), reverse(R1, T).

css_unclosed(What) :-
    throw(error(domain_error(css_unclosed, What), css_parse/2)).
