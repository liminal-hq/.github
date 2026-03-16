# Liminal HQ Shared Infrastructure

![Liminal HQ CI hero](assets/ci-hero.svg)

This repository is the shared home for Liminal HQ CI infrastructure, container image pipelines, and reusable automation.

## Scope

- Shared GitHub Actions workflows for CI image publication
- Shared Docker images for Tauri desktop and mobile workloads
- Runbooks for publish, rollback, and digest pinning

## Shared Images

- `ghcr.io/liminal-hq/tauri-ci-desktop`
- `ghcr.io/liminal-hq/tauri-ci-mobile`
- `ghcr.io/liminal-hq/tauri-dev-desktop`
- `ghcr.io/liminal-hq/tauri-dev-mobile`

## Platform Support

- `tauri-ci-desktop` publishes `linux/amd64` and `linux/arm64`.
- `tauri-ci-mobile` currently publishes `linux/amd64` only.
- `tauri-dev-desktop` currently publishes `linux/amd64` only.
- `tauri-dev-mobile` currently publishes `linux/amd64` only.

The ARM variant exists today to support downstream Linux ARM runners such as `ubuntu-24.04-arm` release jobs that consume `tauri-ci-desktop`.

## Image Families

- CI images are for GitHub Actions and other automated pipelines that want a lean, root-friendly toolchain baseline.
- Dev images are for devcontainers and interactive local work, with a non-root user-home layout for Cargo, Rustup, pnpm, and Android tooling.

## Layout Scheme

- Docker targets:
  - `ci-desktop`
  - `ci-mobile`
  - `dev-desktop`
  - `dev-mobile`
- Shared image layout reference: [`docs/reference/shared-image-layout.md`](https://github.com/liminal-hq/.github/blob/main/docs/reference/shared-image-layout.md)
- Shared image implementation spec: [`docs/reference/shared-image-implementation-spec.md`](https://github.com/liminal-hq/.github/blob/main/docs/reference/shared-image-implementation-spec.md)

## Repositories in Scope

- [`liminal-hq/tauri-plugins-workspace`](https://github.com/liminal-hq/tauri-plugins-workspace)
- [`liminal-hq/threshold`](https://github.com/liminal-hq/threshold)
- [`ScottMorris/liminal-notes`](https://github.com/ScottMorris/liminal-notes)

## Onboarding Links

- Image publish workflow: [`.github/workflows/shared-tauri-ci-images.yml`](https://github.com/liminal-hq/.github/blob/main/.github/workflows/shared-tauri-ci-images.yml)
- Shared Dockerfile: [`docker/ci/Dockerfile`](https://github.com/liminal-hq/.github/blob/main/docker/ci/Dockerfile)
- Shared image layout reference: [`docs/reference/shared-image-layout.md`](https://github.com/liminal-hq/.github/blob/main/docs/reference/shared-image-layout.md)
- Shared image implementation spec: [`docs/reference/shared-image-implementation-spec.md`](https://github.com/liminal-hq/.github/blob/main/docs/reference/shared-image-implementation-spec.md)
- Publish and rollback runbook: [`docs/runbooks/image-publish-and-rollback.md`](https://github.com/liminal-hq/.github/blob/main/docs/runbooks/image-publish-and-rollback.md)
