#!/bin/sh
# The string type: SWI's, as a cell tag in the engine.
#
# WHAT IS BEING CHECKED IS THAT IT IS A TYPE, not that a handful of
# predicates answer. A string that were secretly an atom would pass every
# conversion test and fail the three that matter: it must not BE an atom, it
# must carry a NUL, and it must sit between atom and compound in the standard
# order. Those three are the reason SWI has the type and the reason cocolog
# now does.
#
#   sh test/string.sh
#
# The last line is GREEN or SKIP, because test/run.sh discards a shell case's
# exit status and reads only that line.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
cd "$ROOT" || exit 0
[ -x "$ROOT/cocolog" ] || { echo "SKIP no binary"; exit 0; }

red=0
q() { timeout 60 "$ROOT/cocolog" --local query "$1" 2>&1 | grep -aoE 'answer\([^)]*\)' | head -1 | sed 's/^answer(//; s/)$//'; }
is() {
  if [ "$2" = "$3" ]; then printf '  ok   %-52s %s\n' "$1" "$3"
  else red=$((red + 1)); printf '  RED  %-52s want %s, got %s\n' "$1" "$2" "$3"; fi
}

# ---- it is a TYPE, not an atom in disguise -------------------------------
is "string/1 is true of one"        yes "$(q "atom_string(a,S), string(S), write(answer(yes)), nl")"
is "and false of the atom"          no  "$(q "( string(a) -> write(answer(yes)) ; write(answer(no)) ), nl")"
is "a string is not an atom"        no  "$(q "atom_string(a,S), ( atom(S) -> write(answer(yes)) ; write(answer(no)) ), nl")"
is "nor a list"                     no  "$(q "atom_string(a,S), ( is_list(S) -> write(answer(yes)) ; write(answer(no)) ), nl")"
is "nor equal to its atom"          no  "$(q "atom_string(a,S), ( S == a -> write(answer(yes)) ; write(answer(no)) ), nl")"

# ---- the NUL, which is the whole reason the type exists -------------------
#
# The same three bytes: a 3-character STRING and a 1-character ATOM, because
# an atom is a NUL-terminated name in a table and stops at the first one.
is "a string carries a NUL"         3   "$(q "string_codes(S,[0'a,0,0'b]), string_length(S,N), write(answer(N)), nl")"
is "the same bytes as an atom stop" 1   "$(q "atom_codes(A,[0'a,0,0'b]), atom_length(A,N), write(answer(N)), nl")"
is "and the codes come back whole"  3   "$(q "string_codes(S,[0'a,0,0'b]), string_codes(S,C), length(C,N), write(answer(N)), nl")"

# ---- the standard order is SWI's ------------------------------------------
is "atom < string"                  yes "$(q "atom_string(a,S), ( compare(<,a,S) -> write(answer(yes)) ; write(answer(no)) ), nl")"
is "string < compound"              yes "$(q "atom_string(a,S), ( compare(<,S,f(1)) -> write(answer(yes)) ; write(answer(no)) ), nl")"
is "number < string"                yes "$(q "atom_string(a,S), ( compare(<,1,S) -> write(answer(yes)) ; write(answer(no)) ), nl")"
is "== is by bytes, not by identity" yes "$(q "atom_string(x,A), atom_string(x,B), ( A == B -> write(answer(yes)) ; write(answer(no)) ), nl")"

# ---- the conversions -------------------------------------------------------
is "atom_string both ways"          hello "$(q "atom_string(hello,S), atom_string(A,S), write(answer(A)), nl")"
is "number_string parses"           3.5   "$(q "number_string(N,\"3.5\"), write(answer(N)), nl")"
is "string_concat"                  ab    "$(q "string_concat(\"a\",\"b\",S), atom_string(A,S), write(answer(A)), nl")"
is "string_upper"                   ABC   "$(q "string_upper(\"aBc\",S), atom_string(A,S), write(answer(A)), nl")"
is "term_string reads back"         yes   "$(q "term_string(T,\"g(2)\"), ( T = g(2) -> write(answer(yes)) ; write(answer(no)) ), nl")"

# ---- split_string, including the two rules everybody trips over -----------
is "split_string counts the fields" 3 "$(q "split_string(\"a,b,c\",\",\",\"\",P), length(P,N), write(answer(N)), nl")"
is "an empty field is a field"      3 "$(q "split_string(\"a,,b\",\",\",\"\",P), length(P,N), write(answer(N)), nl")"
is "no separators means one field"  1 "$(q "split_string(\"abc\",\"\",\"\",P), length(P,N), write(answer(N)), nl")"
is "padding is stripped"            ab "$(q "split_string(\"  ab  \",\"\",\" \",[S]), atom_string(A,S), write(answer(A)), nl")"

# ---- sub_string/5 backtracks, which is why it is a clause ------------------
is "sub_string enumerates"          21 "$(q "findall(B-L, sub_string(\"hello\",B,L,_,_), All), length(All,N), write(answer(N)), nl")"
is "and finds a known substring"    1  "$(q "sub_string(\"hello\",B,_,_,\"ell\"), write(answer(B)), nl")"

# ---- A CODE LIST IS TEXT, which is SWI's rule and matters more here --------
#
# `double_quotes' is `codes', so "hello" IS [104,101,108,108,111]. Before
# these accepted a code list, string_length("hello", N) answered 21 -- the
# length of the list written out -- which is a silent wrong answer.
is "a code list is text"            5 "$(q "string_length(\"hello\",N), write(answer(N)), nl")"

# ---- and what has NOT changed ---------------------------------------------
is "a double-quoted literal is codes" no "$(q "( string(\"abc\") -> write(answer(yes)) ; write(answer(no)) ), nl")"

# ---- the writer ------------------------------------------------------------
is "quoted, it writes in quotes"    '"ell"' "$(q "sub_string(\"hello\",1,3,_,S), format(\"answer(~q)~n\",[S])")"
is "unquoted, it writes its text"   ell     "$(q "sub_string(\"hello\",1,3,_,S), format(\"answer(~w)~n\",[S])")"

if [ $red -eq 0 ]; then echo "GREEN: the string type is a type"; else echo "RED: $red"; fi
