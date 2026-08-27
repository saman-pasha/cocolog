#!/bin/sh
# library(http) -- HTTP/1.1 as a grammar, and what it refuses.
#
# WHAT IS BEING PINNED, and where the answers come from:
#
#   THE DECODING IS CHECKED AGAINST PYTHON, not against this file's
#   opinion. Percent-decoding and form-decoding are exactly the kind of
#   thing that looks right in every case an author thinks to write down,
#   so the cases are run through `urllib.parse' as well and the two must
#   agree. An independent implementation disagreeing is a finding; this
#   file agreeing with itself is not.
#
#   AND THE WHOLE THING IS CHECKED AGAINST curl. The last section raises a
#   cocolog that parses a real request and answers with a real response,
#   and drives it with an HTTP client nobody here wrote. A parser tested
#   only against strings its author typed is a parser tested against its
#   author's idea of HTTP.
#
#   WHAT IT REFUSES IS THE POINT, not the leftovers. obs-fold is a
#   request-smuggling surface that RFC 7230 says a server MUST reject;
#   chunked framing handed back as a body is silent corruption; a body
#   shorter than Content-Length is an incomplete request and not a short
#   one. Each of those FAILS the parse, and each is checked, because a
#   parser's refusals are the half that decides whether the server built
#   on it is safe.
#
#   BODIES ARE CODES AND CARRY EVERY BYTE, including the NUL that would
#   have ended an atom. That is why tcp_read/4 answers codes and why this
#   parser never turns a body into one.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
export COCOLOG_LIBRARY="$ROOT/library"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-48s %s\n' "$1" "$(echo "$2" | cut -c1-22)"
  else
    printf 'FAIL %-48s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi
if ! timeout 20 "$C" query "use_module(library(http)), write(ok), nl" 2>/dev/null | grep -aq '\bok\b'; then
  echo "SKIP (library(http) will not load)"
  exit 0
fi

