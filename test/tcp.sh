#!/bin/sh
# modules/tcp/tcp.cicili -- the socket seam, and the three claims its header makes.
#
# WHAT IS BEING PINNED, and why each one is here rather than assumed:
#
#   A HANDLE IS NOT A FILE DESCRIPTOR. This is the claim the whole design
#   rests on. Prolog does arithmetic, so any integer can arrive at any of
#   these predicates -- and if a handle were an fd, `tcp_close(1)' would
#   close stdout and the next `write/1' would vanish into a closed pipe.
#   The test closes 1 and then writes, so a regression is not a subtle
#   wrong answer: the proof of stdout is stdout.
#
#   A TIMEOUT FAILS RATHER THAN HANGING. A suite that hangs tells you
#   nothing at all, which is the one test outcome with no information in
#   it. Every blocking call takes a timeout and the timeout expiring is an
#   ordinary failure, so `accept' with nobody there is a false goal and not
#   a wedged run.
#
#   READS CARRY EVERY BYTE. An atom in cocolog is a C string and stops at
#   the first NUL, so a read that answered an atom would silently truncate
#   a body -- the kind of bug that only appears against real traffic. The
#   test sends a NUL in the middle and counts what comes back.
#
#   AND IT WORKS ACROSS PROCESSES, which is the only version of this claim
#   worth making. One cocolog listens, a SECOND one that consulted nothing
#   connects to it, and the bytes cross. An in-process round trip proves
#   the API; two processes prove the socket.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-46s %s\n' "$1" "$(echo "$2" | cut -c1-24)"
  else
    printf 'FAIL %-46s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

U="use_module(library(tcp))"

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi
# library(tcp) IS A LOADABLE MODULE NOW, under modules/tcp, so this needs
# tcp.so on the library path rather than a socket layer in the binary.
export COCOLOG_LIBRARY="$ROOT/library"
if [ ! -f "$ROOT/library/tcp.so" ]; then
  echo "SKIP (no library/tcp.so -- sh modules/tcp/build.sh)"
  exit 0
fi
if ! timeout 20 "$C" query "$U, tcp_sockets(_), write(ok), nl" 2>/dev/null | grep -aq '\bok\b'; then
  echo "SKIP (library(tcp) will not load)"
  exit 0
fi

# Every answer is written inside `answer(...)' so the extraction cannot pick
# up a stray digit from the echoed goal or from "1 answer(s)".
q() { timeout 60 "$C" query "$U, $1" 2>/dev/null \
      | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }

# Ports chosen high and fixed rather than random: a fixed port that is busy
# fails loudly, and a random one that is busy fails one run in a hundred.
P1=18810
P2=18811
P3=18812

echo "-- the round trip"
check "listen, connect, accept, write, read" \
  "$(q "tcp_listen($P1,S), tcp_connect('127.0.0.1',$P1,C), tcp_accept(S,2000,A,_),
        tcp_write(C,'hello sockets'), tcp_read(A,100,2000,Cs), atom_codes(T,Cs),
        tcp_close(C), tcp_close(A), tcp_close(S), write(answer(T)), nl")" \
  "hello sockets"

check "the peer is named, host and port" \
  "$(q "tcp_listen($P2,S), tcp_connect('127.0.0.1',$P2,C), tcp_accept(S,2000,A,Peer),
        sub_atom(Peer,0,9,_,Head), tcp_close(C), tcp_close(A), tcp_close(S),
        write(answer(Head)), nl")" \
  "127.0.0.1"

check "and nothing is left open afterwards" \
  "$(q "tcp_listen($P3,S), tcp_connect('127.0.0.1',$P3,C), tcp_accept(S,2000,A,_),
        tcp_close(C), tcp_close(A), tcp_close(S), tcp_sockets(L),
        write(answer(L)), nl")" \
  "[]"

echo "-- a handle is not a file descriptor"
# THE ONE THAT MATTERS. If a handle were an fd, this would close stdout and
# the write after it would go nowhere -- so the check is the output itself.
check "tcp_close(1) is refused" \
  "$(q "( tcp_close(1) -> write(answer(closed)) ; write(answer(refused)) ), nl")" \
  "refused"
check "and stdout is still there to say so" \
  "$(q "( tcp_close(1) -> true ; true ), write(answer(stdout_lives)), nl")" \
  "stdout_lives"
