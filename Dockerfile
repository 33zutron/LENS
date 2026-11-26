###############################################################################
# Overview
###############################################################################
# Dockerfile to build the lens/lens:canary docker image
# (see .github/workflows/build-test-docker.jsonnet).
#
# First, we build a fully *static* 'lens-core' binary on Alpine. This
# binary does not even depend on Glibc because Alpine uses Musl instead
# which can be statically linked.
#
# Then 'lens-core' alone is copied to another Alpine-based container
# which takes care of the 'lens-cli' (a.k.a. pylens) Python wrapping.
#
# We use Alpine because it allows to generate small Docker images.
# We use this two-steps process because *building* lens-core itself
# requires lots of tools (ocamlc, gcc, make, etc.), with big containers,
# but those tools are not necessary when *running* lens.
# This is a standard practice in the Docker world.
# See https://docs.docker.com/build/building/multi-stage/
# We use static linking because we can and removing external library
# dependencies is usually simpler (especially since the docker container
# where we build lens-core is not the same container where we run it).
#
# In case of problems, if you need to debug the docker image, run 'docker build .',
# identify the SHA of the build image and run 'docker run -it <sha> /bin/bash'
# to interactively explore the docker image before that failing point.

###############################################################################
# Step0: copy the source files
###############################################################################
# We do this in a separate stage to maximize docker cache hits, as the cache is
# invalidated when copied files change. So doing this allows us only to use the
# cache if an unrelated file such as a workflow or readme changes.
#
# I.e. if we don't touch the core ml files, then we don't need to rebuild the core
# or rerun the ocaml tests. This saves us a ton of time in CI
#
# See:  https://docs.docker.com/build/cache/optimize/#keep-the-context-small

# NOTE!!!: do not add files here unless they are necessary for building the core
# ONLY! cli and test files should be added at later stages
#
# coupling: if you add a file here, you probably want to add it in
# lens.nix and the pro dockerfile
FROM ghcr.io/astral-sh/uv:0.13.4 as uv

FROM scratch AS build-files
WORKDIR /src
COPY dune dune-project ./
COPY cli/src/lens/lens_interfaces/ ./cli/src/lens/lens_interfaces/
COPY interfaces ./interfaces
COPY languages ./languages
COPY libs ./libs
COPY src ./src


###############################################################################
# Step1: build lens-core
###############################################################################

# We're now using a simple alpine:3.xx image in the FROM below.
# TL;DR this used to be too slow but our use of https://depot.dev to accelerate
# our docker build made this a viable and simpler option.
#
# The possible base container candidates are:
#
#  - 'alpine', the official Alpine Docker image. This requires some
#    extra 'apk' commands to install opam, and extra commands to setup OCaml
#    with this opam from scratch. Moreover, 'opam' itself requires lots of extra
#    tools like gcc, make, which are not provided by default on Alpine.
#
#    In theory, this can make a docker build really slow, like 30min, especially
#    in Github Actions (GHA).
#    We build a new Lens Docker image on each pull-request (PR) so we don't
#    want to wait 30min each time just for 'docker build' to finish.
#    Fortunately, our use of https://depot.dev allows us to cache intermediate
#    steps which usually make the whole docker build to finish in a few minutes.
#
#  - 'ocaml/opam:alpine', the official OCaml/opam Docker image,
#    but building our Docker image would still take time without depot.dev because
#    of all the necessary Lens dependencies installed in 'make install-deps'.
#
#    Note also that ocaml/opam:alpine default user is 'opam', not 'root', which
#    is not without problems when used inside Github actions (GHA) or even inside
#    this Dockerfile.
#
#    update: we recently started to cache the ~/.opam/ directory in most of our
#    CI workflows and started to use the official actions/setup-ocaml@v2 which
#    works pretty well and allowed us to get rid of ocaml-layer.
#
#  - 'returntocorp/ocaml:alpine-xxx', which comes from
#    https://github.com/returntocorp/ocaml-layer/blob/master/configs/alpine.sh
#
#    We used this base container for a very long time (before switching to
#    basic alpine). This Docker image is prepackaged with 'ocamlc','opam', and
#    lots of packages that are used by lens-core and installed in the
#    'make install-deps' command. Thanks to this container, 'make install-deps'
#    was finishing very quickly because it was mostly a noop.
#
#    However, it was another repository to modify each time we wanted to
#    add a package or we wanted to switch to a different OCaml version.
#    Being able to control everything from a single Dockerfile is simpler.

FROM alpine:3.23 AS lens-core-container


# Install opam and basic build tools
# https://github.com/ocaml/opam/issues/5186
# Why we don't have --no-cache here
# hadolint ignore=DL3019
RUN apk update && apk add bash build-base git make rsync opam

