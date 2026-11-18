#!/bin/sh
set -eu

tool=${CONTAINER_TOOL:-podman}
registry_tool=${REGISTRY_TOOL:-skopeo}
registry=${REGISTRY:-git.9dev.tech}
owner=${OWNER:-9-developers}
freebsd=${FREEBSD_VERSION:-15.1}
quarter=${PKG_QUARTER:-2026q4}
revision=${IMAGE_REVISION:-1}
release=freebsd${freebsd}-${quarter}-r${revision}
source_url=https://git.9dev.tech/9-Developers/Docker-Images

image() { printf '%s/%s/ci-%s' "$registry" "$owner" "$1"; }
version() {
	case "$1" in
	node) printf '24-%s' "$release" ;;
	openjdk) printf '25-%s' "$release" ;;
	postgres) printf '18-%s' "$release" ;;
	dotnet) printf '10-%s' "$release" ;;
	*) printf '%s' "$release" ;;
	esac
}
aliases() {
	case "$1" in
	node) echo "24 24-freebsd${freebsd}" ;;
	openjdk) echo "25 25-freebsd${freebsd}" ;;
	postgres) echo "18 18-freebsd${freebsd}" ;;
	dotnet) echo "10 10-freebsd${freebsd}" ;;
	*) echo "freebsd${freebsd}" ;;
	esac
}
validate() {
	printf '%s\n' "$quarter" | grep -Eq '^[0-9]{4}q[1-4]$'
	printf '%s\n' "$revision" | grep -Eq '^[1-9][0-9]*$'
	printf '%s\n' "$freebsd" | grep -Eq '^[0-9]+\.[0-9]+$'
	if [ "${CONFIRMED_PKG_QUARTER:-}" != "$quarter" ]; then
		echo "Verify the public quarterly package branch, then set CONFIRMED_PKG_QUARTER=$quarter" >&2
		exit 1
	fi
}

command=$1
shift
case "$command" in
check-tools)
	"$tool" info
	"$registry_tool" --version
	;;
login)
	: "${REGISTRY_USER:?REGISTRY_USER is required}"
	: "${REGISTRY_TOKEN:?REGISTRY_TOKEN is required}"
	printf '%s' "$REGISTRY_TOKEN" | "$tool" login "$registry" --username "$REGISTRY_USER" --password-stdin
	;;
build)
	validate
	name=$1
	case "$name" in
	base)
		upstream=ghcr.io/freebsd/freebsd-toolchain:$freebsd
		"$tool" pull "$upstream"
		digest=$("$tool" image inspect --format '{{index .RepoDigests 0}}' "$upstream")
		base=$digest
		context=ci/base
		;;
	node | openjdk | postgres | rust | security | odin | go | dotnet)
		base=$(image base):$release
		digest=$("$tool" image inspect --format '{{index .Labels "tech.9dev.freebsd.upstream-digest"}}' "$base")
		context=ci/$name
		case "$name" in node) context=$context/24 ;; openjdk) context=$context/25 ;; postgres) context=$context/18 ;; dotnet) context=$context/10 ;; esac
		;;
	*)
		echo "Unknown image: $name" >&2
		exit 1
		;;
	esac
	dockerfile=$(pwd)/$context/Dockerfile
	# Language images share cross-toolchain sources and smoke tests under ci/cross.
	case "$name" in rust | odin | go | dotnet) context=. ;; esac
	"$tool" build --no-cache --pull=never \
		--file "$dockerfile" \
		--build-arg "FREEBSD_BASE=$base" \
		--build-arg "FREEBSD_CI_BASE=$base" \
		--label "org.opencontainers.image.source=$source_url" \
		--label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
		--label "org.opencontainers.image.version=$(version "$name")" \
		--label "org.opencontainers.image.created=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--label "tech.9dev.freebsd.upstream-digest=${digest##*@}" \
		--label "tech.9dev.freebsd.package-quarter=$quarter" \
		--tag "$(image "$name"):$(version "$name")" "$context"
	;;
publish)
	validate
	# Check every tag before pushing; fail closed on auth/network errors.
	error=$(mktemp)
	trap 'rm -f "$error"' EXIT HUP INT TERM
	for name; do
		ref=$(image "$name"):$(version "$name")
		# Skopeo's docker transport always queries the registry, never local storage.
		if "$registry_tool" inspect --raw "docker://$ref" >/dev/null 2>"$error"; then
			echo "Release already exists: $ref (increment IMAGE_REVISION)" >&2
			exit 1
		elif ! grep -Eiq 'manifest unknown|name unknown' "$error"; then
			cat "$error" >&2
			exit 1
		fi
	done
	# Ensure the entire local release is available before the first push.
	for name; do
		"$tool" image inspect "$(image "$name"):$(version "$name")" >/dev/null
	done
	for name; do
		"$tool" push "$(image "$name"):$(version "$name")"
	done
	# Advance aliases only after all release pushes succeed.
	for name; do
		ref=$(image "$name"):$(version "$name")
		for alias in $(aliases "$name"); do
			"$tool" push "$ref" "docker://$(image "$name"):$alias"
		done
	done
	;;
*)
	echo "Unknown command: $command" >&2
	exit 1
	;;
esac
