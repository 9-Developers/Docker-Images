#!/bin/sh
set -eu
mkdir -p /tmp/cross-smoke
cd /tmp/cross-smoke
cargo new --bin rust-smoke
cd rust-smoke
cat >>Cargo.toml <<'EOF'

[build-dependencies]
cc = "=1.11.2"
EOF
cat >build.rs <<'EOF'
fn main() {
    cc::Build::new().file("answer.c").compile("answer");
    println!("cargo:rerun-if-changed=answer.c");
}
EOF
echo 'int answer(void) { return 42; }' >answer.c
cat >src/main.rs <<'EOF'
unsafe extern "C" { fn answer() -> i32; }
fn main() {
    assert_eq!(unsafe { answer() }, 42);
    let handle = std::thread::spawn(|| String::from("cross compilation works"));
    println!("{}", handle.join().unwrap());
}
EOF
for target in x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu x86_64-unknown-linux-musl aarch64-unknown-linux-musl; do
	cargo zigbuild --target "$target"
	file "target/$target/debug/rust-smoke"
	llvm-readelf -h -l "target/$target/debug/rust-smoke"
done
cd ..
cat >hello.odin <<'EOF'
package main
import "core:fmt"
main :: proc() {
    values := make([]int, 3)
    defer delete(values)
    values[0] = 42
    fmt.println("cross compilation works", values[0])
}
EOF
for arch in amd64 arm64; do
	case "$arch" in amd64) zig_arch=x86_64 ;; arm64) zig_arch=aarch64 ;; esac
	odin build hello.odin -file "-target:linux_$arch" -build-mode:obj -use-single-module "-out:hello-$arch.o"
	zig cc -target "$zig_arch-linux-gnu" "hello-$arch.o" -o "hello-$arch" -lm -lpthread -ldl
	file "hello-$arch"
	llvm-readelf -h -l "hello-$arch"
done
