#!/bin/sh
set -eu
cd /tmp/cross-smoke/dotnet
dotnet --info
# Portable managed output avoids requiring a FreeBSD apphost NuGet download.
dotnet build -c Release -p:UseAppHost=false
dotnet bin/Release/net10.0/Smoke.dll
for rid in linux-x64 linux-arm64 linux-musl-x64 linux-musl-arm64 win-x64 win-arm64; do
	out=/tmp/cross-smoke/publish/$rid
	dotnet publish -c Release -r "$rid" --self-contained true \
		-p:PublishAot=false -p:PublishReadyToRun=false -o "$out"
	test -s "$out/Smoke.dll"
	case "$rid" in
	win-*)
		test -s "$out/Smoke.exe"
		test -s "$out/coreclr.dll"
		;;
	*)
		test -s "$out/Smoke"
		test -s "$out/libcoreclr.so"
		;;
	esac
done
