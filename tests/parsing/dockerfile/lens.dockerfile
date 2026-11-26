#
# First, build a *static* 'lens-core' binary on Alpine because it comes set
# up for it (requires using musl rather than glibc).
#
# Then 'lens-core' alone is copied to a container which takes care
# of the 'lens-python' wrapping.
#

# NOTE: This is just a test file for the Dockerfile parser !
FROM returntocorp/ocaml:fake-tag as build-lens-core

USER root
# for ocaml-pcre now used in lens-core
# TODO: update root image to include python 3.9
RUN apk add --update --no-cache pcre-dev python3
RUN pip install --no-cache-dir pipenv==2022.6.7

USER user
WORKDIR /home/user

COPY --chown=user .gitmodules /lens/.gitmodules
COPY --chown=user .git/ /lens/.git/
COPY --chown=user scripts /lens/scripts

WORKDIR /lens

# Protect against dirty environment during development.
# (ideally, we should translate .gitignore to .dockerignore)
RUN git clean -dfX
RUN git submodule foreach --recursive git clean -dfX

RUN git submodule update --init --recursive --depth 1

#coupling: if you add dependencies here, you probably also need to update:
#  - scripts/install-alpine-lens-core
#  - the setup target in Makefile
RUN eval "$(opam env)" && ./scripts/install-tree-sitter-runtime
RUN eval "$(opam env)" && opam install --deps-only -y src/ocaml-tree-sitter-core
RUN eval "$(opam env)" && opam install --deps-only -y .
RUN eval "$(opam env)" && make -C  all

# Sanity checks
RUN ./_build/install/default/bin/lens-core -version

#
# We change container, bringing only the 'lens-core' binary with us.
#

FROM python:3.9.1-alpine3.13
LABEL maintainer="support@lens.com"

# ugly: circle CI requires valid git and ssh programs in the container
# when running lens on a repository containing submodules
RUN apk add --no-cache git openssh

COPY --from=build-lens-core \
     /lens/_build/install/default/bin/lens-core /usr/local/bin/lens-core
RUN lens-core -version

COPY lens /lens
RUN LENS_SKIP_BIN=true python -m pip install /lens
RUN lens --version

RUN mkdir -p /src
RUN chmod 777 /src
RUN mkdir -p /tmp/.cache
RUN chmod 777 /tmp/.cache

# Let the user know how their container was built
COPY dockerfiles/lens.Dockerfile /Dockerfile

RUN adduser -D -u 1000 lens

# The following triggers a parsing bug at the moment
# (see the 'numeric-user.dockerfile' test case)
#USER 1000

ENV LENS_IN_DOCKER=1
ENV LENS_VERSION_CACHE_PATH=/tmp/.cache/lens_version
ENV LENS_USER_AGENT_APPEND="(Docker)"
ENV PYTHONIOENCODING=utf8
ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["lens"]
CMD ["--help"]
