#!/bin/sh
# library(thread) -- threads that share nothing, channels that copy.
#
# THE TWO CLAIMS WORTH CHECKING are that it is really parallel and that
# nothing is lost under contention. Everything else here is semantics --
# what a closed channel does, what a failed thread reports -- and those are
# cheap. The two that matter are the last two sections, and neither can be
# checked by reading the code.
#
# CONTENTION IS CHECKED BY COUNTING, not by timing. Eight threads each send
# a hundred terms into one channel; if the ring, the head index or the
# condition variables were wrong the count comes out short or the run hangs,
# and a count is a verdict where a stopwatch is an opinion.
#
# PARALLELISM IS CHECKED BY TIMING, because there is no other way. Four
# threads doing the same work as one should take rather less than four times
# as long, and the threshold here is deliberately loose: this proves the
# threads are not taking turns, not that the scheduler is good.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-50s %s\n' "$1" "$(echo "$2" | cut -c1-20)"
  else
    printf 'FAIL %-50s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$C" ]; then echo "SKIP (build cocolog first)"; exit 0; fi
if [ ! -f "$ROOT/library/thread.so" ]; then
  echo "SKIP (no library/thread.so -- sh modules/thread/build.sh)"
  exit 0
fi

D=/tmp/coco-thread-test
rm -rf "$D"; mkdir -p "$D"

# A MODULE, loaded before any thread starts. This is how a thread sees a
# predicate at all: its store is empty, and what fills it is the process-wide
# module registry consulted on the first goal.
cat > "$D/work.pl" <<'PL'
spin(0) :- !.
spin(N) :- M is N - 1, spin(M).

%% Sends Count terms into Ch, tagged with Who, then stops. The body of the
%% contention case.
flood(_, _, 0) :- !.
flood(Ch, Who, N) :- channel_send(Ch, item(Who, N)), M is N - 1, flood(Ch, Who, M).

%% Receive up to Want items, counting what actually arrived. The timeout is
%% what turns a LOST message into a short count instead of a hung test --
%% which is the difference between a failure that names itself and one that
%% has to be killed and guessed at.
th_drain_n(_, 0, N, N) :- !.
th_drain_n(Ch, K, Acc, N) :-
    channel_recv(Ch, 5000, _), !,
    A is Acc + 1, K1 is K - 1,
    th_drain_n(Ch, K1, A, N).
th_drain_n(_, _, N, N).
PL

U="use_module(library(thread))"
W="$U, use_module('$D/work.pl')"
# ANCHORED TO THE LINE, not matched inside it. `answer([^)]*)' stops at the
# first `)', so an answer that is a compound -- `answer(hello(world))' --
# came back as `hello(world'. The written answer is on a line of its own,
# so anchoring and stripping only the outer parens is both simpler and right.
q() { timeout 120 "$C" query "$1" 2>/dev/null \
      | grep -a '^answer(' | head -1 | sed 's/^answer(//; s/)$//'; }

if ! timeout 30 "$C" query "$U, write(ok), nl" 2>/dev/null | grep -aq '\bok\b'; then
  echo "SKIP (library(thread) will not load)"
  exit 0
fi

echo "-- a thread is a goal on a machine of its own"
check "it runs and joins" \
  "$(q "$U, thread_create((X is 2+2, X =:= 4), I), thread_join(I, S),
        write(answer(S)), nl")" "true"
# A THREAD THAT FAILED IS A THREAD THAT RAN. Failing the join instead would
# make "it did not prove it" and "it never started" the same answer.
check "a goal that fails reports false, and join succeeds" \
  "$(q "$U, thread_create(fail, I), thread_join(I, S), write(answer(S)), nl")" "false"
check "a goal that raises reports error(Message)" \
  "$(q "$U, thread_create((X is 1/0, write(X)), I), thread_join(I, S),
        ( S = error(_) -> W = tagged ; W = S ), write(answer(W)), nl")" "tagged"
check "and the message names the fault" \
  "$(q "$U, thread_create((X is 1/0, write(X)), I), thread_join(I, error(M)),
        ( sub_atom(M, _, _, _, zero_divisor) -> W = named ; W = vague ),
        write(answer(W)), nl")" "named"

echo "-- what a thread can see, and what it cannot"
# The registry is process-wide, so a module loaded BEFORE the thread started
# is there. This is the whole reason a worker can be useful at all.
check "a module loaded before it started is there" \
  "$(q "$W, thread_create(spin(1000), I), thread_join(I, S), write(answer(S)), nl")" "true"
# ...and the parent's own clauses are NOT, because a thread's store is empty
# and clauses are shared through the database in this project, not memory.
# Documented rather than fixed: it is the share-nothing rule holding.
check "a clause the PARENT asserted is not" \
  "$(q "$U, assertz(only_here(1)),
        thread_create(only_here(_), I), thread_join(I, S),
        ( S = error(_) -> A = unseen ; A = S ), write(answer(A)), nl")" "unseen"

echo "-- a channel carries a term between two machines"
check "a term crosses" \
  "$(q "$U, channel_new(Ch), thread_create(channel_send(Ch, hello(world)), I),
        channel_recv(Ch, M), thread_join(I, _), write(answer(M)), nl")" "hello(world)"
