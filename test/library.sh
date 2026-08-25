#!/bin/sh
# use_module, like SWI's: libraries load at run time.
#
# WHAT IT IS CHECKING, and why each part is there:
#
#   A REGISTERED MODULE ANSWERS AT ONCE. `use_module(library(lists))'
#   finds the linked-in module and succeeds without touching the disk.
#
#   A .pl LIBRARY LOADS FROM THE LIBRARY PATH -- as a goal and as a
#   `:- use_module' directive in a consulted file -- and loading twice
#   answers everything ONCE: the file registers as a clauses-only
#   module, and a module's clauses never load twice into one store.
#
#   A .so LIBRARY IS THE WHOLE SEAM, REACHED LATER: a module written in
#   Cicili against lib/sdk.cicili, compiled to a shared object, found on
#   $COCOLOG_LIBRARY, dlopen'd, and both its halves answer -- the C
#   predicate and the Coco clause on top of it. SKIPs without sbcl and
#   a Cicili checkout, because "no transpiler here" and "the loader is
#   wrong" are different findings.
#
#   A LIBRARY IS PROCESS-LOCAL, exactly as in SWI: its clauses are muted
#   and never written through, so a second process on the same knowledge
#   base does not see them -- proven across processes, because that is
#   the claim. SKIPs without a server.
#
#   A MISSING LIBRARY THROWS A CATCHABLE ERROR as a goal, and as a
#   directive warns and continues, so a borrowed file still reads.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
OUT=$(mktemp -d "${TMPDIR:-/tmp}/cocolog-library-XXXXXX")
trap 'rm -rf "$OUT"' EXIT INT TERM

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

# ---- a registered module ---------------------------------------------
got=$(timeout 60 "$C" query "use_module(library(lists)), msort([b,a],[a,b]), write(ok), nl" 2>/dev/null | grep -c '^ok$')
check "a linked-in library answers at once" "$got" "1"

# ---- a .pl library on the path ---------------------------------------
mkdir -p "$OUT/plib"
printf 'greeting(hello_from_pl).\n' > "$OUT/plib/greet.pl"
export COCOLOG_LIBRARY="$OUT/plib"

got=$(timeout 60 "$C" query "use_module(library(greet)), greeting(G), write(G), nl" 2>/dev/null | grep -c '^hello_from_pl$')
check "a .pl library loads as a goal" "$got" "1"

got=$(timeout 60 "$C" query "use_module(library(greet)), use_module(library(greet)), findall(G, greeting(G), L), length(L, N), write(N), nl" 2>/dev/null | grep -c '^1$')
check "and loading twice answers once" "$got" "1"

printf ':- use_module(library(greet)).\nboth(G) :- greeting(G).\n' > "$OUT/uses.pl"
got=$(timeout 60 "$C" run "$OUT/uses.pl" "both(G), write(G), nl" 2>/dev/null)
check "the :- use_module directive loads it too" "$got" "hello_from_pl"

# ---- the errors ------------------------------------------------------
got=$(timeout 60 "$C" query "catch(use_module(library(nosuch)), error(cocolog_error(_), _), (write(caught), nl))" 2>/dev/null | grep -c '^caught$')
check "a missing library throws, catchably" "$got" "1"

printf ':- use_module(library(nosuch)).\nstill(here).\n' > "$OUT/warns.pl"
got=$(timeout 60 "$C" run "$OUT/warns.pl" "still(X), write(X), nl" 2>/dev/null)
check "as a directive it warns and the file still reads" "$got" "here"

# ---- a .so library: the seam, reached later --------------------------
CICILI_DIR="${CICILI:-$HOME/cicili}"
if command -v sbcl >/dev/null 2>&1 && [ -f "$CICILI_DIR/cicili.lisp" ]; then
  ( cd "$CICILI_DIR" && sbcl --script cicili.lisp "$ROOT/test/hoot.cicili" ) > "$OUT/transpile.log" 2>&1
  if gcc -shared -fPIC -O2 -o "$OUT/plib/hoot.so" "$ROOT/test/hoot.c" > "$OUT/cc.log" 2>&1; then
    got=$(timeout 60 "$C" query "use_module(library(hoot)), hoot(X), double_hoot(X, X), write(X), nl" 2>/dev/null | grep -c '^hoot_from_c$')
    check "a compiled Cicili module loads, both halves" "$got" "1"
  else
    echo "FAIL the hoot fixture would not compile:"; cat "$OUT/cc.log"
    failures=$((failures + 1))
  fi
else
  echo ".so: SKIP (no sbcl or no CICILI checkout)"
fi

# ---- process-local, proven across processes --------------------------
HOST=${ZIGURAT_HOST:-127.0.0.1}
PORT=${ZIGURAT_PORT:-2160}
W="--kb library_test --host $HOST --port $PORT --timeout 15"
if timeout 20 "$C" $W list >/dev/null 2>&1; then
  timeout 60 "$C" $W forget >/dev/null 2>&1
  got=$(timeout 60 "$C" $W query "use_module(library(greet)), greeting(G), write(G), nl" 2>/dev/null | grep -c '^hello_from_pl$')
  check "wire: the loading process sees the library" "$got" "1"
  got=$(timeout 60 "$C" $W query "catch(greeting(_), error(existence_error(procedure, _), _), (write(clean), nl))" 2>/dev/null | grep -c '^clean$')
  check "wire: a second process does not -- nothing leaked" "$got" "1"

  # THE OTHER SIDE OF THE SAME COIN. A library is process-local and must
  # not leak, which is what the two checks above prove. A `:- dynamic'
  # DECLARATION is the opposite: README says a declaration is about the
  # knowledge base, so it has to outlive the process -- and it did not.
  # The row was written and read back, but ordinary resolution loads a
  # predicate lazily, one at a time, and that path learns clauses and not
  # declarations. A predicate declared in one process and never written
  # to had no clauses to fetch, so the next process raised
  # existence_error where SWI simply fails.
  timeout 60 "$C" $W forget >/dev/null 2>&1
  printf ':- dynamic ledger_mark/2.\n' > "$OUT/dyn.pl"
  timeout 60 "$C" $W consult "$OUT/dyn.pl" >/dev/null 2>&1
  got=$(timeout 60 "$C" $W query "catch((ledger_mark(_,_) -> write(unexpected) ; write(fails_cleanly)), error(existence_error(_,_),_), write(raised)), nl" 2>/dev/null | grep -acE '^fails_cleanly$')
  check "wire: a dynamic declaration DOES outlive the process" "$got" "1"
  got=$(timeout 60 "$C" $W query "catch(never_declared_at_all(_), error(existence_error(procedure,_),_), (write(raised), nl))" 2>/dev/null | grep -c '^raised$')
  check "wire: and an undeclared predicate still raises" "$got" "1"
  timeout 60 "$C" $W forget >/dev/null 2>&1
else
  echo "wire: SKIP no Zigurat server at $HOST:$PORT"
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
