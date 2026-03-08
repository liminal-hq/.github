# Liminal HQ Shared Infrastructure

![Liminal HQ CI hero](assets/ci-hero.svg)

This repository is the shared home for Liminal HQ CI infrastructure, container image pipelines, and cross-repository alignment tracking.

## Scope

- Shared GitHub Actions workflows for CI image publication
- Shared Docker images for Tauri desktop and mobile workloads
- Runbooks for publish, rollback, and digest pinning
- Cross-repository migration tracking and status reporting

## Shared Images

- `ghcr.io/liminal-hq/tauri-ci-desktop`
- `ghcr.io/liminal-hq/tauri-ci-mobile`

## Repositories in Scope

- [`liminal-hq/tauri-plugins-workspace`](https://github.com/liminal-hq/tauri-plugins-workspace)
- [`liminal-hq/threshold`](https://github.com/liminal-hq/threshold)
- [`ScottMorris/liminal-notes`](https://github.com/ScottMorris/liminal-notes)

## Onboarding Links

- Image publish workflow: [`.github/workflows/shared-tauri-ci-images.yml`](https://github.com/liminal-hq/.github/blob/main/.github/workflows/shared-tauri-ci-images.yml)
- Shared Dockerfile: [`docker/ci/Dockerfile`](https://github.com/liminal-hq/.github/blob/main/docker/ci/Dockerfile)
- Publish and rollback runbook: [`docs/runbooks/image-publish-and-rollback.md`](https://github.com/liminal-hq/.github/blob/main/docs/runbooks/image-publish-and-rollback.md)
- Cross-repo tracking: [`docs/tracking/cross-repo-ci-alignment.md`](https://github.com/liminal-hq/.github/blob/main/docs/tracking/cross-repo-ci-alignment.md)
