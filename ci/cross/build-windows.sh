#!/bin/sh
set -eu

# This release pairs MinGW headers with LLVM 21.1.8. Update them together.
export LLVM_VERSION=llvmorg-21.1.8
export TOOLCHAIN_ARCHS="x86_64 aarch64"
export TOOLCHAIN_TARGET_OSES=mingw32
export CORES=${CROSS_BUILD_JOBS:-6}
export CMAKE_BUILD_PARALLEL_LEVEL=$CORES
export PATH=/usr/local/llvm21/bin:$PATH

test "$(llvm-config --version)" = 21.1.8
mkdir -p /tmp/windows-toolchain
cd /tmp/windows-toolchain
git clone --depth 1 --branch 20251216 https://github.com/mstorsjo/llvm-mingw.git
cd llvm-mingw
./install-wrappers.sh /opt/llvm-mingw --host-clang=/usr/local/llvm21/bin/clang
./build-mingw-w64-tools.sh /opt/llvm-mingw
./build-mingw-w64.sh /opt/llvm-mingw
./build-compiler-rt.sh /opt/llvm-mingw
./build-libcxx.sh /opt/llvm-mingw --disable-shared
./build-mingw-w64-libraries.sh /opt/llvm-mingw
mkdir -p /opt/llvm-mingw/share
printf 'llvm-mingw=20251216\nllvm=21.1.8\n' >/opt/llvm-mingw/share/ci-toolchain.txt
