#!/bin/sh
# --tls: the BINARY protocol over TLS.
#
# WHAT ZiguratIP ACTUALLY OFFERS. `SERVER/TLS_MODE: TRUE' in
# ziguratip.conf turns 2160 into a mutually authenticated port -- the same
# port, a different thing on it -- with `TLS_CLIENT_AUTH' defaulting to
# REQUIRED, because the binary protocol has no anonymous use. With
# `SECURITY/PERMISSIONS_MODE' on, the certificate that opened the
# connection also decides which tables and procedures it reaches.
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
trap 'kill $TERM_PID 2>/dev/null; rm -rf "$OUT"' EXIT INT TERM

openssl req -x509 -newkey rsa:2048 -nodes -keyout "$OUT/s.pem" -out "$OUT/s.crt" \
  -days 2 -subj '/CN=localhost' -addext 'subjectAltName=DNS:localhost' >/dev/null 2>&1 \
  || { echo "SKIP openssl would not make a certificate"; exit 0; }
cat "$OUT/s.pem" "$OUT/s.crt" > "$OUT/full.pem"

cat > "$OUT/term.py" <<'PYEOF'
import sys, socket, ssl, threading
FULL, PORT, ORIGIN = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(FULL, FULL)
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

python3 "$OUT/term.py" "$OUT/full.pem" "$PORT" 2160 > "$OUT/term.out" 2>&1 &
TERM_PID=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
  grep -q up "$OUT/term.out" 2>/dev/null && break
  grep -q "CANNOT BIND" "$OUT/term.out" 2>/dev/null && { echo "SKIP cannot bind $PORT"; exit 0; }
  sleep 0.3
done
grep -q up "$OUT/term.out" || { echo "SKIP the terminator did not come up"; exit 0; }

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
