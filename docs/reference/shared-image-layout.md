# Shared Image Layout

This repository publishes two related image families built from granular tiers:

1. CI images for automated pipelines
2. Dev images for devcontainers, interactive local development, and host-side toolbox use

Each tier adds exactly one concern on top of its parent, so consumer repos pick the leanest image that covers their toolchain instead of inheriting everything.

## Published Images

| Image | Docker target | Tier contents | Primary consumers |
| --- | --- | --- | --- |
| `ghcr.io/liminal-hq/ci-rust` | `ci-rust` | Rust toolchain (pinned), clippy, rustfmt, cargo-nextest, gh | Pure-Rust libraries, CLIs, and TUIs |
| `ghcr.io/liminal-hq/ci-web` | `ci-web` | Node, pnpm, Bun (pinned), gh | JS/TS-only projects |
| `ghcr.io/liminal-hq/tauri-ci-desktop` | `ci-desktop` | ci-rust + Node/pnpm/Bun + GTK/webkit2gtk system stack + GStreamer/xvfb/emoji fonts + tauri-cli | Tauri desktop CI jobs |
| `ghcr.io/liminal-hq/tauri-ci-mobile` | `ci-mobile` | ci-desktop + Java 17 + Android SDK/NDK + Android Rust targets | Android/mobile CI jobs |
| `ghcr.io/liminal-hq/dev-rust` | `dev-rust` | Rust toolchain under the user home | Pure-Rust devcontainers and toolbox use |
| `ghcr.io/liminal-hq/dev-web` | `dev-web` | Node/pnpm/Bun with user-home tool paths | JS/TS devcontainers and toolbox use |
| `ghcr.io/liminal-hq/tauri-dev-desktop` | `dev-desktop` | dev-rust + JS runtimes + GUI stack + X11 inspection tools + tauri-cli | Desktop devcontainers |
| `ghcr.io/liminal-hq/tauri-dev-mobile` | `dev-mobile` | dev-desktop + Java 17 + Android SDK/NDK | Android/mobile devcontainers |
| `ghcr.io/liminal-hq/tauri-dev-windows` | `dev-windows` | dev-desktop + clang/lld/llvm + NSIS + cargo-xwin + Windows MSVC Rust targets | Cross-compiling Windows builds from Linux or WSL2 |

## Tier Tree

```text
ci-base (unpublished)          universal CLI: certs, curl, wget, git, gh, file,
│                              build-essential, pkg-config, zip, unzip, jq
├── ci-rust                    + rustup (pinned) + clippy + rustfmt + cargo-nextest
│   └── ci-desktop             + Node/pnpm/Bun + GTK/webkit stack + GStreamer/xvfb/
│       │                        emoji fonts + tauri-cli
│       └── ci-mobile          + Java 17 + Android SDK/NDK + Android Rust targets
└── ci-web                     + Node/pnpm/Bun

dev-base (unpublished)         devcontainers base + universal CLI + vim/ripgrep/fd/jq
├── dev-rust                   + rustup (pinned) + clippy + rustfmt + cargo-nextest
│   └── dev-desktop            + Node/pnpm/Bun + GUI stack + GStreamer/xvfb/fonts +
│       │                        X11 inspection tools (xprop/xev/wmctrl/xdotool) +
│       │                        tauri-cli
│       ├── dev-mobile         + Java 17 + Android SDK/NDK under $HOME
│       └── dev-windows        + clang/lld/llvm + NSIS + cargo-xwin + Windows MSVC
│                                targets (no Microsoft SDK baked in)
└── dev-web                    + Node/pnpm/Bun with user-home tool paths
```

The JS runtime install block (Node + pnpm + Bun) intentionally appears in both the web tiers and the Tauri desktop tiers: single inheritance cannot give the desktop tier two parents, and all sites install from the same shared `ARG` pins so versions cannot drift.

## Platform Coverage

