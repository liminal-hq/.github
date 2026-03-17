# Shared Image Publish and Rollback Runbook

## Publish Workflow

1. Trigger `.github/workflows/shared-tauri-ci-images.yml` manually or via push/schedule.
2. Confirm the publish matrix completes for all intended image families:
   - CI desktop
   - CI mobile
   - Dev desktop
   - Dev mobile
3. Record published digest and tags from the step summary.

## Image Families

Published images:

1. `ghcr.io/liminal-hq/tauri-ci-desktop`
   Current platforms: `linux/amd64`, `linux/arm64`
2. `ghcr.io/liminal-hq/tauri-ci-mobile`
   Current platforms: `linux/amd64`
3. `ghcr.io/liminal-hq/tauri-dev-desktop`
   Current platforms: `linux/amd64`
4. `ghcr.io/liminal-hq/tauri-dev-mobile`
   Current platforms: `linux/amd64`

Only `tauri-ci-desktop` is multi-arch today. Downstream consumers should not assume ARM support exists for the mobile or dev image families unless that contract is expanded in a later change.

Docker targets:

1. `ci-desktop`
2. `ci-mobile`
3. `dev-desktop`
4. `dev-mobile`

Usage guidance:

1. Use `tauri-ci-*` images for CI and other automated pipeline contexts.
2. Use `tauri-dev-*` images for devcontainers and interactive local development.
3. Expect CI images to remain root-friendly and minimal.
4. Expect dev images to use a non-root home-directory layout for writable tool paths.

## Tag Policy

Each image publish produces:

1. `latest`
2. `sha-<commit>`
3. `YYYYMMDD` schedule tag

## Consumer Rollout

1. Start with `latest` in non-critical CI or local testing.
2. For production rollout, pin consumer repos to a tested `sha-*` tag.
3. Keep previous digest/tag noted for immediate fallback.

## Rollback Procedure

1. Identify the last known-good image tag or digest.
2. Update consumer workflow image references to the known-good `sha-*` tag.
3. Re-run CI to validate recovery.
4. Open a follow-up issue in this repository documenting:
   - regression summary
   - affected repo/jobs
   - missing contract item or tool mismatch

## Contract Checks

Before promoting a new image to broad usage, validate:

1. `command -v` checks for `cargo`, `rustup`, `node`, `pnpm`, `cargo-tauri`
2. Environment values:
   - `TAURI_BUNDLER_NEW_APPIMAGE_FORMAT=true`
   - `JAVA_HOME` (mobile images)
   - `ANDROID_HOME` (mobile images)
   - user-home tool paths for dev images
3. Smoke commands:
   - `cargo --version`
   - `node --version`
   - `pnpm --version`
   - `sdkmanager --version` (mobile images)
4. Writable-path checks for dev images:
   - `CARGO_HOME`
   - `PNPM_HOME`
   - `ANDROID_HOME` (dev mobile)
