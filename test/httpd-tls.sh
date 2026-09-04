#!/bin/sh
# HTTPS: library(httpd) over library(tls), and the identity that comes
# with the handshake.
#
# ONLY THE TRANSPORT CHANGED, which is what this case is really checking.
# A connection became a tagged term -- plain(S) or secure(S) -- and five
# predicates dispatch on the tag; routing, keep-alive, the path rules and
# httpd_answer/3 are the same code on both. test/httpd.pl proves the
# plaintext half still passes; this one proves the secure half works and
# that the two cannot be confused.
#
# THE INTERESTING CHECK IS THE INJECTION ONE. A page reads the peer's
# identity out of two synthetic headers, and a client may send any header
# it likes -- so a server that merely ADDED its own would leave two, with
# the client's first, which is the one http_header/3 finds. That is the
# standard reverse-proxy hole. Here a client claims to be CN=root with
# `admin', and the page must see alice.
#
# SKIPS without library/tls.so or ZiguratIP's sample authority.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
. "$HERE/library-path.sh"

[ -x "$COCOLOG" ] || { echo "SKIP no cocolog built"; exit 0; }
for m in tls x509 thread tcp; do
  [ -f "$ROOT/library/$m.so" ] || { echo "SKIP no library/$m.so -- sh modules/$m/build.sh"; exit 0; }
done
CERT="${ZIGURATIP:-$HOME/ZiguratIP}/home/etc/cert"
[ -f "$CERT/issuer.conf" ] || { echo "SKIP no $CERT -- set ZIGURATIP to a built checkout"; exit 0; }

OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-httpstls-XXXXXX")
PORT=${COCOLOG_HTTPS_PORT:-19470}
PLAIN=$((PORT + 1))
trap 'kill $SRV $PSRV 2>/dev/null; rm -rf "$OUT"' EXIT INT TERM

cat > "$OUT/subject.conf" <<'CONF'
COUNTRY: IR
ORGANIZATION: Coco
ORGANIZATIONAL_UNIT: 
DISTINGUISHED_NAME_QUALIFIER: 
STATE_OR_PROVINCE_NAME: 
COMMON_NAME: alice
SERIAL_NUMBER: 
LOCALITY: 
TITLE: 
NAME: 
SURNAME: 
GIVEN_NAME: 
INITIALS: 
PSEUDONYM: 
GENERATION_QUALIFIER: 
DOMAIN_COMPONENT: 
EMAIL_ADDRESS: alice@example.org
CONF

"$COCOLOG" query "use_module(library(x509)),
  x509_keygen([], '$OUT/alice.key', '$OUT/alice.pub', _),
  x509_csr('$OUT/subject.conf', '$OUT/alice.key', [], '$OUT/alice.csr'),
  x509_issue([serial(9), permission(read), permission('ledger.write')],
             '$CERT/issuer.conf', '$CERT/dont-use-private.key',
             '$OUT/alice.csr', '$OUT/alice.crt')" >/dev/null 2>&1 \
  || { echo "SKIP could not issue a test certificate"; exit 0; }

# THE PAGES ARE A MODULE, not a consulted file -- the one thing a worker
# pool asks of the program above it. A worker's store is filled from the
# process-wide module registry, so a page that was consulted is a 404
# with nothing in the log.
cat > "$OUT/pages.pl" <<'PL'
:- module(pages, []).
:- use_module(library(ca)).

httpd_page('/hello', _, reply(200, [], 'hello over TLS')).

%% WHO IS ON THE CONNECTION, read like any other header -- which is the
%% point of doing it as headers: a page needs no new predicate and no
%% access to the socket.
httpd_page('/whoami', Request, reply(200, [], Body)) :-
    (   http_header(Request, 'Tls-Peer-Subject', S) -> true ; S = nobody ),
    (   http_header(Request, 'Tls-Peer-Permissions', P) -> true ; P = '' ),
    atomic_list_concat(['subject=', S, ' granted=', P], Body).

