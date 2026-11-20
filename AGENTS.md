# Repository guidance

## Build and verification

- Exception to the FreeBSD release guidance below: `ci-railway` is a Linux
  Bookworm image built directly from the official Node image via Linuxulator.
  Use `build-railway` / `push-railway` or the single-image workflow. It has
  independent `BOOKWORM_*` release settings and is outside the aggregate targets.

- These are native FreeBSD OCI images: builds require a FreeBSD host with rootful Podman, not a Linux container VM on macOS. Use GNU make (`gmake`) from the repository root.
- `Makefile` is the release-settings source of truth; invoking `sh ci/images.sh` directly uses different revision defaults. Prefer make targets.
- Before building, verify the public FreeBSD quarterly package branch and set `CONFIRMED_PKG_QUARTER` to match `PKG_QUARTER`. The public `quarterly` URL rolls forward; this variable is an operator attestation, not a provenance check.
- Run `gmake check-tools`, then `gmake build-NAME` for a focused build (e.g. `gmake build-go`); it rebuilds base first. `gmake -j 4 build` builds all images. Builds deliberately disable caching and refresh the upstream base.
- Unprivileged FreeBSD runners use `CONTAINER_TOOL=/usr/local/bin/ci-podman` and `REGISTRY_TOOL=/usr/local/bin/ci-skopeo`. See “Rootful Podman through doas” below; all container operations must share the same rootful storage/auth.
- Verification lives in Dockerfile `RUN` steps, including `ci/cross/smoke-*.sh` for Rust/Odin/Go/.NET. Those scripts expect fixtures at `/tmp/cross-smoke` inside the build, not the checkout. Cross-target compilation does not prove runtime support; Go and .NET additionally execute native smoke programs.
- There is no standalone test/lint target. For shell-only edits, `sh -n path/to/script` is a portable syntax check; full verification requires the affected FreeBSD image build.

### Validation scope and outstanding checks

- The existing documentation records Go/.NET image builds as still needing validation on the FreeBSD runner. Do not treat the presence of smoke scripts as evidence of a successful runner build.
- Rust smoke builds exercise C calls and threads; Odin exercises allocation, printing, and floating-point arithmetic. Go checks goroutines and cgo allocation/C calls. .NET publishes all six Linux/Linux-musl/Windows x64/ARM64 combinations and runs native tasks, cryptography, and ICU checks.
- Linux x64 prototypes ran under FreeBSD's Linux compatibility layer; Windows and ARM64 runtime validation remains pending in the recorded investigation. Odin Windows uses an MSVC compatibility marker and needs application-specific runtime/native-dependency validation.

## Shared implementation

- `ci/images.sh` handles build contexts, tags, labels, and publishing. Rust, Odin, Go, and .NET use the repository root as build context to copy `ci/cross`; other images use their Dockerfile directory. Preserve this distinction in direct builds.
- `ci/cross/build-windows.sh` is shared by Rust/Odin/Go builder stages. Update LLVM-MinGW and LLVM runtime sources together; the script checks an exact LLVM version and installed wrappers depend on `/usr/local/llvm21`.
- Update the .NET SDK version and both architecture hashes together in `ci/dotnet/10/install-sdk.sh`.
- `ci/cross-prototype` is investigation material, excluded from the root build context and production make targets. Production helpers and smoke fixtures live in `ci/cross`.

## Publishing and CI

- `gmake publish` rebuilds everything; `gmake publish-existing` publishes local images with the current release settings. `gmake push-NAME` builds and publishes that image. Login requires `REGISTRY_USER` and `REGISTRY_TOKEN`.
- Release tags are immutable. The publisher checks all requested remote tags and local images before pushing, then advances aliases only after release pushes succeed. A partial publication requires a new `IMAGE_REVISION`; do not publish concurrently.
- `.forgejo/workflows/publish.yml` runs on a FreeBSD host, serializes publication, and verifies pushed Git tags against `gmake help`'s release value. Keep shell-based steps: JavaScript actions can assume unsupported platform-specific Node binaries.
- `.forgejo/workflows/publish-one.yml` shares the full publisher's concurrency group. Select a single image to publish a missing release tag without bumping the shared revision. Keep its image choices in sync with `IMAGES` in the Makefile.

## Releases and quarterly packages

Read current release values from `Makefile` or `gmake help`. Examples below use
placeholders rather than tracking published revisions. Available published tags
are listed at https://git.9dev.tech/9-Developers/Docker-Images/packages.

| Image | Release tag pattern | Moving aliases |
| --- | --- | --- |
| ci-node | `24-freebsd<version>-<quarter>-r<revision>` | `24`, `24-freebsd<version>` |
| ci-openjdk | `25-freebsd<version>-<quarter>-r<revision>` | `25`, `25-freebsd<version>` |
| ci-postgres | `18-freebsd<version>-<quarter>-r<revision>` | `18`, `18-freebsd<version>` |
| ci-dotnet | `10-freebsd<version>-<quarter>-r<revision>` | `10`, `10-freebsd<version>` |
| ci-base, ci-go, ci-rust, ci-security, ci-odin | `freebsd<version>-<quarter>-r<revision>` | `freebsd<version>` |

