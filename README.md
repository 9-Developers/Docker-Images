# FreeBSD CI Images

Native FreeBSD OCI images published to Forgejo Packages at
`git.9dev.tech/9-developers/ci-{base,node,odin,openjdk,rust,security}`.
Source: https://git.9dev.tech/9-Developers/Docker-Images

## Releases and quarterly packages

Release settings live at the top of `Makefile`: `FREEBSD_VERSION=15.1`,
`PKG_QUARTER=2026q4`, and `IMAGE_REVISION=1`.

| Image | Release tag | Moving aliases |
| --- | --- | --- |
| ci-node | `24-freebsd15.1-2026q4-r1` | `24`, `24-freebsd15.1` |
| ci-openjdk | `25-freebsd15.1-2026q4-r1` | `25`, `25-freebsd15.1` |
| ci-base, ci-rust, ci-security, ci-odin | `freebsd15.1-2026q4-r1` | `freebsd15.1` |

Increment the revision for each rebuild in a quarter. The publisher refuses
existing release tags; use full release tags or image digests in pinned CI jobs.
Aliases advance only after all requested release images have been pushed.
Publication is not transactional: a failed partial release requires a new revision.
Do not publish concurrently outside the serialized Actions workflow.

`2026q4` means the FreeBSD Ports quarterly branch served **at build time**.
The upstream OS image is independently selected by FreeBSD release, refreshed
and resolved to a digest. All images inherit an explicit public `quarterly`
package repository configuration; builds disable layer caching and upgrade
the base's inherited packages before installing additional packages.

The public `quarterly` URL rolls forward and is not an archive. Before building,
verify the branch currently served for your ABI using the FreeBSD package build
status at https://pkg-status.freebsd.org/ (branch `2026Q4` for this release).
Do not infer the branch solely from the date, especially during rollover.
Set `CONFIRMED_PKG_QUARTER=2026q4` to attest to that check. This is an operator
confirmation, not an automated check of the repository's provenance.
After rollover, update the quarter and reset the revision to 1. Old images
remain usable, but rebuilding their old quarter requires retained packages.

OCI labels record the source commit, release, creation time, package quarter,
and upstream FreeBSD base digest. `/usr/local/share/ci-packages.txt` records
installed FreeBSD package versions in each final image. npm, rustup, and
source-built tools have independent versions; the quarter does not pin them.
Public package repositories can change during a build, so these are not
bit-for-bit reproducible snapshots.

## Build and publish locally

### Cross-compilation

`ci-rust` and `ci-odin` include FreeBSD-hosted cross-compilers. Native builds
remain the default. The other images do not install cross-compilation tooling.

| Image | Cross targets | Toolchain |
| --- | --- | --- |
| ci-rust | Linux x64/ARM64, GNU libc and musl | Zig + cargo-zigbuild |
| ci-rust | Windows x64/ARM64 | LLVM-MinGW, Rust `windows-gnullvm` targets |
| ci-odin | Linux x64/ARM64, GNU libc | Odin object generation + Zig linking |
| ci-odin | Windows x64 (experimental) | Odin object generation + LLVM-MinGW |

Image builds compile and link smoke programs for every listed target. The Rust
smoke program calls C and uses threads; the Odin program allocates, prints, and
checks floating-point arithmetic. Linux x64 prototypes also ran under FreeBSD's
Linux compatibility layer. Windows and ARM64 runtime validation is still pending.
Odin Windows uses an MSVC compatibility marker and is experimental until tested
with your application's runtime and native dependencies.

#### Rust

```sh
cargo zigbuild --release --target x86_64-unknown-linux-gnu
cargo zigbuild --release --target aarch64-unknown-linux-gnu
cargo zigbuild --release --target x86_64-unknown-linux-musl
cargo zigbuild --release --target aarch64-unknown-linux-musl
cargo build --release --target x86_64-pc-windows-gnullvm
cargo build --release --target aarch64-pc-windows-gnullvm
```

Windows linker, C/C++ compiler, and archiver settings are scoped to those target
triples. The Windows runtime is UCRT; use Windows 10/11 as the deployment baseline.
Linux musl is the option for static binaries. GNU targets use Zig's default glibc
baseline; select a particular baseline with, for example,
`--target aarch64-unknown-linux-gnu.2.28`.

Cross-compilers do not supply every third-party dependency. Native libraries
such as OpenSSL must also be built for the selected target; FreeBSD libraries
cannot be linked into Linux or Windows binaries.

#### Odin

Generate one object, then link it with the supplied helper:

```sh
odin build . -target:linux_amd64 -build-mode:obj -use-single-module -out:app.o
odin-cross-link linux-amd64 app.o app

odin build . -target:linux_arm64 -build-mode:obj -use-single-module -out:app-arm64.o
odin-cross-link linux-arm64 app-arm64.o app-arm64

odin build . -target:windows_amd64 -build-mode:obj -use-single-module -out:app-windows.o
odin-cross-link windows-amd64 app-windows.o app.exe
```

`odin-cross-link TARGET OBJECT OUTPUT [flags...]` supplies basic runtime libraries.
Pass additional target-specific libraries and search paths after the output
argument, for example `-L/path/to/target/lib -lfoo`. It does not resolve arbitrary
foreign libraries automatically. It supports executables; DLLs, custom entry
points, sanitizers, and LTO require project-specific linking.

#### Toolchain maintenance

