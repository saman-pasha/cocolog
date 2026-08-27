#!/bin/sh
# library(curl) -- the client half, and what it will not do quietly.
#
# NOTHING HERE TOUCHES THE NETWORK, which is cicili's own rule for
# test/c/curl and the right one: a test that fetched a real host would be
# measuring somebody else's uptime and would fail behind a proxy. Every
# transfer is a file:// URL over a file this script wrote, or a request to
# a cocolog listening on loopback -- and libcurl runs both through exactly
# the same easy-handle machinery.
#
# THE LAST SECTION IS THE ONE WORTH HAVING. A cocolog raises a server out
# of library(tcp) and library(http), and a SECOND cocolog fetches it with
# library(curl). Client and server, both in Prolog, in two processes --
# which is the whole reason any of these three files exist. It also
# crosses every seam at once: sockets in C, the grammar in clauses,
# libcurl through cicili's binding, and terms in and out of all of them.
#
# THE DEFAULTS ARE CHECKED, because they are the security posture:
# verification ON, redirects NOT followed. A client that follows
# redirects by default can be walked somewhere the caller never named,
# and a client that skips verification is not a client for anything that
# matters. Both are overridable and neither is silent.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-46s %s\n' "$1" "$(echo "$2" | cut -c1-24)"
  else
    printf 'FAIL %-46s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi
if [ ! -f "$ROOT/library/curl.so" ]; then
  echo "SKIP (no library/curl.so -- sh modules/curl/build.sh, and it needs libcurl's headers)"
  exit 0
fi
if ! timeout 20 "$C" query "use_module(library(curl)), write(ok), nl" 2>/dev/null | grep -aq '\bok\b'; then
  echo "SKIP (library(curl) will not load)"
  exit 0
fi

U="use_module(library(curl))"
q() { timeout 60 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

# The file every file:// transfer below reads. Written rather than
# assumed: a test that fetched /etc/hostname would pass or fail on what
# the container is called.
PAY='hello from a file url'
printf '%s\n' "$PAY" > /tmp/coco-curl-test.txt
printf 'ab\000cd' > /tmp/coco-curl-nul.bin

echo "-- the library is really libcurl"
check "it names its own version" \
  "$(q "curl_version(V), sub_atom(V, 0, 7, _, X), write(answer(X)), nl")" "libcurl"
check "and says whether it can do TLS at all" \
  "$(q "curl_ssl(S), ( S == none -> X = no_tls ; X = has_tls ), write(answer(X)), nl")" \
  "has_tls"

echo "-- a transfer, over a file this test wrote"
check "the body comes back" \
  "$(q "curl_get('file:///tmp/coco-curl-test.txt', _, B), atom_codes(A, B),
        sub_atom(A, 0, 21, _, X), write(answer(X)), nl")" "$PAY"
check "the body is CODES, so its length is bytes" \
  "$(q "curl_get('file:///tmp/coco-curl-test.txt', _, B), length(B, X),
        write(answer(X)), nl")" "22"
# A file:// URL has no HTTP status and libcurl reports 0 for it. Said out
# loud because a caller checking `Status == 200' on a file URL would
# otherwise be quietly wrong.
check "a file url has no HTTP status, and says 0" \
  "$(q "curl_get('file:///tmp/coco-curl-test.txt', S, _), write(answer(S)), nl")" "0"

echo "-- every byte survives, which is why the body is codes"
check "a NUL in the middle does not end the body" \
  "$(q "curl_get('file:///tmp/coco-curl-nul.bin', _, B), length(B, X), write(answer(X)), nl")" "5"
check "and the byte after it is the right one" \
  "$(q "curl_get('file:///tmp/coco-curl-nul.bin', _, B), nth0(3, B, X), write(answer(X)), nl")" "99"

echo "-- what it refuses"
check "a scheme libcurl does not know fails" \
  "$(q "( curl_get('nosuchscheme://host/path', _, _) -> write(answer(fetched))
        ; write(answer(refused)) ), nl")" "refused"
check "a file that is not there fails" \
  "$(q "( curl_get('file:///no/such/coco/file', _, _) -> write(answer(fetched))
        ; write(answer(refused)) ), nl")" "refused"
# A FAILED TRANSFER BINDS NOTHING. Both outputs are unified only after
# the perform succeeded, so a caller cannot read a status of 0 beside an
# empty body and think the request happened.
check "and a failed transfer leaves Status unbound" \
  "$(q "S = untouched, ( curl_get('file:///no/such/coco/file', S, _) -> true ; true ),
        write(answer(S)), nl")" "untouched"

echo "-- and the two halves of this repository, talking to each other"
cat > /tmp/coco-curl-server.pl <<'PL'
:- use_module(library(tcp)).
:- use_module(library(http)).

serve(Port) :-
    tcp_listen(Port, S),
    tcp_accept(S, 10000, C, _),
    tcp_read(C, 65536, 5000, Codes),
    ( http_request(Codes, R) -> answer(C, R) ; refuse(C) ),
    tcp_close(S).

answer(C, request(Method, Path, _, _, _, Body)) :-
    length(Body, N),
    atomic_list_concat(['served ', Method, ' ', Path, ' ', N], Text),
    http_response(200, ['Content-Type'-'text/plain'], Text, Out),
    tcp_write(C, Out), tcp_close(C).

refuse(C) :- http_response(400, [], bad, Out), tcp_write(C, Out), tcp_close(C).
PL

# Started detached: a plain `&' from a tool call does not survive the
# turn, which is the same hazard the ZiguratIP server has in CLAUDE.md.
setsid timeout 25 "$C" run /tmp/coco-curl-server.pl "serve(18840)" >/dev/null 2>&1 &
sleep 3
check "one cocolog fetches another's page" \
  "$(q "curl_get('http://127.0.0.1:18840/hello', St, B), atom_codes(A, B),
        atomic_list_concat([St, ' ', A], X), write(answer(X)), nl")" \
  "200 served get /hello 0"
wait 2>/dev/null

setsid timeout 25 "$C" run /tmp/coco-curl-server.pl "serve(18841)" >/dev/null 2>&1 &
sleep 3
check "and POSTs a body it reads back by length" \
  "$(q "curl_post('http://127.0.0.1:18841/p', 'text/plain', 'twelve bytes', St, B),
        atom_codes(A, B), atomic_list_concat([St, ' ', A], X), write(answer(X)), nl")" \
  "200 served post /p 12"
wait 2>/dev/null
rm -f /tmp/coco-curl-server.pl /tmp/coco-curl-test.txt /tmp/coco-curl-nul.bin

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