- Increment the revision for each rebuild in a quarter; pin consuming CI jobs to full release tags or digests.
- Verify the branch served for your ABI at https://pkg-status.freebsd.org/, rather than inferring it from the date. After rollover, update the quarter and reset the revision to 1. Rebuilding old quarters requires retained packages.
- The upstream OS image is independently selected from `ghcr.io/freebsd/freebsd-toolchain` by FreeBSD release, refreshed, and resolved to a digest. The base explicitly configures public quarterly packages and upgrades inherited packages before installing more.
- OCI labels record source commit, release, creation time, package quarter, and upstream base digest. `/usr/local/share/ci-packages.txt` records installed FreeBSD packages. npm, rustup, and source-built tools have independent versions; public packages can change during builds, so these are not bit-for-bit reproducible snapshots.

## Toolchain maintenance

- The .NET installer selects a FreeBSD 15 x64 or ARM64 SDK archive for the build host and verifies its SHA-256 digest. Publication uses a single host, not a multi-architecture manifest. The SDK lives under `/opt/dotnet`; `/usr/local/share/ci-dotnet-sdk.txt` records its version, URL, and checksum. The Dockerfile selects ports OpenSSL ABI `.17`.
- The Windows builder pairs LLVM-MinGW `20251216` with LLVM `21.1.8`; newer MinGW headers failed against LLVM 21's unwinder during investigation. `CROSS_BUILD_JOBS` defaults to 6.
- Rust installs cargo-zigbuild `0.24.1`; Zig and LLVM come from quarterly packages. `/usr/local/share/ci-cross-toolchains.txt` records installed versions.
- Only the installed Windows toolchain is copied from builder stages, excluding source trees and build dependencies. Rust, Odin, and Go still need LLVM at runtime for the wrappers.

For a direct Rust build from the repository root, use the base tag matching
your release settings:

```sh
ci-podman build -f ci/rust/Dockerfile \
  --build-arg 'FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:<base-release-tag>' \
  -t localhost/ci-rust:cross-test .
```

## Local release builds

The host needs Git, GNU make, native rootful Podman configured for FreeBSD
containers, and Skopeo for remote-only release-tag checks. After installing the
wrappers below and verifying the quarterly branch:

```sh
export CONTAINER_TOOL=/usr/local/bin/ci-podman
export REGISTRY_TOOL=/usr/local/bin/ci-skopeo
export CONFIRMED_PKG_QUARTER='<verified-quarter>'
gmake check-tools
gmake -j 4 build
# Or build one image, including its base:
gmake build-node
```

`gmake help` lists targets. Override release settings through make, for example
`gmake IMAGE_REVISION=<next-revision> publish` (replace the placeholder). Login reads `REGISTRY_USER` and `REGISTRY_TOKEN`
from the environment and sends the token through stdin; the account needs package
write access to `9-Developers`.

To publish images already built in the same host's Podman storage:

```sh
# Keep the same tool and release settings as the original build.
# REGISTRY_USER and REGISTRY_TOKEN must be set in your environment.
export REGISTRY_AUTH_FILE="$(mktemp -d)/auth.json"
gmake login
gmake publish-existing
rm -f "$REGISTRY_AUTH_FILE"
rmdir "$(dirname "$REGISTRY_AUTH_FILE")"
```

Use `gmake -j 4 publish` instead of `publish-existing` to build and publish a fresh
release. Retrying a partially published release requires a new revision.

## Forgejo Actions setup

1. Enable Actions and register the Kirrahe runner at the Docker-Images repository scope. Configure this mapping-style runner label:

   ```yaml
   labels:
     freebsd-image-publish:
       backend: host
   ```

2. Give the runner account access to Git, GNU make, standard shell utilities, and the privileged container wrappers below. Builds execute directly on that FreeBSD host.
3. Set repository secrets `REGISTRY_USER` and `REGISTRY_TOKEN` for an account with package write access to `9-Developers`.
4. After checking public package status, set the Actions variable `CONFIRMED_PKG_QUARTER` to match the Makefile. Recheck before each release.
5. Commit release settings to `main` and invoke **Publish FreeBSD CI images** manually from `main`, or push the matching tag for a commit on `main`:

   ```sh
   release=$(gmake help | sed -n 's/^Release: //p')
   git tag "$release"
   git push origin "$release"
   ```

The workflow checks tool access, builds base before dependent images, and removes
its temporary registry authentication file at the end of the job.

## Rootful Podman through doas

Run once as root on the runner host, from this checkout:

```sh
install -o root -g wheel -m 0755 ci/podman-doas.sh /usr/local/bin/ci-podman
pkg install -y skopeo
install -o root -g wheel -m 0755 ci/skopeo-doas.sh /usr/local/bin/ci-skopeo
```

Add to `/usr/local/etc/doas.conf`, replacing `RUNNER_USER` with the runner account:

```text
permit nopass setenv { REGISTRY_AUTH_FILE } RUNNER_USER as root cmd /usr/local/bin/podman
permit nopass setenv { REGISTRY_AUTH_FILE } RUNNER_USER as root cmd /usr/local/bin/skopeo
```

The wrappers use `doas -n` to fail immediately if noninteractive access is missing.
Preserving `REGISTRY_AUTH_FILE` keeps login, pull, build, inspect, and push on the
same credentials. Place the auth file directly in a runner-owned temporary
directory so the runner can unlink it even if Podman creates it as root.

Check as the runner account:

```sh
/usr/local/bin/ci-podman info
/usr/local/bin/ci-skopeo --version
```