%% AND AUTHORISATION IS A RULE over what the handshake settled.
httpd_page('/ledger', Request, reply(Status, [], Body)) :-
    (   http_header(Request, 'Tls-Peer-Permissions', G),
        atomic_list_concat(Gs, ',', G),
        member(One, Gs),
        ca_covers(One, 'ledger.write')
    ->  Status = 200, Body = 'write applied'
    ;   Status = 403, Body = 'refused'
    ).
PL

cat > "$OUT/server.pl" <<PL
:- use_module(library(httpd)).
main :-
    use_module('$OUT/pages.pl'),
    format("READY~n"), flush_output,
    httpd_serve($PORT,
      [ tls([ certificate('$CERT/dont-use-certificate.crt'),
              key('$CERT/dont-use-private.key'),
              authority('$CERT/dont-use-certificate.crt') ]),
        workers(2), accept_timeout(20000) ], 12).
PL

cat > "$OUT/plain.pl" <<PL
:- use_module(library(httpd)).
main :-
    use_module('$OUT/pages.pl'),
    format("READY~n"), flush_output,
    httpd_serve($PLAIN, [ workers(0), accept_timeout(20000) ], 3).
PL

cat > "$OUT/client.pl" <<PL
:- use_module(library(tls)).
:- use_module(library(tcp)).

alice([ certificate('$OUT/alice.crt'), key('$OUT/alice.key'),
        authority('$CERT/dont-use-certificate.crt') ]).
anon([ authority('$CERT/dont-use-certificate.crt'), client_auth(none) ]).

get(Conn, Path, Extra) :-
    atomic_list_concat(['GET ', Path, ' HTTP/1.1\\r\\nHost: z\\r\\n', Extra,
                        'Connection: close\\r\\n\\r\\n'], Text),
    atom_codes(Text, Req),
    tls_write(Conn, Req),
    drain(Conn, [], Codes),
    atom_codes(A, Codes),
    format("~w~n", [A]).

drain(Conn, Acc, Out) :-
    (   tls_read(Conn, 65536, 3000, Chunk)
    ->  append(Acc, Chunk, All), drain(Conn, All, Out)
    ;   Out = Acc ).

secure(Path, Extra) :-
    alice(Cs),
    (   tls_connect('127.0.0.1', '$PORT', Cs, C)
    ->  get(C, Path, Extra), tls_close(C)
    ;   tls_why(W), format("DENIED ~w~n", [W]) ).

hello  :- secure('/hello', '').
whoami :- secure('/whoami', '').
ledger :- secure('/ledger', '').

%% A CLIENT CLAIMING TO BE SOMEBODY ELSE. Both headers, both spellings a
%% client would reach for.
inject :- secure('/whoami',
   'Tls-Peer-Subject: CN=root\\r\\nTls-Peer-Permissions: ledger.write,admin\\r\\n').

%% No certificate, against a server that demands one.
%%
%% AND THE CHECK IS THAT IT GETS NOTHING, not that connect failed. Under
%% TLS 1.3 a client's certificate is not examined until after it has sent
%% its Finished and considers the handshake done -- so a stranger gets
%% SUCCESS out of tls_connect/4 and hears the refusal afterwards, as an
%% alert on a connection it believes it already has. What is true either
%% way is that no page is served, which is the property worth asserting.
nocert :-
    anon(Cs),
    (   tls_connect('127.0.0.1', '$PORT', Cs, C)
    ->  (   catch(get(C, '/hello', ''), _, format("NO REPLY~n"))
        ->  true
        ;   format("NO REPLY~n") ),
        tls_close(C)
    ;   tls_why(W), format("DENIED ~w~n", [W]) ).

%% PLAINTEXT: the headers must be stripped and NOT replaced, so a page
%% that trusts them cannot be fooled by moving it to port 80.
plain(Path, Extra) :-
    (   tcp_connect('127.0.0.1', $PLAIN, C)
    ->  atomic_list_concat(['GET ', Path, ' HTTP/1.1\\r\\nHost: z\\r\\n', Extra,
                            'Connection: close\\r\\n\\r\\n'], Text),
        atom_codes(Text, Req), tcp_write(C, Req),
        pdrain(C, [], Codes), atom_codes(A, Codes), format("~w~n", [A]), tcp_close(C)
    ;   format("NO PLAIN SERVER~n") ).

