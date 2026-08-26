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
CC             ?= cc
CFLAGS         ?= -Wall -Wextra -std=c99 -O3 -D_DEFAULT_SOURCE
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
# --release is Cicili's own release set (-O3; -falign-loops=32 for C):
# the interpreter ships optimised, matching the engine and the server.
CICILI_RUN = cd "$(CICILI)" && $(SBCL) --script cicili.lisp --release

# ONE BINARY. The Cicili run compiles the interpreter and links a plain
# executable; the link below replaces it with the full one -- the embedded
# knowledge base (embed/embed.cicili: the same eighteen procedures the
# server offers, in-process over the Cicili MVCCS engine, so --embed DIR
# opens the store embedded and `swarm' runs its workers as threads of the
# one process the store belongs to) and the torch module
# (torch/coco-torch.cicili: libtorch as cocolog predicates). Both register
# through weak symbols the interpreter already carries, so linking them in
# is all it takes. Which knowledge base a run uses -- --local, the server,
# --http, or --embed -- is then an option, never a build.
#
# TORCH_LIB must name the lib directory Cicili's {$TORCH_*} tokens resolved
# at compile time (default: the pip torch package's).
TORCH_LIB ?= $(shell python3 -c "import torch, os; print(os.path.join(os.path.dirname(torch.__file__), 'lib'))" 2>/dev/null)

cocolog: check-cicili cocolog.cicili $(LIB_SOURCES) $(CLIENT_LIB)
	$(CICILI_RUN) "$(CURDIR)/cocolog.cicili"
	CICILI="$(CICILI)" ZIGURATIP="$(ZIGURATIP)" sh embed/build.sh
	CICILI="$(CICILI)" sh torch/build.sh
	CICILI="$(CICILI)" ZIGURATIP="$(ZIGURATIP)" sh bigint/build.sh
	g++ -O3 .libs/cocolog.o embed/.libs/embed.o torch/.libs/coco-torch.o \
	  bigint/.libs/coco-bigint.o \
	  -o cocolog \
	  -rdynamic -ldl \
	  -Lbuild -lcocologc -lm -lpthread \
	  -L"$(ZIGURATIP)/home/lib" -lCore -lStreamIO \
	  -L"$(TORCH_LIB)" -ltorch -ltorch_cpu -lc10 \
	  -Wl,-rpath,"$(ZIGURATIP)/home/lib" -Wl,-rpath,"$(TORCH_LIB)"

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
	rm -rf torch/coco-torch.cpp torch/*.o torch/*.lo torch/.libs
	rm -rf embed/embed.cpp embed/*.o embed/*.lo embed/.libs embed/ce_smoke embed/smoke.o
	rm -rf bigint/coco-bigint.cpp bigint/*.o bigint/*.lo bigint/.libs bigint/zigheaders
	rm -f embed/Core embed/StreamIO embed/mvccs-lib.cicili embed/generated embed/ziglib
	rm -f test/*.c test/*.o test/*.lo test/cocolog_*_test
	rm -rf test/.libs