| Image | Platforms | Notes |
| --- | --- | --- |
| `ci-rust` | `linux/amd64`, `linux/arm64` | Multi-arch because Rust release jobs already run on both x64 and ARM runners. |
| `ci-web` | `linux/amd64`, `linux/arm64` | Multi-arch for ARM binary-compile jobs (e.g. Bun `--target` builds on `ubuntu-24.04-arm`). |
| `tauri-ci-desktop` | `linux/amd64`, `linux/arm64` | Multi-arch because downstream Linux desktop release jobs already run on both x64 and ARM runners. |
| `tauri-ci-mobile` | `linux/amd64` | ARM is not part of the current shared mobile CI contract. |
| `dev-rust` | `linux/amd64` | Dev-family ARM support is a possible follow-up, not a current baseline. |
| `dev-web` | `linux/amd64` | Dev-family ARM support is a possible follow-up, not a current baseline. |
| `tauri-dev-desktop` | `linux/amd64` | Dev-family ARM support is a possible follow-up, not a current baseline. |
| `tauri-dev-mobile` | `linux/amd64` | Dev-family ARM support is a possible follow-up, not a current baseline. |
| `tauri-dev-windows` | `linux/amd64` | For Linux and WSL2 hosts only; it does not run on Windows runners. |

Consumers that need Linux ARM should use the multi-arch CI images and should not assume ARM variants exist for the mobile or dev image families.

## Design Intent

### CI Images

- Keep them lean and predictable — each tier carries only its own concern
- Keep them suitable for root-friendly automation
- Preserve the existing `tauri-ci-*` contract for shared consumers

### Dev Images

- Use a devcontainer-friendly base image
- Default to a non-root user model
- Put writable tool paths under the user home
- Serve both devcontainer use and interactive host-side toolbox use
- Reduce repo-local overrides for Cargo, Rustup, pnpm, Bun, and Android SDK paths

## Choosing an Image

1. Pure Rust (libraries, CLIs, TUIs): `ci-rust` / `dev-rust`
2. JS/TS only (sites, CLIs, Bun-compiled binaries): `ci-web` / `dev-web`
3. Tauri desktop (with either pnpm or Bun): `tauri-ci-desktop` / `tauri-dev-desktop`
4. Tauri Android/mobile: `tauri-ci-mobile` / `tauri-dev-mobile`
5. Windows builds cross-compiled from Linux or WSL2: `tauri-dev-windows` (there is no CI counterpart; it is not meant for Windows runners)

Both JS runtimes (pnpm via Node, plus Bun) ship in every image tier that carries JavaScript tooling, so pnpm-based and Bun-based repos use the same images.

## Expected Environment Model

### CI Images

- `CARGO_HOME=/usr/local/cargo` (Rust tiers)
- `RUSTUP_HOME=/usr/local/rustup` (Rust tiers)
- `BUN_INSTALL=/usr/local/bun` (JS tiers)
- mobile images install Android tooling under `/opt/android-sdk`

### Dev Images

- `HOME=/home/vscode`
- `CARGO_HOME=$HOME/.cargo` (Rust tiers)
- `RUSTUP_HOME=$HOME/.rustup` (Rust tiers)
- `PNPM_HOME=$HOME/.local/share/pnpm` (JS tiers)
- `BUN_INSTALL=$HOME/.bun` (JS tiers)
- mobile images install Android tooling under `$HOME/Android/Sdk`
- `dev-windows` sets `XWIN_CACHE_DIR=$HOME/.cache/cargo-xwin`, created empty and owned by `vscode`

## Layout Rules

1. Keep version pins aligned across CI and dev image families through the shared `ARG` values at the top of the Dockerfile.
2. Keep final CI targets clearly named with the `ci-` prefix.
3. Keep final dev targets clearly named with the `dev-` prefix.
4. Keep each tier single-concern: GUI/Tauri system libraries live only in the desktop tiers, never in a base or lean tier.
5. Keep emulator tooling out of the shared mobile dev image unless a real consumer need appears.
6. Prefer shared intermediate stages where that does not compromise CI or dev ergonomics.

## Validation Expectations

Every published image is smoke-validated by `docker/ci/smoke-check.sh` (invoked by the publish workflow before push) for:

- tier tool availability (e.g. `cargo`/`rustup`/`cargo-nextest` on Rust tiers, `node`/`pnpm`/`bun` on JS tiers, `cargo-tauri` on Tauri tiers, `gh`/`jq` everywhere)
- tier leanness on the lean CI tiers (`ci-rust` must not contain Node or Bun; `ci-web` must not contain cargo)
- Android tooling on mobile images
- writable user-home paths on dev images
- `dev-windows`: the LLVM tool names, `cargo-xwin`, `makensis` and both Windows MSVC Rust targets are present, and the xwin cache directory is empty (no Microsoft SDK in the image); the smoke check never runs `cargo xwin build`, which would download it
- expected environment variables for the image family
- expected platform coverage for the image family

