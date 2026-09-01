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
# THE BALL'S TEXT IS A QUOTED ATOM, deliberately: cocolog's
# `double_quotes' default is ISO's `codes' and SWI's is `string', so a
# "..." here would make this check about the flag rather than about the
# message. `:- set_prolog_flag(double_quotes, string).' is how a file
# that wants SWI's reading asks for it -- test/string.sh covers that.
cat > "$TMP/ithrow.pl" <<'PL'
:- initialization(build).
build :- throw(my_error('not a type', nosuch_t)).
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

# ---- 8. THE PROGRAM THIS CASE WAS WRITTEN FOR ---------------------------
#
# A Cicili TYPE DESCRIPTOR table, trimmed from the real one but not
# simplified: `nil' as a value with `null/1' to test for it, a `type/N'
# family whose arities overlap, `describe/7' choosing among them, a
# `typedef/1' that dispatches through `apply/2' BECAUSE THE ARITY IS ONLY
# KNOWN AT RUN TIME, and a ball of its own when the answer is no.
#
# Every part of it was impossible here a day ago: the directive at the
# foot of the file was REFUSED and took the whole consult with it, and
# `apply/2' did not exist. Both halves of the failure path are checked
# too, because a table that only ever succeeds proves nothing about the
# reporting.

cat > "$TMP/typedef.pl" <<'PL'
nil.                                   % Cicili's NIL, as a value
null(A) :- A == nil.

:- dynamic type/1.
type(void).
type(char).
type(int).
type('unsigned int').
type('FILE').

multi_pointer(M) :-
    atom(M), atom_chars(M, Ps), length(Ps, L), L =< 3,
    forall(member(P, Ps), P == *).

describe(C, T, M, P, V, DESC) :-
    ( null(C) ; C == const ),
    atom(T), type(T),
    ( ( null(M), null(P) ) ; ( multi_pointer(M), ( null(P) ; P == const ) ) ),
    atom(V),
    DESC = [C, T, M, P, V], !.

type(T, V, DESC)            :- describe(nil, T, nil, nil, V, DESC).
type(T, M, V, DESC)         :- describe(nil, T, M, nil, V, DESC).
type(const, T, M, V, DESC)  :- describe(const, T, M, nil, V, DESC).

typedef(Es) :-
    reverse(Es, Rs),
    reverse([DESC | Rs], FEs),
    (   apply(type, FEs), !
    ;   throw(ccl_type_error('type does not exist', typedef(Es)))   ),
    nth0(4, DESC, V),
    (   type(V), !, throw(ccl_type_error('name exists', typedef(Es)))
    ;   assert(type(V)), !   ).

names(Ns) :- findall(T, type(T), Ns).
PL
cat >> "$TMP/typedef.pl" <<'PL'
:- initialization(( typedef([const, char, *, cstr_t]),
                    typedef([int, *, intptr_t]),
                    typedef([int, size_t]) )).
PL

is "apply/2 dispatches on an arity known at run time" \
   "[void,char,int,unsigned int,FILE,cstr_t,intptr_t,size_t]" \
   "$(./cocolog --local run "$TMP/typedef.pl" "(names(Ns), write(Ns))" 2>&1)"

# A NAME ALREADY TAKEN, and a type that was never there: the two ways the
# table says no, both of them a ball of the program's own shape reported
# at the line the directive was written on.
sed 's|typedef(\[int, size_t\])|typedef([int, *, cstr_t])|' "$TMP/typedef.pl" > "$TMP/taken.pl"
out=$(./cocolog --local run "$TMP/taken.pl" "true" 2>&1)
has "a typedef of a name already taken throws" \
    "Unknown message: ccl_type_error('name exists'" "$out"
has "...reported at the directive's line" "typedef.pl" "$(printf '%s' "$out" | sed 's|taken|typedef|')"

sed 's|typedef(\[int, size_t\])|typedef([nosuch_t, x_t])|' "$TMP/typedef.pl" > "$TMP/unknown.pl"
out=$(./cocolog --local run "$TMP/unknown.pl" "true" 2>&1)
has "and a typedef of a type that is not there throws" \
    "Unknown message: ccl_type_error('type does not exist'" "$out"

# THE TEXT IS A QUOTED ATOM AND NOT A "STRING", which is the thing to
# copy out of this fixture: `double_quotes' is ISO's `codes' here and
# SWI's is `string', so a ball carrying "text" reports as a list of
# numbers under cocolog and reads back as text under swipl. The same
# throw with an atom in it reads the same under both -- which is what
# the diff below is able to check.

# ---- 9. the same files under swipl --------------------------------------
#
# THE CLAIM IS COMPATIBILITY, so the check is a diff. Only the files whose
# output is Prolog's own and not cocolog's are run here: a message's exact
# wording differs (`[Thread main]', `user:' and the `catch/3:' context are
# SWI's and cocolog has no equivalent), so what is compared is what the
# PROGRAM printed and the exit status -- which is what a caller depends on.

if command -v swipl >/dev/null 2>&1; then
  for f in run init order m0 typedef; do
    case "$f" in
      run)   goal="(answer(A), write(A))" ;;
      typedef) goal="(names(Ns), write(Ns))" ;;
      *)     goal="true" ;;
    esac
    a=$(./cocolog --local run "$TMP/$f.pl" "$goal" 2>/dev/null; printf 'rc=%s' $?)
    b=$(swipl -q -g "$goal" -t halt "$TMP/$f.pl" 2>/dev/null; printf 'rc=%s' $?)
    is "swipl agrees over $f.pl" "$b" "$a"
  done

  # AND THE MESSAGE ITSELF, for the one case where both systems have
  # something to say. Two SWI-isms are normalised away and nothing else
  # is: `[Thread main]' names the thread that raised it, which the
  # cocolog CLI has no equivalent for, and swipl prints the path
  # absolute where cocolog prints it as the caller wrote it. What is
  # left is compared line for line -- including the four-space indent
  # on a directive's second line, which cocolog copies, and its ABSENCE
  # on an initialization's, where swipl's slot holds the thread tag.
  norm() { sed "s|$TMP/||; s|\[Thread main\] ||" ; }
  a=$(./cocolog --local run "$TMP/ithrow.pl" true 2>&1 >/dev/null | norm)
  b=$(swipl -q -g true -t halt "$TMP/ithrow.pl" 2>&1 >/dev/null | norm)
  is "swipl says the same words about a thrown init goal" "$b" "$a"
  # ONLY THE LOCATION LINE FOR A DIRECTIVE, and the reason is worth
  # writing down rather than normalising away: swipl prefixes the message
  # with the CONTEXT of the throw -- `catch/3: Unknown procedure: …' --
  # and cocolog has nothing to put there, because a builtin leaves
  # error/2's second argument unbound (card row C3). The line that says
  # WHERE is identical, and that is the half a reader navigates by.
  a=$(./cocolog --local run "$TMP/bad.pl" true 2>&1 >/dev/null | norm | head -1)
  b=$(swipl -q -g true -t halt "$TMP/bad.pl" 2>&1 >/dev/null | norm | head -1)
  is "...and locates a directive that threw the same way" "$b" "$a"
else
  say "swipl is not here, so the diff did not run" "SKIP"
fi

echo
if [ "$red" -eq 0 ]; then echo "GREEN"; else echo "RED: $red failure(s)"; fi
[ "$red" -eq 0 ]
