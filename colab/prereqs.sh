#!/bin/sh
# What to install before building, and it lives HERE rather than in the
# notebook cell.
#
# WHY THIS FILE EXISTS, and it is the second time the same lesson has
# been paid for in this directory. The package list used to be a line
# inside the notebook:
#
#     !apt-get -qq install -y build-essential sbcl libtool
#
# A notebook cell is a COPY of a fact that lives in the repository, and
# the two drift the moment either moves. When `libtool' turned out to be
# the wrong package -- the script Cicili invokes is in `libtool-bin' --
# the fix landed in the repo, the notebook cell in the user's BROWSER
# stayed as it was, and their next run cloned the corrected preflight,
# ran the stale apt line, and refused for the same reason a second time.
# Nothing was broken; the two halves were simply different ages.
#
# So the list is a file in the repo, the notebook calls it AFTER cloning,
# and a stale notebook still installs the right things -- because the
# only thing the cell still knows is where to find this.
#
#   sh colab/prereqs.sh
#
# Nothing here is quiet and nothing is forgiven: `-qq' with the output
# thrown away and `|| true' on the end is how the first version of this
# hid a failed install and cost a whole build.

set -e

echo "== installing what the build needs"

# THE PACKAGE LISTS GO STALE, and that is what breaks an install on a
# Colab image more often than anything else. Update first.
apt-get -qq update

# build-essential  gcc, g++ and make
# sbcl             runs Cicili, which emits every line of C in cocolog
#                  and in ZiguratIP's storage engine
# libtool-bin      /usr/bin/libtool ITSELF. Not `libtool': Debian and
#                  Ubuntu split them, and the `libtool' package ships
#                  libtoolize and the m4 macros while the script Cicili
#                  invokes is in libtool-bin. Installing the wrong one
#                  succeeds and leaves the build with no libtool.
apt-get -qq install -y build-essential sbcl libtool-bin

echo "   installed; colab/preflight.sh will say whether that was enough"