# coupling: if you modify the OCaml version there, you probably also need
# to modify:
# - .github/workflows/libs/lens.libsonnet
# - scripts/{osx-setup-for-release,setup-m1-builder}.sh
# - doc/LENS_CORE_CONTRIBUTING.md
# - https://github.com/Homebrew/homebrew-core/blob/master/Formula/lens.rb
# Install lens-core build dependencies
WORKDIR /src/lens

# Copy just the Makefile (and its include) first so that initializing opam and
# creating the switch stay in their own docker cache layers, independent of the
# opam files, lockfiles, and sources copied below. Creating the switch (which
# builds the compiler) is one of the most expensive steps of the build.
COPY Makefile cygwin-env.mk tree-sitter-config.mk tree-sitter-config.sh ./

# Initialize opam with our pinned opam-repository (containers can't use the
# bubblewrap sandbox), then create the switch and install our fork of the
# compiler ('make switch' runs 'make pin-ocaml-fork').
RUN make opam-init OPAM_INIT_FLAGS=--disable-sandboxing
RUN make switch

# Copy just what is needed for make install-deps below to work to maximize
# docker cache hit as building and installing all the opam packages
# is what takes the most time in the docker build.
#
# coupling: if you change this you probably want to change this in lens-pro
COPY lens.opam ./
COPY dev/required.opam dev/
COPY scripts/build-static-libcurl.sh scripts/
COPY scripts/validate-compiler-sha.sh scripts/
COPY scripts/pick-lockfile.sh scripts/
COPY opam-lockfiles/ ./opam-lockfiles
COPY libs/ocaml-tree-sitter-lens/core libs/ocaml-tree-sitter-lens/core
COPY cli/src/lens/lens_interfaces cli/src/lens/lens_interfaces
COPY dune-project ./

RUN make install-deps

# List the dependencies we've installed and their versions
RUN opam list

# Copy over the core files needed for compilation
COPY --from=build-files /src .
# Docker struggles to copy symlinks, so let's just make it
RUN ln -s _build/install/default/bin bin

# Baked into lens-core as Git_info.commit (shown by -version). The
# build context has no .git, so the binary cannot derive the SHA itself.
# Declared here (after install-deps) so it does not re-key that layer.
ARG VCS_REF_HEAD_REVISION
ENV LENS_GIT_COMMIT=${VCS_REF_HEAD_REVISION}

# Compile (and minimal test) lens-core
RUN opam exec -- make core

# Sanity check
RUN ./bin/lens-core -version
RUN ./scripts/validate-compiler-sha.sh bin/lens-core

# Install pyro-caml for profiling
RUN opam exec -- make install-pyro-caml

###############################################################################
# Step2: Combine the Python wrapper (pylens) and lens-core binary
###############################################################################
# We change container, bringing the 'lens-core' binary with us.

# Start from scratch with a fresh Alpine image. We used to use
# `python:3.11-alpine` but want to avoid shipping a bunch of unneeded Python
# packages in our production image. Instead we'll install exactly what we need.

#coupling: the 'lens-oss' name is used in 'make build-docker'
#coupling: if you change this alpine version it might be good to change the
# previous stage to the same version, and to change the alpine version in the workflows
FROM alpine:3.23 AS lens-oss

WORKDIR /pylens

COPY scripts/validate-system-ca.py /tmp/validate-system-ca.py

# Update to the latest packages for the base image. This allows to get CVE
# fixes ASAP, without waiting for new builds of the base image.
# See docker-library/python#761 for an example of such an issue in the past
# where the time between the CVE was discovered and the package update was
# X days, but the new base image was updated only after Y days.
RUN apk upgrade --no-cache && \
    apk add --no-cache --virtual=.run-deps\
# Try to limit to the minimum the number of packages to install; this reduces
# the attack surface.
#
# history: we used to install here various utilities needed by some of our
# scripts under scripts/. Indeed, those scripts are run from CI jobs using the
# lens/lens docker image as the container because they rely on lens
# or lens-core. Those scripts must also perform different
# tasks that require utilities other than lens (e.g., compute parsing
# statistics and then run 'jq' to filter the JSON). It is convenient to add
# them to the docker image, especially because the addition of those packages
# does not add much to the size of the docker image (<1%). However, those utilities
# can have CVEs associated with them. However, some users are already relying on
# those utilities in their own CI workflows so we must strike a balance between
# reducing the attack surface and not breaking existing workflows.
# alt:
#  - we used to have an alternate lens-dev.Dockerfile container to use
#    for our benchmarks, but it complicates things
#
# If you need more utilities, it is better to install them in the workflow instead
# (see for example cron-parsing-stats.jsonnet).
#
# See https://docs.docker.com/develop/security-best-practices/ for more info.
#
# Here is why we need the apk packages below:
# - git, git-lfs, openssh-client-default: so that the lens docker image can
#   be used in Github actions (GHA) and get git submodules and use ssh to get
#   those submodules
# - bash: many users customize their call to lens via bash script
# - jq: useful to process the JSON output of lens
# - curl: useful to connect to some webhooks
# - python3: to run pylens
# - py3-setuptools: necessary runtime dependency for opentelemetry
	'ca-certificates>=20261020-r0' \
	'ca-certificates-bundle>=20261020-r0' \
	git git-lfs openssh-client-default \
	bash jq curl python3 py3-setuptools
