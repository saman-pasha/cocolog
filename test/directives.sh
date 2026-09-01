#!/bin/sh
# directives: `:- G' is a GOAL, `initialization' puts one off, and a bad one
# is reported rather than fatal.
#
# WHAT CHANGED, AND WHY IT NEEDED A CASE OF ITS OWN. A directive used to be
# matched against a list of fourteen names and refused if it was not one of
# them -- and the refusal took the WHOLE CONSULT with it, so a file whose
# first line was `:- initialization(main).' loaded nothing at all and the
# error named a directive rather than the file. Now the fourteen are only
# the ones that must act on the READER (op/3, set_prolog_flag,
# dynamic/1, if/elif/else/endif: they change how the rest of the file
# parses or what it means) and everything else is CALLED, in file order,
# through a seam the library layer fills in with an engine.
#
# THE THREE ANSWERS A DIRECTIVE CAN GIVE are what most of this file is
# about, because they are what a person sees when something is wrong:
# proved (silence), failed (a Warning naming the goal), threw (an ERROR
# naming the ball in SWI's words). None of the three stops the load.
#
# MEASURED AGAINST swipl, not remembered. Every message shape below was
# read off a real `swipl -q -g main -t halt' run first and the code written
# to match; where swipl is on the machine the last section runs the SAME
# file under both and diffs what they say. That is the only kind of
# compatibility claim that cannot be fooled by its author.
#
#   sh test/directives.sh
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
has() { # has LABEL NEEDLE TEXT
  case "$3" in
    *"$2"*) say "$1" "ok" ;;
    *) red=$((red + 1)); say "$1" "RED"
       printf '      wanted to find: %s\n      in            : %s\n' "$2" "$3" ;;
  esac
}

# ---- 1. a directive is a goal -------------------------------------------

cat > "$TMP/run.pl" <<'PL'
:- assert(seen(one)).
:- ( seen(one) -> assert(order(kept)) ; assert(order(broken)) ).
:- X is 2 + 3, assert(sum(X)).
answer(A-B-C) :- seen(A), order(B), sum(C).
PL

is "a directive RUNS" \
   "one-kept-5" \
   "$(./cocolog --local run "$TMP/run.pl" "(answer(A), write(A))" 2>&1)"

# THE ORDER IS THE FILE'S. `order(kept)' above is only kept if the second
# directive could see what the first one asserted -- which is the whole
# difference between running a directive where it stands and collecting
# them all up for later.

# ---- 2. a directive that does not prove -------------------------------

cat > "$TMP/bad.pl" <<'PL'
p(1).
:- nosuch_goal.
:- fail.
q(2).
PL

out=$(./cocolog --local run "$TMP/bad.pl" "(q(X), write(X))" 2>&1)
has "an unknown goal is an ERROR"        "ERROR: $TMP/bad.pl:2:"           "$out"
has "...in SWI's words"                  "Unknown procedure: nosuch_goal/0" "$out"
has "a failing goal is a Warning"        "Warning: $TMP/bad.pl:3:"          "$out"
has "...and the Warning names the goal"  "Goal (directive) failed: fail"    "$out"

is "AND THE LOAD CARRIED ON" "2" \
   "$(./cocolog --local run "$TMP/bad.pl" "(q(X), write(X))" 2>/dev/null)"

# The line numbers above are the point of the check: a message that says
# only "unknown procedure" in a file of two hundred clauses is a message
# you have to go looking for.

# ---- 3. a syntax error still ends the consult ---------------------------
#
# THE ONE THING THAT IS STILL FATAL, and it has to be: after a syntax error
# the reader does not know where the next clause begins, so carrying on
# would mean guessing.

