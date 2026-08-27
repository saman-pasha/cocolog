#!/bin/sh
# --tls: the BINARY protocol over TLS.
#
# WHAT ZiguratIP ACTUALLY OFFERS. `SERVER/TLS_MODE: TRUE' in
# ziguratip.conf turns 2160 into an encrypted port -- the same port, a
# different thing on it.
#
# A CLIENT CERTIFICATE IS OPTIONAL, and the SERVER says which:
# `SERVER/TLS_CLIENT_AUTH' takes REQUIRED (the default), OPTIONAL or NONE
# -- loadzigurat.cpp accepts all three -- so `--tls' with no `--cert' is a
# real arrangement rather than a half-configured one, and this case
# exercises both.
#
# WHAT A CERTIFICATE IS MANDATORY FOR IS PERMISSIONS. ZiguratIP identifies
# every TLS peer, certificate or not: one with none is identified with an
# empty subject and an empty permission set, and `Globals::permits' lets
# everything through only for a peer that is NOT identified -- which is to
# say a plain connection. So under `SECURITY/PERMISSIONS_MODE': plain
# reaches everything, TLS with a certificate reaches what the certificate
# grants, and TLS WITHOUT one reaches nothing. Turning TLS on is what
# turns access control on. That half is ZiguratIP's own suite's to prove;
# what is proved here is that the CLIENT can do either.
#
# THIS IS A REHEARSAL, AND SAYS SO. Turning TLS_MODE on means restarting
# the suite's shared server with different credentials, which every other
# case would then have to speak. So a TLS TERMINATOR stands in front of
# 2160 and forwards the decrypted bytes -- exactly what test/tunnel.sh
# does for the Cloudflare edge, and for the same reason. What it proves is
# the CLIENT half: that the handshake happens before the greeting, that
# the framing survives, that a reconnect comes back secure, and that the
# hostname is checked. What it does not prove is ZiguratIP's own server
# side, which is ZiguratIP's suite's business.
#
# SKIPS without a server, without openssl, or without a TLS build.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"

[ -x "$C" ] || { echo "SKIP no cocolog built"; exit 0; }
command -v openssl >/dev/null 2>&1 || { echo "SKIP no openssl to make a certificate with"; exit 0; }

"$C" --host 127.0.0.1 --tcp 2160 --timeout 5 --kb main list >/dev/null 2>&1 \
  || { echo "SKIP no server on 2160"; exit 0; }

OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-zigtls-XXXXXX")
PORT=${COCOLOG_ZIGTLS_PORT:-22160}
# The second stands for `TLS_CLIENT_AUTH: REQUIRED'; the first for NONE.
CPORT=$((PORT + 1))
trap 'kill $TERM_PID $CTERM_PID 2>/dev/null; rm -rf "$OUT"' EXIT INT TERM

openssl req -x509 -newkey rsa:2048 -nodes -keyout "$OUT/s.pem" -out "$OUT/s.crt" \
  -days 2 -subj '/CN=localhost' -addext 'subjectAltName=DNS:localhost' >/dev/null 2>&1 \
  || { echo "SKIP openssl would not make a certificate"; exit 0; }
cat "$OUT/s.pem" "$OUT/s.crt" > "$OUT/full.pem"

# THE CLIENT'S OWN, for the REQUIRED half. Self-signed and its own
# authority, which is all the terminator needs to be told to trust: what
# is under test is that cocolog PRESENTS one when asked, not who signed
# it. A real ZiguratIP would name a CA under SECURITY/AUTHORITY and read
# the subject out of the certificate to decide permissions.
openssl req -x509 -newkey rsa:2048 -nodes -keyout "$OUT/c.key" -out "$OUT/c.crt" \
  -days 2 -subj '/CN=cocolog-client' >/dev/null 2>&1 \
  || { echo "SKIP openssl would not make a client certificate"; exit 0; }

cat > "$OUT/term.py" <<'PYEOF'
# ONE TERMINATOR, TWO CLIENT-AUTH SETTINGS, which is the whole point of
# the MODE argument: `none' stands in for TLS_CLIENT_AUTH: NONE and
# `required' for the default REQUIRED, and the two ports below are the
# two arrangements a cocolog has to be able to speak.
import sys, socket, ssl, threading
FULL, PORT, ORIGIN, MODE = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(FULL, FULL)
if MODE == "required":
    ctx.verify_mode = ssl.CERT_REQUIRED
    ctx.load_verify_locations(sys.argv[5])
def pump(a, b):
    try:
        while True:
            d = a.recv(65536)
            if not d: break
            b.sendall(d)
    except Exception:
        pass
    finally:
        for s in (a, b):
            try: s.close()
            except Exception: pass
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    s.bind(("127.0.0.1", PORT))
except OSError:
    print("CANNOT BIND", flush=True); sys.exit(3)
s.listen(16)
print("up", flush=True)
while True:
    c, _ = s.accept()
    try:
        c = ctx.wrap_socket(c, server_side=True)
        o = socket.create_connection(("127.0.0.1", ORIGIN), timeout=30)
        threading.Thread(target=pump, args=(c, o), daemon=True).start()
        threading.Thread(target=pump, args=(o, c), daemon=True).start()
    except Exception:
        try: c.close()
        except Exception: pass
PYEOF

python3 "$OUT/term.py" "$OUT/full.pem" "$PORT" 2160 none > "$OUT/term.out" 2>&1 &
TERM_PID=$!
python3 "$OUT/term.py" "$OUT/full.pem" "$CPORT" 2160 required "$OUT/c.crt" \
  > "$OUT/cterm.out" 2>&1 &
