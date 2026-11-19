# CI Images

9 Developers CI images.

Canonical repository:
[https://git.9dev.tech/9-Developers/Docker-Images][canonical-repo]

Packages:
[https://git.9dev.tech/9-Developers/Docker-Images/packages][packages]

## Images

### FreeBSD images

- **ci-base**: FreeBSD 15.1 image on quarterly ports tree
- **ci-dotnet**: Provides .NET 10 LTS toolchain
- **ci-go**: Provides Go toolchain
- **ci-node**: Provides Node 24 LTS and npm
- **ci-odin**: Provides Odin from quarterly packages with native FreeBSD, Linux x64/ARM64, and experimental Windows x64 targets
- **ci-openjdk**: Provides OpenJDK 25 LTS
- **ci-postgres**: PostgreSQL 18 database service for integration tests
- **ci-rust**: Provides Rust managed by rustup with native FreeBSD and Linux/Windows x64/ARM64 targets
- **ci-security**: Provides gitleaks, semgrep, socket, and trivy security scanning

### Linux images

- **ci-rust-node**: Debian Bookworm with Node 24, npm, rustup-managed Rust, Railway CLI, and crane

## Using the images

The FreeBSD images require a native FreeBSD host with rootful Podman configured for
FreeBSD containers. They do not run in a standard Linux container VM.

Images are published as `git.9dev.tech/9-developers/ci-NAME`. Check
[Packages][packages] for available tags and image architectures. Choose an
immutable release tag or digest for reproducible CI.

For example, run the following as root on the FreeBSD host, replacing `<tag>`
with a tag from Packages:

```sh
podman run --rm -it \
  -v "$PWD:/workspace" -w /workspace \
  'git.9dev.tech/9-developers/ci-go:<tag>' \
  sh -c 'go build ./...'
```

The language examples below run inside the selected image with your project as
the working directory. Cross-compilation targets describe the generated
binaries, not the host architectures on which the container can run.

### Debian Bookworm with Rust and Node

Use `git.9dev.tech/9-developers/ci-rust-node:24-bookworm` for Linux jobs that
should stay on Node 24. Pin `:24-bookworm-r1` for the exact first build, or
use `:bookworm` to follow the designated default Node major. Use a
`rust-toolchain.toml` to select a Rust release; jobs installing extra toolchains
need network access and write access to the rustup directories (root by default).

The `railway` command is preinstalled. For CI deployments, supply a Railway
project token through the job's `RAILWAY_TOKEN` secret at runtime.
Use `crane` to inspect or copy registry images without a local container daemon.

Run `gmake build-rust-node` on the FreeBSD runner with Linuxulator enabled.
The build uses native-architecture Linux binaries and tests Node and Rust during
the build. To publish, select `rust-node` in **Publish one CI image**.
This image is released separately from the aggregate FreeBSD build and publish.

For each rebuild of a Node major, increment `BOOKWORM_REVISION` in the Makefile.
For a new major, change `BOOKWORM_NODE_MAJOR` and start its revision at 1.
Only builds matching `BOOKWORM_DEFAULT_NODE_MAJOR` advance `:bookworm`.
To promote an already published major, select it as the default and publish
its next revision.

### PostgreSQL in Forgejo Actions

For a containerized `ci-rust` job, use the service name `postgres` as the
hostname in SQLx's `DATABASE_URL`. No host port mapping is needed.

```yaml
jobs:
  test:
    runs-on: ci-rust
    services:
      postgres:
        image: git.9dev.tech/9-developers/ci-postgres:18-freebsd15.1-2026q4-r3
        env:
          POSTGRES_USER: ci
          POSTGRES_PASSWORD: ci
          POSTGRES_DB: app_test
    env:
      DATABASE_URL: postgres://ci:ci@postgres:5432/app_test
    # Add checkout, database readiness, migrations, and test steps here.
```

On first startup the image requires `POSTGRES_PASSWORD`; `POSTGRES_USER`
defaults to `postgres`, and `POSTGRES_DB` defaults to the user name. A new
service container gets an empty cluster. The moving aliases are `18` and
`18-freebsd15.1`. To publish just this image, run **Publish one CI image**
from the branch containing the image and select `postgres`. This rebuilds the
base locally but pushes only Postgres. After publishing, run **Test PostgreSQL service
from ci-rust** workflow to check DNS, readiness, and an authenticated `SELECT 1`.

## Cross-compilation

`ci-rust`, `ci-odin`, and `ci-go` include FreeBSD-hosted cross-compilers.
`ci-dotnet` supports managed cross-publishing through its SDK.
Native builds remain the default.

| Image     | Cross targets                               | Toolchain                                  |
| --------- | ------------------------------------------- | ------------------------------------------ |
| ci-rust   | Linux x64/ARM64, GNU libc and musl          | Zig + cargo-zigbuild                       |
| ci-rust   | Windows x64/ARM64                           | LLVM-MinGW, Rust `windows-gnullvm` targets |
| ci-odin   | Linux x64/ARM64, GNU libc                   | Odin object generation + Zig linking       |
| ci-odin   | Windows x64 (experimental)                  | Odin object generation + LLVM-MinGW        |
| ci-go     | FreeBSD, Linux, Windows x64/ARM64 (pure Go) | Go `GOOS`/`GOARCH`                         |
| ci-go     | Linux x64/ARM64, GNU libc and musl (cgo)    | Zig                                        |
| ci-go     | Windows x64/ARM64 (cgo)                     | LLVM-MinGW                                 |
| ci-dotnet | Linux, Linux-musl, Windows x64/ARM64        | .NET SDK managed publishing                |

Cross-build checks do not establish runtime compatibility; test generated
binaries on their destination platforms. Odin Windows support is experimental.

Cross-compilers do not supply every third-party native dependency. Libraries
such as OpenSSL, including libraries used through cgo or P/Invoke, must be
provided for the destination OS and CPU. FreeBSD libraries cannot be linked
into Linux or Windows binaries.

### Rust

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

### Odin

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

### Go

`ci-go` installs Go from the quarterly package repository. Pure-Go cross-builds
need no external linker:

```sh
CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o app-linux-arm64 .
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o app.exe .
```

For cgo, `go-cross TARGET GO-COMMAND [arguments...]` selects a compiler and
enables cgo only for that command:

```sh
go-cross linux-amd64-gnu build -o app-linux .
go-cross linux-arm64-musl build -o app-linux-arm64 .
go-cross windows-amd64 build -o app.exe .
go-cross windows-arm64 build -o app-arm64.exe .
```

Linux targets accept `amd64` or `arm64` with either `gnu` or `musl`.

### C# / .NET 10

`ci-dotnet` includes .NET 10 LTS using the community-maintained
[FreeBSD SDK](https://github.com/sec/dotnet-core-freebsd-source-build).

```sh
# Portable managed build, runnable with the installed FreeBSD runtime.
dotnet build -c Release -p:UseAppHost=false
dotnet bin/Release/net10.0/MyApp.dll

# Self-contained managed deployments (runtime included).
dotnet publish -c Release -r linux-arm64 --self-contained true
dotnet publish -c Release -r linux-musl-x64 --self-contained true
dotnet publish -c Release -r win-x64 --self-contained true
```

Publishing restores target runtime packs from NuGet and requires network access.
NativeAOT, ReadyToRun, and platform-specific workloads are outside this target
matrix.

[canonical-repo]: https://git.9dev.tech/9-Developers/Docker-Images
[packages]: https://git.9dev.tech/9-Developers/Docker-Images/packages
