#!/bin/sh
# library(zigurat): the connection under the knowledge base, steered from
# Prolog.
#
# WHAT IT IS CHECKING, and why each part is there:
#
#   THE TRANSACTION IS THE PROGRAM'S TO SHAPE. zigurat_begin,
#   zigurat_isolation/1, zigurat_auto_commit/1 and zigurat_transaction_id/1
#   answer on a live connection; an explicit zigurat_commit makes a write
#   durable BEFORE the turn's own commit, and an explicit zigurat_rollback
#   takes an uncommitted write back -- both proven ACROSS PROCESSES,
#   because "committed" is a claim about what another process sees.
#
#   DML TRAVELS AS PROCEDURE CALLS. zigurat_call/3 calls a compiled
#   procedure with typed arguments and hands back what came: a RETURNS
#   value as itself, a cursor's rows as lists -- the same rows the
#   knowledge base's own hooks ride.
#
#   DDL IS THE SERVER'S COMPILER, AND THE SERVER'S GATE. zigurat_compile/1
#   ships Parsi source; a server with COMPILER/REMOTE_MODE FALSE -- the
#   shipped default -- refuses it, and the refusal arrives as a catchable
#   error. That the refusal is exact is what this suite can check against
#   a default server; the positive road needs an operator who turned the
#   gate, and is documented rather than assumed here.
#
#   --local HAS NO CONNECTION, and every predicate says so as a catchable
#   error instead of pretending a local store has a transaction to steer.
#
# THERE IS NO `use_module(library(zigurat))' IN ANY CASE HERE, and that is
# the point rather than an omission: zigurat is TIER 1 -- compiled in and
# registered before the first goal, like lists, apply, dcg, files and
# builtins -- so asking for it is a directive that does nothing. These
# cases used to open with one, which made every query read as though the
# import were doing some work. `test/library.sh' is where the fact that
# `use_module' on a registered module succeeds at once is checked.
#
# SKIPs without a server, because "no server here" and "the module is
# wrong" are different findings.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-52s %s\n' "$1" "$2"
  else
    printf 'FAIL %-52s got [%s] want [%s]\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

if [ ! -x "$C" ]; then echo "no cocolog binary -- make first"; exit 1; fi

# ---- --local refuses, catchably, with no server needed ----------------
got=$(timeout 60 "$C" query "catch(zigurat_commit, error(cocolog_error(_), _), (write(refused), nl))" 2>/dev/null | grep -c '^refused$')
check "--local refuses the connection verbs" "$got" "1"

HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
if ! timeout 20 "$C" --kb ziglib_test --host "$HOST" --tcp "$PORT" \
     query "true" >/dev/null 2>&1; then
  echo "SKIP no Zigurat server at $HOST:$PORT"
  exit 0
fi

W="$C --kb ziglib_test --host $HOST --tcp $PORT --timeout 10"

# ---- `--port' IS DEPRECATED AND STILL EXACTLY `--tcp' ------------------
# It named a number when there was one transport; there are four now, and
# --tcp/--tls/--http/--https say WHICH as well as where. Nothing in this
# tree spells it any more -- but a script somewhere does, so it keeps
# working, and SILENTLY: a deprecation notice on stderr every run would
# land in the output of every pipeline that has one.
got=$(timeout 20 "$C" --kb ziglib_test --host "$HOST" --port "$PORT" --timeout 10 \
        query "true" 2>/dev/null | grep -c '^  1. true$')
check "--port still reaches the server" "$got" "1"
got=$(timeout 20 "$C" --kb ziglib_test --host "$HOST" --port "$PORT" --timeout 10 \
        query "true" 2>&1 >/dev/null | wc -c | tr -d ' ')
check "--port says nothing on stderr" "$got" "0"

# a clean slate for the counts below
timeout 60 $W forget >/dev/null 2>&1

# ---- the verbs answer -------------------------------------------------
got=$(timeout 60 $W query "zigurat_begin, zigurat_isolation(serializable), zigurat_isolation(read_committed), zigurat_auto_commit(false), zigurat_transaction_id(T), integer(T), write(ok), nl" 2>/dev/null | grep -c '^ok$')
check "begin, isolation, auto_commit, transaction_id" "$got" "1"

# ---- an explicit commit is durable across processes -------------------
timeout 60 $W query "assert(zlib_c(1)), zigurat_commit, write(done), nl" >/dev/null 2>&1
got=$(timeout 60 $W query "zlib_c(X), write(X), nl" 2>/dev/null | grep -c '^1$')
check "an explicit commit is seen by a second process" "$got" "1"

# ---- an explicit rollback takes an uncommitted write back -------------
timeout 60 $W query "assert(zlib_r(1)), zigurat_rollback, write(done), nl" >/dev/null 2>&1
# an unknown procedure THROWS here (as in SWI) -- a rolled-back predicate
# is not merely false, it is not there at all
got=$(timeout 60 $W query "catch(( zlib_r(_) -> write(seen) ; write(clean) ), error(existence_error(_, _), _), write(clean)), nl" 2>/dev/null | grep -c '^clean$')
check "an explicit rollback is invisible to a second process" "$got" "1"

# ---- DML: a compiled procedure, called with typed arguments -----------
timeout 60 $W query "assert(zlib_q(41)), assert(zlib_q(42))" >/dev/null 2>&1
got=$(timeout 60 $W query "zigurat_call('cocolog::clause_count', [ziglib_test, zlib_q, int(1)], [N]), write(N), nl" 2>/dev/null | grep -c '^2$')
check "zigurat_call answers a RETURNS value" "$got" "1"

got=$(timeout 60 $W query "zigurat_call('cocolog::clauses_of', [ziglib_test, zlib_q, int(1)], Rows), length(Rows, N), write(N), nl" 2>/dev/null | grep -c '^2$')
check "and hands a cursor's rows back as lists" "$got" "1"

got=$(timeout 60 $W query "zigurat_call('cocolog::clauses_of', [ziglib_test, zlib_q, int(1)], [[_, B] | _]), write(B), nl" 2>/dev/null | grep -c 'zlib_q(41)')
check "with the fields readable in place" "$got" "1"

# ---- DDL: the compiler's gate answers as an error ---------------------
# The shipped default is COMPILER/REMOTE_MODE FALSE, and the refusal must
# arrive as a catchable error naming the server's reason -- not as a hang,
# not as a success. An operator who turned the gate on gets the compile
# instead, and then the catch simply never fires; either way the goal
# proves, which is what makes this checkable against any server.
got=$(timeout 60 $W query "catch((zigurat_compile('SUITE zlib_ddl; CREATE TABLE cocolog::zlib_ddl (id Long NOT NULL); END SUITE;'), write(compiled)), error(cocolog_error(_), _), write(refused)), nl" 2>/dev/null | grep -c '^\(refused\|compiled\)$')
check "zigurat_compile answers, gate or compile" "$got" "1"

# ---- leave nothing behind ---------------------------------------------
timeout 60 $W forget >/dev/null 2>&1

echo
if [ "$failures" -eq 0 ]; then echo "GREEN"; else echo "RED: $failures failure(s)"; fi
[ "$failures" -eq 0 ]
