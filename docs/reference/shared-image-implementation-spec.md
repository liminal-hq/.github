# Shared Image Implementation Spec

This document describes the intended implementation and operating contract for the shared image families published from this repository.

It exists to make the image architecture, stage layout, workflow responsibilities, and verification expectations explicit for maintainers and downstream consumers.

## Scope

The shared image system covers two related image families, each built from granular single-concern tiers:

1. CI images for automated pipelines
2. Dev images for devcontainers, interactive local development, and host-side toolbox use

Published image set:

| Image | Docker target | Primary use |
| --- | --- | --- |
| `ghcr.io/liminal-hq/ci-rust` | `ci-rust` | Pure-Rust CI jobs |
| `ghcr.io/liminal-hq/ci-web` | `ci-web` | JS/TS-only CI jobs |
| `ghcr.io/liminal-hq/tauri-ci-desktop` | `ci-desktop` | Tauri desktop CI jobs |
| `ghcr.io/liminal-hq/tauri-ci-mobile` | `ci-mobile` | Android/mobile CI jobs |
| `ghcr.io/liminal-hq/dev-rust` | `dev-rust` | Pure-Rust devcontainers and toolbox use |
| `ghcr.io/liminal-hq/dev-web` | `dev-web` | JS/TS devcontainers and toolbox use |
| `ghcr.io/liminal-hq/tauri-dev-desktop` | `dev-desktop` | Desktop devcontainers |
| `ghcr.io/liminal-hq/tauri-dev-mobile` | `dev-mobile` | Android/mobile devcontainers |

The platform contract is intentionally asymmetric: the `ci-rust`, `ci-web`, and `tauri-ci-desktop` images publish both `linux/amd64` and `linux/arm64`, while the mobile and dev image families currently publish `linux/amd64` only.

## Design Goals

1. Keep every published image single-concern-per-tier: consumers pull exactly the toolchain they need and nothing heavier.
2. Keep the pre-existing `tauri-ci-*` / `tauri-dev-*` names, environment models, and tag policy stable for current consumers.
3. Keep version pins aligned across all tiers and both families through shared `ARG` values.
4. Make Docker targets and published image names easy to reason about.
5. Catch regressions during publication with per-tier smoke validation, including leanness checks on the lean tiers.

## Dockerfile Architecture

The shared Dockerfile builds two parallel tier chains. Each tier adds exactly one concern to its parent; GUI/Tauri system libraries live only in the desktop tiers.

### Stage Layout

#### CI stages

- `ci-base` (unpublished)
  - Ubuntu base with universal CLI tooling only: certificates, curl/wget, git, gh, file, build-essential, pkg-config, zip/unzip
- `ci-rust`
  - adds the pinned Rust toolchain, clippy, rustfmt, and `cargo-nextest`
  - root-friendly tool paths under `/usr/local`
- `ci-web`
  - adds pinned Node, pnpm, and Bun on `ci-base` (no Rust)
- `ci-desktop`
  - builds on `ci-rust`
  - adds the JS runtimes (same pins as `ci-web`), the GTK/webkit2gtk/appindicator/rsvg system stack, patchelf/xdg-utils/libssl-dev, GStreamer (base + bad), emoji fonts, xvfb, and `cargo-tauri`
- `ci-mobile`
  - builds on `ci-desktop`
  - adds Java, Android SDK/NDK, and Android Rust targets

#### Dev stages

- `dev-base` (unpublished)
  - devcontainer-oriented base image with universal CLI tooling and interactive quality-of-life packages (vim, ripgrep, fd, jq)
- `dev-rust`
  - adds the pinned Rust toolchain, clippy, rustfmt, and `cargo-nextest` under the user home
- `dev-web`
  - adds pinned Node, pnpm, and Bun with user-home tool paths (no Rust)
- `dev-desktop`
  - builds on `dev-rust`
  - adds the JS runtimes, the GUI system stack, GStreamer/xvfb/emoji fonts, X11 inspection tools (xprop/xev via x11-utils, wmctrl, xdotool), and `cargo-tauri`
