#!/bin/sh
# Install as /usr/local/bin/ci-podman on the FreeBSD runner host.
# doas.conf must preserve REGISTRY_AUTH_FILE for the Podman command.
set -eu
exec /usr/local/bin/doas -n /usr/local/bin/podman "$@"
