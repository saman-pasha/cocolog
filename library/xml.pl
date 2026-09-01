%% library(xml) -- an element tree as XML text.
%%
%% EVERY PREDICATE IS `xml_'-PREFIXED, helpers and nonterminals included,
%% for the reason library(http) spells out at length: cocolog has ONE
%% namespace, a library's private names are everybody's, and the first
%% clash is silent.
%%
%% IT IS ALL CLAUSES, and a DCG at that -- the same shape library(json)
%% has and for the same reason. There is no C in this file and there
%% should never be any.
%%
%% THE TREE IS SWI's, so a document read by any sgml-shaped parser is one
%% this file can write back:
%%
%%     element(Name, Attributes, Children)
%%
%%     Name        an atom, written as-is. It is NOT validated: `xml_'
%%     Attributes  a list of `Name=Value' (`Name-Value' is accepted too)
%%     Children    a list of children, each one of:
%%
%%         an atom or a number    text, escaped
%%         element(_, _, _)       a nested element
%%         cdata(Text)            a CDATA section
%%         comment(Text)          <!-- Text -->
%%         pi(Text)               <?Text?>, a processing instruction
%%         raw(Text)              verbatim, NOT escaped -- the fire escape
%%
%% A CHILD IS NEVER A LIST, and that is the same decision library(json)
%% makes for the same reason. `double_quotes' defaults to `codes', so in a
%% file that did not set it `"hello"' IS `[104,101,...]' -- and a list in the
%% children position could honestly be either five text nodes or one word.
%% Guessing is how `element(p, [], ["hello"])' silently becomes
%% `<p>104101108108111</p>', which is exactly what it did here before this
%% rule existed. So a list among the children is an ERROR that names both
%% fixes, `str/1' writes text from codes, and the SWI tree this file
%% follows never nests a list inside children anyway.
%%
%% A LIST AT THE TOP IS A FRAGMENT, because there the ambiguity is gone:
%% a document has no text at its outermost level, so `xml_codes([A, B], C)'
%% can only mean two nodes side by side -- which is what a caller building
%% a document in pieces has.
%%
%% ---- WHERE IT IS STRICT, each a decision rather than an omission ------
%%
%%   AN UNBOUND VARIABLE IS AN ERROR. A tree with a hole in it is a tree
%%   you have not finished building.
%%
%%   AN EMPTY ELEMENT IS WRITTEN `<name/>', which is the same document as
%%   `<name></name>' to every XML parser. library(html) does NOT do this,
%%   and the note there says why.
%%
%%   A COMMENT CONTAINING `--' IS REFUSED. XML 1.0 section 2.5 forbids it
%%   outright -- there is no escape for it -- so a serialiser that let it
%%   through would emit a document no parser will read. Better to throw at
%%   the call site than to hand somebody an unparseable file.
%%
%%   CDATA CONTAINING `]]>' IS SPLIT, not refused, because there IS a way:
%%   the section is ended and reopened around it, `]]]]><![CDATA[>', which
%%   every parser reassembles into the same text. This one is worth doing
%%   rather than refusing because a CDATA section is usually holding
%%   somebody else's document and the caller cannot always change it.
%%
%%   A NUL BYTE ANYWHERE IN TEXT IS AN ERROR. XML 1.0 has no way to spell
%%   one -- not as a raw byte, not as `&#0;' -- so it cannot be written at
%%   all. It is checked rather than passed through because the failure
%%   otherwise happens far away: an atom in cocolog is a C string, so a NUL
%%   truncates it, and a document that lost half its text at the point of
%%   the byte is a much worse afternoon than an error.
%%
%%   BYTES ABOVE 0x7F PASS THROUGH UNTOUCHED, exactly as in library(json).
%%   cocolog is byte-oriented and there is no decoder here, so UTF-8 in is
%%   UTF-8 out and `header(true)' declares that encoding.
%%
%% ---- OPTIONS ---------------------------------------------------------
%%
%%     header(true)     <?xml version="1.0" encoding="UTF-8"?> in front
%%     header(Enc)      the same with `Enc' as the encoding
%%     doctype(Text)    <!DOCTYPE Text> after the header
%%     indent(N)        N spaces per level -- see below
%%
%% INDENTING ONLY HAPPENS WHERE IT CANNOT CHANGE THE DOCUMENT. Whitespace
%% between elements is CONTENT in XML, not decoration, so an indenter that
%% simply broke every line would be rewriting the data it was asked to
%% write down. The rule here is the one every careful pretty-printer uses:
%% an element whose children are ALL elements has element-only content,
%% and a newline there adds a whitespace node that any schema-aware reader
%% already ignores; an element with so much as one text child is MIXED
%% content and is written on one line, whatever the indent. That is why
%% library(html) has no indent option at all -- HTML's inline elements
%% make even element-only content whitespace-sensitive.