The Windows builder stage uses LLVM-MinGW `20251216` with LLVM `21.1.8`.
Update the MinGW release and LLVM runtime sources together: newer MinGW headers
failed against LLVM 21's unwinder during investigation. The builder checks the
installed LLVM version. `CROSS_BUILD_JOBS` defaults to 6.

Rust installs cargo-zigbuild `0.24.1`; Zig and LLVM come from the quarterly package
repository. `/usr/local/share/ci-cross-toolchains.txt` records installed versions.
Only the installed Windows toolchain is copied from the builder stage; source
trees and build dependencies are excluded from the final image. Both images
need LLVM at runtime because the Windows wrappers use `/usr/local/llvm21`.

The Rust and Odin Dockerfiles use the repository root as build context, including
shared files from `ci/cross`. `gmake` handles this automatically. For a direct build:

```sh
ci-podman build -f ci/rust/Dockerfile \
  --build-arg FREEBSD_CI_BASE=git.9dev.tech/9-developers/ci-base:freebsd15.1-2026q4-r2 \
  -t localhost/ci-rust:cross-test .
```

### Local release builds

Use a FreeBSD host with native Podman configured for FreeBSD containers,
Git, and GNU make (`gmake`). The upstream base remains hosted at GHCR.
Podman must run as root on FreeBSD. When building as an unprivileged user,
install the doas wrapper described below and export
`CONTAINER_TOOL=/usr/local/bin/ci-podman` before invoking `gmake`.

```sh
export CONFIRMED_PKG_QUARTER=2026q4
gmake -j 4 build
# Or build one dependent image, including its base:
gmake build-node

# Supply a Forgejo username and token through your environment.
# The token needs package write access for the 9-Developers organization.
gmake login
gmake -j 4 publish
```

Login reads `REGISTRY_USER` and `REGISTRY_TOKEN` from the environment and passes
the token through stdin. `publish` includes a fresh build. `gmake help` lists
targets. Override settings with, for example, `gmake IMAGE_REVISION=2 publish`.

Publishing also requires Skopeo (`REGISTRY_TOOL`, default `skopeo`) for
remote-only release-tag checks. Run `gmake check-tools` before a local build.
The Actions workflow checks tool access before building.

To retry publishing images already present in the host's Podman storage:

```sh
export CONTAINER_TOOL=/usr/local/bin/ci-podman
export REGISTRY_TOOL=/usr/local/bin/ci-skopeo
export CONFIRMED_PKG_QUARTER=2026q4
# REGISTRY_USER and REGISTRY_TOKEN must be set in your environment.
export REGISTRY_AUTH_FILE="$(mktemp -d)/auth.json"
gmake login
gmake publish-existing
rm -f "$REGISTRY_AUTH_FILE"
rmdir "$(dirname "$REGISTRY_AUTH_FILE")"
```

Use the same release settings as the original build. This checks that every
requested image exists locally and every release tag is absent remotely before
pushing. A partial earlier publication still requires a new release revision.

## Forgejo Actions

1. Enable Actions for this repository.
2. Add the mapping-style runner label below; the workflow selects
   `runs-on: freebsd-15.1-host`:

   ```yaml
   labels:
     freebsd-15.1-host:
       backend: host
   ```
3. Ensure the runner account can run Podman, Git, GNU make, and standard shell
   utilities. Install the doas wrapper below. Host execution builds directly
   on that FreeBSD machine.
4. Add repository secrets `REGISTRY_USER` and `REGISTRY_TOKEN` for a Forgejo
   account/token with package write access to `9-Developers`.
5. After checking the public package build status, set repository Actions
   variable `CONFIRMED_PKG_QUARTER` to `2026q4`. Recheck before each release
   and update it when changing quarters.
6. Commit the release settings and invoke **Publish FreeBSD CI images** manually,
   or push a Git tag matching the release settings:

   ```sh
   git tag freebsd15.1-2026q4-r1
   git push origin freebsd15.1-2026q4-r1
   ```

The workflow uses shell checkout, builds the base before its dependent images,
then publishes release tags and moving aliases. Registry credentials use a
temporary authentication file removed at the end of the job.

### Rootful Podman through doas

Run this once as root on the runner host, from a checkout of this repository:

```sh
install -o root -g wheel -m 0755 ci/podman-doas.sh /usr/local/bin/ci-podman
pkg install -y skopeo
install -o root -g wheel -m 0755 ci/skopeo-doas.sh /usr/local/bin/ci-skopeo
```

Add this rule to `/usr/local/etc/doas.conf`, replacing `RUNNER_USER` with the
actual Unix account running the Forgejo runner:

```text
permit nopass setenv { REGISTRY_AUTH_FILE } RUNNER_USER as root cmd /usr/local/bin/podman
permit nopass setenv { REGISTRY_AUTH_FILE } RUNNER_USER as root cmd /usr/local/bin/skopeo
```

The rule preserves the workflow's temporary authentication-file path for every
Podman invocation. The registry token itself is passed through stdin at login.
The workflow sets `CONTAINER_TOOL=/usr/local/bin/ci-podman`, so login, pull,
build, inspect, and push all use the same rootful Podman storage and credentials.
The wrapper uses `doas -n` to fail immediately if noninteractive access is missing.

Check the installation as the runner account:

```sh
/usr/local/bin/ci-podman info
/usr/local/bin/ci-skopeo --version
```

The authentication file lives directly in the runner-owned temporary directory,
so the runner can unlink it during cleanup even if Podman creates it as root.
