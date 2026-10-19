#!/bin/sh
# cocolint -- the cocolog dialect linter, written in cocolog.
#
#     sh tools/cocolint/lint.sh myprogram.pl [more.pl ...]
#     sh tools/cocolint/lint.sh --auto   [--quiet] [--repo DIR]
#     sh tools/cocolint/lint.sh --staged [--quiet] [--repo DIR]
#
# Exits 1 if there is a HARD finding, or if an auto mode's dialect-card check
# fails, 0 otherwise.
#
# AUTO MODE LINTS WHAT CHANGED, in every area the repository keeps Prolog
# in: --auto takes the working tree against HEAD -- staged, unstaged and
# untracked -- and --staged takes the index alone, checking the content the
# commit will hold rather than the file on disk. Both also run the dialect
# card's citation check, because a commit that moves a cited line breaks the
# card without touching a .pl.
#
# A .pl IS THE ONLY THING LINTED. A module is Cicili; its Prolog half is
# strings inside the module, not a file, and it does not lint as one --
# library(stream)'s half implements the ISO stream names the X2 trap warns
# about, and answers 58 HARD findings for doing its job. So a changed
# .cicili is NAMED and skipped, never silently passed. lib/swipl's files are
# vendored and unmodified, and are named too. Silence is the one answer this
# mode must not give: a changed module that looks checked is worse than one
# that says it was not.
#
# --repo DIR scans another checkout's git changes with this checkout's
# linter: a worktree, or the suite's fixture. The card check is this
# checkout's, and runs only when DIR is this checkout.
#
# THE INDEX IS NEVER STALE, and is rebuilt only when it is. blocklist.pl and
# traps.pl are generated from this checkout's own source, and a linter running
# against a stale blocklist reports collisions with names that have moved --
# worse than not running, because the message is confident. It used to rebuild
# unconditionally, which cost nothing while the reader was Python; the reader
# is clauses.pl now and that is four and a half seconds a run. --if-stale
# keeps the guarantee and drops the waste: a missing or out-of-date output is
# rebuilt, and nothing else is.
#
# THE FILE LIST GOES THROUGH THE ENVIRONMENT, not the goal term. cocolog HAS
# argv now -- `--' ends its own arguments and the tail reaches the program as
# `current_prolog_flag(argv, V)' -- so this could be `... cl_main -- $@'. It
# is not, and the reason is worth keeping: a path with a space in it survives
# a file with one path per line unambiguously, and the environment costs this
# script one mktemp. Rewriting it to argv would be a change with no defect
# behind it.

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
BIN="${COCOLOG_BIN:-$ROOT/cocolog}"

usage() {
    echo "usage: lint.sh FILE.pl [FILE.pl ...]" >&2
    echo "       lint.sh --auto   [--quiet] [--repo DIR]" >&2
    echo "       lint.sh --staged [--quiet] [--repo DIR]" >&2
    exit 2
}

MODE=files
QUIET=0
REPO=$ROOT
while [ $# -gt 0 ]; do
    case "$1" in
        --auto)   MODE=auto; shift ;;
        --staged) MODE=staged; shift ;;
        --quiet)  QUIET=1; shift ;;
        --repo)   [ $# -ge 2 ] || usage; REPO=$2; shift 2 ;;
        --)       shift; break ;;
        -*)       usage ;;
        *)        break ;;
    esac
done
if [ "$MODE" = files ]; then
    [ $# -gt 0 ] || usage
else
    [ $# -eq 0 ] || usage
    GIVEN=$REPO
    REPO=$(git -C "$GIVEN" rev-parse --show-toplevel 2>/dev/null) || {
        echo "cocolint: $GIVEN is not a git repository" >&2
        exit 2
    }
fi
[ -x "$BIN" ] || { echo "cocolint: no binary at $BIN" >&2; exit 2; }

T=
LIST=
TREE=
cleanup() {
    [ -n "$T" ] && rm -f "$T"
    [ -n "$LIST" ] && rm -f "$LIST"
    [ -n "$TREE" ] && rm -rf "$TREE"
    return 0
}
trap cleanup EXIT INT TERM

T=$(mktemp) || exit 2

if [ "$MODE" = files ]; then
    for f in "$@"; do
        case "$f" in /*) printf '%s\n' "$f" ;; *) printf '%s\n' "$(pwd)/$f" ;; esac
    done > "$T"
    LIST=$T
else
    LIST=$(mktemp) || exit 2
    if [ "$MODE" = staged ]; then
        TREE=$(mktemp -d) || exit 2
        git -C "$REPO" diff --cached --name-only --diff-filter=ACMR > "$T" || exit 2
    else
        if git -C "$REPO" rev-parse --verify -q HEAD >/dev/null 2>&1; then
            git -C "$REPO" diff HEAD --name-only --diff-filter=ACMR > "$T" || exit 2
        else
            git -C "$REPO" ls-files > "$T" || exit 2
        fi
        git -C "$REPO" ls-files --others --exclude-standard >> "$T" || exit 2
    fi
    sort -u "$T" -o "$T"

    N=0
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        case "$f" in
            *.pl)
                case "$f" in
                    lib/swipl/*)
                        echo "cocolint: $f: vendored, not read" >&2
                        continue
                        ;;
                esac
                if [ "$MODE" = staged ]; then
                    mkdir -p "$TREE/$(dirname "$f")" || continue
                    if git -C "$REPO" show ":$f" > "$TREE/$f" 2>/dev/null; then
                        printf '%s\n' "$TREE/$f" >> "$LIST"
                        N=$((N + 1))
                    fi
                else
                    [ -f "$REPO/$f" ] || continue
                    printf '%s\n' "$REPO/$f" >> "$LIST"
                    N=$((N + 1))
                fi
                ;;
            *.cicili)
                echo "cocolint: $f: Cicili, not Prolog -- not linted" >&2
                ;;
        esac
    done < "$T"

    RC=0
    if [ "$REPO" = "$ROOT" ]; then
        if ! CARD=$(sh "$HERE/tool.sh" card --check 2>&1); then
            printf '%s\n' "$CARD"
            echo "cocolint: the dialect card's citations moved, or are gone; see tools/cocolint/traps.jsonl" >&2
            RC=1
        fi
    fi

    if [ "$N" -eq 0 ]; then
        if [ "$QUIET" -eq 0 ]; then
            if [ "$MODE" = staged ]; then
                echo "cocolint: no staged .pl file" >&2
            else
                echo "cocolint: no changed .pl file" >&2
            fi
        fi
        exit $RC
    fi
fi

sh "$HERE/tool.sh" build --if-stale >/dev/null || exit 2
sh "$HERE/tool.sh" card --facts --if-stale >/dev/null || exit 2

COCOLOG_LIBRARY="$ROOT/library:$COCOLOG_LIBRARY" \
COCOLOG_ROOT="$ROOT" \
COCO_LINT_FILES="$LIST" \
  "$BIN" --local run \
    "$HERE/blocklist.pl" "$HERE/traps.pl" "$HERE/clauses.pl" "$HERE/lint.pl" \
    cl_main
LINT_RC=$?
[ "$LINT_RC" -ne 0 ] && exit $LINT_RC
[ "$MODE" = files ] && exit 0
exit $RC
