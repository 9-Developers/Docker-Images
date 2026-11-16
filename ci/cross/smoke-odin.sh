#!/bin/sh
set -eu
cd /tmp/cross-smoke
odin build hello.odin -file -out:native
./native
for target in linux-amd64 linux-arm64 windows-amd64; do
	odin_target=$(echo "$target" | tr - _)
	odin build hello.odin -file "-target:$odin_target" \
		-build-mode:obj -use-single-module "-out:$target.o"
	odin-cross-link "$target" "$target.o" "$target.bin"
	/usr/local/llvm21/bin/llvm-readobj --file-headers "$target.bin"
done
