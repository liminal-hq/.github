# Shared Image Implementation Spec

This document describes the intended implementation and operating contract for the shared Tauri image families published from this repository.

It exists to make the image architecture, stage layout, workflow responsibilities, and verification expectations explicit for maintainers and downstream consumers.

## Scope

The shared image system covers two related image families:

1. CI images for automated pipelines
2. Dev images for devcontainers and interactive local development

Published image set:

| Image | Docker target | Primary use |
| --- | --- | --- |
| `ghcr.io/liminal-hq/tauri-ci-desktop` | `ci-desktop` | Desktop CI jobs |
| `ghcr.io/liminal-hq/tauri-ci-mobile` | `ci-mobile` | Android/mobile CI jobs |
| `ghcr.io/liminal-hq/tauri-dev-desktop` | `dev-desktop` | Desktop devcontainers |
| `ghcr.io/liminal-hq/tauri-dev-mobile` | `dev-mobile` | Android/mobile devcontainers |

The platform contract is intentionally asymmetric today: `tauri-ci-desktop` publishes both `linux/amd64` and `linux/arm64`, while the mobile and dev image families currently publish `linux/amd64` only.

## Design Goals

1. Keep the CI image family stable for current consumers.
2. Add devcontainer-oriented images without forcing CI images to absorb interactive-user assumptions.
3. Keep version pins aligned across CI and dev families.
4. Make Docker targets and published image names easy to reason about.
5. Catch regressions during publication with lightweight smoke validation.

## Dockerfile Architecture

The shared Dockerfile intentionally separates:

- intermediate setup stages
- final CI targets
- final dev targets

### Stage Layout

#### CI stages

- `ci-base`
  - Ubuntu-based shared package baseline for Tauri desktop CI builds
- `ci-toolchain`
  - installs pinned Node, pnpm, Rust, `cargo-nextest`, and `cargo-tauri`
  - uses root-friendly tool paths
- `ci-desktop`
  - final desktop CI image
- `ci-mobile`
  - final mobile CI image
  - extends the CI toolchain with Java, Android SDK/NDK, and Android Rust targets

#### Dev stages

- `dev-base`
  - devcontainer-oriented base image
  - interactive development packages and desktop-friendly tooling
- `dev-toolchain`
  - installs pinned Node, pnpm, Rust, `cargo-nextest`, and `cargo-tauri`
  - uses a Threshold-style non-root home-directory tool layout
- `dev-desktop`
  - final desktop devcontainer image
- `dev-mobile`
  - final mobile devcontainer image
  - extends the dev toolchain with Java, Android SDK/NDK, and Android Rust targets

## Environment Model

### CI images

CI images remain root-friendly and automation-oriented.

Expected paths:

- `RUSTUP_HOME=/usr/local/rustup`
- `CARGO_HOME=/usr/local/cargo`
- mobile images:
  - `ANDROID_HOME=/opt/android-sdk`
  - `ANDROID_SDK_ROOT=/opt/android-sdk`

### Dev images

Dev images are optimised for non-root devcontainer use.

Expected paths:

- `HOME=/home/vscode`
- `RUSTUP_HOME=$HOME/.rustup`
- `CARGO_HOME=$HOME/.cargo`
- `PNPM_HOME=$HOME/.local/share/pnpm`
- mobile images:
  - `ANDROID_HOME=$HOME/Android/Sdk`
  - `ANDROID_SDK_ROOT=$HOME/Android/Sdk`

Dev images should pre-create writable user-owned directories for:

- `.cargo`
- `.rustup`
- `.local/share/pnpm`
- `Android/Sdk` where applicable

## Shared Versioning Rules

The image families should stay aligned on:

- Ubuntu baseline
- Node major version
- pnpm version
- Rust toolchain version
- Android command-line tools version
- Android platform, build-tools, and NDK versions
- Tauri CLI source and branch

When these values change, update them centrally in the shared Dockerfile rather than drifting CI and dev families independently.

## Workflow Contract

The shared image publication workflow is responsible for:

1. evaluating the publish cadence
2. publishing all intended image families
3. applying a consistent tag policy
4. running smoke validation before push
5. writing digest and tag summaries for each image

### Cadence

- Pushes to `main` that touch the Dockerfile or workflow should publish.
- Manual dispatch should publish.
- Scheduled runs should follow the configured bi-weekly cadence gate.

### Tag policy

Each published image should receive:

1. `latest`
2. `sha-<commit>`
3. `YYYYMMDD`

### Platform policy

Initial expected platform coverage:

| Image | Platforms |
| --- | --- |
| `tauri-ci-desktop` | `linux/amd64`, `linux/arm64` |
| `tauri-ci-mobile` | `linux/amd64` |
| `tauri-dev-desktop` | `linux/amd64` |
| `tauri-dev-mobile` | `linux/amd64` |

The `linux/arm64` desktop CI variant is required by downstream Linux ARM release jobs that run on `ubuntu-24.04-arm`.

If multi-arch dev images or mobile images become necessary later, that should be treated as an explicit follow-up rather than assumed by default.

## Smoke Validation Contract

Publication should validate the image before pushing it.

### CI desktop

Minimum checks:

- `cargo`
- `rustup`
- `node`
- `pnpm`
- `cargo-tauri`
- `gh`
- version commands for core tooling

### CI mobile

Minimum checks:

- CI desktop checks
- `sdkmanager`
- `java`
- Android version command checks

### Dev desktop

Minimum checks:

- CI desktop checks
- confirm effective user is non-root
- confirm user-home tool paths are set correctly
- confirm writable paths for Cargo and pnpm locations

### Dev mobile

Minimum checks:

- dev desktop checks
- confirm Android SDK path is under the devcontainer user home
- confirm writable Android path access
- `sdkmanager`
- `java`

## GitHub CLI Authentication

Installing `gh` does not perform authentication by itself.

Expected usage:

- CI jobs that run inside the shared images should provide `GH_TOKEN` or `GITHUB_TOKEN` in the environment when the GitHub CLI is used.
- Devcontainers should authenticate explicitly with `gh auth login` or an equivalent token-based flow.

## Documentation Contract

When the shared image layout changes, keep these docs aligned:

- `README.md`
- `docs/reference/shared-image-layout.md`
- `docs/reference/shared-image-implementation-spec.md`
- `docs/runbooks/image-publish-and-rollback.md`

The layout doc should explain the image family from a consumer perspective.

This implementation spec should explain the architecture and maintainer contract.

The runbook should explain how to publish, validate, roll back, and consume the images operationally.

## Consumer Guidance

Use the CI images when:

- the workload is a GitHub Actions or other automated pipeline job
- root-friendly defaults are acceptable
- minimal runtime assumptions are preferred

Use the dev images when:

- the workload is a devcontainer
- the default user is non-root
- writable tool paths are needed without repo-local overrides
- interactive local development ergonomics matter

## Out Of Scope

These items are intentionally out of scope for the shared image contract unless a later issue expands the design:

- emulator tooling in the mobile dev image
- repo-specific developer customisations
- per-repo mounted cache contracts as a required baseline
- automatic downstream rollout to consumer repositories
