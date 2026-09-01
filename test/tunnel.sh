#!/bin/sh
# The Zeytun read path through a hostname-routing edge -- the local
# rehearsal of a Cloudflare tunnel in front of a Colab VM (colab/COLAB.md).
#
# WHAT IT IS CHECKING, and why:
#
#   AN EDGE ROUTES BY THE HOST HEADER, and a quick tunnel's hostname is
#   registered bare -- no port. So the client must send `Host: name` on
#   the default port and `Host: name:port` elsewhere, and the whole
#   knowledge-base read path -- warm, then a page per predicate -- must
#   survive a proxy hop that admits only the exact registered name and
#   forwards verbatim, which is what the edge.py stand-in below does and
#   what the Cloudflare edge + cloudflared pair do for real.
#
# The wire half of the story (the trainer writing) is zigurat.sh's and
# repl.sh's business; this case is the reader behind the proxy. SKIPs
# without a server, and the port-80 check SKIPs when 80 cannot be bound.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-tunnel-XXXXXX")
trap 'rm -rf "$OUT"; [ -n "$EDGE_PID" ] && kill "$EDGE_PID" 2>/dev/null' EXIT INT TERM

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-52s\n' "$1"
  else
    printf 'FAIL %-52s got [%s] want [%s]\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$ROOT/cocolog" ]; then
  echo "SKIP (no cocolog; make)"
  exit 0
fi
C="$ROOT/cocolog"

# THE EDGE IS WAITED FOR, NOT SLEPT AT. It prints `edge up' once it is
# listening, and a fixed second was not enough on a Mac whose python3 is a
# pyenv shim that takes two to four seconds to start: the query then met
# nothing on the port, `Connection refused' read as a routing failure, and
# the kill at the end of the check reached the edge before it had printed a
# line -- nine reds, every one of them the same second. Fifteen seconds is
# the ceiling; the usual wait is well under one. `CANNOT BIND' is the other
# thing an edge says, on a privileged port it may not have -- waited for
# too, so the SKIP below it is decided on what the edge said and not on
# what it had not yet said.
wait_edge() {
  i=0
  while [ $i -lt 150 ]; do
    grep -qE 'edge up|CANNOT BIND' "$1" 2>/dev/null && return 0
    sleep 0.1
    i=$((i + 1))
  done
  return 1
}
HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
ZEYTUN=${ZEYTUN_PORT:-2190}

if ! timeout 20 "$C" --kb tunnel_test --host "$HOST" --tcp "$PORT" \
       --timeout 10 list >/dev/null 2>&1; then
  echo "SKIP no Zigurat server at $HOST:$PORT"
  exit 0
fi

# the fact the reader will be asked for, in over the wire
timeout 60 "$C" --kb tunnel_test --host "$HOST" --tcp "$PORT" --timeout 10 \
  query 'assertz(edge_fact(routed))' >/dev/null 2>&1

# The edge stand-in is test/edge.pl, in cocolog: it admits only requests
# whose Host header is exactly PUBLIC -- the way the Cloudflare edge routes
# a quick tunnel by its registered hostname -- and forwards verbatim to
# Zeytun, which is what cloudflared does at the far end. Every Host seen is
# logged. Naming a .pem turns it into a TLS terminator, which is what the
# real edge is.
EDGE="$HERE/edge.pl"


# ---- a high port: the Host carries the port ------------------------

"$C" -s "$EDGE" -- 18080 "localhost:18080" "$ZEYTUN" "$OUT/hosts-high.log" \
  > "$OUT/edge-high.out" 2>&1 &
EDGE_PID=$!
wait_edge "$OUT/edge-high.out"
got=$(timeout 60 "$C" --host localhost --http 18080 --kb tunnel_test \
        query 'edge_fact(X)' 2>/dev/null | head -1)
check "a query answers through the Host-routing edge" "$got" "  1. edge_fact(routed)"
got=$(sort -u "$OUT/hosts-high.log" 2>/dev/null | tr '\n' ' ')
check "off the default port, Host names the port" "$got" "localhost:18080 "
kill "$EDGE_PID" 2>/dev/null; wait "$EDGE_PID" 2>/dev/null; EDGE_PID=

