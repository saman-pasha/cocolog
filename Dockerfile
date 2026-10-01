# Dockerfile -- cocolog on Ubuntu 24.04, built from source by
# install/install-linux.sh, with Cicili and ZiguratIP beside it.
#
#   make docker          # BOTH images, every time: the owner's rule
#                        #   cocolog:VERSION, :latest          no optional part, no Python
#                        #   cocolog:VERSION-ray-torch-numpy   WITH_RAY WITH_TORCH WITH_NUMPY
#   make docker-save     # each as dist/*.tar.gz, with dist/SHA256SUMS
#   docker build --build-arg WITH_OPENCV=1 -t cocolog:opencv .   # any other mix
#
#   docker run --rm cocolog query 'X is 6*7, write(X), nl'
#   docker run --rm -it cocolog                          # the REPL
#   docker run --rm -v "$PWD":/work cocolog --embed KB -s program.pl
#
#   docker save cocolog | gzip > cocolog.tar.gz      # to another machine,
#   docker load -i cocolog.tar.gz                    # a Windows PC included
#
# The run with a mount keeps its knowledge base in ./KB on the host, through
# the embedded store: no server to start. On a Mac the image runs in
# Docker's Linux VM like any other; it is a Linux build, not a macOS one.
# README's "Or in Docker" has the Windows commands and their caveats.
#
# THE INSTALL IS THE ONE install/README.md DOCUMENTS, not a copy of its
# steps -- a copy is a second place for a fact, and colab/prereqs.sh records
# what that cost once. What the Dockerfile adds is only what a bare image
# lacks before the script can run, and a check of what it built.
#
# FOUR PARTS ARE OPTIONAL, AND OFF unless a build argument asks, so the
# default image is cocolog with fourteen loadable modules and ZiguratIP, and
# no Python:
#
#   WITH_NUMPY=1    python3 and NumPy, so library(numpy) -- the one module
#                   that embeds CPython, until it is rewritten without it
#   WITH_OPENCV=1   OpenCV 4, so library(opencv)
#   WITH_RAY=1      raylib 6.0, built from source, and Xvfb, so library(ray)
#                   and library(clay_ray), drawing on a virtual screen when
#                   the container has no display of its own
#   WITH_TORCH=1    PyTorch, so library(torch) -- CPU-only wheels unless
#                   TORCH_INDEX_URL names another index
#
# They are install-linux.sh's own knobs of the same names, passed through.
#
# WHAT IT DOES NOT DO: start a server, or run the suite.
#
# BUILT on 2026-10-01 under Docker Desktop 4.93.0 on an Intel Mac, both
# images by `make docker-save' in 24 minutes with the caches warm:
#
#   cocolog:1.8.38                  1.26 GB in Docker, 299 MB saved. No
#                                   Python. engine, gc and string GREEN
#                                   inside; numpy and langs SKIP by name.
#   cocolog:1.8.38-ray-torch-numpy  3.07 GB in Docker, 683 MB saved. Python
#                                   3.12.3, NumPy 1.26.4, torch 2.13.0+cpu.
#                                   engine, gc, string, numpy, langs, ray and
#                                   clay GREEN inside; lessons 22, 39 and 40
#                                   done, and 29 and 47 under xvfb-run.
#
# The plain image also answered --version, a query, the REPL from a pipe,
# and an --embed store on a mounted directory that a second container read
# back; the wire sections SKIP by name, there being no server inside. The
# first builds found three faults outside this file: library(numpy) needing
# NumPy 2's headers and then not starting on Linux (both fixed in 1.8.37),
# and torch 2.14's headers needing C++20 (install-linux.sh pins 2.13).

FROM ubuntu:24.04

ARG CICILI_REF=master
ARG ZIGURATIP_REF=master
ENV DEBIAN_FRONTEND=noninteractive

