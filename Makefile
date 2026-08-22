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
#   make test       run the suite (the database tests skip without a server)
#   make clean

CICILI         ?= $(HOME)/cicili
SBCL           ?= sbcl
CC             ?= cc
CFLAGS         ?= -Wall -Wextra -std=c99 -g -O2 -D_DEFAULT_SOURCE
AR             ?= ar

BUILD          := build
CLIENT_LIB     := $(BUILD)/libcocologc.a
CLIENT_OBJS    := $(BUILD)/zigurat.o $(BUILD)/zeytun.o
LIB_SOURCES    := $(wildcard lib/*.cicili)

.PHONY: all client schema test clean check-cicili

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
	rm -rf $(BUILD) cocolog cocolog.c *.o *.lo .libs
	rm -f test/*.c test/*.o test/*.lo test/cocolog_*_test
	rm -rf test/.libs
