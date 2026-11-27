#!/bin/sh
set -eu

version=$1
prefix=/opt/freebsd-arm64
mkdir -p "$prefix/bin"
if [ "$(uname -p)" = aarch64 ]; then
	# The target is native here, including any installed ports.
	ln -s /usr/bin/cc "$prefix/bin/clang"
	ln -s /usr/bin/c++ "$prefix/bin/clang++"
	exit 0
fi

case "$version" in
15.1) checksum=5b7a46a0abfbe23a1d4454b5600e2efcfce16b705bc7e9c851c37470c035ef98 ;;
*)
	echo "No pinned ARM64 FreeBSD base.txz checksum for $version" >&2
	exit 1
	;;
esac

archive=$(mktemp)
trap 'rm -f "$archive"' EXIT
fetch -o "$archive" "https://download.freebsd.org/releases/arm64/aarch64/$version-RELEASE/base.txz"
sha256 -c "$checksum" "$archive"
sysroot=$prefix/sysroot
mkdir -p "$sysroot"
tar -xf "$archive" -C "$sysroot" ./lib ./usr/lib ./usr/include ./libexec/ld-elf.so.1

for driver in clang clang++; do
	cat >"$prefix/bin/$driver" <<EOF
#!/bin/sh
exec /usr/local/llvm21/bin/$driver --target=aarch64-unknown-freebsd$version --sysroot=$sysroot \\
    --start-no-unused-arguments -fuse-ld=lld --end-no-unused-arguments "\$@"
EOF
	chmod 755 "$prefix/bin/$driver"
done
