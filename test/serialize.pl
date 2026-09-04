%% library(json), library(xml), library(html) -- the three serialisers.
%%
%% WHAT IS ACTUALLY WORTH CHECKING HERE is not that a nested term comes out
%% nested. It is the ESCAPING and the REFUSALS, because those are the two
%% places a serialiser is silently wrong rather than loudly wrong:
%%
%%   * escaping, because the failure is not an error -- it is a document
%%     that parses into something ELSE at the far end, and the only way to
%%     see it is to put the awkward byte in and read what came out;
%%   * refusals, because the alternative to throwing is emitting something
%%     plausible, and a `"foo(1)"' or a `<br>text</br>' is discovered days
%%     later by whoever has to read it.
%%
%% So the awkward cases are the bulk of the file and the happy path is four
%% lines. Every check compares against a string written out by hand: a case
%% that computed its expectation from the same code it is testing would
%% agree with any bug at all.
%%
%% AND THEN THE ROUND TRIP, once the readers are in. Write a document, read
%% it, write it again, compare the two texts: a reader and a writer that
%% disagree about the same bytes are worse than either one alone, and no
%% amount of hand-written expectations on each half finds a disagreement
%% between them.
%%
%%     cocolog -s test/serialize.pl      from the checkout root
%%
%% ONE PROCESS FOR ALL 114 CHECKS. This was test/serialize.sh: 114 cocolog
%% invocations, 15.6 s on this machine, for answers that take well under a
%% second to compute. The pins are the .sh's own, byte for byte -- a check
%% that compared a written term compares the same written text here,
%% through written/3, rather than a term re-guessed from it.

:- use_module('test/prelude.pl').
:- use_module(library(json)).
:- use_module(library(xml)).
:- use_module(library(html)).

main :-
    json_writes, json_escapes, json_lists, json_refusals, json_indent,
    xml_writes, xml_payloads, xml_refusals, xml_indent,
    html_writes, html_raw, together,
    json_reads, json_read_escapes, json_strict, json_streaming, json_round_trip,
    xml_reads, xml_prologue, xml_read_refusals, xml_space, xml_round_trip,
    html_reads, html_unclosed, html_raw_reads, html_round_trip,
    agreement, css_reads, css_refusals,
    checks_done.

json_writes :-
    section('library(json): what maps to what'),
    written(json_atom(json([b-1, a-2]), A1), A1, G1),
    check('an object keeps the order it was given', G1, '{"b":1,"a":2}'),
    written(json_atom(json([a-1, b=2, c:3]), A2), A2, G2),
    check('the three pair spellings all read as pairs', G2, '{"a":1,"b":2,"c":3}'),
    written(json_atom(json([xs-[1,2], ok- @(true), in-json([n- @(null)])]), A3), A3, G3),
    check('an array, a literal and a nested object', G3, '{"xs":[1,2],"ok":true,"in":{"n":null}}'),
    %% EMPTY IS FLAT, at any indent. There is nothing to put on a line of its own.
    written(( json_atom(json([a-json([]), b-[]]), A4, [indent(2)]),
              (   sub_atom(A4, _, _, _, '{}'), sub_atom(A4, _, _, _, '[]')
              ->  R4 = flat ; R4 = broken ) ), R4, G4),
    check('an empty object and an empty array are flat', G4, flat).

json_escapes :-
    section('library(json): escaping, which is where it is silently wrong'),
    written(json_atom(json([k-'a"b\\c']), A1), A1, G1),
    check('a quote and a backslash', G1, '{"k":"a\\"b\\\\c"}'),
    written(( atom_codes(V2, [0'a, 9, 10, 13, 8, 12, 0'b]),
              json_atom(json([k-V2]), A2) ), A2, G2),
    check('the named control escapes', G2, '{"k":"a\\t\\n\\r\\b\\fb"}'),
    %% A CONTROL WITH NO SHORT NAME becomes \u00XX, which is what RFC 8259
    %% requires and the only escape in this file that is computed rather than
    %% looked up.
    written(( atom_codes(V3, [1, 31]), json_atom(json([k-V3]), A3) ), A3, G3),
    check('an unnamed control becomes a \\u escape', G3, '{"k":"\\u0001\\u001f"}'),
    %% UTF-8 PASSES THROUGH. There is no decoder in the library, so the bytes
    %% of a two-byte sequence must come out as themselves -- an escape here
    %% would mean the library had guessed at an encoding.
    written(( atom_codes(V4, [0xC3, 0xA9]), json_atom(json([k-V4]), A4),
              atom_length(A4, N4) ), N4, G4),
    check('a UTF-8 byte pair is not escaped', G4, '10').