- `dev-mobile`
  - builds on `dev-desktop`
  - adds Java and Android SDK/NDK under the user home

### JS runtime duplication

The Node + pnpm + Bun install block appears in both the web tier and the Tauri desktop tier of each family. This is deliberate: single inheritance cannot give the desktop tier two parents, and every install site consumes the same shared `ARG` pins (`NODE_MAJOR`, `PNPM_VERSION`, `BUN_VERSION`), so versions cannot drift between tiers.

## Environment Model

### CI images

CI images remain root-friendly and automation-oriented.

Expected paths:

- Rust tiers (`ci-rust`, `ci-desktop`, `ci-mobile`):
  - `RUSTUP_HOME=/usr/local/rustup`
  - `CARGO_HOME=/usr/local/cargo`
- JS tiers (`ci-web`, `ci-desktop`, `ci-mobile`):
  - `BUN_INSTALL=/usr/local/bun`
- mobile images:
  - `ANDROID_HOME=/opt/android-sdk`
  - `ANDROID_SDK_ROOT=/opt/android-sdk`

### Dev images

Dev images are optimised for non-root devcontainer and toolbox use.

Expected paths:

- `HOME=/home/vscode`
- Rust tiers: `RUSTUP_HOME=$HOME/.rustup`, `CARGO_HOME=$HOME/.cargo`
- JS tiers: `PNPM_HOME=$HOME/.local/share/pnpm`, `BUN_INSTALL=$HOME/.bun`
- mobile images: `ANDROID_HOME=$HOME/Android/Sdk`, `ANDROID_SDK_ROOT=$HOME/Android/Sdk`

Dev images should pre-create writable user-owned directories for the tool paths their tier owns (`.cargo`/`.rustup` on Rust tiers, `.local/share/pnpm` on JS tiers, `Android/Sdk` where applicable).

## Shared Versioning Rules

The image tiers stay aligned on:

- Ubuntu baseline
- Node major version
- pnpm version
- Bun version
- Rust toolchain version
- Android command-line tools version
- Android platform, build-tools, and NDK versions
- Tauri CLI source and branch

When these values change, update them centrally in the shared Dockerfile `ARG`s rather than drifting tiers or families independently.

## Workflow Contract

The shared image publication workflow is responsible for:

1. evaluating the publish cadence
2. publishing all intended image families
3. applying a consistent tag policy
4. running smoke validation (via `docker/ci/smoke-check.sh`) before push
5. reusing persistent build cache across runs
6. writing digest and tag summaries for each image

### Cadence

- Pushes to `main` that touch `docker/ci/**` or the workflow should publish.
- Manual dispatch should publish.
- Scheduled runs should follow the configured bi-weekly cadence gate.

### Tag policy

Each published image should receive:

1. `latest` (on `main`) or `staging` (on other refs)
2. `sha-<commit>`
3. `YYYYMMDD` (scheduled runs)

### Platform policy

| Image | Platforms |
| --- | --- |
| `ci-rust` | `linux/amd64`, `linux/arm64` |
| `ci-web` | `linux/amd64`, `linux/arm64` |
| `tauri-ci-desktop` | `linux/amd64`, `linux/arm64` |
| `tauri-ci-mobile` | `linux/amd64` |
| `dev-rust` | `linux/amd64` |
| `dev-web` | `linux/amd64` |
| `tauri-dev-desktop` | `linux/amd64` |
| `tauri-dev-mobile` | `linux/amd64` |

The `linux/arm64` CI variants are required by downstream Linux ARM jobs that run on `ubuntu-24.04-arm` (desktop releases, Rust release builds, and ARM binary-compile jobs).

Multi-platform CI images build each platform natively (amd64 on `ubuntu-24.04`, arm64 on `ubuntu-24.04-arm`), push by digest, and merge digests into one manifest — QEMU emulation of the from-source cargo installs is deliberately avoided.