# ---- HTTPS: the same edge, terminating TLS -------------------------------
#
# WHAT CLOUDFLARE ACTUALLY IS. A quick tunnel is reached over TLS and
# nothing else -- the `https://NAME.trycloudflare.com' URL is the only one
# -- so a client that could only speak plaintext had to be given port 80 and
# hope the edge did not redirect. This is that arrangement, locally: a
# TLS-terminating edge that routes by Host and forwards decrypted bytes to
# Zeytun, and a cocolog reaching it with `--https'.
#
# THE CERTIFICATE IS MADE HERE AND TRUSTED BY NAME. `--cacert' points at the
# same self-signed certificate the edge presents, and `localhost' is its
# subject -- so the HOSTNAME check that `--https' does without being asked
# has something true to check. A test that reached for `--insecure' would
# have proved the bytes moved and nothing about the verification.

if openssl req -x509 -newkey rsa:2048 -nodes -keyout "$OUT/edge.pem" \
     -out "$OUT/edge.crt" -days 2 -subj '/CN=localhost' \
     -addext 'subjectAltName=DNS:localhost' >/dev/null 2>&1; then
  cat "$OUT/edge.pem" "$OUT/edge.crt" > "$OUT/edge-full.pem"

  "$C" -s "$EDGE" -- 18443 "localhost:18443" "$ZEYTUN" "$OUT/hosts-tls.log" \
    "$OUT/edge-full.pem" > "$OUT/edge-tls.out" 2>&1 &
  EDGE_PID=$!
  wait_edge "$OUT/edge-tls.out"

  got=$(timeout 60 "$C" --host localhost --https 18443 --cacert "$OUT/edge.crt" \
          --kb tunnel_test query 'edge_fact(X)' 2>/dev/null | head -1)
  check "a query answers through a TLS edge" "$got" "  1. edge_fact(routed)"

  # AND --insecure GOES THROUGH, loudly. It exists because a self-signed
  # rehearsal is a real thing to want; what it must not be is quiet.
  got=$(timeout 60 "$C" --host localhost --https 18443 --insecure \
          --kb tunnel_test query 'edge_fact(X)' 2>/dev/null | head -1)
  check "--insecure reaches it anyway" "$got" "  1. edge_fact(routed)"
  got=$(timeout 60 "$C" --host localhost --https 18443 --insecure \
          --kb tunnel_test query 'edge_fact(X)' 2>&1 >/dev/null | head -1)
  check "and says so on stderr" "$got" "cocolog: --insecure: the server is NOT being verified"

  # ---- AND FROM INSIDE A PROGRAM: library(curl) reaches Zeytun over https.
  #
  # The `--https' checks above are the ARRANGEMENT reading its knowledge
  # base through the edge. This is the other reader a Colab tunnel has: a
  # cocolog PROGRAM, using library(curl), fetching a Zeytun page with an
  # https:// URL -- which is the only kind of URL a quick tunnel has. The
  # page is a real one (`/cocolog/predicates.zt', the same page `--http'
  # warms from), the certificate is verified with `ca_info(...)' against
  # the very cert the edge presents, and the hostname check has something
  # true to check because the URL says `localhost' and so does the subject.
  #
  # THE DEFAULT IS ALSO HELD: without ca_info, the self-signed edge must be
  # REFUSED, because verification defaulting to on is the client's security
  # posture (test/curl.sh pins it for file URLs; this pins it against a
  # live TLS listener). A curl_get that quietly trusted a self-signed edge
  # would pass every other line in this file and be wrong.
  if [ -f "$ROOT/library/curl.so" ] && \
     timeout 20 "$C" query "use_module(library(curl)), write(ok), nl" 2>/dev/null \
       | grep -aq '\bok\b'; then
    got=$(timeout 60 "$C" query "use_module(library(curl)), \
            curl_get('https://localhost:18443/cocolog/predicates.zt?kb=tunnel_test', \
                     [ca_info('$OUT/edge.crt')], S, B), \
            atom_codes(A, B), \
            ( S == 200, sub_atom(A, _, _, _, edge_fact) -> write(answer(page_read)) \
            ; write(answer(wrong(S))) ), nl" 2>/dev/null \
          | grep -aoE 'answer\([^)]*\)' | head -1)
    check "curl_get reads a Zeytun page through the TLS edge" \
      "$got" "answer(page_read)"

    got=$(timeout 60 "$C" query "use_module(library(curl)), \
            ( curl_get('https://localhost:18443/cocolog/predicates.zt?kb=tunnel_test', S, _) \
            -> write(answer(fetched(S))) ; write(answer(refused)) ), nl" 2>/dev/null \
          | grep -aoE 'answer\([^)]*\)' | head -1)
    check "and without ca_info the self-signed edge is refused" \
      "$got" "answer(refused)"
  else
    echo "curl: SKIP (no library/curl.so -- sh modules/curl/build.sh)"
  fi

  kill "$EDGE_PID" 2>/dev/null; wait "$EDGE_PID" 2>/dev/null; EDGE_PID=

  # THE HOSTNAME IS CHECKED, and this is how we know: a SECOND edge, on the
  # same loopback and routing the same Host, presenting a certificate for a
  # name nobody asked for. The chain still verifies -- it is its own
  # authority and --cacert names it -- and the NAME does not, which is
  # precisely the man-in-the-middle case a client that skipped this check
  # would have missed.
  #
  # A SEPARATE EDGE rather than reaching the first one by address, because
  # the Host header would then be 127.0.0.1:PORT and the edge would answer
  # 404 before TLS was ever the reason.
  openssl req -x509 -newkey rsa:2048 -nodes -keyout "$OUT/other.pem" \
    -out "$OUT/other.crt" -days 2 -subj '/CN=other.invalid' \
    -addext 'subjectAltName=DNS:other.invalid' >/dev/null 2>&1
  cat "$OUT/other.pem" "$OUT/other.crt" > "$OUT/other-full.pem"

  "$C" -s "$EDGE" -- 18444 "localhost:18444" "$ZEYTUN" "$OUT/hosts-bad.log" \
    "$OUT/other-full.pem" > "$OUT/edge-bad.out" 2>&1 &
  EDGE_PID=$!
  wait_edge "$OUT/edge-bad.out"

  got=$(timeout 60 "$C" --host localhost --https 18444 --cacert "$OUT/other.crt" \
          --kb tunnel_test query 'edge_fact(X)' 2>&1 >/dev/null \
        | grep -c 'hostname mismatch')
  check "a name the certificate does not carry is refused" "$got" "2"

  # AND THE REFUSAL IS VISIBLE, which is the half that was missing. A failed
  # fetch used to go into the store and answer 0, which the engine reads as
  # "no clauses" -- so an unreachable edge, a refused certificate and an
  # empty knowledge base were all `existence_error(procedure, ...)'.
  got=$(timeout 60 "$C" --host localhost --https 18444 --cacert "$OUT/other.crt" \
          --kb tunnel_test query 'edge_fact(X)' 2>&1 >/dev/null | head -1)
  check "and names the server it was refused by" "$got" \
    "cocolog: Zeytun at localhost:18444 -- fetching clauses: the server's certificate was refused: hostname mismatch"

  kill "$EDGE_PID" 2>/dev/null; wait "$EDGE_PID" 2>/dev/null; EDGE_PID=
