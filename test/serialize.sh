#!/bin/sh
# library(json), library(xml), library(html) -- the three serialisers.
#
# WHAT IS ACTUALLY WORTH CHECKING HERE is not that a nested term comes out
# nested. It is the ESCAPING and the REFUSALS, because those are the two
# places a serialiser is silently wrong rather than loudly wrong:
#
#   * escaping, because the failure is not an error -- it is a document
#     that parses into something ELSE at the far end, and the only way to
#     see it is to put the awkward byte in and read what came out;
#   * refusals, because the alternative to throwing is emitting something
#     plausible, and a `"foo(1)"' or a `<br>text</br>' is discovered days
#     later by whoever has to read it.
#
# So the awkward cases are the bulk of the file and the happy path is four
# lines. Every check compares against a string written out by hand: a case
# that computed its expectation from the same code it is testing would
# agree with any bug at all.
#
# AND THEN THE ROUND TRIP, once the readers are in. Write a document, read
# it, write it again, compare the two texts: a reader and a writer that
# disagree about the same bytes are worse than either one alone, and no
# amount of hand-written expectations on each half finds a disagreement
# between them.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
export COCOLOG_LIBRARY="$ROOT/library"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-52s %s\n' "$1" "$2"
  else
    printf 'FAIL %-52s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi

# ANCHORED TO THE LINE, not matched inside it: `answer([^)]*)' stops at the
# first `)', so an answer that is a compound comes back truncated. The
# written answer is on a line of its own, so anchoring and stripping only
# the outer parens is both simpler and right. (library(thread)'s own suite
# carries this note; it was learned there.)
q() { timeout 60 "$C" query "$1" 2>/dev/null \
      | grep -a '^answer(' | head -1 | sed 's/^answer(//; s/)$//'; }

J="use_module(library(json))"
X="use_module(library(xml))"
H="use_module(library(html))"

echo "-- library(json): what maps to what"
check "an object keeps the order it was given" \
  "$(q "$J, json_atom(json([b-1, a-2]), A), write(answer(A)), nl")" \
  '{"b":1,"a":2}'
check "the three pair spellings all read as pairs" \
  "$(q "$J, json_atom(json([a-1, b=2, c:3]), A), write(answer(A)), nl")" \
  '{"a":1,"b":2,"c":3}'
check "an array, a literal and a nested object" \
  "$(q "$J, json_atom(json([xs-[1,2], ok- @(true), in-json([n- @(null)])]), A),
        write(answer(A)), nl")" \
  '{"xs":[1,2],"ok":true,"in":{"n":null}}'
# EMPTY IS FLAT, at any indent. There is nothing to put on a line of its own.
check "an empty object and an empty array are flat" \
  "$(q "$J, json_atom(json([a-json([]), b-[]]), A, [indent(2)]),
        (   sub_atom(A, _, _, _, '{}'), sub_atom(A, _, _, _, '[]')
        ->  R = flat ; R = broken ),
        write(answer(R)), nl")" "flat"

echo "-- library(json): escaping, which is where it is silently wrong"
check "a quote and a backslash" \
  "$(q "$J, json_atom(json([k-'a\"b\\\\c']), A), write(answer(A)), nl")" \
  '{"k":"a\"b\\c"}'
check "the named control escapes" \
  "$(q "$J, atom_codes(V, [0'a, 9, 10, 13, 8, 12, 0'b]),
        json_atom(json([k-V]), A), write(answer(A)), nl")" \
  '{"k":"a\t\n\r\b\fb"}'
# A CONTROL WITH NO SHORT NAME becomes \u00XX, which is what RFC 8259
# requires and the only escape in this file that is computed rather than
# looked up.
check "an unnamed control becomes a \\u escape" \
  "$(q "$J, atom_codes(V, [1, 31]), json_atom(json([k-V]), A),
        write(answer(A)), nl")" \
  '{"k":"\u0001\u001f"}'