%% ---- the entry points ------------------------------------------------

%% xml_codes(+Tree, -Codes) is det.
xml_codes(Tree, Codes) :- xml_codes(Tree, Codes, []).

%% xml_codes(+Tree, -Codes, +Options) is det.
xml_codes(Tree, Codes, Options) :-
    xml_step(Options, Step),
    phrase(xml_document(Tree, Step, Options), Codes).

%% xml_atom(+Tree, -Atom) is det.
xml_atom(Tree, Atom) :- xml_atom(Tree, Atom, []).

xml_atom(Tree, Atom, Options) :-
    xml_codes(Tree, Codes, Options),
    atom_codes(Atom, Codes).

%% xml_write(+Tree) is det.
xml_write(Tree) :- xml_write(Tree, []).

xml_write(Tree, Options) :-
    xml_codes(Tree, Codes, Options),
    format("~s", [Codes]).

%% xml_content(+Node)// is det.
%% One node, or a list of them, for a caller already building codes with a
%% grammar of its own. Compact, because a fragment being assembled has no
%% level to indent to.
xml_content(Node) --> xml_fragment(Node, 0, 0).

xml_step(Options, Step) :-
    (   memberchk(indent(N), Options),
        integer(N),
        N > 0
    ->  Step = N
    ;   Step = 0
    ).

%% ---- the document, which is the prologue and then the tree -----------

xml_document(Tree, Step, Options) -->
    xml_header(Options),
    xml_doctype(Options),
    xml_fragment(Tree, Step, 0).

%% A FRAGMENT IS A NODE OR A LIST OF THEM, and this is the ONLY place a
%% list means that -- see the note at the top of the file.
xml_fragment(V, _, _) --> { var(V) }, !,
    { throw(error(instantiation_error, xml_codes/2)) }.
xml_fragment([], _, _) --> !, [].
xml_fragment([K|Ks], Step, Depth) --> !, xml_nodes([K|Ks], Step, Depth).
xml_fragment(Node, Step, Depth) --> xml_node(Node, Step, Depth).

xml_header(Options) --> { memberchk(header(H), Options), H \== false }, !,
    { ( H == true -> Enc = 'UTF-8' ; Enc = H ) },
    "<?xml version=\"1.0\" encoding=\"", xml_name(Enc), "\"?>\n".
xml_header(_) --> [].

xml_doctype(Options) --> { memberchk(doctype(D), Options) }, !,
    "<!DOCTYPE ", xml_name(D), ">\n".
xml_doctype(_) --> [].

%% ---- one node --------------------------------------------------------
%%
%% ORDER IS THE DISPATCH, as in library(json), and every clause but the
%% last two cuts. The list clause is a REFUSAL rather than a case, and it
%% sits before the text clause on purpose: `[]' is atomic in this reader,
%% so without it an empty list among the children would write nothing at
%% all and look like it had worked.

xml_node(V, _, _) --> { var(V) }, !,
    { throw(error(instantiation_error, xml_codes/2)) }.
xml_node(element(Name, Attrs, Kids), Step, Depth) --> !,
    xml_element(Name, Attrs, Kids, Step, Depth).
xml_node(cdata(Text), _, _) --> !, xml_cdata(Text).
xml_node(comment(Text), _, _) --> !, xml_comment(Text).
xml_node(pi(Text), _, _) --> !, "<?", xml_name(Text), "?>".
xml_node(raw(Text), _, _) --> !, { xml_text_codes(Text, Cs) }, xml_raw(Cs).
xml_node(str(Text), _, _) --> !, { xml_text_codes(Text, Cs) }, xml_escaped(Cs).
xml_node(L, _, _) --> { is_list(L) }, !,
    { throw(error(type_error(xml_node, L), xml_codes/2)) }.
xml_node(Text, _, _) --> { atomic(Text) }, !,
    { xml_text_codes(Text, Cs) }, xml_escaped(Cs).
xml_node(T, _, _) --> { throw(error(type_error(xml_node, T), xml_codes/2)) }.

xml_nodes([], _, _) --> [].
xml_nodes([K|Ks], Step, Depth) --> xml_node(K, Step, Depth), xml_nodes(Ks, Step, Depth).

%% ---- an element ------------------------------------------------------

xml_element(Name, Attrs, [], _, _) --> !,
    "<", xml_name(Name), xml_attributes(Attrs), "/>".
xml_element(Name, Attrs, Kids, Step, Depth) -->
    "<", xml_name(Name), xml_attributes(Attrs), ">",
    xml_children(Kids, Step, Depth),
    "</", xml_name(Name), ">".

%% MIXED CONTENT GOES ON ONE LINE. `xml_element_only/1' is the whole
%% indent policy, in one predicate, so the reason lives next to the check.
xml_children(Kids, Step, Depth) -->
    { Step > 0, xml_element_only(Kids) }, !,
    { Deeper is Depth + 1 },
    xml_indented(Kids, Step, Deeper),
    xml_break(Step, Depth).
