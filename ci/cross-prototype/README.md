# Cross-compilation investigation

These are temporary, locally tagged FreeBSD prototypes. They use the existing
`ci-rust:freebsd15.1-2026q4-r2` image and do not publish images.

## Results

On a FreeBSD 15.1 amd64 host:

| Language | Target | Result |
| --- | --- | --- |
| Rust | Linux x64 GNU | Compiled and linked; ran under FreeBSD Linux compatibility in Debian |
| Rust | Linux ARM64 GNU | Compiled and linked; ELF architecture inspected |
| Rust | Linux x64 musl | Compiled and statically linked; ran under FreeBSD Linux compatibility in Debian |
| Rust | Linux ARM64 musl | Compiled and statically linked; ELF architecture inspected |
| Odin | Linux x64 GNU | Compiled and linked; ran under FreeBSD Linux compatibility in Debian |
| Odin | Linux ARM64 GNU | Compiled and linked; ELF architecture inspected |
| Rust | Windows x64 GNU-LLVM | Compiled and linked; PE architecture and imports inspected |
| Rust | Windows ARM64 GNU-LLVM | Compiled and linked; PE architecture and imports inspected |
| Odin | Windows x64 | Compiled and linked using MinGW plus compatibility marker; PE architecture and imports inspected |

The Rust fixture calls C, allocates, and creates a thread. The Odin fixture
allocates and prints. Linux compatibility execution is not a substitute for
native Linux or ARM64 runtime testing.
Windows binaries have not been executed. Odin Windows support remains
experimental until runtime tests cover initialization, threads, floating-point
operations, and the project's actual foreign libraries.

Versions observed: Rust 1.100.0, cargo-zigbuild 0.24.1, Zig 0.16.0,
LLVM 21.1.8. The package identifies Odin as `odin-lang-2026.09`, while
`odin version` reports `dev-2026-11`.

Odin requires `-use-single-module` for a predictable single object output.
`-export-linked-libs-file` did not produce a manifest in object mode.
The explicit `-lm -lpthread -ldl` link flags used here cover this fixture,
not arbitrary foreign dependencies.

Windows uses the Universal CRT. Odin additionally needs `bcrypt` for its random
generator and an `_fltused` marker definition for MSVC-generated object code.
The fixture links through the MinGW compiler driver so that MinGW supplies CRT
startup; it does not use MSVC's linker or SDK.

The installed `/opt/llvm-mingw` tree uses approximately 74 MiB on this host.
That excludes its packaged LLVM dependency, source checkout, and build files.
Production integration should use a builder stage and copy only the installed
toolchain into the final image, retaining the same LLVM package paths.

## Commands

From the repository root on FreeBSD:

```sh
ci-podman build --pull=never -t localhost/ci-cross-prototype:investigation ci/cross-prototype
ci-podman run --name ci-cross-linux-prototype \
  -v "$PWD/ci/cross-prototype:/prototype:ro" \
  localhost/ci-cross-prototype:investigation sh /prototype/linux-smoke.sh
ci-podman run --name ci-cross-windows-prototype \
  -v "$PWD/ci/cross-prototype:/prototype:ro" \
  localhost/ci-cross-prototype:investigation \
  sh -c 'sh /prototype/windows-toolchain.sh && sh /prototype/windows-smoke.sh'
```

Use new container names when repeating these commands. Stopped containers retain
results for inspection. The Windows build uses six jobs and reuses packaged LLVM;
it builds Windows headers, import libraries, compiler runtime, and C++ runtime.
Its LLVM runtime sources are pinned to match the packaged compiler.

The initial Windows attempt used LLVM-MinGW `20261104` with LLVM 21 runtime
sources. Its newer MinGW headers caused an `EXCEPTION_DISPOSITION` type error
in libunwind. The retry uses LLVM-MinGW `20251216`, whose default LLVM version
is 21.1.8, keeping the headers and runtimes from a matched release.

## Integration recommendation

- Rust: Zig and pinned cargo-zigbuild for the four Linux targets; matched
  LLVM-MinGW for both Windows GNU-LLVM targets, with target-scoped Cargo linker,
  C/C++ compiler, and archiver settings.
- Odin: Zig for Linux object linking; LLVM-MinGW for experimental Windows x64
  object linking, including the compatibility marker above.
- Keep native compiler defaults intact. Cross-compilation commands should always
  select their target explicitly.
- Keep third-party headers and libraries target-specific. The smoke-test linker
  arguments do not constitute an automatic resolver for arbitrary Odin projects.
- Confirm native Windows and ARM64 execution before advertising runtime-tested
  support. No production Dockerfiles or release tags were changed by this
  investigation.