json_lists :-
    section('library(json): a code list is a list, and str/1 is the way out'),
    written(json_atom("hi", A1), A1, G1),
    check('a bare code list is an ARRAY, as documented', G1, '[104,105]'),
    written(json_atom(str("hi"), A2), A2, G2),
    check('str/1 makes it a string', G2, '"hi"'),
    written(json_atom(json([str("k")-1]), A3), A3, G3),
    check('and str/1 works on a key too', G3, '{"k":1}').

json_refusals :-
    section('library(json): what it refuses, and it refuses by throwing'),
    written(catch(json_atom(json([a-_]), _), error(E1, _), true), E1, G1),
    check('an unbound variable is an error, not null', G1, instantiation_error),
    written(catch(json_atom(foo(1), _), error(E2, _), true), E2, G2),
    check('a term with no JSON meaning names itself', G2, 'type_error(json_term,foo(1))'),
    written(catch(json_atom(@(maybe), _), error(E3, _), true), E3, G3),
    check('a fourth literal is not a literal', G3, 'type_error(json_term,@(maybe))'),
    written(catch(json_atom(json([oops]), _), error(E4, _), true), E4, G4),
    check('an object member that is not a pair', G4, 'type_error(json_pair,oops)').

json_indent :-
    section('library(json): indenting'),
    written(( json_atom(json([a-[1]]), A1, [indent(2)]),
              atomic_list_concat(L1, '\n', A1), length(L1, N1) ), N1, G1),
    check('indent(2) breaks members and nests', G1, '5'),
    written(( json_atom(json([a-1, b-2]), A2),
              ( sub_atom(A2, _, _, _, ' ') -> R2 = spaced ; R2 = compact ) ), R2, G2),
    check('and the default is compact -- no space at all', G2, compact).

xml_writes :-
    section('library(xml): the tree, and the empty element'),
    written(xml_atom(element(p, [], ['a < b & c']), A1), A1, G1),
    check('text is escaped, markup is not', G1, '<p>a &lt; b &amp; c</p>'),
    written(xml_atom(element(br, [], []), A2), A2, G2),
    check('an empty element closes itself', G2, '<br/>'),
    written(xml_atom(element(a, [t-'say "hi"'], []), A3), A3, G3),
    check('an attribute value is escaped for a quote', G3, '<a t="say &quot;hi&quot;"/>'),
    written(xml_atom(element(a, [href='x?a=1&b=2'], []), A4), A4, G4),
    check('an ampersand in an attribute too', G4, '<a href="x?a=1&amp;b=2"/>'),
    written(xml_atom([element(a,[],[]), element(b,[],[])], A5), A5, G5),
    check('a list at the top is a fragment', G5, '<a/><b/>').

xml_payloads :-
    section('library(xml): the two payloads that can end their own container'),
    %% THE CDATA SPLIT. `]]>' inside a section would end it early, so the
    %% section is closed and reopened around the `>'. Every parser puts the two
    %% halves back together, which is why this is repaired rather than refused.
    written(xml_atom(element(d, [], [cdata('a ]]> b')]), A1), A1, G1),
    check(']]> inside CDATA is split, not refused', G1, '<d><![CDATA[a ]]]]><![CDATA[> b]]></d>'),
    written(catch(xml_atom(element(d,[],[comment('a--b')]), _), error(E2,_), true), E2, G2),
    check('a comment with -- IS refused, because XML has no escape for it', G2, 'domain_error(xml_comment,a--b)').

xml_refusals :-
    section('library(xml): what it refuses'),
    written(catch(xml_atom(element(i, [checked], []), _), error(E1,_), true), E1, G1),
    check('a bare attribute -- XML has no minimised form', G1, 'type_error(xml_attribute,checked)'),
    written(catch(xml_atom(element(p, [], ["hi"]), _), error(E2,_), true), E2, G2),
    check('a code list among the children names itself', G2, 'type_error(xml_node,[104,105])'),
    written(xml_atom(element(p, [], [str("hi")]), A3), A3, G3),
    check('and str/1 is how that is written', G3, '<p>hi</p>'),
    %% A NUL CANNOT BE WRITTEN AS XML AT ALL, and passing it through would
    %% truncate the atom rather than produce a bad document -- which is a much
    %% quieter failure.
    written(( catch(xml_atom(element(p,[],[str([0'a, 0, 0'b])]), _), error(E4,_), true),
              ( E4 = domain_error(xml_text, _) -> R4 = refused ; R4 = E4 ) ), R4, G4),
    check('a NUL byte in text is refused rather than truncating', G4, refused).

