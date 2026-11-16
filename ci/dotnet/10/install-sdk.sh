#!/bin/sh
set -eu

# Update version and both hashes together. Digests are from GitHub release assets.
version=10.0.110
case "$(uname -m)" in
amd64)
	arch=x64
	checksum=c5cd785168d21d778f64cfd044140d0c30e35ef19324e34a8c94ad3f8e213101
	;;
arm64 | aarch64)
	arch=arm64
	checksum=7f95f8e1f1ebd7f8979bde9fff3471cbf1dcd23a808e93f562c23abba032977c
	;;
*)
	echo "Unsupported .NET SDK host architecture" >&2
	exit 1
	;;
esac
url=https://github.com/sec/dotnet-core-freebsd-source-build/releases/download/$version-vmr/dotnet-sdk-$version-freebsd.15-$arch.tar.gz
curl --fail --location --retry 3 "$url" -o /tmp/dotnet-sdk.tar.gz
test "$(sha256 -q /tmp/dotnet-sdk.tar.gz)" = "$checksum"
mkdir -p /opt/dotnet
tar -xzf /tmp/dotnet-sdk.tar.gz -C /opt/dotnet
rm /tmp/dotnet-sdk.tar.gz
ln -s /opt/dotnet/dotnet /usr/local/bin/dotnet
printf 'sdk=%s\nsource=%s\nsha256=%s\n' "$version" "$url" "$checksum" \
	>/usr/local/share/ci-dotnet-sdk.txt
test "$(dotnet --version)" = "$version"
