#!/bin/sh
# Install as /usr/local/bin/ci-skopeo on the FreeBSD runner host.
# doas.conf must preserve REGISTRY_AUTH_FILE for the Skopeo command.
set -eu
exec /usr/local/bin/doas -n /usr/local/bin/skopeo "$@"