xml_children(Kids, Step, Depth) --> xml_nodes(Kids, Step, Depth).

xml_indented([], _, _) --> [].
xml_indented([K|Ks], Step, Depth) -->
    xml_break(Step, Depth),
    xml_node(K, Step, Depth),
    xml_indented(Ks, Step, Depth).

xml_element_only([]) :- !, fail.
xml_element_only(Kids) :- xml_all_elements(Kids).

xml_all_elements([]).
xml_all_elements([K|Ks]) :- nonvar(K), K = element(_, _, _), xml_all_elements(Ks).

xml_break(0, _) --> !, [].
xml_break(Step, Depth) --> "\n", { Wide is Step * Depth }, xml_spaces(Wide).

xml_spaces(N) --> { N =< 0 }, !, [].
xml_spaces(N) --> " ", { M is N - 1 }, xml_spaces(M).

%% ---- attributes ------------------------------------------------------
%%
%% A BARE ATTRIBUTE IS AN ERROR HERE and legal in library(html). XML has
%% no minimised form: `<input checked>' is not XML, and a serialiser that
%% quietly wrote `checked="checked"' would be inventing a value the caller
%% did not give it.

xml_attributes([]) --> [].
xml_attributes([A|As]) --> " ", xml_attribute(A), xml_attributes(As).

xml_attribute(V) --> { var(V) }, !,
    { throw(error(instantiation_error, xml_codes/2)) }.
xml_attribute(Name=Value) --> !, xml_attribute_pair(Name, Value).
xml_attribute(Name-Value) --> !, xml_attribute_pair(Name, Value).
xml_attribute(A) --> { throw(error(type_error(xml_attribute, A), xml_codes/2)) }.

xml_attribute_pair(Name, Value) -->
    xml_name(Name), "=\"",
    { xml_text_codes(Value, Cs) }, xml_escaped_attr(Cs),
    "\"".

%% A NAME IS WRITTEN AS-IS, and that is a decision. Validating it against
%% XML's NameStartChar production would need a UTF-8 decoder this file
%% does not have, and half-validating -- ASCII letters only -- would
%% refuse every non-English document. What IS checked is the NUL, in
%% `xml_text_codes' below, because that one truncates rather than merely
%% offending a parser.
xml_name(Name) --> { xml_text_codes(Name, Cs) }, xml_raw(Cs).

%% ---- text ------------------------------------------------------------

xml_text_codes(A, Cs) :- atom(A), !, atom_codes(A, Cs), xml_no_nul(Cs, A).
xml_text_codes(N, Cs) :- number(N), !, number_codes(N, Cs).
xml_text_codes(str(X), Cs) :- !, xml_text_codes(X, Cs).
xml_text_codes(Cs, Cs) :- is_list(Cs), !, xml_no_nul(Cs, Cs).
xml_text_codes(X, _) :- throw(error(type_error(xml_text, X), xml_codes/2)).

xml_no_nul([], _).
xml_no_nul([C|Cs], Whole) :-
    (   C =:= 0
    ->  throw(error(domain_error(xml_text, Whole), xml_codes/2))
    ;   xml_no_nul(Cs, Whole)
    ).

%% `>' IS ESCAPED IN TEXT although only `&' and `<' strictly must be. The
%% spec's own reason is the third one: a `]]>' appearing in content is
%% forbidden outside a CDATA section, and escaping every `>' is how you
%% never have to think about which ones were part of one.
xml_escaped([]) --> [].
xml_escaped([C|Cs]) --> xml_escape(C), xml_escaped(Cs).

xml_escape(0'&) --> !, "&amp;".
xml_escape(0'<) --> !, "&lt;".
xml_escape(0'>) --> !, "&gt;".
xml_escape(C) --> [C].

%% ATTRIBUTE VALUES ARE QUOTED WITH `"', so that is the one that must go;
%% the apostrophe is escaped anyway, so a value can be dropped into
%% single-quoted markup by hand without a second pass.
xml_escaped_attr([]) --> [].
xml_escaped_attr([C|Cs]) --> xml_escape_attr(C), xml_escaped_attr(Cs).

