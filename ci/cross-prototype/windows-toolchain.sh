#!/bin/sh
set -eu
export TOOLCHAIN_ARCHS="x86_64 aarch64"
export TOOLCHAIN_TARGET_OSES=mingw32
export CORES=6
export LLVM_VERSION=llvmorg-21.1.8
export CMAKE_BUILD_PARALLEL_LEVEL=6
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
