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
# Zigurat's protocol from C and includes nothing of ZiguratIP's -- libc and the
# sockets API and nothing else -- so cocolog builds without a ZiguratIP
# checkout at all. It only needs a running server to talk to.
#
#   make            the C client and the cocolog program
#   make client     just the client
#   make schema     compile the Parsi objects into $(ZIGURATIP_HOME)
#   make embed      cocolog-embed: the knowledge base INSIDE the process,
#                   on the Cicili MVCCS engine (needs CICILI and ZIGURATIP)
#   make test       run the suite (the database tests skip without a server)
#   make clean

CICILI         ?= $(HOME)/cicili
ZIGURATIP      ?= $(HOME)/ZiguratIP
SBCL           ?= sbcl
CC             ?= cc
CFLAGS         ?= -Wall -Wextra -std=c99 -g -O2 -D_DEFAULT_SOURCE
AR             ?= ar

BUILD          := build
CLIENT_LIB     := $(BUILD)/libcocologc.a
CLIENT_OBJS    := $(BUILD)/zigurat.o $(BUILD)/zeytun.o
LIB_SOURCES    := $(wildcard lib/*.cicili)

.PHONY: all client schema embed torch full test clean check-cicili

all: client cocolog

# ---- the C client -----------------------------------------------------------
# A static archive rather than a shared object, so nothing linked against it
# needs an rpath or LD_LIBRARY_PATH at run time.

client: $(CLIENT_LIB)

$(BUILD)/%.o: client/%.c client/zigurat.h client/zeytun.h
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -Iclient -c $< -o $@

$(CLIENT_LIB): $(CLIENT_OBJS)
	$(AR) rcs $@ $(CLIENT_OBJS)

$(BUILD)/probe: client/probe.c $(CLIENT_LIB)
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -Iclient client/probe.c -o $@ -L$(BUILD) -lcocologc

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
CICILI_RUN = cd "$(CICILI)" && $(SBCL) --script cicili.lisp

cocolog: check-cicili cocolog.cicili $(LIB_SOURCES) $(CLIENT_LIB)
	$(CICILI_RUN) "$(CURDIR)/cocolog.cicili"

# ---- the embedded knowledge base --------------------------------------------
# The same eighteen procedures the server offers, implemented in-process over
# the Cicili MVCCS engine and the very .cicili table definitions the Parsi
# compiler generated (embed/embed.cicili). The client's ce_* hooks are weak
# symbols, so the plain `cocolog' binary neither carries nor needs any of
# this; `cocolog-embed' is the same cocolog.o with the engine linked in --
# --store DIR then opens the store embedded, and `swarm' runs its workers as
# threads of the one process the store belongs to.

cocolog-embed: cocolog
	CICILI="$(CICILI)" ZIGURATIP="$(ZIGURATIP)" sh embed/build.sh
	g++ -g -O0 .libs/cocolog.o embed/.libs/embed.o -o cocolog-embed \
	  -Lbuild -lcocologc -lm -lpthread \
	  -L"$(ZIGURATIP)/home/lib" -lCore -lStreamIO \
	  -Wl,-rpath,"$(ZIGURATIP)/home/lib"

embed: cocolog-embed

# ---- the torch module --------------------------------------------------------
# libtorch as cocolog predicates (torch/coco-torch.cicili). The module
# registers through a weak symbol, so only this binary carries it. Needs
# libtorch -- $LIBTORCH, or the pip torch package, resolved by Cicili's
# {$TORCH_*} tokens at build time; TORCH_LIB below must name the same lib
# directory for the link (default: the pip package's).
TORCH_LIB ?= $(shell python3 -c "import torch, os; print(os.path.join(os.path.dirname(torch.__file__), 'lib'))" 2>/dev/null)

cocolog-torch: cocolog
	CICILI="$(CICILI)" sh torch/build.sh
	g++ -g -O0 .libs/cocolog.o torch/.libs/coco-torch.o -o cocolog-torch \
	  -Lbuild -lcocologc -lm -lpthread \
	  -L"$(TORCH_LIB)" -ltorch -ltorch_cpu -lc10 \
	  -Wl,-rpath,"$(TORCH_LIB)"

torch: cocolog-torch

# ---- everything at once ------------------------------------------------------
# The interpreter with BOTH engines embedded: the knowledge base on the
# Cicili MVCCS engine (--store DIR) and libtorch behind the torch module.
# A Prolog program can then load a dataset, train on it, and assert the
# trained model into Zigurat, one process, no server.

cocolog-full: cocolog
	CICILI="$(CICILI)" ZIGURATIP="$(ZIGURATIP)" sh embed/build.sh
	CICILI="$(CICILI)" sh torch/build.sh
	g++ -g -O0 .libs/cocolog.o embed/.libs/embed.o torch/.libs/coco-torch.o \
	  -o cocolog-full \
	  -Lbuild -lcocologc -lm -lpthread \
	  -L"$(ZIGURATIP)/home/lib" -lCore -lStreamIO \
	  -L"$(TORCH_LIB)" -ltorch -ltorch_cpu -lc10 \
	  -Wl,-rpath,"$(ZIGURATIP)/home/lib" -Wl,-rpath,"$(TORCH_LIB)"

full: cocolog-full

# ---- the schema -------------------------------------------------------------
# Compiled by ZiguratIP's own parsi program into a ZiguratIP home. This is the
# one step that needs a ZiguratIP checkout, and it writes only into that home's
# object directory -- which is where a Parsi object is supposed to go.

schema:
	sh parsi/build.sh

# ---- tests -------------------------------------------------------------------

test: all $(BUILD)/probe
	sh test/run.sh

clean:
	rm -rf $(BUILD) cocolog cocolog-embed cocolog-torch cocolog-full cocolog.c *.o *.lo .libs
	rm -rf torch/coco-torch.cpp torch/*.o torch/*.lo torch/.libs
	rm -rf embed/embed.cpp embed/*.o embed/*.lo embed/.libs embed/ce_smoke embed/smoke.o
	rm -f embed/Core embed/StreamIO embed/mvccs-lib.cicili embed/generated embed/ziglib
	rm -f test/*.c test/*.o test/*.lo test/cocolog_*_test
	rm -rf test/.libs