If multi-arch dev images or mobile images become necessary later, that should be treated as an explicit follow-up rather than assumed by default.

## Smoke Validation Contract

Publication validates every image before pushing it, using the per-tier profiles in `docker/ci/smoke-check.sh`. The profiles enforce three kinds of contract:

1. **Tool availability** — the tier's tools exist and respond to `--version` (`cargo`/`rustup`/`cargo-nextest` on Rust tiers; `node`/`pnpm`/`bun` on JS tiers; `cargo-tauri` on Tauri tiers; `sdkmanager`/`java` on mobile tiers; `gh` everywhere).
2. **Leanness** — lean CI tiers must not contain other tiers' toolchains (`ci-rust` has no Node or Bun; `ci-web` has no cargo).
3. **Dev ergonomics** — dev images run as a non-root user, expose the expected user-home environment variables, and have writable tool paths.

## GitHub CLI Authentication

Installing `gh` does not perform authentication by itself.

Expected usage:

- CI jobs that run inside the shared images should provide `GH_TOKEN` or `GITHUB_TOKEN` in the environment when the GitHub CLI is used.
- Devcontainers should authenticate explicitly with `gh auth login` or an equivalent token-based flow.

## Cache Strategy

The shared image workflow should use persistent registry-backed Buildx cache for each published image family.

Expected behaviour:

- smoke builds restore prior cache state when available
- smoke builds write cache state that the publish build in the same job can reuse
- publish builds write the refreshed cache back to the registry for future runs
- cache references stay image-specific rather than sharing one global cache across all targets

Because the tiers share ancestor stages (`ci-base`, `ci-rust`, `dev-base`, `dev-rust`), per-image caches will contain overlapping layers; this is expected and keeps cache keys simple. Repeat runs stay fast while avoiding cache collisions between image families.

## Smoke Build Strategy

Smoke validation should use Buildx rather than a separate plain `docker build`.

Expected behaviour:

- smoke builds load a single-platform image into the local Docker engine for `docker run` validation
- smoke validation targets the runner-compatible platform only (each platform of a multi-arch image is smoke-checked on its own native runner)
- final publish builds remain the place where multi-platform manifests are assembled and pushed

## Documentation Contract

When the shared image layout changes, keep these docs aligned:

- `README.md`
- `docs/reference/shared-image-layout.md`
- `docs/reference/shared-image-implementation-spec.md`
- `docs/runbooks/image-publish-and-rollback.md`

The layout doc should explain the image tiers from a consumer perspective.

This implementation spec should explain the architecture and maintainer contract.

The runbook should explain how to publish, validate, roll back, and consume the images operationally.

## Consumer Guidance

Pick the leanest tier that covers the repo's toolchain:

- Pure Rust: `ci-rust` / `dev-rust`
- JS/TS only: `ci-web` / `dev-web`
- Tauri desktop (pnpm or Bun): `tauri-ci-desktop` / `tauri-dev-desktop`
- Tauri Android/mobile: `tauri-ci-mobile` / `tauri-dev-mobile`

Use the CI images when:

- the workload is a GitHub Actions or other automated pipeline job
- root-friendly defaults are acceptable
- minimal runtime assumptions are preferred

Use the dev images when:

- the workload is a devcontainer or an interactive host-side toolbox container
- the default user is non-root
- writable tool paths are needed without repo-local overrides
- interactive local development ergonomics matter

## Out Of Scope

These items are intentionally out of scope for the shared image contract unless a later issue expands the design:

- per-JS-runtime image splits (`ci-bun` / `ci-node-pnpm`) — both runtimes ship together in the JS tiers
- emulator tooling in the mobile dev image
- repo-specific developer customisations (e.g. ffmpeg for codec validation — layer those in the consuming repo)
- per-repo mounted cache contracts as a required baseline
- automatic downstream rollout to consumer repositories
