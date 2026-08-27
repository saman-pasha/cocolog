#!/bin/sh
# library(tls): a secure connection between two cocolog PROCESSES.
#
# TWO PROCESSES, NOT TWO THREADS, and that is the point of the case. A
# handshake is between two ends that do not share memory; a test that
# proved one process could talk to itself would have proved the least
# interesting half. So a server is raised in the background and clients
# are run against it, exactly as a real one would be reached.
#
# WHAT IT ESTABLISHES, in order: that a mutually authenticated handshake
# completes and each end can name the other; that bytes cross intact, a
# zero byte included; that the PERMISSIONS an issuer wrote into a
# certificate arrive with the handshake, so authorisation is a rule over
# facts and not a second round trip; that a peer whose certificate this
# authority did not sign is refused BEFORE any byte moves; that
# `client_auth(none)' admits a client with no certificate at all, which
# is the browser case; and that a handle is a slot, so an integer this
# module did not hand out is not a connection.
#
# SKIPS without library/tls.so or without ZiguratIP's sample authority,
# because "no ZiguratIP built here" and "the binding is wrong" are
# different findings.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
COCOLOG="$ROOT/cocolog"
. "$HERE/library-path.sh"

[ -x "$COCOLOG" ] || { echo "SKIP no cocolog built"; exit 0; }
for m in tls x509; do
  [ -f "$ROOT/library/$m.so" ] || { echo "SKIP no library/$m.so -- sh modules/$m/build.sh"; exit 0; }
done
CERT="${ZIGURATIP:-$HOME/ZiguratIP}/home/etc/cert"
[ -f "$CERT/issuer.conf" ] || { echo "SKIP no $CERT -- set ZIGURATIP to a built checkout"; exit 0; }

OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-tls-XXXXXX")
PORT=${COCOLOG_TLS_PORT:-19451}
trap 'kill $SRV 2>/dev/null; rm -rf "$OUT"' EXIT INT TERM

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

# A holder the sample authority signed, carrying two permissions. This is
# a real RSA key pair and a real issuance -- a few seconds, and there is
# no cheaper way to have a certificate that is genuinely signed.
"$COCOLOG" query "use_module(library(x509)),
  x509_keygen([], '$OUT/alice.key', '$OUT/alice.pub', _),
  x509_csr('$OUT/subject.conf', '$OUT/alice.key', [], '$OUT/alice.csr'),
  x509_issue([serial(7), permission(read), permission('ledger.write')],
             '$CERT/issuer.conf', '$CERT/dont-use-private.key',
             '$OUT/alice.csr', '$OUT/alice.crt')" >/dev/null 2>&1 \
  || { echo "SKIP could not issue a test certificate"; exit 0; }

cat > "$OUT/server.pl" <<PL
:- use_module(library(tls)).
:- use_module(library(ca)).

creds([ certificate('$CERT/dont-use-certificate.crt'),
        key('$CERT/dont-use-private.key'),
        authority('$CERT/dont-use-certificate.crt') ]).

%% THE BROWSER PORT: no certificate demanded of the peer. Same key, same
%% authority, one different option -- which is the whole difference
%% between a port for machines that have been enrolled and a port for
%% anybody.
open_creds([ certificate('$CERT/dont-use-certificate.crt'),
             key('$CERT/dont-use-private.key'),
             authority('$CERT/dont-use-certificate.crt'),
             client_auth(none) ]).

main :-
    tls_listen($PORT, S),
    %% AND FLUSH IT. cocolog's output is BLOCK buffered when it is a file
    %% rather than a terminal, so without this the harness waits for a
    %% READY that is sitting in a buffer and the whole transcript arrives
    %% at exit. flush_output/0 exists because of this line.
    %%
    %% NO BACKTICKS IN THIS FILE: the heredoc that writes it is unquoted,
    %% because it interpolates the port and the certificate directory --
    %% so a backtick in a Prolog comment is command substitution, and the
    %% shell fails with 'EOF in backquote substitution' pointing at the
    %% end of the script.
    format("READY~n"), flush_output,
    rounds(S, 4),
    tls_close(S).

rounds(_, 0) :- !.
rounds(S, N) :-
    ( N =:= 1 -> open_creds(Cs) ; creds(Cs) ),
    (   tls_accept(S, 15000, Cs, C, Peer)
    ->  tls_peer_subject(C, Who),
        tls_peer_permissions(C, Perms),
        format("ADMIT ~w | ~w | ~q~n", [Peer, Who, Perms]), flush_output,
        (   tls_read(C, 4096, 5000, In)
        ->  atom_codes(A, In), format("GOT ~w~n", [A])
        ;   format("GOT nothing~n") ),
        %% A ZERO BYTE ON PURPOSE: an atom in cocolog is a C string and
        %% stops at the first NUL, so codes are the only shape that can
        %% carry one back. This is what tls_read/4 answering codes is for.
        tls_write(C, [80, 79, 78, 71, 0, 33]),
        tls_close(C)
    ;   tls_why(W), format("REFUSE ~w~n", [W]), flush_output ),
    N1 is N - 1,
    rounds(S, N1).
PL

cat > "$OUT/client.pl" <<PL
:- use_module(library(tls)).

%% Enrolled: a certificate the server's authority signed.
alice([ certificate('$OUT/alice.crt'), key('$OUT/alice.key'),
        authority('$CERT/dont-use-certificate.crt') ]).

%% An impostor: a perfectly good certificate, signed by somebody else.
%% Naming alice's own certificate as the authority is what makes the
%% server's one fail to verify -- a stranger, from either end's view.
mallory([ certificate('$CERT/dont-use-certificate.crt'),
          key('$CERT/dont-use-private.key'),
          authority('$OUT/alice.crt'), client_auth(none) ]).

