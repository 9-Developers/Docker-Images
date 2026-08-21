# FreeBSD CI Images

OCI images used by 9 Developers CI jobs on FreeBSD. Images are built natively
on FreeBSD and published to GitHub Container Registry.

## Build

The default container tool is Podman. Build the base image followed by all
dependent images:

```sh
make build
```

The dependent images can build concurrently after the base image finishes:

```sh
make -j 4 build
```

Build a single image with, for example, `make build-node`. Run `make help` for
the complete target and configuration list.

## Publish

Create a classic GitHub personal access token with `write:packages`, then log
in without placing the token on the command line:

```sh
env GHCR_USER=USERNAME GHCR_TOKEN=TOKEN make login
make -j 4 publish
```

Every image receives an immutable `git-<commit>` tag. Runtime images also get
their runtime version tag, and all images include a tag identifying the
FreeBSD release where useful.

Override settings on the command line when needed:

```sh
make FREEBSD_VERSION=15.1 OWNER=9-developers publish
```
