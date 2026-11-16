#!/bin/sh
set -eu
export PATH=/opt/llvm-mingw/bin:$PATH
export CARGO_TARGET_X86_64_PC_WINDOWS_GNULLVM_LINKER=x86_64-w64-mingw32-clang
export CARGO_TARGET_AARCH64_PC_WINDOWS_GNULLVM_LINKER=aarch64-w64-mingw32-clang
export CC_x86_64_pc_windows_gnullvm=x86_64-w64-mingw32-clang
export CC_aarch64_pc_windows_gnullvm=aarch64-w64-mingw32-clang
export AR_x86_64_pc_windows_gnullvm=llvm-ar
export AR_aarch64_pc_windows_gnullvm=llvm-ar
mkdir -p /tmp/windows-smoke
cd /tmp/windows-smoke
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
for target in x86_64-pc-windows-gnullvm aarch64-pc-windows-gnullvm; do
	cargo build --target "$target"
	file "target/$target/debug/rust-smoke.exe"
	llvm-readobj --file-headers --coff-imports "target/$target/debug/rust-smoke.exe"
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
odin build hello.odin -file -target:windows_amd64 -build-mode:obj -use-single-module -out:hello.obj
# Odin emits MSVC's floating-point-use marker; MinGW does not define it.
echo 'int _fltused = 0x9875;' >odin-msvc-compat.c
x86_64-w64-mingw32-clang hello.obj odin-msvc-compat.c -o hello.exe -lkernel32 -luser32 -lshell32 -ladvapi32 -lbcrypt
file hello.exe
llvm-readobj --file-headers --coff-imports hello.exe
