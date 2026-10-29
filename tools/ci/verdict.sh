#!/bin/sh
# The suite's verdict on a CI runner: every case by name, and a SKIP that
# this machine had no reason to take counted as red.
#
#   sh tools/ci/verdict.sh LOG CASES ALLOWED SUMMARY RERUN
#
#   LOG      what `cocolog -s test/run.pl' printed
#   CASES    the case names, one a line, in the runner's order: test/run.pl's
#            cicili_names/1 then pl_names/1, asked of cocolog itself, so the
#            list is never written down twice
#   ALLOWED  the cases this runner may SKIP, separated by spaces: the ones
#            whose library the install did not build (torch, TensorFlow, ...)
#   SUMMARY  the file the Markdown summary is appended to
#   RERUN    the file the names of the cases worth running again alone are
#            written to, one a line: each red case, and each SKIP that was not
#            allowed (its reason is in its own output, which the runner keeps)
#
# The exit status is the verdict: 0 only when every case printed its line,
# none was red, every SKIP was ALLOWED, and the runner printed `red: 0'.
# On stdout: one line a problem, as a GitHub annotation.
#
# RED: 0 IS NOT A GREEN SUITE (CLAUDE.md, "The suite"). A case whose server
# died, whose swipl is missing, or whose module did not build says SKIP and
# exits 0, and the runner counts it as not red. A run that is green here has
# no such SKIP in it.
set -eu
[ $# -eq 5 ] || { echo "usage: sh tools/ci/verdict.sh LOG CASES ALLOWED SUMMARY RERUN" >&2; exit 2; }
log=$1; cases=$2; allowed=$3; summary=$4; rerun=$5
[ -r "$log" ] || { echo "::error title=suite::no suite log at $log"; exit 1; }
[ -r "$cases" ] || { echo "::error title=suite::no case list at $cases"; exit 1; }
# no names is no verdict: an empty list would read as a green run of nothing
[ -n "$(tr -d ' \n' < "$cases")" ] || { echo "::error title=suite::the case list at $cases is empty -- cocolog did not answer test/run.pl's names"; exit 1; }
: > "$rerun"

# ONE PASS OVER THE NAMES, ANOTHER OVER THE LOG. A case's line begins with its
# name and a space (test/run.pl pads every name to eleven columns, and one of
# eleven letters or more gets a single space), so `httpd ' is never the start
# of `httpd-tls  ...' nor `torch-grad ' of `torch-graph ...'. The lines are
# found in the runner's order, each after the one before, so a FAIL line or a
# build's tail that happens to begin with a case's name is never taken for
# it. What lies between one case's line and the next is that case's: its FAIL
# lines, or a test binary's BUILD FAILED tail.
awk -v allowed=" $allowed " -v summary="$summary" -v rerun="$rerun" '
  FNR == NR { if ($0 != "") name[++n] = $0; next }
  { line[++m] = $0 }
  function md(s) { gsub(/\|/, "\\|", s); gsub(/</, "\\&lt;", s); return s }
  END {
    j = 1
    for (k = 1; k <= n; k++) {
      at[k] = 0
      for (i = j; i <= m; i++)
        if (index(line[i], name[k] " ") == 1) { at[k] = i; j = i + 1; break }
    }
    tail = 0
    for (i = 1; i <= m; i++) if (line[i] ~ /^red: [0-9]+$/) tail = i
    green = 0; skips = 0; reds = 0; missing = 0; odd = 0
    oklist = ""; skiplist = ""; nolist = ""; problems = ""
    for (k = 1; k <= n; k++) {
      c = name[k]
      if (at[k] == 0) {
        missing++; state[k] = "no line"; nolist = nolist " " c
        continue
      }
      rest = substr(line[at[k]], length(c) + 1); sub(/^ +/, "", rest)
      # a .pl case ends its line with its seconds; a test binary has none
      secs[k] = ""
      if (match(rest, / +[0-9]+s$/)) { secs[k] = substr(rest, RSTART); rest = substr(rest, 1, RSTART - 1) }
      else if (rest ~ /^[0-9]+s$/) { secs[k] = rest; rest = "" }
      gsub(/[ s]/, "", secs[k])
      text[k] = rest
      # the lines that belong to this case: up to the next case, or `red: N`
      stop = m + 1
      for (q = k + 1; q <= n; q++) if (at[q] > 0) { stop = at[q]; break }
      if (tail > at[k] && tail < stop) stop = tail
      extra = ""
      for (i = at[k] + 1; i < stop; i++) if (line[i] != "") extra = extra line[i] "\n"
      if (rest == "GREEN") { green++; state[k] = "GREEN" }
      else if (rest == "SKIP") {
        skips++
        if (index(allowed, " " c " ")) { state[k] = "SKIP"; skiplist = skiplist " " c }
        else {
          odd++; state[k] = "SKIP, not allowed here"
          problems = problems "- **" c "**: SKIP, which this runner had no reason to take\n"
          printf "::error title=suite::%s SKIPPED, and nothing on this runner should make it skip (its reason is in the rerun below)\n", c
          print c > rerun
        }
      } else {
        reds++; state[k] = "RED"
        if (rest == "") rest = "(its output ended on an empty line)"
        text[k] = rest
        problems = problems "- **" c "**: `" md(rest) "`\n"
        if (extra != "") problems = problems "\n```\n" extra "```\n\n"
        printf "::error title=suite::%s is red: %s\n", c, rest
        print c > rerun
      }
    }
    # a runner that died takes every case after it: one annotation, not fifty
    if (missing) {
      problems = problems "- " missing " cases have no line in the log (the runner stopped before them?):" nolist "\n"
      first = substr(nolist, 2); sub(/ .*/, "", first)
      printf "::error title=suite::%d cases have no line in the suite log, the first %s: the runner stopped before them\n", missing, first
    }
    for (k = 1; k <= n; k++) if (state[k] == "GREEN" && index(allowed, " " name[k] " ")) oklist = oklist " " name[k]
    said = -1
    if (tail) { said = line[tail]; sub(/^red: /, "", said) }
    whole = 0
    if (!tail) {
      whole = 1
      problems = problems "- the runner never printed `red: N`: it did not finish\n"
      print "::error title=suite::the runner never printed its red: line -- it did not finish"
    } else if (said + 0 != reds) {
      whole = 1
      problems = problems "- the runner said `red: " said "`, and " reds " lines are red\n"
      printf "::error title=suite::the runner said red: %s, and %d case lines are red\n", said, reds
    }
    bad = reds + odd + missing + whole
    printf "### The suite: %d cases, %d GREEN, %d SKIP, %d red", n, green, skips, reds >> summary
    if (missing) printf ", %d with no line", missing >> summary
    printf "\n\n" >> summary
    if (bad) printf "**Red.**\n\n%s\n", problems >> summary
    else printf "**Green**: every case printed its line, none is red, and each SKIP is one this runner was allowed.\n\n" >> summary
    if (skiplist != "") printf "Skipped, as allowed here (no library built for them):%s\n\n", skiplist >> summary
    if (oklist != "") printf "Allowed to skip, and ran green:%s\n\n", oklist >> summary
    printf "<details><summary>Every case</summary>\n\n| case | verdict | seconds |\n|---|---|---|\n" >> summary
    for (k = 1; k <= n; k++) {
      v = state[k]; if (v == "RED") v = "RED: `" md(text[k]) "`"
      printf "| %s | %s | %s |\n", name[k], v, secs[k] >> summary
    }
    printf "\n</details>\n\n" >> summary
    exit (bad ? 1 : 0)
  }' "$cases" "$log"
