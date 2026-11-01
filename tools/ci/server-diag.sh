#!/bin/sh
# What a ZiguratIP server that is gone left behind, written into the job's
# log: the last lines of its own log and, on macOS, the newest crash report
# the system wrote for it, copied beside the logs as well. The artifact holds
# the whole log, but a session that cannot download artifacts reads only the
# job's log (3.14.0's and 3.15.0's Intel jobs lost the server during groups,
# and said no more than that it was gone).
#
#   sh tools/ci/server-diag.sh LOG [DIR]
log=$1
dir=${2:-}
echo "::group::the ZiguratIP server's log ($log), its last 80 lines"
if [ -f "$log" ]; then tail -80 "$log"; else echo "(no log at $log)"; fi
echo "::endgroup::"
for d in "$HOME/Library/Logs/DiagnosticReports" /Library/Logs/DiagnosticReports; do
  r=$(ls -t "$d"/ziguratip* 2> /dev/null | head -1)
  if [ -n "$r" ]; then
    echo "::group::the crash report $r"
    head -120 "$r"
    echo "-- its frames:"
    grep -E '"(symbol|imageOffset|exception|type|signal|faultingThread)"' "$r" | head -80
    echo "::endgroup::"
    if [ -n "$dir" ]; then cp "$r" "$dir/" 2> /dev/null || true; fi
    exit 0
  fi
done
echo "no crash report for ziguratip under DiagnosticReports"
