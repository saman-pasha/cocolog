# cocolog -- a Prolog interpreter that keeps its knowledge base in Zigurat.
#
# WHAT THIS NEEDS, AND WHAT IT DOES NOT TOUCH. cocolog uses two other projects
# and modifies neither:
#
#   Cicili     the language the interpreter is written in. Used at BUILD time:
#              sbcl runs cicili.lisp over the .cicili files and out comes C.
#              Point CICILI at a checkout of it.
#
#   ZiguratIP  the database. Used at RUN time, over a socket, and at setup time
#              through its `parsi' compiler, which turns parsi/*.parsi into
#              objects inside a ZiguratIP home. Point ZIGURATIP_HOME at one.
#
# Neither is patched, forked or vendored. The client under client/ speaks
# Zigurat's protocol from C and includes nothing of ZiguratIP's -- libc and
# the sockets API and nothing else. The embedded knowledge base links against
# a BUILT ZiguratIP's Core and StreamIO (point ZIGURATIP at the checkout),
# and the torch module against libtorch, because the one binary carries both.
#
#   make            the C client and the ONE cocolog binary: the interpreter
#                   with the embedded MVCCS engine and the torch module both
#                   linked in, so the four knowledge-base arrangements --
#                   --local, the server, --http, --embed -- are a
#                   runtime choice, never a build
#   make client     just the client
#   make schema     compile the Parsi objects into $(ZIGURATIP_HOME)
#   make test       run the suite (the database tests skip without a server)
#   make clean

CICILI         ?= $(HOME)/cicili
ZIGURATIP      ?= $(HOME)/ZiguratIP
SBCL           ?= sbcl

# ---- which compiler ---------------------------------------------------------
# CLANG, EVERYWHERE, and the same one for every layer. The interpreter, the
# client, the embedded store and the loadable modules used to be built by
# whatever each step happened to name -- `cc' here, `gcc' in a build.sh,
# `g++' on the link line -- which is three toolchains in one binary and a
# benchmark that cannot say what it measured. CC and CXX are now the single
# answer, exported so every build.sh under modules/ and embed/ inherits it.
#
# `make CICILI_CC=gcc CICILI_CXX=g++' still builds with gcc; nothing here is
# load-bearing on clang. What IS load-bearing is that all of it agrees.
#
# CC and CXX name the two WRAPPERS in tools/cc rather than the compilers
# outright, because tools/cc/cxx carries the --gcc-install-dir that Ubuntu
# makes necessary -- clang borrows libstdc++ from the newest gcc it can
# find, and gcc-14's runtime directory ships no C++ headers, so a bare
# clang++ dies on `#include <string>'. tools/cc/README has the detail.
#
# CICILI NAMES ITS COMPILER OUTRIGHT and takes no override, so the one step
# this file does not run itself is reached through tools/cc -- `gcc' and
# `g++' there are two more shims onto the same wrappers, on PATH for that
# step alone. tools/cc/README also has the three-line Cicili patch that
# would retire them.
# `?=' WOULD NOT HAVE WORKED, and did not: make gives CC and CXX built-in
# values of `cc' and `g++', whose origin is `default' rather than
# `undefined', so `CXX ?= ...' leaves g++ in place and the final link went
# on being a gcc link while every other line said clang. Testing the
# origin is what actually means "unless the caller said otherwise".
CICILI_CC      ?= clang
CICILI_CXX     ?= clang++
ifeq ($(origin CC),default)
CC             := $(CURDIR)/tools/cc/cc
endif
ifeq ($(origin CXX),default)
CXX            := $(CURDIR)/tools/cc/cxx
endif
export CICILI_CC
export CICILI_CXX
CFLAGS         ?= -Wall -Wextra -std=c99 -O3 -D_DEFAULT_SOURCE
AR             ?= ar

BUILD          := build
CLIENT_LIB     := $(BUILD)/libcocologc.a
# THE ARCHIVE IS libc AND SOCKETS, and stays that way: tls.o is NOT
# in it. It goes into the cocolog binary instead, beside -lssl -lcrypto,
# and zeytun.c reaches it through WEAK symbols -- so every test/*.cicili
# target, which links only this archive, gets plaintext and needs no
# OpenSSL. Putting it in here made test/shared.cicili fail to link with
# `undefined reference to SSL_free' from a test that speaks only the
# binary protocol.
CLIENT_OBJS    := $(BUILD)/zigurat.o $(BUILD)/zeytun.o

