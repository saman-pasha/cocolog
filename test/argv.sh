#!/bin/sh
# argv: the engine flag, and library(main) over it.
#
# TWO HALVES, AND THE FIRST IS THE ONE THAT COULD NOT BE FAKED.
# `current_prolog_flag(argv, V)' is answered by lib/library.cicili out of
# main()'s own argv, and the rule is that `--' ends cocolog's arguments and
# everything after belongs to the program. There has to be a separator
# because `run FILE GOAL' reads the LAST argument as the goal: without one,
# `run p.pl main --check' would try to prove `--check'. So the cases below
# check what a program REACHES, never what the parser did.
#
# The second half is library/main.pl, whose guided parsing tutorial 38
# covers. What is here and not there is UNGUIDED parsing -- the mode a
# program gets when it defines no opt_type/3 -- which a lesson that defines
# one cannot demonstrate from inside itself.
#
#   sh test/argv.sh
#
# The last line is GREEN or SKIP, because test/run.sh discards a shell
# case's exit status and reads only that line.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
cd "$ROOT" || exit 0

[ -x "$ROOT/cocolog" ] || { echo "SKIP no binary"; exit 0; }
. "$HERE/library-path.sh"

TMP=$(mktemp -d) || { echo "SKIP no tmpdir"; exit 0; }
trap 'rm -rf "$TMP"' EXIT
red=0

say() { printf '  %-46s %s\n' "$1" "$2"; }
is() {  # is LABEL WANT GOT
  if [ "$2" = "$3" ]; then say "$1" "ok"
  else red=$((red + 1)); say "$1" "RED"
        printf '      want: %s\n      got : %s\n' "$2" "$3"; fi
}

# ---- 1. the flag ---------------------------------------------------------

cat > "$TMP/av.pl" <<'PL'
show :- current_prolog_flag(argv, [_Exe|A]), write(A), nl.
os   :- current_prolog_flag(os_argv, V), length(V, N), write(N), nl.
head :- current_prolog_flag(argv, [E|_]),
        current_prolog_flag(executable, E2),
        ( E == E2 -> write(same) ; write(differ) ), nl.
PL

is "the tail after -- reaches the program" \
   "[--check,--fix,file.pl]" \
   "$(./cocolog --local run "$TMP/av.pl" show -- --check --fix file.pl 2>&1)"

is "no -- means an empty tail" \
   "[]" "$(./cocolog --local run "$TMP/av.pl" show 2>&1)"

is "-- with nothing after it is also empty" \
   "[]" "$(./cocolog --local run "$TMP/av.pl" show -- 2>&1)"

# THE ONE THAT MATTERS: an argument that reads as a cocolog option must NOT
# be eaten by cocolog's own option loop. If this fails, --embed would open a
# store the program meant to name as a file.
is "cocolog's own options pass through untouched" \
   "[--local,--embed,/nope,--kb,x]" \
   "$(./cocolog --local run "$TMP/av.pl" show -- --local --embed /nope --kb x 2>&1)"

# and a goal-shaped argument does not become the goal
is "an argument is not mistaken for the goal" \
   "[os]" "$(./cocolog --local run "$TMP/av.pl" show -- os 2>&1)"

is "argv's head is the executable flag" \
   "same" "$(./cocolog --local run "$TMP/av.pl" head 2>&1)"

# os_argv is the LITERAL line: ./cocolog --local run FILE os -- a b  = 8
is "os_argv is the whole command line" \
   "8" "$(./cocolog --local run "$TMP/av.pl" os -- a b 2>&1)"

# ---- 2. library(main), unguided ------------------------------------------
#
# NO opt_type/3 IN THIS FILE, which is the whole point of it: tutorial 38
# defines one and so can never reach this branch.

cat > "$TMP/ug.pl" <<'PL'
:- use_module(library(main)).
main(Argv) :- argv_options(Argv, P, O), msort(O, S), write(P-S), nl.
PL

is "unguided: --name=value, --name value, --flag, --no-x" \
   "[f.pl]-[colour(false),count(7),flag(true),name(value)]" \
   "$(./cocolog --local run "$TMP/ug.pl" main -- --name=value --count 7 --flag --no-colour f.pl 2>&1)"

# ---- 3. main/0 is the library's, main/1 is yours -------------------------

cat > "$TMP/m0.pl" <<'PL'
:- use_module(library(main)).
main(Argv) :- write(Argv), nl.
PL

is "main/0 hands main/1 the tail, not the executable" \
   "[one,two]" "$(./cocolog --local run "$TMP/m0.pl" main -- one two 2>&1)"

# ---- 4. a program that ACTS on its arguments -----------------------------
#
# END TO END, because everything above could pass over a flag nothing uses.
# This one counts its positional files and honours -n, which is what a real
# tool does with argv_options/3.

cat > "$TMP/tool.pl" <<'PL'
:- use_module(library(main)).
opt_type(n, count, integer).
opt_type(count, count, integer).
opt_type(v, verbose, boolean).
main(Argv) :-
    argv_options(Argv, Files, Opts),
    ( memberchk(count(N), Opts) -> true ; N = 1 ),
    ( memberchk(verbose(true), Opts) -> V = loud ; V = quiet ),
    length(Files, F),
    format("~w files, n=~w, ~w~n", [F, N, V]).
PL

is "a real tool reads its own command line" \
   "3 files, n=5, loud" \
   "$(./cocolog --local run "$TMP/tool.pl" main -- -v -n 5 a.pl b.pl c.pl 2>&1)"

is "and its defaults are the program's, not invented" \
   "0 files, n=1, quiet" \
   "$(./cocolog --local run "$TMP/tool.pl" main -- 2>&1)"

# ---- 5. `-s' is the form to use, and here is why -------------------------
#
# `-s FILE' IS `use_module(FILE), main' AND `run FILE main' IS A CONSULT,
# and the difference is not brevity: consulting WRITES THROUGH. A tool run
# with `run' against a real knowledge base leaves its own source in the
# database. This is the case that says so, and it needs a store to say it --
# --embed, so no server is required.
#
# It is also why `-s' is the right form for library(main) in particular:
# loading the file as a module puts the LIBRARY's main/0 ahead of the file's
# own clauses, which is the one that strips the executable and calls main/1.

is "-s runs a program and gives it argv" \
   "3 files, n=5, loud" \
   "$(./cocolog -s "$TMP/tool.pl" -- -v -n 5 a.pl b.pl c.pl 2>&1)"

KB="$TMP/kb"
cat > "$TMP/priv.pl" <<'PL'
tool_private_fact(1).
main :- write(ran), nl.
PL

./cocolog --embed "$KB" -s "$TMP/priv.pl" >/dev/null 2>&1
is "-s leaves the program's clauses OUT of the store" \
   "absent" \
   "$(./cocolog --embed "$KB" query "tool_private_fact(_)" >/dev/null 2>&1 && echo stored || echo absent)"

./cocolog --embed "$KB" run "$TMP/priv.pl" main >/dev/null 2>&1
is "and run CONSULTS, so the same clauses land in it" \
   "stored" \
   "$(./cocolog --embed "$KB" query "tool_private_fact(_)" >/dev/null 2>&1 && echo stored || echo absent)"

if [ $red -eq 0 ]; then
  echo "GREEN: argv reaches the program, and library(main) parses it"
else
  echo "RED: $red"
fi