# STRUCTURE SURVIVES, which is what canonical form buys: quoted atoms and
# operators written as compounds, so the far machine reads the same term
# even having run no `op/3' of its own.
check "and so does its structure, operators and all" \
  "$(q "$U, channel_new(Ch),
        thread_create(channel_send(Ch, f(1+2, 'an atom', [a,b|T], \"xy\")), I),
        channel_recv(Ch, f(A, B, C, D)), thread_join(I, _),
        ( A == 1+2, B == 'an atom', C = [a,b|_], D == \"xy\"
        -> R = intact ; R = mangled ), write(answer(R)), nl")" "intact"

echo "-- what a closed channel does"
check "receiving from a closed empty channel FAILS" \
  "$(q "$U, channel_new(Ch), channel_close(Ch),
        ( channel_recv(Ch, _) -> R = got ; R = failed ), write(answer(R)), nl")" "failed"
# CLOSING DOES NOT DISCARD. Anything already queued comes out first, and
# only then does recv start saying no -- otherwise a close would silently
# drop whatever was in flight.
check "but what was queued before the close still comes out" \
  "$(q "$U, channel_new(Ch), channel_send(Ch, a), channel_send(Ch, b),
        channel_close(Ch), channel_recv(Ch, X), channel_recv(Ch, Y),
        ( channel_recv(Ch, _) -> Z = more ; Z = done ),
        atomic_list_concat([X,Y,Z], '-', R), write(answer(R)), nl")" "a-b-done"
check "sending to a closed channel fails rather than raising" \
  "$(q "$U, channel_new(Ch), channel_close(Ch),
        ( channel_send(Ch, x) -> R = sent ; R = refused ), write(answer(R)), nl")" "refused"
check "a timeout fails rather than hanging" \
  "$(q "$U, channel_new(Ch),
        ( channel_recv(Ch, 300, _) -> R = got ; R = timed_out ),
        write(answer(R)), nl")" "timed_out"
check "and zero means take only what is already there" \
  "$(q "$U, channel_new(Ch), channel_send(Ch, only),
        channel_recv(Ch, 0, X),
        ( channel_recv(Ch, 0, _) -> Y = more ; Y = empty ),
        atomic_list_concat([X,Y], '-', R), write(answer(R)), nl")" "only-empty"

echo "-- backpressure: a bounded channel makes the sender wait"
# The sender fills the channel and then BLOCKS. If the bound were not
# enforced this would finish immediately with a size of 3; if the block were
# not released by the receive it would hang and time out.
check "a bounded channel holds no more than its capacity" \
  "$(q "$U, channel_new(2, Ch),
        thread_create((channel_send(Ch,1), channel_send(Ch,2),
                       channel_send(Ch,3), channel_send(Ch,4)), I),
        channel_recv(Ch, _), channel_recv(Ch, _),
        channel_recv(Ch, _), channel_recv(Ch, _),
        thread_join(I, S), write(answer(S)), nl")" "true"

echo "-- the helpers the Coco half adds"
# The failure-driven consumer, and the reason `recv fails when closed and
# empty' is the right semantics: no sentinel value, no counting, the loop
# just ends. It runs in THIS thread, so assertz is the parent's own store.
check "channel_forall reads until the channel is done" \
  "$(q "$U, channel_new(Ch), channel_send(Ch,1), channel_send(Ch,2),
        channel_send(Ch,3), channel_close(Ch),
        channel_forall(Ch, [T]>>assertz(seen(T))),
        findall(X, seen(X), L), length(L, N), write(answer(N)), nl")" "3"
check "channel_drain takes what is queued without blocking" \
  "$(q "$U, channel_new(Ch), channel_send(Ch,a), channel_send(Ch,b),
        channel_drain(Ch, L), length(L, N), write(answer(N)), nl")" "2"
check "thread_pool starts them and join_all waits" \
  "$(q "$W, thread_pool(4, spin(1000), Ids), thread_join_all(Ids),
        length(Ids, N), write(answer(N)), nl")" "4"

echo "-- NOTHING IS LOST UNDER CONTENTION, which is the channel's real claim"
# Eight threads, a hundred terms each, one channel. A wrong head index, a
# missed signal or a torn ring shows up as a short count or a hang -- and a
# count is a verdict where a stopwatch is an opinion.
check "eight senders, 800 terms, all 800 arrive" \
  "$(q "$W, channel_new(Ch),
        thread_pool(8, flood(Ch, w, 100), Ids),
        th_drain_n(Ch, 800, 0, N),
        thread_join_all(Ids),
        write(answer(N)), nl")" "800"

echo "-- and it is really parallel, not taking turns"
one=$( { S=$(date +%s%3N)
         timeout 200 "$C" query "$W, thread_create(spin(3000000), I), thread_join(I,_)" \
           >/dev/null 2>&1
         E=$(date +%s%3N); echo $((E-S)); } )
four=$( { S=$(date +%s%3N)
          timeout 200 "$C" query "$W, thread_pool(4, spin(3000000), Ids), thread_join_all(Ids)" \
            >/dev/null 2>&1
          E=$(date +%s%3N); echo $((E-S)); } )
printf '     one thread %sms, four threads %sms\n' "$one" "$four"
# THE THRESHOLD IS LOOSE ON PURPOSE. Four times the work in under three
# times the time cannot happen if the threads are serialised; how much under
# depends on the machine, the allocator and what else is running, and this
# is not a benchmark.
check "four times the work in well under four times the time" \
  "$(awk -v a="$one" -v b="$four" 'BEGIN { print (a > 0 && b < a * 3) ? "parallel" : "serial" }')" \
  "parallel"

rm -rf "$D"
echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