xml_indent :-
    section('library(xml): the indent rule, which is the whole reason it has one'),
    %% ELEMENT-ONLY CONTENT INDENTS. A whitespace node between elements is what
    %% a schema-aware reader already ignores.
    written(( xml_atom(element(r,[],[element(a,[],[]), element(b,[],[])]), A1, [indent(2)]),
              atomic_list_concat(L1, '\n', A1), length(L1, N1) ), N1, G1),
    check('element-only content is broken across lines', G1, '4'),
    %% MIXED CONTENT DOES NOT, because there the whitespace is data.
    written(xml_atom(element(m,[],[element(a,[],[]), 'text']), A2, [indent(2)]), A2, G2),
    check('mixed content stays on ONE line, whatever the indent', G2, '<m><a/>text</m>'),
    written(( xml_atom(element(r,[],[]), A3, [header(true)]),
              sub_atom(A3, 0, 5, _, S3) ), S3, G3),
    check('the header and doctype go in front', G3, '<?xml').

html_writes :-
    section('library(html): where it differs from XML, which is the point'),
    written(html_atom(element(br, [], []), A1), A1, G1),
    check('a void element does NOT self-close', G1, '<br>'),
    written(html_atom(element(input, [type=checkbox, checked], []), A2), A2, G2),
    check('a bare attribute IS the minimised form here', G2, '<input type="checkbox" checked>'),
    written(( catch(html_atom(element(br, [], ['x']), _), error(E3,_), true),
              ( E3 = domain_error(html_empty_content, _) -> R3 = refused ; R3 = E3 ) ), R3, G3),
    check('giving a void element children is an error', G3, refused),
    written(html_atom(element(a, [href='/x?a=1&b=2'], ['a < b']), A4), A4, G4),
    check('text and attributes escape the same as XML''s', G4, '<a href="/x?a=1&amp;b=2">a &lt; b</a>'),
    written(( html_atom(element(html,[],[]), A5, [doctype(true)]),
              sub_atom(A5, 0, 15, _, S5) ), S5, G5),
    check('doctype(true) is HTML5''s', G5, '<!DOCTYPE html>').

html_raw :-
    section('library(html): raw text, and the one check that is not escaping'),
    %% ESCAPING A SCRIPT WOULD BREAK IT. `a < b' must reach the JavaScript
    %% parser as `a < b', so the content goes out untouched...
    written(html_atom(element(script, [], [str("if (a < b) f();")]), A1), A1, G1),
    check('script content is NOT escaped', G1, '<script>if (a < b) f();</script>'),
    %% ...which leaves exactly one hazard, and it is the one that tears a page
    %% in half. The tokenizer is case-insensitive, so the check has to be.
    written(( catch(html_atom(element(script,[],[str("x = '</script>'")]), _), error(E2,_), true),
              ( E2 = domain_error(html_raw_text, script) -> R2 = refused ; R2 = E2 ) ), R2, G2),
    check('but a </script inside it is refused', G2, refused),
    written(( catch(html_atom(element(script,[],[str("x = '</ScRiPt>'")]), _), error(E3,_), true),
              ( E3 = domain_error(html_raw_text, script) -> R3 = refused ; R3 = E3 ) ), R3, G3),
    check('and the refusal does not care about case', G3, refused),
    written(( catch(html_atom(element(d,[],[comment('a --> b')]), _), error(E4,_), true),
              ( E4 = domain_error(html_comment, _) -> R4 = refused ; R4 = E4 ) ), R4, G4),
    check('a --> inside a comment is refused for the same reason', G4, refused),
    %% `--' ALONE IS FINE HERE and refused by library(xml): HTML5's comment
    %% tokenizer ends on `-->' and nothing else. The two libraries disagree
    %% because the two languages do.
    written(html_atom(element(d,[],[comment('a--b')]), A5), A5, G5),
    check('but a bare -- is fine, unlike in XML', G5, '<d><!--a--b--></d>'),
    written(catch(html_atom(element(d,[],[cdata(x)]), _), error(E6,_), true), E6, G6),
    check('cdata is refused: HTML5 has no CDATA sections', G6, 'type_error(html_node,cdata(x))').

