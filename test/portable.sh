# Two things a test script does that BSD userland spells differently.
# Sourced by the scripts that need them; nothing here is a test.
#
# now_ms: milliseconds since the epoch. `date +%s%3N' is GNU date; BSD's
# prints a literal `3N' on the end, and the arithmetic that follows dies
# with `value too great for base' -- which is how a timing check on a Mac
# came to say "serial" about threads that were running in parallel.
# perl's Time::HiRes is on every box that has perl, which is all of them.
now_ms() { perl -MTime::HiRes=time -e 'printf "%d\n", time*1000'; }
# detach: start a server in its own session where `setsid' exists (so a
# tool call's end does not take it down), and plainly where it does not
# -- macOS has no setsid, and inside a script the plain `&' is enough.
detach() { if command -v setsid >/dev/null 2>&1; then setsid "$@"; else "$@"; fi; }