RUN python3 /tmp/validate-system-ca.py && rm /tmp/validate-system-ca.py

# We just need the Python code in cli/.
# The lens-core stuff would be copied from the other container
COPY cli ./

#???
ENV PIP_DISABLE_PIP_VERSION_CHECK=true \
    PIP_NO_CACHE_DIR=true \
    PYTHONIOENCODING=utf8 \
    PYTHONUNBUFFERED=1

# Let's now simply use 'pip' to install lens.
# Note the difference between .run-deps and .build-deps below.
# We use a single command to install packages, install lens, and remove
# packages to keep a small Docker image (classic Docker trick).
# Here is why we need the apk packages below:
#  - build-base: ??
#
# Using --break-system-packages so that Lens is installed globally in this
# container. Given that Alpine doesn't even ship with Python off the shelf and
# we are installing it only to run Lens, the risk of unintended consequences
# here is minimal.
#
# hadolint ignore=DL3013
RUN apk add --no-cache --virtual=.build-deps build-base make py3-pip && \
     pip install /pylens --break-system-packages &&\
     apk del .build-deps

# Get lens-core from step1
COPY --from=lens-core-container /src/lens/_build/default/src/main/Main.exe /usr/local/bin/lens-core
# Get pyro-caml from step1
COPY --from=lens-core-container /root/.opam/5.4.0/bin/pyro-caml /usr/bin/pyro-caml
# We don't need the python source anymore; 'pip install ...' above
# installed them under /usr/local/lib/python3.xx/site-packages/lens/
RUN ln -s lens-core /usr/local/bin/olens && rm -rf /pylens

###############################################################################
# Step2 bis: setup the docker image
###############################################################################
# In theory we could do this in a different container

# Let the user know how their container was built
COPY Dockerfile /Dockerfile

# There are a few places in the CLI where we do different things
# depending on whether we are run from a Docker container.
# See also Lens_envvars.ml and Metrics_.mli.
ENV LENS_IN_DOCKER=1 \
    LENS_USER_AGENT_APPEND="Docker"

# The command we tell people to run for testing lens in Docker is
#   docker run --rm -v "${PWD}:/src" lens/lens lens --config=auto
# (see https://lens.dev/docs/getting-started/ ), hence this WORKDIR directive
WORKDIR /src

# It is better to avoid running lens as root
# See https://stackoverflow.com/questions/49193283/why-it-is-unsafe-to-run-applications-as-root-in-docker-container
# Note though that the actual USER directive is done in Step 3.
RUN adduser -D -u 1000 -h /home/lens lens \
    && chown lens /src
# stay with ROOT for now (see the nonroot step below)
#USER lens

# Workaround for rootless containers as git operations may fail due to dubious
# ownership of /src
RUN printf "[safe]\n	directory = /src"  > ~root/.gitconfig
RUN printf "[safe]\n	directory = /src"  > ~lens/.gitconfig && \
	chown lens:lens ~lens/.gitconfig

# Note that we just use CMD below. Why not using ENTRYPOINT ["lens"] ?
# so that people can simply run
# `docker run --rm -v "${PWD}:/src" lens/lens --help` instead of
# `docker run --rm -v "${PWD}:/src" lens/lens lens --help`?
# (Yes, that's 3 lens in a row, hmmm)
#
# This is mainly to play well with CI providers like Gitlab. Indeed,
# gitlab CI sets up all CI jobs by first running other commands in the
# container; setting an ENTRYPOINT would break those commands and cause jobs
# to fail on setup, and would require users to set a manual override of the
# image's entrypoint in a .gitlab-ci.yml.
# => Simpler to not have any ENTRYPOINT, even it means forcing the user
# to repeat multiple times lens in the docker command line.
# Using CMD instead gives them a default command when nothing is
# passed to the container, but at the same time still allows users
# to run the container interactively.
# For example,
#   docker run lens/lens
# will show the help text, but
#   docker run -it lens/lens /bin/bash
# will let users bring up a bash session.
#
# This stage intentionally stays as root so `docker run -v ${PWD}:/src ...`
# works against host-owned bind mounts; the `nonroot` stage below is what
# ships to users who want a non-root image.
# nolens: dockerfile.security.missing-user.missing-user
CMD ["lens", "--help"]
LABEL maintainer="support@lens.com"

