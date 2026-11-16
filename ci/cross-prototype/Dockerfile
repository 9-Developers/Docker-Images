FROM git.9dev.tech/9-developers/ci-rust:freebsd15.1-2026q4-r2

RUN pkg update -f \
    && pkg install -y zig llvm21 odin-lang cmake-core ninja gmake autoconf automake libtool pkgconf \
    && pkg clean -ay

ENV PATH=/usr/local/llvm21/bin:/root/.cargo/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN cargo install --locked --version 0.24.1 cargo-zigbuild \
    && rustup target add \
        x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu \
        x86_64-unknown-linux-musl aarch64-unknown-linux-musl \
        x86_64-pc-windows-gnullvm aarch64-pc-windows-gnullvm
