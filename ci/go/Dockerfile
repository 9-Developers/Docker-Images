ARG FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1

FROM ${FREEBSD_CI_BASE} AS windows-toolchain

ARG CROSS_BUILD_JOBS=6
RUN pkg update \
    && pkg install -y llvm21 cmake-core ninja gmake autoconf automake libtool pkgconf \
    && pkg clean -ay
COPY ci/cross/build-windows.sh /tmp/build-windows.sh
RUN sh /tmp/build-windows.sh

FROM ${FREEBSD_CI_BASE}

RUN pkg update \
    && pkg install -y go zig llvm21 \
    && pkg clean -ay
COPY --from=windows-toolchain /opt/llvm-mingw /opt/llvm-mingw
COPY ci/cross/go-cross /usr/local/bin/go-cross
RUN chmod 755 /usr/local/bin/go-cross

COPY ci/cross/smoke/go /tmp/cross-smoke/go
COPY ci/cross/smoke-go.sh /tmp/cross-smoke/run.sh
RUN sh /tmp/cross-smoke/run.sh \
    && rm -rf /tmp/cross-smoke /root/.cache/go-build /root/.cache/zig

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt
RUN { go version; zig version; cat /opt/llvm-mingw/share/ci-toolchain.txt; } \
    > /usr/local/share/ci-cross-toolchains.txt

WORKDIR /workspace
CMD ["bash"]