else
  echo "https: SKIP (no openssl to make a certificate with)"
fi

# ---- port 80: the Host is the bare hostname, as an edge registers it

"$C" -s "$EDGE" -- 80 "localhost" "$ZEYTUN" "$OUT/hosts-80.log" \
  > "$OUT/edge-80.out" 2>&1 &
EDGE_PID=$!
wait_edge "$OUT/edge-80.out"
if grep -q "CANNOT BIND" "$OUT/edge-80.out" 2>/dev/null; then
  echo "port 80: SKIP (cannot bind without privilege)"
  EDGE_PID=
else
  got=$(timeout 60 "$C" --host localhost --http 80 --kb tunnel_test \
          query 'edge_fact(X)' 2>/dev/null | head -1)
  check "the same query on port 80" "$got" "  1. edge_fact(routed)"
  got=$(sort -u "$OUT/hosts-80.log" 2>/dev/null | tr '\n' ' ')
  check "on the default port, Host is the bare name" "$got" "localhost "
  kill "$EDGE_PID" 2>/dev/null; wait "$EDGE_PID" 2>/dev/null; EDGE_PID=
fi

timeout 60 "$C" --kb tunnel_test --host "$HOST" --tcp "$PORT" --timeout 10 \
  forget >/dev/null 2>&1

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  exit 1
fi