CTERM_PID=$!
for f in "$OUT/term.out" "$OUT/cterm.out"; do
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    grep -q up "$f" 2>/dev/null && break
    grep -q "CANNOT BIND" "$f" 2>/dev/null && { echo "SKIP cannot bind $PORT/$CPORT"; exit 0; }
    sleep 0.3
  done
  grep -q up "$f" || { echo "SKIP a terminator did not come up"; exit 0; }
done

fail_count=0
check() {
  if [ "$2" = "$3" ]; then printf 'ok   %-50s\n' "$1"; else
    fail_count=$((fail_count + 1))
    printf 'FAIL %-50s got [%s] want [%s]\n' "$1" "$2" "$3"
  fi
}

# ---- the handshake happens BEFORE the greeting, and the framing survives
got=$("$C" --host localhost --tls "$PORT" --cacert "$OUT/s.crt" --kb main \
        --timeout 20 list 2>&1 | head -1)
check "a command over TLS" "$got" "  no suspended machines in 'main'"

got=$("$C" --host localhost --tls "$PORT" --cacert "$OUT/s.crt" --kb main \
        --timeout 20 query 'true' 2>&1 | head -1)
check "and a query" "$got" "  1. true"

# ---- ASSERT AND READ BACK IN A SECOND PROCESS, which is the claim this
#      project exists to make, made over an encrypted connection.
"$C" --host localhost --tls "$PORT" --cacert "$OUT/s.crt" --kb tls_test \
     --timeout 20 query 'assertz(secure_fact(carried))' >/dev/null 2>&1
got=$("$C" --host localhost --tls "$PORT" --cacert "$OUT/s.crt" --kb tls_test \
        --timeout 20 query 'secure_fact(X)' 2>&1 | head -1)
check "a clause written and read by two processes" "$got" "  1. secure_fact(carried)"

# ---- THE HOSTNAME IS CHECKED. The same terminator by address: the chain
#      still verifies -- --cacert names the very certificate -- and the
#      NAME does not.
got=$("$C" --host 127.0.0.1 --tls "$PORT" --cacert "$OUT/s.crt" --kb main \
        --timeout 20 list 2>&1 | head -1)
check "a name the certificate does not carry is refused" "$got" \
  "cocolog: no server at 127.0.0.1:$PORT -- the server's certificate was refused: hostname mismatch"

# ---- --insecure reaches it anyway, loudly
got=$("$C" --host 127.0.0.1 --tls "$PORT" --insecure --kb main \
        --timeout 20 list 2>/dev/null | head -1)
check "--insecure reaches it anyway" "$got" "  no suspended machines in 'main'"

# ---- AND PLAIN --tcp AGAINST THE TLS PORT FAILS, rather than sending the
#      protocol in the clear at something expecting a ClientHello.
got=$("$C" --host localhost --tcp "$PORT" --kb main --timeout 5 list 2>&1 \
      | grep -c 'cocolog:')
check "plaintext against a TLS port does not go through" "$got" "1"

# ---- TLS WITH AND WITHOUT A CLIENT CERTIFICATE, which is the whole of
#      what `SERVER/TLS_CLIENT_AUTH' decides. Every check above went
#      through the NONE terminator with no --cert at all, so cert-less
#      TLS is already proved; these three are about the other setting,
#      and about the failure being legible when the two disagree.

# a certificate is ACCEPTED where none is demanded -- the OPTIONAL case,
# where a peer that has one presents it and the server may or may not care
got=$("$C" --host localhost --tls "$PORT" --cacert "$OUT/s.crt" \
        --cert "$OUT/c.crt" --key "$OUT/c.key" --kb main --timeout 20 list 2>&1 | head -1)
check "a certificate offered where none is required" "$got" \
  "  no suspended machines in 'main'"

# and it is what gets through where one IS demanded
got=$("$C" --host localhost --tls "$CPORT" --cacert "$OUT/s.crt" \
        --cert "$OUT/c.crt" --key "$OUT/c.key" --kb main --timeout 20 list 2>&1 | head -1)
check "a certificate where one is required" "$got" \
  "  no suspended machines in 'main'"

# WITHOUT ONE, AGAINST A SERVER THAT WANTS ONE, THE REFUSAL IS LEGIBLE.
# Under TLS 1.3 this is not a failed handshake: the client is finished
# talking before the server looks at what it sent, so `SSL_connect'
# SUCCEEDS and the refusal comes back as an ALERT on the first read.
# Without client/tls.c's `coco_client_tls_why' the reader gets
# `read failed: Success' and goes looking at the wrong end.
got=$("$C" --host localhost --tls "$CPORT" --cacert "$OUT/s.crt" \
        --kb main --timeout 20 list 2>&1 | head -1)
check "no certificate where one is required, said plainly" "$got" \
  "cocolog: no server at localhost:$CPORT -- read failed: tlsv13 alert certificate required -- this server wants a client certificate: --cert and --key"

# ---- HALF A CERTIFICATE IS A MISTAKE, and named as one before any socket
got=$("$C" --host localhost --tls "$CPORT" --cert "$OUT/c.crt" --kb main list 2>&1 | head -1)
check "--cert without --key is refused" "$got" "cocolog: --cert and --key go together"

# ---- and the two arrangements are not confusable
got=$("$C" --tls --https --kb main list 2>&1 | head -1)
check "--tls and --https together are refused" "$got" \
  "cocolog: --tls names the binary protocol and --http/--https names Zeytun; choose one"

if [ $fail_count -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
else
  echo "RED: $fail_count failure(s)"
  exit 1
fi
