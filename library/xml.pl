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
%% makes for the same reason. cocolog has no string type -- `double_quotes'
%% is `codes', so `"hello"' IS `[104,101,...]' -- and a list sitting in the
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

:- use_module(library(lists)).

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
