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
if ! command -v python3 >/dev/null 2>&1; then
  echo "SKIP (no python3 for the edge stand-in)"
  exit 0
fi
C="$ROOT/cocolog"
HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
ZEYTUN=${ZEYTUN_PORT:-2190}

if ! timeout 20 "$C" --kb tunnel_test --host "$HOST" --port "$PORT" \
       --timeout 10 list >/dev/null 2>&1; then
  echo "SKIP no Zigurat server at $HOST:$PORT"
  exit 0
fi

# the fact the reader will be asked for, in over the wire
timeout 60 "$C" --kb tunnel_test --host "$HOST" --port "$PORT" --timeout 10 \
  query 'assertz(edge_fact(routed))' >/dev/null 2>&1

# The edge stand-in: admits only requests whose Host header is exactly
# PUBLIC -- the way the Cloudflare edge routes a quick tunnel by its
# registered hostname -- and forwards verbatim to Zeytun, which is what
# cloudflared does at the far end. Every Host seen is logged.
cat > "$OUT/edge.py" <<'PYEOF'
import socket, sys, threading
PORT, PUBLIC, ORIGIN, LOG = int(sys.argv[1]), sys.argv[2], int(sys.argv[3]), sys.argv[4]
def handle(c):
    try:
        head = b""
        while b"\r\n\r\n" not in head:
            b = c.recv(4096)
            if not b: return
            head += b
        host = ""
        for line in head.split(b"\r\n"):
            if line.lower().startswith(b"host:"):
                host = line.split(b":", 1)[1].strip().decode()
        with open(LOG, "a") as f: f.write(host + "\n")
        if host != PUBLIC:
            c.sendall(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")
            return
        o = socket.create_connection(("127.0.0.1", ORIGIN), timeout=20)
        o.sendall(head)
        while True:
            b = o.recv(65536)
            if not b: break
            c.sendall(b)
        o.close()
    finally:
        c.close()
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    s.bind(("127.0.0.1", PORT))
except OSError:
    print("CANNOT BIND", flush=True); sys.exit(3)
s.listen(16)
print("edge up", flush=True)
while True:
    c, _ = s.accept()
    threading.Thread(target=handle, args=(c,), daemon=True).start()
PYEOF

# ---- a high port: the Host carries the port ------------------------

python3 "$OUT/edge.py" 18080 "localhost:18080" "$ZEYTUN" "$OUT/hosts-high.log" \
  > "$OUT/edge-high.out" 2>&1 &
EDGE_PID=$!
sleep 1
got=$(timeout 60 "$C" --host localhost --http 18080 --kb tunnel_test \
        query 'edge_fact(X)' 2>/dev/null | head -1)
check "a query answers through the Host-routing edge" "$got" "  1. edge_fact(routed)"
got=$(sort -u "$OUT/hosts-high.log" 2>/dev/null | tr '\n' ' ')
check "off the default port, Host names the port" "$got" "localhost:18080 "
kill "$EDGE_PID" 2>/dev/null; wait "$EDGE_PID" 2>/dev/null; EDGE_PID=

# ---- port 80: the Host is the bare hostname, as an edge registers it

python3 "$OUT/edge.py" 80 "localhost" "$ZEYTUN" "$OUT/hosts-80.log" \
  > "$OUT/edge-80.out" 2>&1 &
EDGE_PID=$!
sleep 1
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

timeout 60 "$C" --kb tunnel_test --host "$HOST" --port "$PORT" --timeout 10 \
  forget >/dev/null 2>&1

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"
  exit 0
else
  echo "RED: $failures failure(s)"
  exit 1
fi