# UBUNTU'S OWN CLANG. 24.04's is 18, so install-linux.sh finds clang 16 or
# newer and never goes to apt.llvm.org -- whose llvm.sh wants lsb_release,
# wget and add-apt-repository, none of them in a bare image. git and the CA
# certificates are for the two clones below.
RUN apt-get update \
 && apt-get install -y --no-install-recommends clang git ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# The siblings, at the refs asked for. install-linux.sh looks for them beside
# its own checkout, finds them, and clones nothing.
RUN git clone -q https://github.com/saman-pasha/cicili.git /opt/cicili \
 && git -C /opt/cicili checkout -q "$CICILI_REF" \
 && git clone -q https://github.com/saman-pasha/ZiguratIP.git /opt/ZiguratIP \
 && git -C /opt/ZiguratIP checkout -q "$ZIGURATIP_REF"

# This checkout as it stands; .dockerignore leaves the host's build output
# behind, so nothing compiled for the host is found up to date in here.
COPY . /opt/cocolog
WORKDIR /opt/cocolog

# THE OPTIONS ARE DECLARED HERE AND NOT AT THE TOP, because every RUN after an
# ARG sees it, and a new value is a cache miss for each of them: declared
# above the clones, any change of option fetched clang and both siblings
# again. Here every variant of the image shares everything up to the install.
ARG WITH_NUMPY=0
ARG WITH_OPENCV=0
ARG WITH_RAY=0
ARG WITH_TORCH=0
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu

# Packages, the Lisp side, ZiguratIP with its artifacts checked by name,
# make, make schema, make modules, and a query the binary must answer.
#
# THE DOWNLOADED PACKAGES ARE KEPT IN A BUILD CACHE, because this step runs
# again whenever the checkout changes and its packages are most of its time:
# twenty-one of its twenty-seven minutes on the connection the first build
# ran over, two of eight with the cache warm. Ubuntu's image deletes them
# after every install (docker-clean); it is set aside for this step and put
# back after, so the image behaves as the base does. PIP'S DOWNLOADS ARE KEPT
# THE SAME WAY: torch's CPU wheels took eleven minutes to fetch here once.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/root/.cache/pip \
    { mv /etc/apt/apt.conf.d/docker-clean /tmp/ 2>/dev/null || true; } \
 && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
 && WITH_NUMPY=$WITH_NUMPY WITH_OPENCV=$WITH_OPENCV WITH_RAY=$WITH_RAY WITH_TORCH=$WITH_TORCH \
    TORCH_INDEX_URL=$TORCH_INDEX_URL sh install/install-linux.sh \
 && rm /etc/apt/apt.conf.d/keep-cache \
 && { mv /tmp/docker-clean /etc/apt/apt.conf.d/ 2>/dev/null || true; } \
 && rm -rf /var/lib/apt/lists/*

# `make modules' answers 0 whether or not a module built, so every module
# this build asked for is checked by name: the ones every image has, and
# each optional one whose argument was 1. tensorflow is never built here.
RUN mods="tcp thread process text os curl bigint sha aes der x509 tls clay stream"; \
    if [ "$WITH_NUMPY" = 1 ]; then mods="$mods numpy"; fi; \
    if [ "$WITH_OPENCV" = 1 ]; then mods="$mods opencv"; fi; \
    if [ "$WITH_RAY" = 1 ]; then mods="$mods ray"; fi; \
    if [ "$WITH_TORCH" = 1 ]; then mods="$mods torch"; fi; \
    for m in $mods; do \
      [ -f "library/$m.so" ] || { echo "library/$m.so was not built: sh modules/$m/build.sh says why"; exit 1; }; \
    done; \
    echo "modules checked: $mods"

ENV CICILI=/opt/cicili \
    ZIGURATIP=/opt/ZiguratIP \
    ZIGURATIP_HOME=/opt/ZiguratIP/home \
    LD_LIBRARY_PATH=/opt/ZiguratIP/home/lib \
    PATH=/opt/cocolog:$PATH

WORKDIR /work
ENTRYPOINT ["cocolog"]