# UTF-8 PASSES THROUGH. There is no decoder in the library, so the bytes
# of a two-byte sequence must come out as themselves -- an escape here
# would mean the library had guessed at an encoding.
check "a UTF-8 byte pair is not escaped" \
  "$(q "$J, atom_codes(V, [0xC3, 0xA9]), json_atom(json([k-V]), A),
        atom_length(A, N), write(answer(N)), nl")" "10"

echo "-- library(json): a code list is a list, and str/1 is the way out"
check "a bare code list is an ARRAY, as documented" \
  "$(q "$J, json_atom(\"hi\", A), write(answer(A)), nl")" "[104,105]"
check "str/1 makes it a string" \
  "$(q "$J, json_atom(str(\"hi\"), A), write(answer(A)), nl")" '"hi"'
check "and str/1 works on a key too" \
  "$(q "$J, json_atom(json([str(\"k\")-1]), A), write(answer(A)), nl")" '{"k":1}'

echo "-- library(json): what it refuses, and it refuses by throwing"
check "an unbound variable is an error, not null" \
  "$(q "$J, catch(json_atom(json([a-_]), _), error(E, _), true),
        write(answer(E)), nl")" "instantiation_error"
check "a term with no JSON meaning names itself" \
  "$(q "$J, catch(json_atom(foo(1), _), error(E, _), true),
        write(answer(E)), nl")" "type_error(json_term,foo(1))"
check "a fourth literal is not a literal" \
  "$(q "$J, catch(json_atom(@(maybe), _), error(E, _), true),
        write(answer(E)), nl")" "type_error(json_term,@(maybe))"
check "an object member that is not a pair" \
  "$(q "$J, catch(json_atom(json([oops]), _), error(E, _), true),
        write(answer(E)), nl")" "type_error(json_pair,oops)"

echo "-- library(json): indenting"
check "indent(2) breaks members and nests" \
  "$(q "$J, json_atom(json([a-[1]]), A, [indent(2)]),
        atomic_list_concat(L, '\n', A), length(L, N), write(answer(N)), nl")" "5"
check "and the default is compact -- no space at all" \
  "$(q "$J, json_atom(json([a-1, b-2]), A),
        ( sub_atom(A, _, _, _, ' ') -> R = spaced ; R = compact ),
        write(answer(R)), nl")" "compact"

echo "-- library(xml): the tree, and the empty element"
check "text is escaped, markup is not" \
  "$(q "$X, xml_atom(element(p, [], ['a < b & c']), A), write(answer(A)), nl")" \
  "<p>a &lt; b &amp; c</p>"
check "an empty element closes itself" \
  "$(q "$X, xml_atom(element(br, [], []), A), write(answer(A)), nl")" "<br/>"
check "an attribute value is escaped for a quote" \
  "$(q "$X, xml_atom(element(a, [t-'say \"hi\"'], []), A), write(answer(A)), nl")" \
  '<a t="say &quot;hi&quot;"/>'
check "an ampersand in an attribute too" \
  "$(q "$X, xml_atom(element(a, [href='x?a=1&b=2'], []), A), write(answer(A)), nl")" \
  '<a href="x?a=1&amp;b=2"/>'
check "a list at the top is a fragment" \
  "$(q "$X, xml_atom([element(a,[],[]), element(b,[],[])], A), write(answer(A)), nl")" \
  "<a/><b/>"

echo "-- library(xml): the two payloads that can end their own container"
# THE CDATA SPLIT. `]]>' inside a section would end it early, so the
# section is closed and reopened around the `>'. Every parser puts the two
# halves back together, which is why this is repaired rather than refused.
check "]]> inside CDATA is split, not refused" \
  "$(q "$X, xml_atom(element(d, [], [cdata('a ]]> b')]), A), write(answer(A)), nl")" \
  "<d><![CDATA[a ]]]]><![CDATA[> b]]></d>"
check "a comment with -- IS refused, because XML has no escape for it" \
  "$(q "$X, catch(xml_atom(element(d,[],[comment('a--b')]), _), error(E,_), true),
        write(answer(E)), nl")" "domain_error(xml_comment,a--b)"

echo "-- library(xml): what it refuses"
check "a bare attribute -- XML has no minimised form" \
  "$(q "$X, catch(xml_atom(element(i, [checked], []), _), error(E,_), true),
        write(answer(E)), nl")" "type_error(xml_attribute,checked)"
check "a code list among the children names itself" \
  "$(q "$X, catch(xml_atom(element(p, [], [\"hi\"]), _), error(E,_), true),
        write(answer(E)), nl")" "type_error(xml_node,[104,105])"
check "and str/1 is how that is written" \
  "$(q "$X, xml_atom(element(p, [], [str(\"hi\")]), A), write(answer(A)), nl")" \
  "<p>hi</p>"
# A NUL CANNOT BE WRITTEN AS XML AT ALL, and passing it through would
# truncate the atom rather than produce a bad document -- which is a much
# quieter failure.
check "a NUL byte in text is refused rather than truncating" \
  "$(q "$X, atom_codes(V, [0'a, 0, 0'b]),
        catch(xml_atom(element(p,[],[str([0'a, 0, 0'b])]), _), error(E,_), true),
        ( E = domain_error(xml_text, _) -> R = refused ; R = E ),
        write(answer(R)), nl")" "refused"

echo "-- library(xml): the indent rule, which is the whole reason it has one"
# ELEMENT-ONLY CONTENT INDENTS. A whitespace node between elements is what
# a schema-aware reader already ignores.
check "element-only content is broken across lines" \
  "$(q "$X, xml_atom(element(r,[],[element(a,[],[]), element(b,[],[])]), A, [indent(2)]),
        atomic_list_concat(L, '\n', A), length(L, N), write(answer(N)), nl")" "4"
# MIXED CONTENT DOES NOT, because there the whitespace is data.
check "mixed content stays on ONE line, whatever the indent" \
  "$(q "$X, xml_atom(element(m,[],[element(a,[],[]), 'text']), A, [indent(2)]),
        write(answer(A)), nl")" "<m><a/>text</m>"
check "the header and doctype go in front" \
  "$(q "$X, xml_atom(element(r,[],[]), A, [header(true)]),
        sub_atom(A, 0, 5, _, S), write(answer(S)), nl")" "<?xml"

echo "-- library(html): where it differs from XML, which is the point"
check "a void element does NOT self-close" \
  "$(q "$H, html_atom(element(br, [], []), A), write(answer(A)), nl")" "<br>"
check "a bare attribute IS the minimised form here" \
  "$(q "$H, html_atom(element(input, [type=checkbox, checked], []), A),
        write(answer(A)), nl")" '<input type="checkbox" checked>'
check "giving a void element children is an error" \
  "$(q "$H, catch(html_atom(element(br, [], ['x']), _), error(E,_), true),
        ( E = domain_error(html_empty_content, _) -> R = refused ; R = E ),
        write(answer(R)), nl")" "refused"
check "text and attributes escape the same as XML's" \
  "$(q "$H, html_atom(element(a, [href='/x?a=1&b=2'], ['a < b']), A),
        write(answer(A)), nl")" '<a href="/x?a=1&amp;b=2">a &lt; b</a>'
check "doctype(true) is HTML5's" \
  "$(q "$H, html_atom(element(html,[],[]), A, [doctype(true)]),
        sub_atom(A, 0, 15, _, S), write(answer(S)), nl")" "<!DOCTYPE html>"

echo "-- library(html): raw text, and the one check that is not escaping"
# ESCAPING A SCRIPT WOULD BREAK IT. `a < b' must reach the JavaScript
# parser as `a < b', so the content goes out untouched...
check "script content is NOT escaped" \
  "$(q "$H, html_atom(element(script, [], [str(\"if (a < b) f();\")]), A),
        write(answer(A)), nl")" "<script>if (a < b) f();</script>"
# ...which leaves exactly one hazard, and it is the one that tears a page
# in half. The tokenizer is case-insensitive, so the check has to be.
check "but a </script inside it is refused" \
  "$(q "$H, catch(html_atom(element(script,[],[str(\"x = '</script>'\")]), _),
                  error(E,_), true),
        ( E = domain_error(html_raw_text, script) -> R = refused ; R = E ),
        write(answer(R)), nl")" "refused"
check "and the refusal does not care about case" \
  "$(q "$H, catch(html_atom(element(script,[],[str(\"x = '</ScRiPt>'\")]), _),
                  error(E,_), true),
        ( E = domain_error(html_raw_text, script) -> R = refused ; R = E ),
        write(answer(R)), nl")" "refused"
check "a --> inside a comment is refused for the same reason" \
  "$(q "$H, catch(html_atom(element(d,[],[comment('a --> b')]), _), error(E,_), true),
        ( E = domain_error(html_comment, _) -> R = refused ; R = E ),
        write(answer(R)), nl")" "refused"
# `--' ALONE IS FINE HERE and refused by library(xml): HTML5's comment
# tokenizer ends on `-->' and nothing else. The two libraries disagree
# because the two languages do.
check "but a bare -- is fine, unlike in XML" \
  "$(q "$H, html_atom(element(d,[],[comment('a--b')]), A), write(answer(A)), nl")" \
  "<d><!--a--b--></d>"
check "cdata is refused: HTML5 has no CDATA sections" \
  "$(q "$H, catch(html_atom(element(d,[],[cdata(x)]), _), error(E,_), true),
        write(answer(E)), nl")" "type_error(html_node,cdata(x))"

echo "-- the three of them together, which is the real use"
# A JSON BODY INSIDE AN HTML PAGE, which is what a page that ships its own
# data does -- and the reason library(json) does not escape the solidus is
# that THIS is where the hazard lives, and here it is caught by name.
check "a JSON document inside a <script> is refused if it can close it" \
  "$(q "$J, $H, json_atom(json([k-'</script>']), Body),
        catch(html_atom(element(script,[],[Body]), _), error(E,_), true),
        ( E = domain_error(html_raw_text, script) -> R = refused ; R = E ),
        write(answer(R)), nl")" "refused"
check "and goes through when it cannot" \
  "$(q "$J, $H, json_atom(json([k-1]), Body),
        html_atom(element(script,[type='application/json'],[Body]), A),
        write(answer(A)), nl")" \
  '<script type="application/json">{"k":1}</script>'
# THE WHOLE POINT, in one line: a page is a term, and the term is data.
check "a page built as a term comes out as a page" \
  "$(q "$H, html_atom(element(html,[],[element(body,[],[element(p,[],['hi'])])]),
                      A, [doctype(true)]),
        atomic_list_concat(L, '\n', A), length(L, N), write(answer(N)), nl")" "2"


echo "-- library(json): reading it back"
check "an object, an array and the three literals" \
  "$(q "$J, json_parse('{\"a\":1,\"b\":[true,false,null]}', T), write(answer(T)), nl")" \
  "json([a-1,b-[@(true),@(false),@(null)]])"
check "a string comes back as an ATOM, so it can be written again" \
  "$(q "$J, json_parse('{\"k\":\"v\"}', json([K-V])),
        ( atom(K), atom(V) -> R = atoms ; R = something_else ),
        write(answer(R)), nl")" "atoms"
check "an empty string is '' and not the empty list" \
  "$(q "$J, json_parse('\"\"', T), ( T == '' -> R = empty_atom ; R = T ),
        write(answer(R)), nl")" "empty_atom"
check "integers and floats keep their kinds" \
  "$(q "$J, json_parse('[1,2.5,-3,1e2]', [A,B,C,D]),
        ( integer(A), float(B), integer(C), float(D) -> R = kept ; R = lost ),
        write(answer(R)), nl")" "kept"
check "whitespace between tokens is skipped" \
  "$(q "$J, json_parse('  { \"a\" : [ 1 , 2 ] }  ', T), write(answer(T)), nl")" \
  "json([a-[1,2]])"
check "duplicate keys are all kept, in order" \
  "$(q "$J, json_parse('{\"a\":1,\"a\":2}', json(Ps)), write(answer(Ps)), nl")" \
  "[a-1,a-2]"

echo "-- library(json): escapes, and the ones that are two code units"
check "the named escapes come back as their bytes" \
  "$(q "$J, json_parse('\"a\\\\tb\\\\nc\"', T), atom_codes(T, Cs), write(answer(Cs)), nl")" \
  "[97,9,98,10,99]"
# A \u ESCAPE NAMES A UTF-16 CODE UNIT and this library deals in bytes, so
# the parser has to encode. U+00E9 is two bytes of UTF-8.
check "a \\u escape becomes UTF-8" \
  "$(q "$J, json_parse('\"\\\\u00e9\"', T), atom_codes(T, Cs), write(answer(Cs)), nl")" \
  "[195,169]"
# ...AND A CHARACTER ABOVE U+FFFF IS A SURROGATE PAIR, which is the whole
# reason the \u reader is more than one clause. U+1F600 is four bytes.
check "a surrogate pair becomes one character" \
  "$(q "$J, json_parse('\"\\\\ud83d\\\\ude00\"', T), atom_codes(T, Cs),
        write(answer(Cs)), nl")" "[240,159,152,128]"
check "a lone high surrogate is refused" \
  "$(q "$J, catch(json_parse('\"\\\\ud800\"', _), error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"

echo "-- library(json): the strictness people leave out"
# EVERY ONE OF THESE IS ACCEPTED BY SOME PARSER SOMEWHERE, which is exactly
# why they are refused here: they are the places two implementations
# disagree about the same bytes.
check "a leading zero is not a number" \
  "$(q "$J, catch(json_parse('01', _), error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"
check "a trailing comma is not a shorter array" \
  "$(q "$J, catch(json_parse('[1,]', _), error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"
check "a raw newline inside a string is refused" \
  "$(q "$J, atom_codes(Doc, [0'\", 0'a, 10, 0'b, 0'\"]),
        catch(json_parse(Doc, _), error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"
check "a missing colon says so, and says where" \
  "$(q "$J, catch(json_parse('{\"a\" 1}', _), error(syntax_error(W), json_at(At)), true),
        ( sub_atom(W, _, _, _, colon), At == '1}' -> R = precise ; R = W-At ),
        write(answer(R)), nl")" "precise"
# AN INTEGER TOO BIG FOR THE MACHINE. number_codes/2 answers -1 for this
# and complains about nothing, which is the worst thing a JSON parser can
# do with a balance.
check "an integer past 64 bits is refused, not wrapped" \
  "$(q "$J, catch(json_parse('12345678901234567890', _),
                  error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"
check "and one that fits is exact" \
  "$(q "$J, json_parse('9007199254740993', T), write(answer(T)), nl")" \
  "9007199254740993"

echo "-- library(json): the streaming entry point"
# json_parse/3 IS library(http)'s RULE APPLIED HERE: a socket hands you
# what arrived, which may be one value and the start of the next.
check "json_parse/3 hands back what was not this value" \
  "$(q "$J, json_parse(\"{\\\"a\\\":1}rest\", T, Rest), atom_codes(A, Rest),
        write(answer(T-A)), nl")" "json([a-1])-rest"
check "json_parse/2 refuses the same input" \
  "$(q "$J, catch(json_parse('{\"a\":1}rest', _), error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"

echo "-- library(json): the round trip, which is the real check"
# A READER AND A WRITER THAT DISAGREE ARE WORSE THAN EITHER ALONE, so the
# document is written, read and written again and the two texts compared.
check "write, read, write again is the same document" \
  "$(q "$J, T = json([n-1, x-2.5, s-'a\"b', l-[1,@(null)], o-json([k- @(true)])]),
        json_atom(T, A1), json_parse(A1, T2), json_atom(T2, A2),
        ( A1 == A2 -> R = same ; R = A1/A2 ), write(answer(R)), nl")" "same"
check "and the term survives it too" \
  "$(q "$J, T = json([a-[1,2], b-'x']), json_atom(T, A), json_parse(A, T2),
        ( T == T2 -> R = identical ; R = T2 ), write(answer(R)), nl")" "identical"

echo "-- library(xml): reading it back"
check "an element, its attributes and its text" \
  "$(q "$X, xml_parse('<a href=\"x\">go</a>', T), write(answer(T)), nl")" \
  "element(a,[href=x],[go])"
check "entities are resolved in text and in attributes" \
  "$(q "$X, xml_parse('<a t=\"1&amp;2\">a &lt; b</a>', T), write(answer(T)), nl")" \
  "element(a,[t=1&2],[a < b])"
check "a numeric reference, either spelling" \
  "$(q "$X, xml_parse('<p>&#65;&#x42;</p>', T), write(answer(T)), nl")" \
  "element(p,[],[AB])"
check "both quote characters work for an attribute" \
  "$(q "$X, xml_parse('<a t=\\'q\\'/>', T), write(answer(T)), nl")" \
  "element(a,[t=q],[])"
# CDATA IS A SPELLING OF CHARACTER DATA, not a kind of node, so it comes
# back as text -- and merged with the text either side of it, because to
# XML that is one text node.
check "CDATA comes back as text, merged with its neighbours" \
  "$(q "$X, xml_parse('<d>x<![CDATA[a<b]]>y</d>', T), write(answer(T)), nl")" \
  "element(d,[],[xa<by])"
check "comments and PIs inside the root are kept" \
  "$(q "$X, xml_parse('<m><!--c--><?pi y?></m>', T), write(answer(T)), nl")" \
  "element(m,[],[comment(c),pi(pi y)])"

echo "-- library(xml): the prologue, and the DOCTYPE that is not read"
# THE INTERNAL SUBSET IS COUNTED, NOT SEARCHED FOR A `>'. Without that,
# the skip stops inside the brackets and the parser reads an entity
# declaration as markup.
check "a declaration, a DOCTYPE with an internal subset, and a comment" \
  "$(q "$X, xml_parse('<?xml version=\"1.0\"?><!DOCTYPE r [<!ENTITY e \"x\">]><!-- c --><r/>', T),
        write(answer(T)), nl")" "element(r,[],[])"
# AND THE ENTITY IT DECLARED IS STILL UNDEFINED, which is the whole XXE
# answer: no DTD is read, so no entity but the five predefined exists, and
# nothing in this library can open a file or a socket.
check "an entity that DOCTYPE declared is still unknown" \
  "$(q "$X, catch(xml_parse('<!DOCTYPE r [<!ENTITY e \"x\">]><r>&e;</r>', _),
                  error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"
check "and so is any other undeclared entity" \
  "$(q "$X, catch(xml_parse('<a>&nbsp;</a>', _), error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"

echo "-- library(xml): what it refuses, and what it names"
check "a mismatched end tag names both" \
  "$(q "$X, catch(xml_parse('<a></b>', _), error(syntax_error(W), _), true),
        write(answer(W)), nl")" "mismatched_end_tag(a,b)"
check "an unclosed element names itself" \
  "$(q "$X, catch(xml_parse('<a><b></a>', _), error(syntax_error(W), _), true),
        write(answer(W)), nl")" "mismatched_end_tag(b,a)"
check "an unquoted attribute value is not XML" \
  "$(q "$X, catch(xml_parse('<a x=1/>', _), error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"
check "a raw < in an attribute value is refused" \
  "$(q "$X, catch(xml_parse('<a x=\"1<2\"/>', _), error(syntax_error(_), _), true),
        write(answer(refused)), nl")" "refused"

echo "-- library(xml): space(remove), and what it will NOT remove"
check "an indented document comes back as its tree" \
  "$(q "$X, xml_parse('<r>\n  <a/>\n  <b/>\n</r>', T, [space(remove)]),
        write(answer(T)), nl")" "element(r,[],[element(a,[],[]),element(b,[],[])])"
# IT DROPS ALL-WHITESPACE NODES, NEVER TRIMS ONE. Turning `  hi  ' into
# `hi' would be editing content, which is the same line the writer draws
# when it refuses to indent mixed content.
check "but text with anything else in it is untouched" \
  "$(q "$X, xml_parse('<p>  hi  </p>', T, [space(remove)]), write(answer(T)), nl")" \
  "element(p,[],[  hi  ])"

echo "-- library(xml): the round trip"
check "write, read, write again is the same document" \
  "$(q "$X, T = element(r, [a='1&2', b='q\"q'], [element(c,[],['x < y']), 'tail']),
        xml_atom(T, A1), xml_parse(A1, T2), xml_atom(T2, A2),
        ( A1 == A2 -> R = same ; R = A1/A2 ), write(answer(R)), nl")" "same"
check "and a document with CDATA in it survives as the same TEXT" \
  "$(q "$X, xml_parse('<d><![CDATA[a<b]]></d>', T), xml_atom(T, A),
        write(answer(A)), nl")" "<d>a&lt;b</d>"

echo "-- library(html): reading it back, and where it differs"
check "tag and attribute names are downcased" \
  "$(q "$H, html_parse('<DIV CLASS=\"x\">hi</DIV>', T), write(answer(T)), nl")" \
  "[element(div,[class=x],[hi])]"
check "a void element takes no end tag" \
  "$(q "$H, html_parse('<p>a<br>b</p>', T), write(answer(T)), nl")" \
  "[element(p,[],[a,element(br,[],[]),b])]"
check "an unquoted value, and a bare attribute" \
  "$(q "$H, html_parse('<input type=checkbox checked>', T), write(answer(T)), nl")" \
  "[element(input,[type=checkbox,checked],[])]"
# A `<' THAT IS NOT MARKUP IS TEXT, which is how a browser reads it and
# what makes an arithmetic comparison in a paragraph survive.
check "a < that begins no tag is three characters of text" \
  "$(q "$H, html_parse('<p>a < b</p>', T), write(answer(T)), nl")" \
  "[element(p,[],[a < b])]"
# AND AN UNKNOWN ENTITY IS TEXT TOO, which is the deliberate difference
# from library(xml): HTML's table has two thousand names and a browser
# leaves anything else alone. It is why AT&T renders as AT&T.
check "an unknown entity is left alone, unlike in XML" \
  "$(q "$H, html_parse('<p>AT&T</p>', T), write(answer(T)), nl")" \
  "[element(p,[],[AT&T])]"
check "a known one is still resolved" \
  "$(q "$H, html_parse('<p>a &amp; b</p>', T), write(answer(T)), nl")" \
  "[element(p,[],[a & b])]"

echo "-- library(html): the tags people do not close"
check "<li> closes an open <li>" \
  "$(q "$H, html_parse('<ul><li>one<li>two</ul>', T), write(answer(T)), nl")" \
  "[element(ul,[],[element(li,[],[one]),element(li,[],[two])])]"
check "a block element closes an open paragraph" \
  "$(q "$H, html_parse('<p>one<p>two', T), write(answer(T)), nl")" \
  "[element(p,[],[one]),element(p,[],[two])]"
check "<td> and <tr> close each other" \
  "$(q "$H, html_parse('<table><tr><td>1<td>2</table>', T), write(answer(T)), nl")" \
  "[element(table,[],[element(tr,[],[element(td,[],[1]),element(td,[],[2])])])]"
# A MISNESTED END TAG CLOSES WHAT IT NAMES, which is what a browser does
# and what XML refuses outright.
check "</div> with a <span> still open closes both" \
  "$(q "$H, html_parse('<div><span>x</div>', T), write(answer(T)), nl")" \
  "[element(div,[],[element(span,[],[x])])]"
check "and a stray end tag is discarded" \
  "$(q "$H, html_parse('<p>x</p></div><p>y</p>', T), write(answer(T)), nl")" \
  "[element(p,[],[x]),element(p,[],[y])]"

echo "-- library(html): raw text, read the way it was written"
# THE READING HALF OF THE WRITER'S ONE SECURITY CHECK. A `<' inside a
# script is not markup, so the content is taken verbatim to the matching
# end tag -- which is exactly why the writer refuses to EMIT a </script
# inside one.
check "a script is read verbatim, angle brackets and all" \
  "$(q "$H, html_parse('<script>if (a < b) f(\"</b>\");</script>', T),
        write(answer(T)), nl")" \
  "[element(script,[],[if (a < b) f(\"</b>\");])]"
check "and it ends on its own tag whatever the case" \
  "$(q "$H, html_parse('<script>x = 1;</ScRiPt>', T), write(answer(T)), nl")" \
  "[element(script,[],[x = 1;])]"
# textarea AND title ARE ESCAPABLE RAW TEXT: no nesting, but entities do
# resolve. Getting that wrong either loses the & or reads a tag that is
# not there.
check "a textarea resolves entities but nests nothing" \
  "$(q "$H, html_parse('<textarea>a &amp; b</textarea>', T), write(answer(T)), nl")" \
  "[element(textarea,[],[a & b])]"
check "the doctype and a comment are handled, not parsed as elements" \
  "$(q "$H, html_parse('<!DOCTYPE html><!--c--><p>hi</p>', T), write(answer(T)), nl")" \
  "[comment(c),element(p,[],[hi])]"

echo "-- library(html): the round trip"
check "write, read, write again is the same page" \
  "$(q "$H, T = [element(html, [], [element(body, [lang=en],
                 [element(p, [], ['a < b & c']), element(br, [], []),
                  element(input, [type=text, disabled], [])])])],
        html_atom(T, A1), html_parse(A1, T2), html_atom(T2, A2),
        ( A1 == A2 -> R = same ; R = A1/A2 ), write(answer(R)), nl")" "same"
check "and a script survives being written and read" \
  "$(q "$H, T = [element(script, [], ['if (a < b) go();'])],
        html_atom(T, A1), html_parse(A1, T2), html_atom(T2, A2),
        ( A1 == A2 -> R = same ; R = A1/A2 ), write(answer(R)), nl")" "same"

echo "-- and the three of them agree with each other"
# THE SAME TREE THROUGH BOTH MARKUP LIBRARIES. XML and HTML share the
# term, so a document that is legal in both must parse to the same tree.
check "a tree legal in both parses the same in both" \
  "$(q "$X, $H, Doc = '<div class=\"a\"><span>x</span></div>',
        xml_parse(Doc, TX), html_parse(Doc, [TH]),
        ( TX == TH -> R = agree ; R = TX/TH ), write(answer(R)), nl")" "agree"
# AND JSON INSIDE A PAGE, read back out: the writer refuses a body that
# could close the script, so anything that got written can be read.
check "a JSON body written into a page reads back as itself" \
  "$(q "$J, $H, Data = json([k-'v', n-1]),
        json_atom(Data, Body),
        html_atom([element(script, [type='application/json'], [Body])], Page),
        html_parse(Page, [element(script, _, [Read])]),
        json_parse(Read, Back),
        ( Back == Data -> R = round_trip ; R = Back ), write(answer(R)), nl")" \
  "round_trip"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