xml_escape_attr(0'&) --> !, "&amp;".
xml_escape_attr(0'<) --> !, "&lt;".
xml_escape_attr(0'>) --> !, "&gt;".
xml_escape_attr(0'") --> !, "&quot;".
xml_escape_attr(0'') --> !, "&#39;".
xml_escape_attr(0'\n) --> !, "&#10;".
xml_escape_attr(0'\r) --> !, "&#13;".
xml_escape_attr(0'\t) --> !, "&#9;".
xml_escape_attr(C) --> [C].

%% ---- CDATA, comments -------------------------------------------------

xml_cdata(Text) --> { xml_text_codes(Text, Cs) }, "<![CDATA[", xml_cdata_body(Cs), "]]>".

%% THE SPLIT, and it is why this is a nonterminal rather than a straight
%% copy: `]]>' inside the payload would end the section early, so the
%% section is ended and reopened around the `>'. Every parser puts the two
%% halves back together as one text node.
xml_cdata_body([]) --> [].
xml_cdata_body([0'], 0'], 0'>|Cs]) --> !, "]]]]><![CDATA[>", xml_cdata_body(Cs).
xml_cdata_body([C|Cs]) --> [C], xml_cdata_body(Cs).

xml_comment(Text) -->
    { xml_text_codes(Text, Cs),
      (   xml_has_double_dash(Cs)
      ->  throw(error(domain_error(xml_comment, Text), xml_codes/2))
      ;   true
      ) },
    "<!--", xml_raw(Cs), "-->".

xml_has_double_dash([0'-, 0'-|_]) :- !.
xml_has_double_dash([_|Cs]) :- xml_has_double_dash(Cs).

%% ---- a code list, verbatim -------------------------------------------
%%
%% A BODY ITEM THAT IS A VARIABLE IS A CALL, not a literal: `--> Cs' with
%% Cs bound to a list translates to `phrase(Cs, S0, S)', which calls a
%% predicate named after the first element. This walks it instead.
xml_raw([]) --> [].
xml_raw([C|Cs]) --> [C], xml_raw(Cs).

%% ======================================================================
%% ---- READING: XML text as an element tree ----------------------------
%% ======================================================================
%%
%% THE INVERSE OF EVERYTHING ABOVE, and deliberately the same tree. What
%% `xml_codes/2' writes, `xml_parse/2' reads back, and `test/serialize.sh'
%% checks the round trip in both directions -- a reader and a writer that
%% disagree about the same document are worse than either one alone.
%%
%%     xml_parse(+Text, -Element)           Text is codes OR an atom
%%     xml_parse(+Text, -Element, +Options)
%%     xml_input(-Element)//                the nonterminal, for a grammar
%%                                          with XML inside it
%%
%% IT ANSWERS THE ROOT ELEMENT, one element and not a list, because XML
%% requires exactly one. The declaration, the DOCTYPE and any comment or
%% processing instruction OUTSIDE the root are skipped: none of them is a
%% node in this tree, and there is nowhere honest to put them. Comments
%% and PIs INSIDE the root are kept, as `comment/1' and `pi/1'.
%%
%% ---- THERE IS NO DTD, AND THAT IS THE SECURITY DECISION ---------------
%%
%% This parser SKIPS the DOCTYPE declaration -- internal subset and all --
%% and never opens a file or a socket for anything. It has no code that
%% could: there is no fetching in this library at all.
%%
%% That makes the whole XXE family structurally impossible rather than
%% defended against. An entity a DOCTYPE declared is therefore never
%% defined, so `&whatever;' in the content is an ERROR naming the entity,
%% which is the honest answer: the parser cannot know what it expands to
%% and will not guess. The five predefined entities and numeric character
%% references are all that exist here.
%%
%% ---- WHAT COMES BACK -------------------------------------------------
%%
%%     an element     element(Name, [Name=Value, ...], Children)
%%     text           an ATOM, entities resolved, runs merged
%%     a comment      comment(Text)
%%     a PI           pi(Text)
%%
%% CDATA COMES BACK AS TEXT, not as `cdata/1', because to XML that is what
%% it IS: the section is a SPELLING of character data, not a kind of node,
%% and `<p><![CDATA[a<b]]></p>' and `<p>a&lt;b</p>' are the same document.
%% A consumer that had to handle both spellings for the same content would
%% be doing the parser's job. The writer still has `cdata/1' for when you
%% want that spelling on the way out.
%%
%% ADJACENT TEXT IS ONE NODE. A run of characters, an entity reference and
%% a CDATA section next to each other are one atom, because they are one
%% text node to XML -- and a consumer matching `element(p, [], [Text])'
%% should not have to care how the author spelled it.
%%
%% ---- OPTIONS ---------------------------------------------------------
%%
%%     space(preserve)   every text node is kept -- the default
%%     space(remove)     text nodes that are ENTIRELY whitespace are
%%                       dropped, which is what turns an indented document
%%                       back into the tree somebody meant
%%
%% `space(remove)' DROPS ONLY ALL-WHITESPACE NODES, never the whitespace
%% inside a node that has other characters in it. Trimming `  hello  ' to
%% `hello' would be editing content, and this library's writer already
%% refuses to indent mixed content for the same reason.
%%
%% ---- NAMES ARE NOT VALIDATED, which matches the writer ----------------
%%
%% A name is read as the run of bytes up to a delimiter. Checking it
%% against XML's NameStartChar production needs a UTF-8 decoder this file
%% does not have, and half-checking -- ASCII letters only -- would refuse
%% every document not written in English. Namespace prefixes therefore
%% come back attached: `svg:rect' is the atom `svg:rect', not a resolved
%% namespace, which is also what the writer takes.

%% ---- the entry points ------------------------------------------------

%% xml_parse(+Text, -Element) is det.
xml_parse(Text, Element) :- xml_parse(Text, Element, []).

%% xml_parse(+Text, -Element, +Options) is det.
xml_parse(Text, Element, Options) :-
    xml_in_codes(Text, Cs),
    phrase(xml_only(Element, Options), Cs).

%% xml_input(-Element)// is det.
%% One element, for a caller whose grammar has XML inside it.
xml_input(Element) --> xml_element_in(Element, []).

xml_in_codes(Text, Cs) :- is_list(Text), !, Cs = Text.
xml_in_codes(Text, Cs) :- atom(Text), !, atom_codes(Text, Cs).
xml_in_codes(Text, _) :- throw(error(type_error(xml_text, Text), xml_parse/2)).

xml_only(Element, Options) -->
    xml_prologue,
    xml_element_in(Element, Options),
    xml_prologue,
    xml_at_eof.

xml_at_eof([], []) :- !.
xml_at_eof(Rest, _) :- xml_oops('the end of the document after the root element', Rest).

%% THE ERROR CARRIES A SNIPPET, for the reason library(json)'s does: an
%% offset is only useful with the document beside it, and forty bytes of
%% what was actually there is readable in a log by somebody who has not
%% got the file.
xml_oops(What, Rest) :-
    xml_snippet(Rest, 40, Cs),
    atom_codes(Where, Cs),
    throw(error(syntax_error(What), xml_at(Where))).

xml_snippet(_, 0, []) :- !.
xml_snippet([], _, []) :- !.
xml_snippet([C|Cs], N, Out) :-
    (   C =:= 0
    ->  Out = []
    ;   Out = [C|Rest], M is N - 1, xml_snippet(Cs, M, Rest)
    ).

%% ---- the prologue, and everything in it that is skipped --------------

xml_prologue --> xml_ws_in, xml_prologue_item, !, xml_prologue.
xml_prologue --> xml_ws_in.

xml_prologue_item --> "<?", !, xml_pi_body(_).
xml_prologue_item --> "<!--", !, xml_comment_body(_).
xml_prologue_item --> "<!DOCTYPE", !, xml_doctype_skip(0).

%% THE INTERNAL SUBSET IS COUNTED, not searched for a `>'. A DOCTYPE may
%% carry declarations in brackets and those contain `>' freely, so a skip
%% that stopped at the first one would leave the parser inside the subset
%% reading entity declarations as markup.
xml_doctype_skip(0) --> [0'>], !.
xml_doctype_skip(N) --> [0'[], !, { M is N + 1 }, xml_doctype_skip(M).
xml_doctype_skip(N) --> [0']], !, { M is N - 1 }, xml_doctype_skip(M).
xml_doctype_skip(N) --> [_], !, xml_doctype_skip(N).
xml_doctype_skip(_, Rest, _) :- xml_oops('the end of the DOCTYPE declaration', Rest).

xml_ws_in --> [C], { xml_ws_code(C) }, !, xml_ws_in.
xml_ws_in --> [].

xml_ws_code(0' ).
xml_ws_code(0'\t).
xml_ws_code(0'\n).
xml_ws_code(0'\r).

%% ---- an element ------------------------------------------------------

xml_element_in(element(Name, Attrs, Kids), Options) -->
    [0'<], !,
    xml_name_in(NameCs), { atom_codes(Name, NameCs) },
    xml_attrs_in(Attrs),
    xml_tag_close(Shape),
    xml_element_body(Shape, Name, Kids, Options).
xml_element_in(_, _, Rest, _) :- xml_oops('an element', Rest).

xml_element_body(empty, _, [], _) --> [].
xml_element_body(open, Name, Kids, Options) --> xml_kids_in(Name, Kids, Options).

xml_tag_close(empty) --> "/>", !.
xml_tag_close(open) --> [0'>], !.
xml_tag_close(_, Rest, _) :- xml_oops('the end of the start tag', Rest).

%% ---- names -----------------------------------------------------------

xml_name_in([C|Cs]) --> [C], { xml_name_code(C) }, !, xml_name_rest(Cs).
xml_name_in(_, Rest, _) :- xml_oops('an element or attribute name', Rest).

xml_name_rest([C|Cs]) --> [C], { xml_name_code(C) }, !, xml_name_rest(Cs).
xml_name_rest([]) --> [].

xml_name_code(C) :- C > 0x20, \+ xml_name_stop(C).

xml_name_stop(0'<).
xml_name_stop(0'>).
xml_name_stop(0'/).
xml_name_stop(0'=).
xml_name_stop(0'").
xml_name_stop(0'').
xml_name_stop(0'?).
xml_name_stop(0'&).

%% ---- attributes ------------------------------------------------------

xml_attrs_in(Attrs) --> xml_ws_in, xml_attrs_more(Attrs).

xml_attrs_more([]) --> xml_peek_tag_close, !.
xml_attrs_more([A|As]) --> xml_attr_in(A), xml_ws_in, xml_attrs_more(As).

xml_peek_tag_close([0'>|S], [0'>|S]).
xml_peek_tag_close([0'/, 0'>|S], [0'/, 0'>|S]).

xml_attr_in(Name=Value) -->
    xml_name_in(NameCs), { atom_codes(Name, NameCs) },
    xml_ws_in, xml_eq, xml_ws_in,
    xml_attvalue_in(ValueCs), { xml_atom_of(ValueCs, Value) }.

xml_eq --> [0'=], !.
xml_eq(Rest, _) :- xml_oops('an equals sign after the attribute name', Rest).

%% BOTH QUOTES ARE LEGAL and the closing one must match the opening one,
%% which is why the quote is threaded through rather than matched by a
%% second literal.
xml_attvalue_in(Cs) --> [Q], { Q == 0'" ; Q == 0'' }, !, xml_attvalue_rest(Q, Cs).
xml_attvalue_in(_, Rest, _) :- xml_oops('a quoted attribute value', Rest).

xml_attvalue_rest(Q, []) --> [Q], !.
xml_attvalue_rest(Q, Out) --> [0'&], !, xml_entity_in(A), xml_attvalue_rest(Q, B),
    { append(A, B, Out) }.
%% A RAW `<' IN AN ATTRIBUTE VALUE IS NOT WELL-FORMED, and this is the one
%% well-formedness rule worth enforcing by hand: it is the difference
%% between a document and a document with an unclosed tag in it, and every
%% other parser will reject what this one would have accepted.
xml_attvalue_rest(_, _, [0'<|_], _) :- !,
    xml_oops('an escaped &lt; -- a raw < is not legal in an attribute value',
             [0'<]).
xml_attvalue_rest(Q, [C|Cs]) --> [C], !, xml_attvalue_rest(Q, Cs).
xml_attvalue_rest(_, _, Rest, _) :- xml_oops('the closing quote of the attribute value', Rest).

%% ---- children --------------------------------------------------------
%%
%% THE SHAPE IS: eat character data, then look at what stopped it. Because
%% CDATA is character data, `xml_chars_in' swallows a whole section and
%% goes on, which is what makes adjacent runs come back as ONE text node
%% with no joining pass afterwards.

xml_kids_in(Name, Kids, Options) -->
    xml_chars_in(Cs),
    xml_peek_what(What),
    xml_kids_step(What, Name, Cs, Kids, Options).

xml_kids_step(end, Name, Cs, Kids, Options) --> !,
    xml_end_tag_in(Name),
    { xml_text_node(Cs, Options, Kids, []) }.
xml_kids_step(comment, Name, Cs, Kids, Options) --> !,
    "<!--", xml_comment_body(T),
    xml_kids_in(Name, Rest, Options),
    { xml_text_node(Cs, Options, Kids, [comment(T)|Rest]) }.
xml_kids_step(pi, Name, Cs, Kids, Options) --> !,
    "<?", xml_pi_body(T),
    xml_kids_in(Name, Rest, Options),
    { xml_text_node(Cs, Options, Kids, [pi(T)|Rest]) }.
xml_kids_step(element, Name, Cs, Kids, Options) --> !,
    xml_element_in(E, Options),
    xml_kids_in(Name, Rest, Options),
    { xml_text_node(Cs, Options, Kids, [E|Rest]) }.
xml_kids_step(eof, Name, _, _, _, _, _) :-
    throw(error(syntax_error(unclosed_element(Name)), xml_at(end_of_input))).

xml_peek_what(W, S, S) :- xml_what(S, W).

xml_what([], eof) :- !.
xml_what([0'<, 0'/|_], end) :- !.
xml_what([0'<, 0'!, 0'-, 0'-|_], comment) :- !.
xml_what([0'<, 0'?|_], pi) :- !.
xml_what([0'<|_], element) :- !.
xml_what(Rest, _) :- xml_oops('markup or the end of the element', Rest).

xml_end_tag_in(Name) -->
    "</", xml_name_in(EndCs), xml_ws_in, xml_gt,
    { atom_codes(End, EndCs),
      (   End == Name
      ->  true
      ;   throw(error(syntax_error(mismatched_end_tag(Name, End)), xml_at(End)))
      ) }.

xml_gt --> [0'>], !.
xml_gt(Rest, _) :- xml_oops('the closing > of an end tag', Rest).

%% A TEXT NODE IS ONLY A NODE IF THERE IS TEXT. An empty run happens on
%% every boundary between two elements, and emitting `''' for each would
%% double the length of every tree.
xml_text_node([], _, Kids, Kids) :- !.
xml_text_node(Cs, Options, Kids, Tail) :-
    (   memberchk(space(remove), Options),
        xml_all_space(Cs)
    ->  Kids = Tail
    ;   xml_atom_of(Cs, A),
        Kids = [A|Tail]
    ).

xml_all_space([]).
xml_all_space([C|Cs]) :- xml_ws_code(C), xml_all_space(Cs).

%% ---- character data, entities, CDATA ---------------------------------

xml_chars_in(Out) --> "<![CDATA[", !, xml_cdata_in(A), xml_chars_in(B),
    { append(A, B, Out) }.
xml_chars_in([]) --> xml_peek_lt, !.
xml_chars_in([]) --> xml_peek_eof, !.
xml_chars_in(Out) --> [0'&], !, xml_entity_in(A), xml_chars_in(B),
    { append(A, B, Out) }.
xml_chars_in([C|Cs]) --> [C], !, xml_chars_in(Cs).

xml_peek_lt([0'<|S], [0'<|S]).
xml_peek_eof([], []).

xml_cdata_in([]) --> "]]>", !.
xml_cdata_in([C|Cs]) --> [C], !, xml_cdata_in(Cs).
xml_cdata_in(_, Rest, _) :- xml_oops('the end of the CDATA section', Rest).

%% FIVE ENTITIES AND THE NUMERIC REFERENCES, and nothing else can exist:
%% every other entity is declared in a DTD, and this parser reads none.
%% Saying so by name beats passing `&nbsp;' through as text, which is what
%% turns one missing declaration into a document that looks fine until
%% somebody validates it.
xml_entity_in([0'&]) --> "amp;", !.
xml_entity_in([0'<]) --> "lt;", !.
xml_entity_in([0'>]) --> "gt;", !.
xml_entity_in([0'"]) --> "quot;", !.
xml_entity_in([0'']) --> "apos;", !.
xml_entity_in(Cs) --> [0'#], !, xml_charref_in(Cs).
xml_entity_in(_, Rest, _) :-
    xml_oops('one of the five predefined entities, or a numeric reference -- this parser reads no DTD, so no others are defined', Rest).

xml_charref_in(Cs) --> [0'x], !, xml_hex_digits(0, N), xml_semi, { xml_utf8(N, Cs) }.
xml_charref_in(Cs) --> xml_dec_digits(0, 0, N), xml_semi, { xml_utf8(N, Cs) }.

xml_hex_digits(Acc, N) --> [C], { xml_hex(C, D) }, !,
    { A is Acc * 16 + D }, xml_hex_more(A, N).
xml_hex_digits(_, _, Rest, _) :- xml_oops('a hex digit in the character reference', Rest).

xml_hex_more(Acc, N) --> [C], { xml_hex(C, D) }, !,
    { A is Acc * 16 + D }, xml_hex_more(A, N).
xml_hex_more(N, N) --> [].

xml_dec_digits(Acc, _, N) --> [C], { code_type(C, digit) }, !,
    { A is Acc * 10 + (C - 0'0) }, xml_dec_digits(A, 1, N).
xml_dec_digits(N, 1, N) --> [].
xml_dec_digits(_, 0, _, Rest, _) :- xml_oops('a digit in the character reference', Rest).

xml_semi --> [0';], !.
xml_semi(Rest, _) :- xml_oops('the semicolon ending the reference', Rest).

xml_hex(C, N) :- C >= 0'0, C =< 0'9, !, N is C - 0'0.
xml_hex(C, N) :- C >= 0'a, C =< 0'f, !, N is C - 0'a + 10.
xml_hex(C, N) :- C >= 0'A, C =< 0'F, !, N is C - 0'A + 10.

%% ---- comments and processing instructions ----------------------------
%%
%% THE OPENING IS ALREADY EATEN in both, for the reason library(json)'s
%% string reader gives: the dispatch had to look at those bytes to know
%% which of the four things this was.

xml_comment_body(Text) --> xml_comment_codes(Cs), { xml_atom_of(Cs, Text) }.

xml_comment_codes([]) --> "-->", !.
xml_comment_codes([C|Cs]) --> [C], !, xml_comment_codes(Cs).
xml_comment_codes(_, Rest, _) :- xml_oops('the end of the comment', Rest).

xml_pi_body(Text) --> xml_pi_codes(Cs), { xml_atom_of(Cs, Text) }.

xml_pi_codes([]) --> "?>", !.
xml_pi_codes([C|Cs]) --> [C], !, xml_pi_codes(Cs).
xml_pi_codes(_, Rest, _) :- xml_oops('the end of the processing instruction', Rest).

%% ---- UTF-8, and why there are two copies of it -----------------------
%%
%% A NUMERIC CHARACTER REFERENCE NAMES A CODE POINT and this library deals
%% in bytes, so something has to encode it. library(json) has the same
%% eight lines for the same reason.
%%
%% THAT IS DUPLICATION ON PURPOSE, and the distinction is worth stating
%% because library(html) does the opposite -- it calls this file's
%% escapers by name rather than copying them. An ESCAPER encodes a POLICY:
%% which characters this project decided to escape, and two copies of a
%% policy drift. RFC 3629 is a FIXED TRANSFORM that cannot drift, and
%% copying it is what lets library(json) stand alone rather than importing
%% a markup library to read a JSON string.
xml_utf8(0, _) :-
    throw(error(syntax_error('any character but a NUL -- an atom stops there'),
                xml_at(zero))).
xml_utf8(C, [C]) :- C < 0x80, !.
xml_utf8(C, [A, B]) :- C < 0x800, !,
    A is 0xC0 \/ (C >> 6), B is 0x80 \/ (C /\ 0x3F).
xml_utf8(C, [A, B, D]) :- C < 0x10000, !,
    A is 0xE0 \/ (C >> 12), B is 0x80 \/ ((C >> 6) /\ 0x3F), D is 0x80 \/ (C /\ 0x3F).
xml_utf8(C, [A, B, D, E]) :-
    A is 0xF0 \/ (C >> 18), B is 0x80 \/ ((C >> 12) /\ 0x3F),
    D is 0x80 \/ ((C >> 6) /\ 0x3F), E is 0x80 \/ (C /\ 0x3F).

xml_atom_of(Cs, Atom) :- xml_no_nul(Cs, Cs), atom_codes(Atom, Cs).