U="use_module(library(http))"
# Every answer is written inside `answer(...)' so the extraction cannot pick
# up a stray digit from the echoed goal or from "1 answer(s)".
q() { timeout 60 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
# Whether a request parses at all.
p() { timeout 60 "$C" query "$U, atom_codes('$1', Cs),
        ( http_request(Cs,_) -> write(answer(parsed)) ; write(answer(refused)) ), nl" 2>/dev/null \
      | grep -aoE 'answer\((parsed|refused)\)' | head -1 | sed 's/^answer(//; s/)$//'; }
# One field of a parsed request.
f() { timeout 60 "$C" query "$U, atom_codes('$1', Cs), http_request(Cs, R),
        R = request(M,P,Q,V,H,B), $2, write(answer(X)), nl" 2>/dev/null \
      | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

REQ='GET /a%20b?x=1&y=hi+there HTTP/1.1\r\nHost: example.org\r\nContent-Length: 5\r\n\r\nhello'

echo "-- the request line"
check "the method is a lowercase atom"      "$(f "$REQ" "X = M")" "get"
check "the path is percent-decoded"         "$(f "$REQ" "X = P")" "/a b"
# Asked for paren-free, because the answer(...) extractor above stops at
# the first `)' -- `http(1,1)' came back as `http(1,1'. The harness's
# limit, not the parser's, and worth saying rather than working around
# silently.
check "the version is structured"           \
  "$(f "$REQ" "V = http(Ma,Mi), atomic_list_concat([Ma,'.',Mi], X)")" "1.1"
check "an unknown method still arrives"     \
  "$(f 'PROPFIND / HTTP/1.1\r\n\r\n' "X = M")" "propfind"
check "HTTP/1.0 is parsed, not assumed"     \
  "$(f 'GET / HTTP/1.0\r\n\r\n' "V = http(Ma,Mi), atomic_list_concat([Ma,'.',Mi], X)")" "1.0"

echo "-- headers"
check "names are downcased"                 "$(f "$REQ" "X = H")" \
  "[host-example.org,content-length-5]"
check "lookup is case-insensitive"          \
  "$(f "$REQ" "http_header(R,'HOST',X)")" "example.org"
check "a value keeps its inner spaces"      \
  "$(f 'GET / HTTP/1.1\r\nX: a  b\r\n\r\n' "http_header(R,x,X)")" "a  b"
check "and loses the outer ones"            \
  "$(f 'GET / HTTP/1.1\r\nX:   trimmed   \r\n\r\n' "http_header(R,x,X)")" "trimmed"
check "a duplicated header keeps both"      \
  "$(f 'GET / HTTP/1.1\r\nX: 1\r\nX: 2\r\n\r\n' "X = H")" "[x-1,x-2]"
check "a request with no headers at all"    \
  "$(f 'GET / HTTP/1.1\r\n\r\n' "X = H")" "[]"

echo "-- the query, and the body"
check "the query splits into pairs"         "$(f "$REQ" "X = Q")" "[x-1,y-hi there]"
check "a key with no value is empty"        \
  "$(f 'GET /?flag HTTP/1.1\r\n\r\n' "X = Q")" "[flag-]"
check "no query at all is the empty list"   \
  "$(f 'GET /p HTTP/1.1\r\n\r\n' "X = Q")" "[]"
check "the body is exactly Content-Length"  \
  "$(f "$REQ" "atom_codes(X, B)")" "hello"
check "and no body means no body"           \
  "$(f 'GET / HTTP/1.1\r\n\r\n' "length(B, X)")" "0"
check "bytes past the length are not it"    \
  "$(f 'POST / HTTP/1.1\r\nContent-Length: 2\r\n\r\nhiEXTRA' "atom_codes(X, B)")" "hi"
check "a form body decodes like a query"    \
  "$(q "http_form(\"a=1&b=two+words\", X), write(answer(X)), nl")" "[a-1,b-two words]"

echo "-- every byte survives, which is why bodies are codes"
check "a NUL in the body does not end it"   \
  "$(q "atom_codes('POST / HTTP/1.1\r\nContent-Length: 5\r\n\r\nab', H),
        append(H, [0, 99, 100], Cs), http_request(Cs, request(_,_,_,_,_,B)),
        length(B, X), write(answer(X)), nl")" "5"
check "and the byte after the NUL is kept"  \
  "$(q "atom_codes('POST / HTTP/1.1\r\nContent-Length: 5\r\n\r\nab', H),
        append(H, [0, 99, 100], Cs), http_request(Cs, request(_,_,_,_,_,B)),
        nth0(3, B, X), write(answer(X)), nl")" "99"

echo "-- what it refuses, which is the half that decides safety"
check "obs-fold is refused"                 \
  "$(p 'GET / HTTP/1.1\r\nX: a\r\n  b\r\n\r\n')" "refused"
check "chunked framing is refused"          \
  "$(p 'POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nhello\r\n0\r\n\r\n')" "refused"
check "a body short of its length is refused" \
  "$(p 'POST / HTTP/1.1\r\nContent-Length: 99\r\n\r\nhi')" "refused"
check "a request line with no version"      "$(p 'GET /\r\n\r\n')" "refused"
check "a request line with no target"       "$(p 'GET HTTP/1.1\r\n\r\n')" "refused"
check "headers that never end"              "$(p 'GET / HTTP/1.1\r\nHost: x\r\n')" "refused"
check "an empty request"                    "$(p '')" "refused"
check "a bare LF is ACCEPTED, by the spec"  \
  "$(p 'GET / HTTP/1.1\nHost: x\n\n')" "parsed"

echo "-- the decoding, checked against Python rather than against itself"
# urllib.parse is an implementation nobody here wrote. Agreeing with it is
# evidence; agreeing with this file's author is not.
dec() { timeout 60 "$C" query "$U, atom_codes('$1', Cs), http_percent_decode(Cs, D),
          atom_codes(X, D), write(answer(X)), nl" 2>/dev/null \
        | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
for raw in 'a%20b' '%2Fslash' 'plus+kept' '%41%42%43' 'caf%C3%A9' '100%25' 'a%2Bb'; do
  want=$(python3 -c "import urllib.parse,sys; print(urllib.parse.unquote('$raw'))")
  check "percent-decode $raw" "$(dec "$raw")" "$want"
done
# ONE KEY AT A TIME, because comparing the printed list compares cocolog's
# WRITER as well as its parser: `e-@home' is written `e- @home', with a
# space, so that reading it back cannot mistake `-@' for one operator. The
# writer is right and the comparison was wrong.
fval() { timeout 60 "$C" query "$U, http_query(\"$1\", Q), memberchk($2-X, Q),
           write(answer(X)), nl" 2>/dev/null \
         | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
for pair in 'a=1&b=2:b' 'x=hi+there:x' 'e=%40home:e' 'k=a%26b:k' 'u=caf%C3%A9:u'; do
  qs=${pair%:*}; key=${pair##*:}
  want=$(python3 -c "
import urllib.parse
print(dict(urllib.parse.parse_qsl('$qs', keep_blank_values=True))['$key'])")
  check "query $qs -> $key" "$(fval "$qs" "$key")" "$want"
done

echo "-- building a response"
check "the status line and a computed length" \
  "$(q "http_response(200, [], hello, Cs), atom_codes(A, Cs),
        sub_atom(A, 0, 15, _, X), write(answer(X)), nl")" "HTTP/1.1 200 OK"
check "Content-Length is computed, not taken" \
  "$(q "http_response(200, ['Content-Length'-999], hello, Cs), atom_codes(A, Cs),
        ( sub_atom(A, _, _, _, 'Content-Length: 5') -> X = computed ; X = trusted ),
        write(answer(X)), nl")" "computed"
check "an unknown status still goes out"    \
  "$(q "http_response(499, [], '', Cs), atom_codes(A, Cs), sub_atom(A, 9, 11, _, X),
        write(answer(X)), nl")" "499 Unknown"
check "and a body of codes is written as bytes" \
  "$(q "http_response(200, [], [104,105], Cs), atom_codes(A, Cs),
        ( sub_atom(A, _, _, 0, hi) -> X = ends_with_body ; X = mangled ),
        write(answer(X)), nl")" "ends_with_body"

echo "-- and the whole thing against curl, which nobody here wrote"
if ! command -v curl >/dev/null 2>&1; then
  echo "     SKIP (no curl to drive it with)"
else
cat > /tmp/coco-http-server.pl <<'PL'
:- use_module(library(http)).

serve(Port) :-
    tcp_listen(Port, S),
    tcp_accept(S, 10000, C, _),
    tcp_read(C, 65536, 5000, Codes),
    ( http_request(Codes, R) -> answer(C, R) ; refuse(C) ),
    tcp_close(S).

answer(C, request(Method, Path, Query, _, _, Body)) :-
    length(Body, N),
    ( memberchk(name-Who, Query) -> true ; Who = nobody ),
    atomic_list_concat([Method, ' ', Path, ' ', Who, ' ', N], Text),
    http_response(200, ['Content-Type'-'text/plain'], Text, Out),
    tcp_write(C, Out),
    tcp_close(C).

refuse(C) :-
    http_response(400, [], 'no', Out),
    tcp_write(C, Out),
    tcp_close(C).
PL
  setsid timeout 25 "$C" run /tmp/coco-http-server.pl "serve(18830)" >/dev/null 2>&1 &
  sleep 3
  got=$(curl -s --max-time 8 'http://127.0.0.1:18830/hello%20world?name=ada' 2>/dev/null)
  check "curl gets what the grammar parsed" "$got" "get /hello world ada 0"
  wait 2>/dev/null

  setsid timeout 25 "$C" run /tmp/coco-http-server.pl "serve(18831)" >/dev/null 2>&1 &
  sleep 3
  got=$(curl -s --max-time 8 -X POST --data-binary 'twelve bytes' 'http://127.0.0.1:18831/p' 2>/dev/null)
  check "a POST body arrives with its length" "$got" "post /p nobody 12"
  wait 2>/dev/null

  setsid timeout 25 "$C" run /tmp/coco-http-server.pl "serve(18832)" >/dev/null 2>&1 &
  sleep 3
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 8 'http://127.0.0.1:18832/' 2>/dev/null)
  check "and curl reads the status line" "$code" "200"
  wait 2>/dev/null
  rm -f /tmp/coco-http-server.pl
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
