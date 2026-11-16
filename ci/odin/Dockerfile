ARG FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1

FROM ${FREEBSD_CI_BASE} AS windows-toolchain

ARG CROSS_BUILD_JOBS=6
RUN pkg update \
    && pkg install -y llvm21 cmake-core ninja gmake autoconf automake libtool pkgconf \
    && pkg clean -ay
COPY ci/cross/build-windows.sh /tmp/build-windows.sh
RUN sh /tmp/build-windows.sh

FROM ${FREEBSD_CI_BASE}

ENV HOME=/root

# Install FreeBSD packages
RUN pkg update \
    && pkg install -y odin-lang zig llvm21 \
    && pkg clean -ay

COPY --from=windows-toolchain /opt/llvm-mingw /opt/llvm-mingw
COPY ci/cross/odin-msvc-compat.c /usr/local/share/ci-cross/odin-msvc-compat.c
COPY ci/cross/odin-cross-link /usr/local/bin/odin-cross-link
RUN chmod 755 /usr/local/bin/odin-cross-link

COPY ci/cross/smoke/hello.odin /tmp/cross-smoke/hello.odin
COPY ci/cross/smoke-odin.sh /tmp/cross-smoke/run.sh
RUN sh /tmp/cross-smoke/run.sh \
    && rm -rf /tmp/cross-smoke /root/.cache/zig

# Verify package installation
RUN bash --version \
    && git --version \
    && odin version

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt
RUN { odin version; zig version; cat /opt/llvm-mingw/share/ci-toolchain.txt; } \
    > /usr/local/share/ci-cross-toolchains.txt

WORKDIR /workspace

CMD ["bash"]
