ARG SOCKET_VERSION=1.1.152
ARG SEMGREP_VERSION=1.130.0
ARG FREEBSD_CI_BASE=ghcr.io/9-developers/images/freebsd-ci-base:15.1

FROM ${FREEBSD_CI_BASE} AS semgrep-core-builder

ARG SEMGREP_VERSION

# Build semgrep-core from source because Semgrep does not publish FreeBSD wheels.
RUN pkg update \
    && pkg install -y \
        gmake \
        gmp \
        libev \
        libffi \
        ocaml-opam \
        pcre2 \
        pkgconf \
        rsync \
        rust \
    && pkg clean -ay

RUN ln -sf /usr/local/bin/gmake /usr/local/bin/make

WORKDIR /tmp/semgrep

RUN git clone --depth 1 --branch "v${SEMGREP_VERSION}" https://github.com/semgrep/semgrep.git . \
    && git submodule update --init --recursive --depth 1

RUN perl -0pi -e 's/(   bos\n)/$1   rresult\n/' libs/commons/dune
RUN perl -0pi -e 's/(    ambient-context-lwt\n)/$1    ambient-context\n/' libs/telemetry/dune

RUN opam init --bare --yes --disable-sandboxing \
    && opam switch create semgrep ocaml-base-compiler.5.3.0 --yes \
    && eval "$(opam env)" \
    && opam pin add --yes --no-action cohttp 6.1.0 \
    && opam pin add --yes --no-action cohttp-eio 6.1.0 \
    && opam pin add --yes --no-action cohttp-lwt 6.1.0 \
    && opam pin add --yes --no-action cohttp-lwt-unix 6.1.0 \
    && opam pin add --yes --no-action ambient-context 0.1.1 \
    && opam pin add --yes --no-action ambient-context-lwt 0.1.1 \
    && gmake install-deps-for-semgrep-core \
    && gmake core \
    && install -m 0755 bin/semgrep-core /usr/local/bin/semgrep-core \
    && semgrep-core -version

FROM ${FREEBSD_CI_BASE} AS semgrep-python-builder

ARG SEMGREP_VERSION

RUN pkg update \
    && pkg install -y \
        python \
        py312-pipx \
        rust \
    && pkg clean -ay

ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin

RUN pipx install "semgrep==${SEMGREP_VERSION}" \
    && pipx runpip semgrep install "setuptools<81"

FROM ${FREEBSD_CI_BASE}

ARG SOCKET_VERSION
ARG SEMGREP_VERSION

# Install FreeBSD packages
RUN pkg update \
    && pkg install -y \
        node26 \
        npm-node26 \
        gmp \
        libev \
        pcre \
        python \
        trivy \
    && pkg clean -ay

ENV LD_LIBRARY_PATH=/usr/local/lib

COPY --from=semgrep-core-builder /usr/local/bin/semgrep-core /usr/local/bin/semgrep-core
COPY --from=semgrep-core-builder /tmp/semgrep/libs/ocaml-tree-sitter-core/tree-sitter/lib/libtree-sitter.so.0.22 /usr/local/lib/libtree-sitter.so.0.22
COPY --from=semgrep-python-builder /opt/pipx /opt/pipx
COPY --from=semgrep-python-builder /usr/local/bin/semgrep /usr/local/bin/semgrep
COPY --from=semgrep-python-builder /usr/local/bin/pysemgrep /usr/local/bin/pysemgrep

# Install NPM packages
RUN npm install --global "socket@${SOCKET_VERSION}"

# Verify package installation
RUN bash --version \
    && git --version \
    && node --version \
    && npm --version \
    && socket --version \
    && semgrep --version \
    && trivy --version

WORKDIR /workspace

CMD ["bash"]
