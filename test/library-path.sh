# THE LIBRARY PATH FOR A TEST, in one place. Sourced by every case that
# needs a tier-2 library, with $ROOT already set to this checkout:
#
#     . "$HERE/library-path.sh"
#
# WHAT IT DOES: puts this checkout's `library/' at the FRONT of
# $COCOLOG_LIBRARY and keeps whatever was already there behind it.
#
# THE SUITE'S OWN PATH COMES FIRST, and that is the whole reason this is a
# prepend rather than an assignment either way round. A test must exercise
# the libraries this checkout SHIPS: if a developer's own
# COCOLOG_LIBRARY held another `httpd.pl', a suite that let it win would
# be green about somebody else's code. Putting ours first makes that
# impossible without ignoring the setting altogether.
#
# AND WHATEVER THE USER HAD IS KEPT, because it used to be thrown away.
# Ten cases each wrote `export COCOLOG_LIBRARY="$ROOT/library"' -- ten
# copies of one fact, and every one of them silently discarded a path
# somebody had exported on purpose. A module of your own that a case
# needs is now simply reachable:
#
#     COCOLOG_LIBRARY=/opt/my/modules sh test/run.sh
#
# THE VARIABLE IS COLON-SEPARATED and always was -- `lib/library.cicili'
# splits it and tries each entry in turn, then `./library', then
# `library/' and `lib/swipl/' beside the BINARY. What was missing was
# anywhere that treated it as a list rather than as one directory.
COCOLOG_LIBRARY="$ROOT/library${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}"
export COCOLOG_LIBRARY