cat > "$TMP/syn.pl" <<'PL'
p(1).
q(x :- .
PL
out=$(./cocolog --local run "$TMP/syn.pl" "true" 2>&1)
rc=$?
is "a syntax error is still fatal" "1" "$rc"

# ---- 4. initialization/1: after the file, not where it stands -----------

cat > "$TMP/init.pl" <<'PL'
:- initialization(greet).
greet :- format("greeted~n").
PL

is "initialization/1 runs AFTER the load" "greeted" \
   "$(./cocolog --local run "$TMP/init.pl" "true" 2>&1)"

# ...which is the reason it exists: `greet' is defined BELOW the directive
# that calls it, and a directive that ran where it stood could not.

cat > "$TMP/now.pl" <<'PL'
:- initialization(greet, now).
greet :- format("greeted~n").
PL
out=$(./cocolog --local run "$TMP/now.pl" "true" 2>&1)
has "now: runs it where it stands" "Unknown procedure: greet/0" "$out"

cat > "$TMP/order.pl" <<'PL'
:- initialization(format("second~n")).
:- initialization(format("third~n")).
:- format("first~n").
PL
is "and they run in the order they were written" "first second third" \
   "$(./cocolog --local run "$TMP/order.pl" "true" 2>&1 | tr '\n' ' ' | sed 's/ *$//')"

cat > "$TMP/ifail.pl" <<'PL'
:- initialization(fail).
:- initialization(format("still ran~n")).
PL
out=$(./cocolog --local run "$TMP/ifail.pl" "true" 2>&1)
has "one that fails is a Warning"    "Initialization goal failed" "$out"
has "...and the next one still runs" "still ran"                  "$out"

# AND ONE THAT THROWS IS AN ERROR NAMING THE BALL, which is what a real
# program does with a real failure: `typedef' throwing a term of its own
# from inside `:- initialization(...)'. The ball is not an error/2, so
# the message is SWI's `Unknown message:' -- word for word, measured.
cat > "$TMP/ithrow.pl" <<'PL'
:- initialization(build).
build :- throw(my_error("not a type", nosuch_t)).
PL
out=$(./cocolog --local run "$TMP/ithrow.pl" "true" 2>&1)
has "one that throws is an ERROR"  "Initialization goal raised exception:" "$out"
has "...and the ball is named"     "Unknown message: my_error"             "$out"
has "...at the line it was written" "$TMP/ithrow.pl:1:"                    "$out"

# ---- 5. initialization(main, main) IS the program -----------------------

cat > "$TMP/m0.pl" <<'PL'
:- initialization(main, main).
main :- format("main ran~n").
PL
out=$(./cocolog --local run "$TMP/m0.pl" "format(\"cli goal ran~n\")" 2>&1)
rc=$?
is "main: runs the goal"            "main ran" "$out"
is "...and HALTS, so the CLI's own goal does not run" "0" "$rc"

cat > "$TMP/m1.pl" <<'PL'
:- initialization(main, main).
main :- fail.
PL
out=$(./cocolog --local run "$TMP/m1.pl" "true" 2>&1)
rc=$?
is "a main that fails exits 1"  "1" "$rc"
has "...and says so"            "main: false" "$out"

cat > "$TMP/m2.pl" <<'PL'
:- initialization(main, main).
main :- throw(my_ball).
PL
out=$(./cocolog --local run "$TMP/m2.pl" "true" 2>&1)
rc=$?
is "a main that throws exits 2" "2" "$rc"
has "...naming the ball"        "Unknown message: my_ball" "$out"

cat > "$TMP/when.pl" <<'PL'
:- initialization(true, restore_state).
PL
out=$(./cocolog --local run "$TMP/when.pl" "true" 2>&1)
has "a when cocolog has not is refused BY NAME" "restore_state" "$out"

# ---- 6. the exit status of a goal, and what is said about it ------------
#
# `swipl -q -g GOAL -t halt': 0 proved, 1 failed -- SILENTLY, measured --
# and 2 threw. cocolog answers the same three.

cat > "$TMP/g.pl" <<'PL'
ok.
bad :- throw(my_ball).
typed :- atom_length(1, _).
PL

is "a proved goal exits 0" "0" \
   "$(./cocolog --local run "$TMP/g.pl" "ok" >/dev/null 2>&1; echo $?)"
is "a failed goal exits 1" "1" \
   "$(./cocolog --local run "$TMP/g.pl" "fail" >/dev/null 2>&1; echo $?)"
is "...and says nothing about it" "" \
   "$(./cocolog --local run "$TMP/g.pl" "fail" 2>&1)"
is "a goal that throws exits 2" "2" \
   "$(./cocolog --local run "$TMP/g.pl" "bad" >/dev/null 2>&1; echo $?)"

out=$(./cocolog --local run "$TMP/g.pl" "bad" 2>&1)
has "the message names the goal it was asked" "-g main:" "$out"
has "...and the ball, in SWI's words"         "Unknown message: my_ball" "$out"

out=$(./cocolog --local run "$TMP/g.pl" "nosuch" 2>&1)
has "an unknown procedure reads as SWI's" "Unknown procedure: nosuch/0" "$out"

out=$(./cocolog --local run "$TMP/g.pl" "X is foo + 1" 2>&1)
has "arithmetic on an atom reads as SWI's" "is not a function" "$out"

out=$(./cocolog --local run "$TMP/g.pl" "atom_length(X, _)" 2>&1)
has "an unbound argument reads as SWI's" "not sufficiently instantiated" "$out"

# ---- 7. the reader-level directives still act on the reader -------------

cat > "$TMP/rd.pl" <<'PL'
:- op(700, xfx, ===>).
rule(a ===> b).
:- dynamic counter/1.
counter(0).
PL
is "op/3 still takes effect for the rest of the file" "a===>b" \
   "$(./cocolog --local run "$TMP/rd.pl" "(rule(R), write(R))" 2>&1)"
is "dynamic/1 still declares" "0" \
   "$(./cocolog --local run "$TMP/rd.pl" "(counter(N), write(N))" 2>&1)"

# ---- 8. a computed argument list, which is what asked for all this ------
#
# THE PROGRAM THIS CASE WAS WRITTEN FOR: a type table whose entries are
# built by a directive at the end of the file, over predicates defined
# above it, through `apply/2' because the arity is only known at run time.
# Every part of that was impossible before: the directive was refused, and
# `apply/2' was not there.

cat > "$TMP/types.pl" <<'PL'
:- dynamic type/1.
type(int).
type(char).

describe(T, M, V, [T, M, V]) :- type(T), atom(V).

typedef(Es) :-
    reverse(Es, Rs), reverse([D|Rs], Full),
    apply(describe, Full),
    nth0(2, D, V),
    ( type(V) -> throw(error(permission_error(modify, type, V), _)) ; assert(type(V)) ).

names(Ns) :- findall(T, type(T), Ns).
PL
cat >> "$TMP/types.pl" <<'PL'
:- initialization(( typedef([int, *, intptr_t]), typedef([char, *, cstr_t]) )).
PL

is "apply/2 calls a goal whose arity was computed" "[int,char,intptr_t,cstr_t]" \
   "$(./cocolog --local run "$TMP/types.pl" "(names(Ns), write(Ns))" 2>&1)"

cat > "$TMP/twice.pl" <<'PL'
:- dynamic type/1.
type(int).
describe(T, M, V, [T, M, V]) :- type(T), atom(V).
typedef(Es) :-
    reverse(Es, Rs), reverse([D|Rs], Full),
    apply(describe, Full),
    nth0(2, D, V),
    ( type(V) -> throw(error(permission_error(modify, type, V), _)) ; assert(type(V)) ).
:- initialization(( typedef([int, *, p_t]), typedef([int, *, p_t]) )).
PL
out=$(./cocolog --local run "$TMP/twice.pl" "true" 2>&1)
has "and a typedef of a name already taken throws" "No permission to modify type" "$out"

# ---- 9. the same files under swipl --------------------------------------
#
# THE CLAIM IS COMPATIBILITY, so the check is a diff. Only the files whose
# output is Prolog's own and not cocolog's are run here: a message's exact
# wording differs (`[Thread main]', `user:' and the `catch/3:' context are
# SWI's and cocolog has no equivalent), so what is compared is what the
# PROGRAM printed and the exit status -- which is what a caller depends on.

if command -v swipl >/dev/null 2>&1; then
  for f in run init order m0 types; do
    case "$f" in
      run)   goal="(answer(A), write(A))" ;;
      types) goal="(names(Ns), write(Ns))" ;;
      *)     goal="true" ;;
    esac
    a=$(./cocolog --local run "$TMP/$f.pl" "$goal" 2>/dev/null; printf 'rc=%s' $?)
    b=$(swipl -q -g "$goal" -t halt "$TMP/$f.pl" 2>/dev/null; printf 'rc=%s' $?)
    is "swipl agrees over $f.pl" "$b" "$a"
  done
else
  say "swipl is not here, so the diff did not run" "SKIP"
fi

echo
if [ "$red" -eq 0 ]; then echo "GREEN"; else echo "RED: $red failure(s)"; fi
[ "$red" -eq 0 ]