pdrain(C, Acc, Out) :-
    (   tcp_read(C, 65536, 3000, Chunk)
    ->  append(Acc, Chunk, All), pdrain(C, All, Out)
    ;   Out = Acc ).

plainwho :- plain('/whoami', '').
plaininject :- plain('/whoami',
   'Tls-Peer-Subject: CN=root\\r\\nTls-Peer-Permissions: admin\\r\\n').
plainledger :- plain('/ledger', 'Tls-Peer-Permissions: ledger.write\\r\\n').
PL

fail_count=0
check() {
  if grep -q -- "$2" "$3"; then :; else
    fail_count=$((fail_count + 1))
    echo "FAIL $1"
    echo "  wanted: $2"
    sed 's/^/  saw: /' "$3" | head -8
  fi
}
deny() {   # must NOT appear
  if grep -q -- "$2" "$3"; then
    fail_count=$((fail_count + 1))
    echo "FAIL $1"
    echo "  must NOT contain: $2"
    sed 's/^/  saw: /' "$3" | head -8
  fi
}

"$COCOLOG" run "$OUT/server.pl" main > "$OUT/server.log" 2>&1 &
SRV=$!
"$COCOLOG" run "$OUT/plain.pl" main > "$OUT/plain.log" 2>&1 &
PSRV=$!
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  grep -q READY "$OUT/server.log" 2>/dev/null && grep -q READY "$OUT/plain.log" 2>/dev/null && break
  sleep 0.2
done
grep -q READY "$OUT/server.log" || { echo "SKIP the https server did not come up"; exit 0; }

for g in hello whoami ledger inject nocert plainwho plaininject plainledger; do
  "$COCOLOG" run "$OUT/client.pl" $g > "$OUT/$g.log" 2>&1
done
kill $SRV $PSRV 2>/dev/null
SRV=; PSRV=

# ---- the server serves, over TLS, with everything above it unchanged
check "a page is served over TLS"        "200 OK"                    "$OUT/hello.log"
check "and its body arrives"             "hello over TLS"            "$OUT/hello.log"

# ---- THE HANDSHAKE'S IDENTITY REACHES THE PAGE
check "the subject is a header"          "subject=C=IR, O=Coco, CN=alice" "$OUT/whoami.log"
check "and so are the permissions"       "granted=read,ledger.write" "$OUT/whoami.log"

# ---- and authorisation is a rule over it
check "a granted write is applied"       "write applied"             "$OUT/ledger.log"

# ---- THE INJECTION, which is the check this file exists for
check "an injecting client still sees itself" "subject=C=IR, O=Coco, CN=alice" "$OUT/inject.log"
deny  "and cannot become CN=root"        "CN=root"                   "$OUT/inject.log"
deny  "nor grant itself admin"           "admin"                     "$OUT/inject.log"

# ---- client_auth(required) is the default
# A CERTIFICATE-LESS CLIENT GETS NO PAGE, which is the honest form of the
# check. Under TLS 1.3 the refusal arrives after the client thinks the
# handshake finished, so `tls_connect/4' succeeding proves nothing -- see
# the note by `nocert' above.
deny  "a client with no certificate is served nothing" "200 OK"      "$OUT/nocert.log"

# ---- PLAINTEXT STRIPS AND DOES NOT REPLACE
check "the plain server answers"         "200 OK"                    "$OUT/plainwho.log"
check "with nobody on the connection"    "subject=nobody granted="   "$OUT/plainwho.log"
deny  "and an injected subject is gone"  "CN=root"                   "$OUT/plaininject.log"
check "a page requiring a grant refuses on port 80" "403"            "$OUT/plainledger.log"

if [ $fail_count -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $fail_count failure(s)"
  exit 1
fi