# ---- TLS for the client, when there is any ----------------------------------
# DETECTED RATHER THAN ASSUMED, and the failure is a sentence rather than a
# missing symbol: client/tls.c compiles a stub half without
# COCO_ZT_TLS, so `--https' reports "built without TLS" by name and every
# other thing in the client is unaffected.
#
# Wherever cocolog builds against a ZiguratIP, OpenSSL is already there --
# libCryptography links -lcrypto. This is for the case where it is not.
ZT_TLS_PROBE   := $(shell printf '\043include <openssl/ssl.h>\nint main(void){return 0;}\n' > /tmp/.coco-ssl-probe.c 2>/dev/null && $(CC) /tmp/.coco-ssl-probe.c -o /dev/null -lssl -lcrypto >/dev/null 2>&1 && echo yes || echo no)
ifeq ($(ZT_TLS_PROBE),yes)
ZT_TLS_CFLAGS  := -DCOCO_ZT_TLS
ZT_TLS_LIBS    := -lssl -lcrypto
else
ZT_TLS_CFLAGS  :=
ZT_TLS_LIBS    :=
endif
LIB_SOURCES    := $(wildcard lib/*.cicili)

.PHONY: all client schema test clean check-cicili modules index dialect-check lint

all: client cocolog

# ---- the C client -----------------------------------------------------------
# A static archive rather than a shared object, so nothing linked against it
# needs an rpath or LD_LIBRARY_PATH at run time.

client: $(CLIENT_LIB)

$(BUILD)/%.o: client/%.c client/zigurat.h client/zeytun.h
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) $(ZT_TLS_CFLAGS) -Iclient -c $< -o $@

$(CLIENT_LIB): $(CLIENT_OBJS)
	$(AR) rcs $@ $(CLIENT_OBJS)

$(BUILD)/probe: client/probe.c $(CLIENT_LIB)
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -Iclient client/probe.c -o $@ -L$(BUILD) -lcocologc $(ZT_TLS_LIBS)

# ---- the interpreter --------------------------------------------------------

check-cicili:
	@test -f "$(CICILI)/cicili.lisp" || { \
	  echo "cocolog: set CICILI to a Cicili checkout (looked in $(CICILI))" >&2; \
	  exit 1; }

# THE COMPILER IS RUN FROM ITS OWN DIRECTORY, and the target is named
# absolutely. Cicili takes the working directory it started in as the place its
# own builtins and standard library live (core.lisp sets *cicili-path* from
# getcwd), so running it from anywhere else makes it fail to find
# builtins.cicili. It changes into the target's directory itself before
# compiling, so a relative -I or -L in a target is relative to that file.
# --release is Cicili's own release set (-O3; -falign-loops=32 for C):
# the interpreter ships optimised, matching the engine and the server.
CICILI_RUN = PATH="$(CURDIR)/tools/cc:$$PATH" \
	     sh -c 'cd "$(CICILI)" && $(SBCL) --script cicili.lisp --release "$$1"' cicili

# ONE BINARY. The Cicili run compiles the interpreter and links a plain
# executable; the link below replaces it with the full one -- the embedded
# knowledge base (embed/embed.cicili: the same eighteen procedures the
# server offers, in-process over the Cicili MVCCS engine, so --embed DIR
# opens the store embedded and `swarm' runs its workers as threads of the
# one process the store belongs to) and the torch module
# (modules/torch/coco-torch.cicili: libtorch as cocolog predicates). Both register
# through weak symbols the interpreter already carries, so linking them in
# is all it takes. Which knowledge base a run uses -- --local, the server,
# --http, or --embed -- is then an option, never a build.

# THE LINK NO LONGER MENTIONS LIBTORCH. torch and bigint were objects in
# this line, reached through weak symbols; they are loadable modules under
# modules/ now, so the binary needs neither libtorch nor its -rpath -- and
# a TORCH_LIB default lived here for the link line long after the link
# line stopped reading it. Where libtorch is is modules/torch/build.sh's
# business now, and $LIBTORCH, $TORCH_INCLUDE and $TORCH_LIB are all read
# there. What is left of the C++ dependency is the EMBEDDED STORE, which
# genuinely is part of the binary and genuinely needs libCore.
cocolog: check-cicili cocolog.cicili $(LIB_SOURCES) $(CLIENT_LIB) $(BUILD)/tls.o
	$(CICILI_RUN) "$(CURDIR)/cocolog.cicili"
	CICILI="$(CICILI)" ZIGURATIP="$(ZIGURATIP)" sh embed/build.sh
	$(CXX) -O3 .libs/cocolog.o embed/.libs/embed.o \
	  -o cocolog \
	  -rdynamic -ldl \
	  $(BUILD)/tls.o -Lbuild -lcocologc $(ZT_TLS_LIBS) -lm -lpthread \
	  -L"$(ZIGURATIP)/home/lib" -lCore -lStreamIO \
	  -Wl,-rpath,"$(ZIGURATIP)/home/lib"

# ---- the loadable modules ---------------------------------------------------
# EVERY ONE OF THESE USED TO BE IN THE BINARY, or on its critical path.
# tcp was swept into cocolog.c by the wildcard; torch and bigint were objects
# in the link, reached through weak symbols; curl was already loadable and is
# what the other three were measured against. They are all modules/ now, and
# `make' builds none of them -- which is the point: a cocolog with no libtorch,
# no ZiguratIP headers and no libcurl still builds and still runs.
#
#   make modules        build every one that CAN be built here
#   sh modules/tcp/build.sh   just that one
#
# Each is skipped, loudly, when what it needs is absent.
modules:
	@for m in tcp thread process text os curl bigint torch tensorflow sha aes der x509 tls ray; do \
	  printf '%-8s ' "$$m"; \
	  if CICILI="$(CICILI)" ZIGURATIP="$(ZIGURATIP)" sh modules/$$m/build.sh >/dev/null 2>&1; then \
	    echo "built"; \
	  else \
	    echo "SKIPPED (see: sh modules/$$m/build.sh)"; \
	  fi; \
	done

# ---- the schema -------------------------------------------------------------
# Compiled by ZiguratIP's own parsi program into a ZiguratIP home. This is the
# one step that needs a ZiguratIP checkout, and it writes only into that home's
# object directory -- which is where a Parsi object is supposed to go.

schema:
	sh parsi/build.sh

# ---- the agent's index -------------------------------------------------------
# tools/coco-agent reads this repository rather than being told about it: the
# reserved-name blocklist is EXTRACTED from lib/, modules/ and library/, and
# the dialect card's citations are CHECKED against the lines they name. Both
# are cocolog now -- there is no Python left in tools/coco-agent -- so both
# need a built binary, which is why they are separate targets rather than
# part of `all'.
#
# `index' regenerates blocklist.json, surface.jsonl, exemplars.jsonl and
# capabilities.json -- all gitignored, all remade in seconds. `dialect-check'
# proves every citation in traps.jsonl still points at the code it claims,
# which is the thing that rots. `lint' runs the linter over files you name:
#
#     make lint FILES="myprogram.pl"

index:
	sh tools/coco-agent/tool.sh build
	sh tools/coco-agent/tool.sh index

dialect-check:
	sh tools/coco-agent/tool.sh card --check

lint: index
	@sh tools/coco-agent/lint.sh $(FILES)

# ---- tests -------------------------------------------------------------------

test: all $(BUILD)/probe
	sh test/run.sh

clean:
	rm -rf $(BUILD) cocolog cocolog.c *.o *.lo .libs
	rm -rf modules/torch/coco-torch.cpp modules/torch/*.o modules/torch/*.lo modules/torch/.libs \
	  modules/tcp/tcp.c modules/tcp/sdk.cicili modules/curl/curl.c modules/curl/sdk.cicili \
  modules/ray/ray.c modules/ray/sdk.cicili \
	  library/*.so
	rm -rf embed/embed.cpp embed/*.o embed/*.lo embed/.libs embed/ce_smoke embed/smoke.o
	rm -rf modules/bigint/coco-bigint.cpp modules/bigint/*.o modules/bigint/*.lo modules/bigint/.libs modules/bigint/zigheaders
	rm -f embed/Core embed/StreamIO embed/mvccs-lib.cicili embed/generated embed/ziglib
	rm -f test/*.c test/*.o test/*.lo test/cocolog_*_test
	rm -rf test/.libs
