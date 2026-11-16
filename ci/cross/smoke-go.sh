#!/bin/sh
set -eu
cd /tmp/cross-smoke/go
go version
go build -o /tmp/cross-smoke/native-pure ./pure
/tmp/cross-smoke/native-pure
CGO_ENABLED=1 go build -o /tmp/cross-smoke/native-cgo ./cgo
/tmp/cross-smoke/native-cgo
for os in freebsd linux windows; do
	for arch in amd64 arm64; do
		GOOS=$os GOARCH=$arch CGO_ENABLED=0 go build \
			-o "/tmp/cross-smoke/pure-$os-$arch" ./pure
	done
done
for target in linux-amd64-gnu linux-arm64-gnu linux-amd64-musl linux-arm64-musl windows-amd64 windows-arm64; do
	go-cross "$target" build -o "/tmp/cross-smoke/cgo-$target" ./cgo
	test -s "/tmp/cross-smoke/cgo-$target"
done