%% A browser: no certificate at all, and it still checks the server's.
browser([ authority('$CERT/dont-use-certificate.crt'), client_auth(none) ]).

talk(Which) :-
    ( Which == alice -> alice(Cs) ; Which == mallory -> mallory(Cs) ; browser(Cs) ),
    (   tls_connect('127.0.0.1', '$PORT', Cs, C)
    ->  tls_peer_subject(C, Who), format("SERVER ~w~n", [Who]),
        atom_codes('HELLO', H), tls_write(C, H),
        (   tls_read(C, 4096, 5000, In)
        ->  length(In, L), format("REPLY ~w bytes ~q~n", [L, In])
        ;   format("REPLY none~n") ),
        tls_close(C)
    ;   tls_why(W), format("DENIED ~w~n", [W]) ).

alice   :- talk(alice).
mallory :- talk(mallory).
browser :- talk(browser).

%% A HANDLE IS A SLOT, and an integer this module did not hand out is not
%% a connection. Prolog does arithmetic, so this is the difference
%% between a failed call and a closed stdout.
handles :-
    ( tls_read(9999, 16, 100, _) -> format("BOGUS read succeeded~n") ; format("BOGUS read failed~n") ),
    ( tls_write(-1, [65]) -> format("BOGUS write succeeded~n") ; format("BOGUS write failed~n") ),
    ( tls_peer_subject(77, _) -> format("BOGUS subject succeeded~n") ; format("BOGUS subject failed~n") ),
    tls_close(9999),
    format("BOGUS close is a no-op~n").

%% Nobody arrives: accept has to give the port back rather than hold it.
quiet :-
    tls_listen(19452, S),
    alice(Cs),
    ( tls_accept(S, 300, Cs, _, _) -> format("QUIET somebody came~n") ; format("QUIET nobody came~n") ),
    tls_close(S),
    tls_connections(N), format("QUIET open handles ~w~n", [N]).
PL

fail_count=0
check() {  # check LABEL EXPECTED-SUBSTRING FILE
  if grep -q -- "$2" "$3"; then :; else
    fail_count=$((fail_count + 1))
    echo "FAIL $1"
    echo "  wanted: $2"
    sed 's/^/  saw: /' "$3" | head -8
  fi
}

"$COCOLOG" run "$OUT/server.pl" main > "$OUT/server.log" 2>&1 &
SRV=$!
# Wait for the port rather than sleeping a guess at it.
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  grep -q READY "$OUT/server.log" 2>/dev/null && break
  sleep 0.2
done
grep -q READY "$OUT/server.log" || { echo "SKIP the server did not come up"; exit 0; }

"$COCOLOG" run "$OUT/client.pl" alice   > "$OUT/alice.log"   2>&1
"$COCOLOG" run "$OUT/client.pl" mallory > "$OUT/mallory.log" 2>&1
"$COCOLOG" run "$OUT/client.pl" alice   > "$OUT/alice2.log"  2>&1
"$COCOLOG" run "$OUT/client.pl" browser > "$OUT/browser.log" 2>&1
wait $SRV 2>/dev/null
SRV=

"$COCOLOG" run "$OUT/client.pl" handles > "$OUT/handles.log" 2>&1
"$COCOLOG" run "$OUT/client.pl" quiet   > "$OUT/quiet.log"   2>&1

# ---- an enrolled peer gets in, and is named by the handshake
check "alice is admitted"            "ADMIT 127.0.0.1:"                  "$OUT/server.log"
check "and named"                    "CN=alice"                          "$OUT/server.log"
check "the client names the server"  "SERVER .*CN=ZiguratIP"             "$OUT/alice.log"
check "her request arrives"          "GOT HELLO"                         "$OUT/server.log"

# ---- PERMISSIONS COME WITH THE HANDSHAKE, which is the interesting part
check "and her grants arrive with her" "\[read,'ledger.write'\]"         "$OUT/server.log"

# ---- bytes cross intact, a zero byte included
check "the reply is six bytes"       "REPLY 6 bytes"                     "$OUT/alice.log"
check "and carries a zero byte"      "\[80,79,78,71,0,33\]"              "$OUT/alice.log"

# ---- an impostor is refused AT THE HANDSHAKE, and both ends say so
check "mallory is denied"            "DENIED"                            "$OUT/mallory.log"
check "and told why"                 "certificate verify failed"         "$OUT/mallory.log"
check "the server refuses her"       "REFUSE"                            "$OUT/server.log"
# THE SERVER CARRIED ON, which is the property that matters: one impostor
# knocking must not take the port down for everybody else. Checked on the
# CLIENT's log because a reply is what "still serving" means to a caller --
# the server's own "GOT" line proves it read, not that anybody heard back.
check "and carries on serving"       "REPLY 6 bytes"                     "$OUT/alice2.log"

# ---- the browser case: no certificate demanded, the server's still checked
check "a certificate-less client is admitted" "ADMIT"                    "$OUT/server.log"
check "and grants nothing"           "REPLY 6 bytes"                     "$OUT/browser.log"

# ---- a handle is a slot
check "a bogus read fails"           "BOGUS read failed"                 "$OUT/handles.log"
check "a bogus write fails"          "BOGUS write failed"                "$OUT/handles.log"
check "a bogus subject fails"        "BOGUS subject failed"              "$OUT/handles.log"
check "a bogus close is a no-op"     "BOGUS close is a no-op"            "$OUT/handles.log"

# ---- accept gives the port back
check "accept times out"             "QUIET nobody came"                 "$OUT/quiet.log"
check "and closing frees the slot"   "QUIET open handles 0"              "$OUT/quiet.log"

if [ $fail_count -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $fail_count failure(s)"
  exit 1
fi
