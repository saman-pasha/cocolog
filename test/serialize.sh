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

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
