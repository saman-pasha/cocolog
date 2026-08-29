#!/bin/sh
# library(os) -- which system, who am I, how many cores, the environment,
# where a tool is: the questions every suite used to ask a shell.
#
# WHAT IS CHECKED, and why it is checkable at all: nearly everything here
# is a fact the shell can also state, so each answer is held against the
# shell's own -- `uname -s', `id -u', `hostname', `$HOME' -- and the two
# must agree. That is the whole promise: a script that asks library(os)
# gets what it would have got by shelling out, on either system, without
# the shell. The platform branch is pinned to what THIS machine is, so the
# same file is green on Linux and on macOS and says which it ran on.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
C="$ROOT/cocolog"
. "$HERE/library-path.sh"

failures=0
check() {
  if [ "$2" = "$3" ]; then
    printf 'ok   %-56s %s\n' "$1" "$(echo "$2" | cut -c1-20)"
  else
    printf 'FAIL %-56s\n     got  %s\n     want %s\n' "$1" "$2" "$3"
    failures=$((failures + 1))
  fi
}

[ -x "$C" ] || { echo "SKIP (build cocolog first)"; exit 0; }
[ -f "$ROOT/library/os.so" ] || { echo "SKIP (no library/os.so -- sh modules/os/build.sh)"; exit 0; }

U="use_module(library(os))"
q() { timeout 60 "$C" query "$U, $1" 2>/dev/null \
      | grep -aE '^answer\(.*\)$' | head -1 | sed 's/^answer(//; s/)$//'; }

echo "-- which system, held to uname"
sys=$(uname -s | tr 'A-Z' 'a-z')
check "os_name is uname -s, folded" "$(q "os_name(N), write(answer(N)), nl")" "$sys"
check "and os_is branches on it" \
  "$(q "( os_is($sys) -> W = here ; W = elsewhere ), write(answer(W)), nl")" "here"
check "os_arch is uname -m" "$(q "os_arch(M), write(answer(M)), nl")" "$(uname -m)"
check "the five-field uname carries the release" \
  "$(q "os_uname(_, _, R, _, _), write(answer(R)), nl")" "$(uname -r)"
check "os_hostname is hostname" "$(q "os_hostname(H), write(answer(H)), nl")" "$(hostname)"

echo
echo "-- who am I, held to id"
check "os_uid is id -u" "$(q "os_uid(U), write(answer(U)), nl")" "$(id -u)"
check "os_gid is id -g" "$(q "os_gid(G), write(answer(G)), nl")" "$(id -g)"
check "os_pid is a live process, and not its parent" \
  "$(q "os_pid(P), os_ppid(PP), ( P > 1, PP > 0, P =\\= PP -> W = distinct ; W = P-PP ), write(answer(W)), nl")" "distinct"
check "os_cpus is at least one, and an integer" \
  "$(q "os_cpus(N), ( integer(N), N >= 1 -> W = ok ; W = N ), write(answer(W)), nl")" "ok"

echo
echo "-- the environment"
check "os_home is \$HOME" "$(q "os_home(H), write(answer(H)), nl")" "$HOME"
check "os_env fails on an unset name, os_env/3 answers the default" \
  "$(q "( os_env('COCOLOG_NO_SUCH_VAR', _) -> A = set ; A = unset ), os_env('COCOLOG_NO_SUCH_VAR', D, fallback), write(answer(A-D)), nl")" \
  "unset-fallback"
check "os_environ lists every NAME-Value pair, HOME among them" \
  "$(q "os_environ(Ps), memberchk('HOME'-H, Ps), write(answer(H)), nl")" "$HOME"
# A value may carry `=' of its own; the split is on the FIRST one.
check "a value with an equals sign in it survives the split" \
  "$(COCOLOG_OS_EQ='a=b=c' timeout 60 "$C" query "$U, os_environ(Ps), memberchk('COCOLOG_OS_EQ'-V, Ps), write(answer(V)), nl" 2>/dev/null | grep -aE '^answer' | sed 's/^answer(//; s/)$//')" "a=b=c"
check "os_setenv is seen by os_env and by a child; os_unsetenv takes it back" \
  "$(q "os_setenv('COCOLOG_OS_PROBE', 'from-prolog'), os_env('COCOLOG_OS_PROBE', V), os_unsetenv('COCOLOG_OS_PROBE'), ( os_env('COCOLOG_OS_PROBE', _) -> W = still ; W = gone ), write(answer(V-W)), nl")" \
  "from-prolog-gone"
# macOS's TMPDIR ends in a slash; a path joined onto it would carry `//'.
check "os_tmp has no trailing slash" \
  "$(q "os_tmp(T), ( atom_concat(_, '/', T) -> W = slash ; W = clean ), write(answer(W)), nl")" "clean"
check "os_path is PATH, split" \
  "$(q "os_path(Ds), length(Ds, N), write(answer(N)), nl")" "$(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')"

echo
echo "-- a tool, found without a shell"
check "os_which finds sh where command -v does" "$(q "os_which(sh, P), write(answer(P)), nl")" "$(command -v sh)"
check "an absolute name is answered as itself, if executable" \
  "$(q "os_which('/bin/sh', P), write(answer(P)), nl")" "/bin/sh"
check "a tool that is not there fails, and os_has says so" \
  "$(q "( os_has(cocolog_no_such_tool_x) -> W = found ; W = absent ), write(answer(W)), nl")" "absent"
check "os_which is deterministic: one answer, no choice point left" \
  "$(q "findall(P, os_which(sh, P), Ps), length(Ps, N), write(answer(N)), nl")" "1"

echo
echo "-- the two names that differ between the systems"
case "$sys" in
  darwin) want_lib=DYLD_LIBRARY_PATH ;;
  *)      want_lib=LD_LIBRARY_PATH ;;
esac
check "os_lib_path_var names this system's linker variable" \
  "$(q "os_lib_path_var(V), write(answer(V)), nl")" "$want_lib"
if command -v setsid >/dev/null 2>&1; then want_pre="setsid "; else want_pre=""; fi
check "os_setsid_prefix is 'setsid ' exactly where setsid exists" \
  "$(q "os_setsid_prefix(P), atom_length(P, L), write(answer(L)), nl")" "${#want_pre}"
check "os_describe is one line naming system, arch and cpus" \
  "$(q "os_describe(D), ( sub_atom(D, _, _, 0, ' cpus') -> W = shaped ; W = D ), write(answer(W)), nl")" "shaped"

echo
if [ "$failures" -eq 0 ]; then
  echo "GREEN: 0 failure(s)"; exit 0
else
  echo "RED: $failures failure(s)"; exit 1
fi
