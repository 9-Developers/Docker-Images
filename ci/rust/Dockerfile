ARG FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1

FROM ${FREEBSD_CI_BASE} AS windows-toolchain

ARG CROSS_BUILD_JOBS=6
RUN pkg update \
    && pkg install -y llvm21 cmake-core ninja gmake autoconf automake libtool pkgconf \
    && pkg clean -ay
COPY ci/cross/build-windows.sh /tmp/build-windows.sh
RUN sh /tmp/build-windows.sh

FROM ${FREEBSD_CI_BASE}

ARG CARGO_ZIGBUILD_VERSION=0.24.1
ENV HOME=/root
ENV PATH=/root/.cargo/bin:${PATH}

# Install FreeBSD packages
RUN pkg update \
    && pkg install -y rustup-init zig llvm21 \
    && pkg clean -ay

COPY --from=windows-toolchain /opt/llvm-mingw /opt/llvm-mingw

# Target-specific settings keep native FreeBSD builds on their native toolchain.
ENV CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_LINKER=/opt/llvm-mingw/bin/x86_64-w64-mingw32-clang \
    CARGO_TARGET_AARCH64_PC_WINDOWS_GNULLVM_LINKER=/opt/llvm-mingw/bin/aarch64-w64-mingw32-clang \
    CC_x86_64_pc_windows_gnullvm=/opt/llvm-mingw/bin/x86_64-w64-mingw32-clang \
    CC_aarch64_pc_windows_gnullvm=/opt/llvm-mingw/bin/aarch64-w64-mingw32-clang \
    CXX_x86_64_pc_windows_gnullvm=/opt/llvm-mingw/bin/x86_64-w64-mingw32-clang++ \
    CXX_aarch64_pc_windows_gnullvm=/opt/llvm-mingw/bin/aarch64-w64-mingw32-clang++ \
    AR_x86_64_pc_windows_gnullvm=/opt/llvm-mingw/bin/llvm-ar \
    AR_aarch64_pc_windows_gnullvm=/opt/llvm-mingw/bin/llvm-ar

# Initialize rustup
RUN rustup-init -y \
    && cargo install --locked --version "${CARGO_ZIGBUILD_VERSION}" cargo-zigbuild \
    && rustup target add \
        x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu \
        x86_64-unknown-linux-musl aarch64-unknown-linux-musl \
        x86_64-pc-windows-gnullvm aarch64-pc-windows-gnullvm

COPY ci/cross/smoke/rust /tmp/cross-smoke/rust
COPY ci/cross/smoke-rust.sh /tmp/cross-smoke/run.sh
RUN sh /tmp/cross-smoke/run.sh \
    && rm -rf /tmp/cross-smoke /root/.cache/zig /root/.cache/cargo-zigbuild

# Verify package installation
RUN bash --version \
    && git --version \
    && cargo --version \
    && rustc --version

RUN pkg query '%n-%v' | sort > /usr/local/share/ci-packages.txt
RUN { rustc --version; cargo install --list; zig version; cat /opt/llvm-mingw/share/ci-toolchain.txt; } \
    > /usr/local/share/ci-cross-toolchains.txt

WORKDIR /workspace

CMD ["bash"]