`gh` installation is part of the shared image contract, but authentication is still environment-driven. GitHub Actions jobs should pass `GH_TOKEN` or `GITHUB_TOKEN` when invoking the CLI inside the container.

Smoke validation builds a single local runner-compatible image variant for fast checks. Multi-platform publication happens only in the final publish step.

## Cross-Compiling for Windows (`tauri-dev-windows`)

`ghcr.io/liminal-hq/tauri-dev-windows` is `tauri-dev-desktop` plus everything needed to cross-compile a Tauri app for Windows from Linux: clang, lld and llvm (with `clang-cl`, `llvm-lib`, `llvm-ar`, `llvm-rc` and `lld-link` on `PATH`), NSIS (so `tauri build` can produce NSIS installers), `cargo-xwin`, and the `x86_64-pc-windows-msvc` and `aarch64-pc-windows-msvc` Rust targets. It is for a Linux host or WSL2 only — it does not run on Windows runners, and the produced `.exe` has to be run on Windows.

The image does not contain the Microsoft CRT or Windows SDK, because redistributing them in a public image is not permitted. `cargo-xwin` downloads them into `XWIN_CACHE_DIR` (`/home/vscode/.cache/cargo-xwin`) on the first `cargo xwin build`: about 1 GB, a few minutes. There is no prompt, flag or environment variable for the licence — by running `cargo xwin`, you accept the [Microsoft licence terms](https://go.microsoft.com/fwlink/?LinkId=2086102) for the SDK it downloads. Keep the cache in a named volume so it is downloaded once.

```sh
docker run --rm -it \
  -v "$PWD":/work -w /work \
  -v cargo-registry:/home/vscode/.cargo/registry \
  -v xwin-cache:/home/vscode/.cache/cargo-xwin \
  -v my-target:/target -e CARGO_TARGET_DIR=/target \
  ghcr.io/liminal-hq/tauri-dev-windows:latest \
  bash
```

Inside the container, run the first-run step once, then build:

```sh
# Install the toolchain the repo pins (see below).
rustup show

cargo xwin build --release --target x86_64-pc-windows-msvc
```

The executable lands in `/target/x86_64-pc-windows-msvc/release/`.

### Keep the target directory in a volume

`CARGO_TARGET_DIR=/target` with `-v my-target:/target` keeps multi-gigabyte build output out of the working tree, so it never shows up in `git status` or a file sync, and `docker volume rm my-target` cleans it up in one step. Any other path works too, such as a host directory you choose, mounted with `-v /path/on/host:/target`.

### Repos that pin their own toolchain

The image's Rust is pinned by `RUST_TOOLCHAIN` in the Dockerfile, and the Windows targets are added to that toolchain only. A repo that pins a different one in `rust-toolchain.toml` makes rustup install it on the first command, and `cargo xwin` starts many `rustc` processes at once, so they race to perform that install. The race can leave a toolchain without `rustc`, which shows up as `could not execute process .../toolchains/<pinned>-.../bin/rustc (never executed) No such file or directory`.

Install the pinned toolchain once, from inside the repo, before the first cross-build:

```sh
rustup show
```

`rustup show` installs the toolchain from `rust-toolchain.toml` together with the `components` and `targets` the file lists, so the cleanest fix is for the repo to list `targets = ["x86_64-pc-windows-msvc"]` there. Otherwise install the toolchain explicitly with the Windows target, using the pinned version:

```sh
rustup toolchain install <pinned> --profile minimal -c rustfmt -c clippy -t x86_64-pc-windows-msvc
```

The installed toolchain lives in the container's `~/.rustup`, so it is reinstalled by each `--rm` container; use a long-lived container (`docker run -d` and `docker exec`) to keep it between builds.

## Related Docs

- Implementation spec: [`shared-image-implementation-spec.md`](./shared-image-implementation-spec.md)
- Publish and rollback runbook: [`../runbooks/image-publish-and-rollback.md`](../runbooks/image-publish-and-rollback.md)
- AppImage packaging (reusable workflow): [`package-arch-appimage.md`](./package-arch-appimage.md)