together :-
    section('the three of them together, which is the real use'),
    %% A JSON BODY INSIDE AN HTML PAGE, which is what a page that ships its own
    %% data does -- and the reason library(json) does not escape the solidus is
    %% that THIS is where the hazard lives, and here it is caught by name.
    written(( json_atom(json([k-'</script>']), Body1),
              catch(html_atom(element(script,[],[Body1]), _), error(E1,_), true),
              ( E1 = domain_error(html_raw_text, script) -> R1 = refused ; R1 = E1 ) ), R1, G1),
    check('a JSON document inside a <script> is refused if it can close it', G1, refused),
    written(( json_atom(json([k-1]), Body2),
              html_atom(element(script,[type='application/json'],[Body2]), A2) ), A2, G2),
    check('and goes through when it cannot', G2, '<script type="application/json">{"k":1}</script>'),
    %% THE WHOLE POINT, in one line: a page is a term, and the term is data.
    written(( html_atom(element(html,[],[element(body,[],[element(p,[],['hi'])])]), A3, [doctype(true)]),
              atomic_list_concat(L3, '\n', A3), length(L3, N3) ), N3, G3),
    check('a page built as a term comes out as a page', G3, '2').

json_reads :-
    section('library(json): reading it back'),
    written(json_parse('{"a":1,"b":[true,false,null]}', T1), T1, G1),
    check('an object, an array and the three literals', G1, 'json([a-1,b-[@(true),@(false),@(null)]])'),
    written(( json_parse('{"k":"v"}', json([K2-V2])),
              ( atom(K2), atom(V2) -> R2 = atoms ; R2 = something_else ) ), R2, G2),
    check('a string comes back as an ATOM, so it can be written again', G2, atoms),
    written(( json_parse('""', T3), ( T3 == '' -> R3 = empty_atom ; R3 = T3 ) ), R3, G3),
    check('an empty string is \'\' and not the empty list', G3, empty_atom),
    written(( json_parse('[1,2.5,-3,1e2]', [A4,B4,C4,D4]),
              ( integer(A4), float(B4), integer(C4), float(D4) -> R4 = kept ; R4 = lost ) ), R4, G4),
    check('integers and floats keep their kinds', G4, kept),
    written(json_parse('  { "a" : [ 1 , 2 ] }  ', T5), T5, G5),
    check('whitespace between tokens is skipped', G5, 'json([a-[1,2]])'),
    written(json_parse('{"a":1,"a":2}', json(Ps6)), Ps6, G6),
    check('duplicate keys are all kept, in order', G6, '[a-1,a-2]').

json_read_escapes :-
    section('library(json): escapes, and the ones that are two code units'),
    written(( json_parse('"a\\tb\\nc"', T1), atom_codes(T1, Cs1) ), Cs1, G1),
    check('the named escapes come back as their bytes', G1, '[97,9,98,10,99]'),
    %% A \u ESCAPE NAMES A UTF-16 CODE UNIT and this library deals in bytes, so
    %% the parser has to encode. U+00E9 is two bytes of UTF-8.
    written(( json_parse('"\\u00e9"', T2), atom_codes(T2, Cs2) ), Cs2, G2),
    check('a \\u escape becomes UTF-8', G2, '[195,169]'),
    %% ...AND A CHARACTER ABOVE U+FFFF IS A SURROGATE PAIR, which is the whole
    %% reason the \u reader is more than one clause. U+1F600 is four bytes.
    written(( json_parse('"\\ud83d\\ude00"', T3), atom_codes(T3, Cs3) ), Cs3, G3),
    check('a surrogate pair becomes one character', G3, '[240,159,152,128]'),
    written(( catch(json_parse('"\\ud800"', _), error(syntax_error(_), _), true), R4 = refused ), R4, G4),
    check('a lone high surrogate is refused', G4, refused).

