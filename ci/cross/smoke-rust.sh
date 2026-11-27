#!/bin/sh
set -eu
cd /tmp/cross-smoke/rust
cargo build
./target/debug/ci-cross-smoke
target=aarch64-unknown-freebsd
cargo build --target "$target"
header=$(/usr/local/llvm21/bin/llvm-readobj --file-headers "target/$target/debug/ci-cross-smoke")
echo "$header" | grep 'Machine: EM_AARCH64'
echo "$header" | grep 'OS/ABI: FreeBSD'
for target in x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu x86_64-unknown-linux-musl aarch64-unknown-linux-musl; do
	cargo zigbuild --target "$target"
	/usr/local/llvm21/bin/llvm-readobj --file-headers "target/$target/debug/ci-cross-smoke"
done
for target in x86_64-pc-windows-gnullvm aarch64-pc-windows-gnullvm; do
	cargo build --target "$target"
	/usr/local/llvm21/bin/llvm-readobj --file-headers "target/$target/debug/ci-cross-smoke.exe"
done
