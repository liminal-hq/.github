# Liminal HQ Shared Infrastructure

![Liminal HQ CI hero](assets/ci-hero.svg)

This repository is the shared home for Liminal HQ CI infrastructure, container image pipelines, and reusable automation.

## Scope

- Shared GitHub Actions workflows for CI image publication
- Shared, reusable GitHub Actions workflows consumer repos call directly (e.g. AppImage packaging)
- Shared Docker images in granular tiers: pure Rust, JS/TS, Tauri desktop, and Tauri mobile
- Runbooks for publish, rollback, and digest pinning

## Shared Images

Pick the leanest tier that covers the repo's toolchain:

- `ghcr.io/liminal-hq/ci-rust` — Rust toolchain + clippy/rustfmt/cargo-nextest (pure-Rust CI)
- `ghcr.io/liminal-hq/ci-web` — Node + pnpm + Bun (JS/TS-only CI)
- `ghcr.io/liminal-hq/tauri-ci-desktop` — Rust + JS runtimes + Tauri desktop system stack
- `ghcr.io/liminal-hq/tauri-ci-mobile` — desktop stack + Java + Android SDK/NDK
- `ghcr.io/liminal-hq/dev-rust` — Rust toolchain for devcontainers/toolbox use
- `ghcr.io/liminal-hq/dev-web` — JS runtimes for devcontainers/toolbox use
- `ghcr.io/liminal-hq/tauri-dev-desktop` — Tauri desktop devcontainers
- `ghcr.io/liminal-hq/tauri-dev-mobile` — Tauri Android devcontainers

## Platform Support

- `ci-rust`, `ci-web`, and `tauri-ci-desktop` publish `linux/amd64` and `linux/arm64`.
- `tauri-ci-mobile` currently publishes `linux/amd64` only.
- Dev images (`dev-rust`, `dev-web`, `tauri-dev-desktop`, `tauri-dev-mobile`) currently publish `linux/amd64` only.

The ARM variants exist today to support downstream Linux ARM runners such as `ubuntu-24.04-arm` release and binary-compile jobs.

## Image Families

- CI images are for GitHub Actions and other automated pipelines that want a lean, root-friendly toolchain baseline.
- Dev images are for devcontainers and interactive local work — including host-side toolbox use — with a non-root user-home layout for Cargo, Rustup, pnpm, Bun, and Android tooling.
- Every tier that carries JavaScript tooling ships both pnpm (via Node) and Bun, so pnpm-based and Bun-based repos use the same images.
- Both image families include the GitHub CLI (`gh`) for release, issue, and workflow operations that run inside the shared containers.

## GitHub CLI Auth

- Installing `gh` does not automatically authenticate it.
- In GitHub Actions jobs, `gh` can use `GH_TOKEN` or `GITHUB_TOKEN` from the job environment without an interactive login step.
- In devcontainers, authenticate explicitly with `gh auth login` or provide a token through the environment when needed.

## Reusable Workflows

- `package-arch-appimage.yml` — packages an already-built `.deb` into a Linux AppImage via `quick-sharun` on a pinned Arch container, replacing Tauri's unmerged experimental AppImage bundler. Called with `uses:` from a consumer repo's own release pipeline. Reference: [`docs/reference/package-arch-appimage.md`](https://github.com/liminal-hq/.github/blob/main/docs/reference/package-arch-appimage.md).

## Layout Scheme

- Docker targets:
  - `ci-rust`
  - `ci-web`
  - `ci-desktop`
  - `ci-mobile`
  - `dev-rust`
  - `dev-web`
  - `dev-desktop`
  - `dev-mobile`
- Shared image layout reference: [`docs/reference/shared-image-layout.md`](https://github.com/liminal-hq/.github/blob/main/docs/reference/shared-image-layout.md)
- Shared image implementation spec: [`docs/reference/shared-image-implementation-spec.md`](https://github.com/liminal-hq/.github/blob/main/docs/reference/shared-image-implementation-spec.md)

## Repositories in Scope

- [`liminal-hq/tauri-plugins-workspace`](https://github.com/liminal-hq/tauri-plugins-workspace)
- [`liminal-hq/threshold`](https://github.com/liminal-hq/threshold)
- [`liminal-hq/emoji-nook`](https://github.com/liminal-hq/emoji-nook)
- [`liminal-hq/spindle`](https://github.com/liminal-hq/spindle)
- [`liminal-hq/foyer`](https://github.com/liminal-hq/foyer)
- [`ScottMorris/liminal-notes`](https://github.com/ScottMorris/liminal-notes)

## Onboarding Links

- Image publish workflow: [`.github/workflows/shared-tauri-ci-images.yml`](https://github.com/liminal-hq/.github/blob/main/.github/workflows/shared-tauri-ci-images.yml)
- AppImage packaging reusable workflow: [`.github/workflows/package-arch-appimage.yml`](https://github.com/liminal-hq/.github/blob/main/.github/workflows/package-arch-appimage.yml) ([reference](https://github.com/liminal-hq/.github/blob/main/docs/reference/package-arch-appimage.md))
- Shared Dockerfile: [`docker/ci/Dockerfile`](https://github.com/liminal-hq/.github/blob/main/docker/ci/Dockerfile)
- Shared image layout reference: [`docs/reference/shared-image-layout.md`](https://github.com/liminal-hq/.github/blob/main/docs/reference/shared-image-layout.md)
- Shared image implementation spec: [`docs/reference/shared-image-implementation-spec.md`](https://github.com/liminal-hq/.github/blob/main/docs/reference/shared-image-implementation-spec.md)
- Publish and rollback runbook: [`docs/runbooks/image-publish-and-rollback.md`](https://github.com/liminal-hq/.github/blob/main/docs/runbooks/image-publish-and-rollback.md)