check "writing to a slot nobody opened is refused" \
  "$(q "( tcp_write(2,'x') -> write(answer(wrote)) ; write(answer(refused)) ), nl")" \
  "refused"
check "a negative handle is refused" \
  "$(q "( tcp_close(-1) -> write(answer(bad)) ; write(answer(refused)) ), nl")" \
  "refused"
check "a handle past the table is refused" \
  "$(q "( tcp_close(99999) -> write(answer(bad)) ; write(answer(refused)) ), nl")" \
  "refused"
check "reading a closed socket is refused, not a crash" \
  "$(q "tcp_listen($P1,S), tcp_close(S),
        ( tcp_read(S,10,100,_) -> write(answer(read)) ; write(answer(refused)) ), nl")" \
  "refused"

echo "-- a timeout is a failure, not a hang"
check "accept with nobody there fails" \
  "$(q "tcp_listen($P2,S), ( tcp_accept(S,300,_,_) -> write(answer(accepted))
        ; write(answer(timed_out)) ), nl, tcp_close(S)")" \
  "timed_out"
# The bound is generous because it includes process start-up, which the bench
# measures at about 0.4s. What it rules out is the thing that matters: a call
# that never returns at all.
start=$(date +%s)
q "tcp_listen($P3,S), ( tcp_accept(S,500,_,_) -> true ; true ), tcp_close(S), write(answer(done)), nl" >/dev/null
elapsed=$(( $(date +%s) - start ))
check "and it comes back in seconds, not never" \
  "$([ "$elapsed" -lt 10 ] && echo bounded || echo hung)" "bounded"

echo "-- every byte survives"
# An atom would stop at the NUL. Codes do not, and this is the only test
# that can tell the difference.
check "a NUL in the middle does not truncate" \
  "$(q "tcp_listen($P1,S), tcp_connect('127.0.0.1',$P1,C), tcp_accept(S,2000,A,_),
        tcp_write(C,[104,105,0,116,104,101,114,101]), tcp_read(A,100,2000,Cs),
        length(Cs,N), tcp_close(C), tcp_close(A), tcp_close(S),
        write(answer(N)), nl")" \
  "8"
check "and the byte after it is the right one" \
  "$(q "tcp_listen($P2,S), tcp_connect('127.0.0.1',$P2,C), tcp_accept(S,2000,A,_),
        tcp_write(C,[104,105,0,116]), tcp_read(A,100,2000,Cs), nth0(3,Cs,B),
        tcp_close(C), tcp_close(A), tcp_close(S), write(answer(B)), nl")" \
  "116"
check "high bytes are not sign-extended" \
  "$(q "tcp_listen($P3,S), tcp_connect('127.0.0.1',$P3,C), tcp_accept(S,2000,A,_),
        tcp_write(C,[255,128,127]), tcp_read(A,100,2000,Cs),
        tcp_close(C), tcp_close(A), tcp_close(S), write(answer(Cs)), nl")" \
  "[255,128,127]"

echo "-- and it crosses PROCESSES, which is the only claim worth making"
# One cocolog listens and echoes; a SECOND, which consulted nothing, connects
# to it. Started detached, because a plain `&' from a tool call does not
# survive the turn -- the same hazard the server has in CLAUDE.md.
cat > /tmp/coco-tcp-listener.pl <<'PL'
:- use_module(library(tcp)).

serve :-
    tcp_listen(18820, S),
    tcp_accept(S, 10000, C, _),
    tcp_read(C, 4096, 5000, Codes),
    append(Codes, [32,98,97,99,107], Reply),   % " back"
    tcp_write(C, Reply),
    tcp_close(C),
    tcp_close(S).
PL
setsid timeout 25 "$C" run /tmp/coco-tcp-listener.pl serve >/dev/null 2>&1 &
# Give the listener time to bind. Polling for the port would be better than
# sleeping, but there is nothing here to poll it with that is not the thing
# under test.
sleep 3
check "a second process reaches the first" \
  "$(q "tcp_connect('127.0.0.1',18820,C), tcp_write(C,'over the wire'),
        tcp_read(C,4096,5000,Cs), atom_codes(T,Cs), tcp_close(C),
        write(answer(T)), nl")" \
  "over the wire back"
wait 2>/dev/null
rm -f /tmp/coco-tcp-listener.pl

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
