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

## Tier Tree

```text
ci-base (unpublished)          universal CLI: certs, curl, wget, git, gh, file,
│                              build-essential, pkg-config, zip, unzip
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
│       └── dev-mobile         + Java 17 + Android SDK/NDK under $HOME
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

## Layout Rules

1. Keep version pins aligned across CI and dev image families through the shared `ARG` values at the top of the Dockerfile.
2. Keep final CI targets clearly named with the `ci-` prefix.
3. Keep final dev targets clearly named with the `dev-` prefix.
4. Keep each tier single-concern: GUI/Tauri system libraries live only in the desktop tiers, never in a base or lean tier.
5. Keep emulator tooling out of the shared mobile dev image unless a real consumer need appears.
6. Prefer shared intermediate stages where that does not compromise CI or dev ergonomics.

## Validation Expectations

Every published image is smoke-validated by `docker/ci/smoke-check.sh` (invoked by the publish workflow before push) for:

- tier tool availability (e.g. `cargo`/`rustup`/`cargo-nextest` on Rust tiers, `node`/`pnpm`/`bun` on JS tiers, `cargo-tauri` on Tauri tiers, `gh` everywhere)
- tier leanness on the lean CI tiers (`ci-rust` must not contain Node or Bun; `ci-web` must not contain cargo)
- Android tooling on mobile images
- writable user-home paths on dev images
- expected environment variables for the image family
- expected platform coverage for the image family

`gh` installation is part of the shared image contract, but authentication is still environment-driven. GitHub Actions jobs should pass `GH_TOKEN` or `GITHUB_TOKEN` when invoking the CLI inside the container.

Smoke validation builds a single local runner-compatible image variant for fast checks. Multi-platform publication happens only in the final publish step.

## Related Docs

- Implementation spec: [`shared-image-implementation-spec.md`](./shared-image-implementation-spec.md)
- Publish and rollback runbook: [`../runbooks/image-publish-and-rollback.md`](../runbooks/image-publish-and-rollback.md)
- AppImage packaging (reusable workflow): [`package-arch-appimage.md`](./package-arch-appimage.md)