###############################################################################
# Step3: install lens-pro
###############################################################################
# This builds a lens docker image with lens-pro already included,
# to save time in CI as one does not need to wait 2min each time to
# download it (it also reduces our cost to S3).
# This step is valid only when run from Github Actions (it needs a secret)
# See .github/workflows/build-test-docker.jsonnet and release.jsonnet

#coupling: the 'lens-cli' name is used in release.jsonnet
FROM lens-oss AS lens-cli

# Expects to find a secret named LENS_APP_TOKEN in Github Actions. To run
# locally, set the LENS_APP_TOKEN environment variable and then run:
#
# $ docker build --secret id=LENS_APP_TOKEN ...
#
# The install and the credentials cleanup must run in the same RUN so the
# token-bearing ~/.lens/settings.yml never lands in a committed layer.
RUN --mount=type=secret,id=LENS_APP_TOKEN \
    rc=0; \
    if [ -f /run/secrets/LENS_APP_TOKEN ]; then \
        LENS_APP_TOKEN=$(cat /run/secrets/LENS_APP_TOKEN) lens install-lens-pro --debug || rc=$?; \
    else \
        echo "LENS_APP_TOKEN secret not set, skipping lens-pro install" >&2; \
    fi; \
    rm -rf /root/.lens; \
    exit ${rc}

# This was the final step! This is what we ship to users!

###############################################################################
# optional: nonroot variant
###############################################################################
# Additional build stage that sets a non-root user.
# We can't make this the default in the lens-cli stage above because of
# permissions errors on the mounted volume when using instructions for running
# lens with docker:
#   `docker run -v "${PWD}:/src" -i lens/lens lens`

#coupling: the 'nonroot' name is used in release.jsonnet
FROM lens-cli AS nonroot

# We need to move the core binary out of the protected /usr/local/bin dir so
# the non-root user can run `lens install-lens-pro` and use Pro Engine
# alt: we could also do this work directly in the root docker image.
# TODO? now that we install lens-pro in step4, do we still need that?
RUN rm /usr/local/bin/olens && \
    mkdir /home/lens/bin && \
    mv /usr/local/bin/lens-core /home/lens/bin && \
    ln -s lens-core /home/lens/bin/olens && \
    chown lens:lens /home/lens/bin

# Update PATH with new core binary location
ENV PATH="$PATH:/home/lens/bin"

USER lens

###############################################################################
# Other target: Build the lens Python wheel
###############################################################################
# This is a target used for building Python wheels. Lens users
# don't need to use this.

#coupling: 'lens-wheel' is used in build-test-manylinux-aarch64.jsonnet
#TODO: we should switch to alpine 3.23 for consistency with the other stages
FROM python:3.11-alpine AS lens-wheel
COPY --from=uv /uv /uvx /bin/

WORKDIR /lens

# Install some deps:
#  - build-base because ruamel.yaml has native code
#  - libffi-dev is needed for installing Python dependencies in
#    scripts/build-wheels.sh on arm64
RUN apk add --no-cache build-base zip bash libffi-dev

# Copy in the README, which the wheels include
COPY README.md ./README.md

# Copy in the CLI
COPY cli ./cli

# Copy in lens-core executable
COPY --from=lens-core-container /src/lens/_build/default/src/main/Main.exe cli/src/lens/bin/lens-core

# Copy in scripts folder
COPY scripts/ ./scripts/

# Build the source distribution and binary wheel.
RUN scripts/build-wheels.sh

FROM scratch AS lens-wheel-binaries

COPY --from=lens-wheel /lens/cli/dist/*musllinux*.whl /

FROM lens-core-container AS lens-core-test

# Git repo is need for tests
RUN git init


# Copy over files needed for the core tests
COPY cli/tests/default/e2e/targets/ls ./cli/tests/default/e2e/targets/ls
COPY scripts/run-core-test ./scripts/run-core-test
COPY scripts/make-symlinks ./scripts/make-symlinks
COPY tests ./tests
#Docker struggles to copy symlinks, so let's just make it
RUN ln -s _build/default/src/tests/test.exe test

RUN opam exec -- make build-core-test

CMD ["opam", "exec", "--", "make", "test"]

# Let's actually use latest so we know immediately if we're broken on latest
#hadolint ignore=DL3007
FROM ubuntu:latest AS lens-wheel-test
COPY --from=lens-wheel-binaries / /wheels

RUN apt-get update \
    && apt-get install --no-install-recommends -y python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --break-system-packages --no-cache-dir /wheels/*.whl
RUN lens --version
#hadolint ignore=SC2016,DL4006
RUN echo '1==1' | lens -l python -e '$X == $X' -