json_strict :-
    section('library(json): the strictness people leave out'),
    %% EVERY ONE OF THESE IS ACCEPTED BY SOME PARSER SOMEWHERE, which is exactly
    %% why they are refused here: they are the places two implementations
    %% disagree about the same bytes.
    refused_by_syntax(json_parse('01', _), G1),
    check('a leading zero is not a number', G1, refused),
    refused_by_syntax(json_parse('[1,]', _), G2),
    check('a trailing comma is not a shorter array', G2, refused),
    atom_codes(Doc3, [0'", 0'a, 10, 0'b, 0'"]),
    refused_by_syntax(json_parse(Doc3, _), G3),
    check('a raw newline inside a string is refused', G3, refused),
    written(( catch(json_parse('{"a" 1}', _), error(syntax_error(W4), json_at(At4)), true),
              ( sub_atom(W4, _, _, _, colon), At4 == '1}' -> R4 = precise ; R4 = W4-At4 ) ), R4, G4),
    check('a missing colon says so, and says where', G4, precise),
    %% AN INTEGER TOO BIG FOR THE MACHINE. number_codes/2 answers -1 for this
    %% and complains about nothing, which is the worst thing a JSON parser can
    %% do with a balance.
    refused_by_syntax(json_parse('12345678901234567890', _), G5),
    check('an integer past 64 bits is refused, not wrapped', G5, refused),
    written(json_parse('9007199254740993', T6), T6, G6),
    check('and one that fits is exact', G6, '9007199254740993').

%% the .sh's idiom: catch the syntax error and answer `refused' -- so a
%% parse that SUCCEEDS answers `failed' here (the catch proves, the
%% expectation does not), and one that throws something else names it
refused_by_syntax(Goal, Got) :-
    written(( catch(Goal, error(syntax_error(_), _), Caught = yes),
              Caught == yes, R = refused ), R, Got).

json_streaming :-
    section('library(json): the streaming entry point'),
    %% json_parse/3 IS library(http)'s RULE APPLIED HERE: a socket hands you
    %% what arrived, which may be one value and the start of the next.
    written(( json_parse("{\"a\":1}rest", T1, Rest1), atom_codes(A1, Rest1) ), T1-A1, G1),
    check('json_parse/3 hands back what was not this value', G1, 'json([a-1])-rest'),
    refused_by_syntax(json_parse('{"a":1}rest', _), G2),
    check('json_parse/2 refuses the same input', G2, refused).

json_round_trip :-
    section('library(json): the round trip, which is the real check'),
    %% A READER AND A WRITER THAT DISAGREE ARE WORSE THAN EITHER ALONE, so the
    %% document is written, read and written again and the two texts compared.
    written(( T1 = json([n-1, x-2.5, s-'a"b', l-[1,@(null)], o-json([k- @(true)])]),
              json_atom(T1, A1), json_parse(A1, T1b), json_atom(T1b, A1b),
              ( A1 == A1b -> R1 = same ; R1 = A1/A1b ) ), R1, G1),
    check('write, read, write again is the same document', G1, same),
    written(( T2 = json([a-[1,2], b-'x']), json_atom(T2, A2), json_parse(A2, T2b),
              ( T2 == T2b -> R2 = identical ; R2 = T2b ) ), R2, G2),
    check('and the term survives it too', G2, identical).

xml_reads :-
    section('library(xml): reading it back'),
    written(xml_parse('<a href="x">go</a>', T1), T1, G1),
    check('an element, its attributes and its text', G1, 'element(a,[href=x],[go])'),
    written(xml_parse('<a t="1&amp;2">a &lt; b</a>', T2), T2, G2),
    check('entities are resolved in text and in attributes', G2, 'element(a,[t=1&2],[a < b])'),
    written(xml_parse('<p>&#65;&#x42;</p>', T3), T3, G3),
    check('a numeric reference, either spelling', G3, 'element(p,[],[AB])'),
    written(xml_parse('<a t=\'q\'/>', T4), T4, G4),
    check('both quote characters work for an attribute', G4, 'element(a,[t=q],[])'),
    %% CDATA IS A SPELLING OF CHARACTER DATA, not a kind of node, so it comes
    %% back as text -- and merged with the text either side of it, because to
    %% XML that is one text node.
    written(xml_parse('<d>x<![CDATA[a<b]]>y</d>', T5), T5, G5),
    check('CDATA comes back as text, merged with its neighbours', G5, 'element(d,[],[xa<by])'),
    written(xml_parse('<m><!--c--><?pi y?></m>', T6), T6, G6),
    check('comments and PIs inside the root are kept', G6, 'element(m,[],[comment(c),pi(pi y)])').

xml_prologue :-
    section('library(xml): the prologue, and the DOCTYPE that is not read'),
    %% THE INTERNAL SUBSET IS COUNTED, NOT SEARCHED FOR A `>'. Without that,
    %% the skip stops inside the brackets and the parser reads an entity
    %% declaration as markup.
    written(xml_parse('<?xml version="1.0"?><!DOCTYPE r [<!ENTITY e "x">]><!-- c --><r/>', T1), T1, G1),
    check('a declaration, a DOCTYPE with an internal subset, and a comment', G1, 'element(r,[],[])'),
    %% AND THE ENTITY IT DECLARED IS STILL UNDEFINED, which is the whole XXE
    %% answer: no DTD is read, so no entity but the five predefined exists, and
    %% nothing in this library can open a file or a socket.
    refused_by_syntax(xml_parse('<!DOCTYPE r [<!ENTITY e "x">]><r>&e;</r>', _), G2),
    check('an entity that DOCTYPE declared is still unknown', G2, refused),
    refused_by_syntax(xml_parse('<a>&nbsp;</a>', _), G3),
    check('and so is any other undeclared entity', G3, refused).

xml_read_refusals :-
    section('library(xml): what it refuses, and what it names'),
    written(catch(xml_parse('<a></b>', _), error(syntax_error(W1), _), true), W1, G1),
    check('a mismatched end tag names both', G1, 'mismatched_end_tag(a,b)'),
    written(catch(xml_parse('<a><b></a>', _), error(syntax_error(W2), _), true), W2, G2),
    check('an unclosed element names itself', G2, 'mismatched_end_tag(b,a)'),
    refused_by_syntax(xml_parse('<a x=1/>', _), G3),
    check('an unquoted attribute value is not XML', G3, refused),
    refused_by_syntax(xml_parse('<a x="1<2"/>', _), G4),
    check('a raw < in an attribute value is refused', G4, refused).

xml_space :-
    section('library(xml): space(remove), and what it will NOT remove'),
    written(xml_parse('<r>\n  <a/>\n  <b/>\n</r>', T1, [space(remove)]), T1, G1),
    check('an indented document comes back as its tree', G1, 'element(r,[],[element(a,[],[]),element(b,[],[])])'),
    %% IT DROPS ALL-WHITESPACE NODES, NEVER TRIMS ONE. Turning `  hi  ' into
    %% `hi' would be editing content, which is the same line the writer draws
    %% when it refuses to indent mixed content.
    written(xml_parse('<p>  hi  </p>', T2, [space(remove)]), T2, G2),
    check('but text with anything else in it is untouched', G2, 'element(p,[],[  hi  ])').

xml_round_trip :-
    section('library(xml): the round trip'),
    written(( T1 = element(r, [a='1&2', b='q"q'], [element(c,[],['x < y']), 'tail']),
              xml_atom(T1, A1), xml_parse(A1, T1b), xml_atom(T1b, A1b),
              ( A1 == A1b -> R1 = same ; R1 = A1/A1b ) ), R1, G1),
    check('write, read, write again is the same document', G1, same),
    written(( xml_parse('<d><![CDATA[a<b]]></d>', T2), xml_atom(T2, A2) ), A2, G2),
    check('and a document with CDATA in it survives as the same TEXT', G2, '<d>a&lt;b</d>').

html_reads :-
    section('library(html): reading it back, and where it differs'),
    written(html_parse('<DIV CLASS="x">hi</DIV>', T1), T1, G1),
    check('tag and attribute names are downcased', G1, '[element(div,[class=x],[hi])]'),
    written(html_parse('<p>a<br>b</p>', T2), T2, G2),
    check('a void element takes no end tag', G2, '[element(p,[],[a,element(br,[],[]),b])]'),
    written(html_parse('<input type=checkbox checked>', T3), T3, G3),
    check('an unquoted value, and a bare attribute', G3, '[element(input,[type=checkbox,checked],[])]'),
    %% A `<' THAT IS NOT MARKUP IS TEXT, which is how a browser reads it and
    %% what makes an arithmetic comparison in a paragraph survive.
    written(html_parse('<p>a < b</p>', T4), T4, G4),
    check('a < that begins no tag is three characters of text', G4, '[element(p,[],[a < b])]'),
    %% AND AN UNKNOWN ENTITY IS TEXT TOO, which is the deliberate difference
    %% from library(xml): HTML's table has two thousand names and a browser
    %% leaves anything else alone. It is why AT&T renders as AT&T.
    written(html_parse('<p>AT&T</p>', T5), T5, G5),
    check('an unknown entity is left alone, unlike in XML', G5, '[element(p,[],[AT&T])]'),
    written(html_parse('<p>a &amp; b</p>', T6), T6, G6),
    check('a known one is still resolved', G6, '[element(p,[],[a & b])]').

html_unclosed :-
    section('library(html): the tags people do not close'),
    written(html_parse('<ul><li>one<li>two</ul>', T1), T1, G1),
    check('<li> closes an open <li>', G1, '[element(ul,[],[element(li,[],[one]),element(li,[],[two])])]'),
    written(html_parse('<p>one<p>two', T2), T2, G2),
    check('a block element closes an open paragraph', G2, '[element(p,[],[one]),element(p,[],[two])]'),
    written(html_parse('<table><tr><td>1<td>2</table>', T3), T3, G3),
    check('<td> and <tr> close each other', G3, '[element(table,[],[element(tr,[],[element(td,[],[1]),element(td,[],[2])])])]'),
    %% A MISNESTED END TAG CLOSES WHAT IT NAMES, which is what a browser does
    %% and what XML refuses outright.
    written(html_parse('<div><span>x</div>', T4), T4, G4),
    check('</div> with a <span> still open closes both', G4, '[element(div,[],[element(span,[],[x])])]'),
    written(html_parse('<p>x</p></div><p>y</p>', T5), T5, G5),
    check('and a stray end tag is discarded', G5, '[element(p,[],[x]),element(p,[],[y])]').

html_raw_reads :-
    section('library(html): raw text, read the way it was written'),
    %% THE READING HALF OF THE WRITER'S ONE SECURITY CHECK. A `<' inside a
    %% script is not markup, so the content is taken verbatim to the matching
    %% end tag -- which is exactly why the writer refuses to EMIT a </script
    %% inside one.
    written(html_parse('<script>if (a < b) f("</b>");</script>', T1), T1, G1),
    check('a script is read verbatim, angle brackets and all', G1, '[element(script,[],[if (a < b) f("</b>");])]'),
    written(html_parse('<script>x = 1;</ScRiPt>', T2), T2, G2),
    check('and it ends on its own tag whatever the case', G2, '[element(script,[],[x = 1;])]'),
    %% textarea AND title ARE ESCAPABLE RAW TEXT: no nesting, but entities do
    %% resolve. Getting that wrong either loses the & or reads a tag that is
    %% not there.
    written(html_parse('<textarea>a &amp; b</textarea>', T3), T3, G3),
    check('a textarea resolves entities but nests nothing', G3, '[element(textarea,[],[a & b])]'),
    written(html_parse('<!DOCTYPE html><!--c--><p>hi</p>', T4), T4, G4),
    check('the doctype and a comment are handled, not parsed as elements', G4, '[comment(c),element(p,[],[hi])]').

html_round_trip :-
    section('library(html): the round trip'),
    written(( T1 = [element(html, [], [element(body, [lang=en],
                     [element(p, [], ['a < b & c']), element(br, [], []),
                      element(input, [type=text, disabled], [])])])],
              html_atom(T1, A1), html_parse(A1, T1b), html_atom(T1b, A1b),
              ( A1 == A1b -> R1 = same ; R1 = A1/A1b ) ), R1, G1),
    check('write, read, write again is the same page', G1, same),
    written(( T2 = [element(script, [], ['if (a < b) go();'])],
              html_atom(T2, A2), html_parse(A2, T2b), html_atom(T2b, A2b),
              ( A2 == A2b -> R2 = same ; R2 = A2/A2b ) ), R2, G2),
    check('and a script survives being written and read', G2, same).

agreement :-
    section('and the three of them agree with each other'),
    %% THE SAME TREE THROUGH BOTH MARKUP LIBRARIES. XML and HTML share the
    %% term, so a document that is legal in both must parse to the same tree.
    written(( Doc1 = '<div class="a"><span>x</span></div>',
              xml_parse(Doc1, TX1), html_parse(Doc1, [TH1]),
              ( TX1 == TH1 -> R1 = agree ; R1 = TX1/TH1 ) ), R1, G1),
    check('a tree legal in both parses the same in both', G1, agree),
    %% AND JSON INSIDE A PAGE, read back out: the writer refuses a body that
    %% could close the script, so anything that got written can be read.
    written(( Data2 = json([k-'v', n-1]),
              json_atom(Data2, Body2),
              html_atom([element(script, [type='application/json'], [Body2])], Page2),
              html_parse(Page2, [element(script, _, [Read2])]),
              json_parse(Read2, Back2),
              ( Back2 == Data2 -> R2 = round_trip ; R2 = Back2 ) ), R2, G2),
    check('a JSON body written into a page reads back as itself', G2, round_trip).

css_reads :-
    section('CSS: the style half of the same documents'),
    %% THE ROUND TRIP IS THE REAL TEST, the same rule the three serialisers
    %% live by: parse, write, parse again, and the two terms must be equal.
    written(( css_parse('a, .nav > li { color: red; margin: 0 } @media screen { p { font: bold 12px/1.4 serif !important } }', S1),
              css_atom(S1, T1), css_parse(T1, S1b),
              ( S1 == S1b -> R1 = round_trip ; R1 = S1/S1b ) ), R1, G1),
    check('a stylesheet round-trips through its terms', G1, round_trip),
    written(css_parse('a  >  b , .c { }', [rule(Sels2, [])]), Sels2, G2),
    check('selectors split on the comma, whitespace collapsed', G2, '[a > b,.c]'),
    written(css_parse('a { color: red  !IMPORTANT }', [rule(_, [D3])]), D3, G3),
    check('!important is surfaced, never left in the value', G3, 'color-important(red)'),
    written(css_declarations('COLOR: x; --My-Var: y', Ds4), Ds4, G4),
    check('properties fold to lower case; custom properties do not', G4, '[color-x,--My-Var-y]'),
    %% THE SCANNER RESPECTS STRINGS AND PARENS: a ; inside url(...) or a
    %% quoted string is content, not structure -- losing that is how
    %% url(data:;base64,...) loses its tail.
    written(css_parse('a:is(b, c) { background: url("a;b.png") }', [rule([Sel5], [_-V5])]), Sel5/V5, G5),
    check('a ; inside url() and a , inside :is() are content', G5, 'a:is(b, c)/url("a;b.png")'),
    written(css_parse('a/**/b { content: "/*kept*/" }', [rule([Sel6], [_-V6])]), Sel6/V6, G6),
    check('comments vanish everywhere but inside a string', G6, 'a b/"/*kept*/"'),
    written(css_parse('@font-face { src: url(f.woff2) } @media print { a { } }', S7), S7, G7),
    check('@font-face reads declarations, @media reads rules, by name', G7, '[at(font-face,,decls([src-url(f.woff2)])),at(media,print,[rule([a],[])])]'),
    written(( css_declarations('color: blue; margin: 0', Ds8),
              css_declarations_atom(Ds8, A8) ), A8, G8),
    check('the style attribute half parses and writes back', G8, 'color: blue; margin: 0').

css_refusals :-
    section('CSS: they throw rather than guess, both directions'),
    written(catch(css_parse('a { color red }', _), error(E1, _), true), E1, G1),
    check('a declaration with no colon is refused, naming its text', G1, 'domain_error(css_declaration,color red)'),
    written(( catch(css_parse('a { content: "x }', _), error(E2a, _), true),
              catch(css_parse('a { color: red', _), error(E2b, _), true) ), E2a/E2b, G2),
    check('an unclosed string says string, an unclosed block says block', G2, 'domain_error(css_unclosed,string)/domain_error(css_unclosed,block)'),
    written(( catch(css_atom([rule(['a,b'], [])], _), error(E3, _), true),
              ( E3 = domain_error(css_selector, _) -> R3 = refused ; R3 = E3 ) ), R3, G3),
    check('the writer refuses a selector that would reparse as two', G3, refused),
    written(( catch(css_atom([rule([a], [c-'red; x: y'])], _), error(E4, _), true),
              ( E4 = domain_error(css_value, _) -> R4 = refused ; R4 = E4 ) ), R4, G4),
    check('and a value that would smuggle a second declaration', G4, refused),
    %% THE HTML SEAM, which is why this lives in library(html): a <style>
    %% element's raw text parses straight out of html_parse's tree.
    written(( html_parse('<style>a { color: red }</style>', [element(style, _, [Text5])]),
              css_parse(Text5, [rule([a], [D5])]) ), D5, G5),
    check('a <style> element\'s text parses straight out of the tree', G5, 'color-red').
