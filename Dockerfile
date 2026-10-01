# Dockerfile -- cocolog on Ubuntu 24.04, built from source by
# install/install-linux.sh, with Cicili and ZiguratIP beside it.
#
#   docker build -t cocolog .
#   docker run --rm cocolog query 'X is 6*7, write(X), nl'
#   docker run --rm -it cocolog                          # the REPL
#   docker run --rm -v "$PWD":/work cocolog --embed KB -s program.pl
#
# The last keeps its knowledge base in ./KB on the host, through the
# embedded store: no server to start. On a Mac the image runs in Docker's
# Linux VM like any other; it is a Linux build, not a macOS one.
#
# THE INSTALL IS THE ONE install/README.md DOCUMENTS, not a copy of its
# steps -- a copy is a second place for a fact, and colab/prereqs.sh records
# what that cost once. What the Dockerfile adds is only what a bare image
# lacks before the script can run, and a check of what it built.
#
# WHAT IT DOES NOT DO: start a server, or run the suite.
#
# BUILT on 2026-10-01 under Docker Desktop 4.93.0 on an Intel Mac: 28
# minutes the first time over a slow connection, 9 with the package cache
# warm, a 3.17 GB image. Smoke-tested by --version, a query, an --embed store
# on a mounted directory that a second container read back, the REPL from a
# pipe, and the engine, gc, string, numpy and langs cases inside the image,
# GREEN -- the wire sections SKIP by name, there being no server in it. The
# first two builds found library(numpy) needing NumPy 2's headers and then
# not starting on Linux; both were fixed in 1.8.37.

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

# Packages, the Lisp side, ZiguratIP with its artifacts checked by name,
# make, make schema, make modules, and a query the binary must answer.
#
# THE DOWNLOADED PACKAGES ARE KEPT IN A BUILD CACHE, because this step runs
# again whenever the checkout changes and its packages are most of its time:
# twenty-one of its twenty-seven minutes on the connection the first build
# ran over, two of eight with the cache warm. Ubuntu's image deletes them
# after every install (docker-clean); it is set aside for this step and put
# back after, so the image behaves as the base does.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    { mv /etc/apt/apt.conf.d/docker-clean /tmp/ 2>/dev/null || true; } \
 && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache \
 && sh install/install-linux.sh \
 && rm /etc/apt/apt.conf.d/keep-cache \
 && { mv /tmp/docker-clean /etc/apt/apt.conf.d/ 2>/dev/null || true; } \
 && rm -rf /var/lib/apt/lists/*

# `make modules' answers 0 whether or not a module built, so every module
# whose dependencies the script installed is checked by name. torch,
# tensorflow and ray want libraries this image does not carry.
RUN for m in tcp thread process text os curl bigint sha aes der x509 tls clay stream numpy opencv; do \
      [ -f "library/$m.so" ] || { echo "library/$m.so was not built: sh modules/$m/build.sh says why"; exit 1; }; \
    done

ENV CICILI=/opt/cicili \
    ZIGURATIP=/opt/ZiguratIP \
    ZIGURATIP_HOME=/opt/ZiguratIP/home \
    LD_LIBRARY_PATH=/opt/ZiguratIP/home/lib \
    PATH=/opt/cocolog:$PATH

WORKDIR /work
ENTRYPOINT ["cocolog"]
