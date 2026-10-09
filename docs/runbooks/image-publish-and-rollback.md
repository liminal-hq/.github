# Shared Image Publish and Rollback Runbook

## Publish Workflow

1. Trigger `.github/workflows/shared-tauri-ci-images.yml` manually or via push/schedule.
2. Confirm all jobs complete for the intended image set:
   - `publish-images` matrix: CI mobile, dev Rust, dev web, dev desktop, dev mobile, dev Windows
   - `build-multiarch` + `merge-multiarch`: CI Rust, CI web, CI desktop (per-platform native builds merged into one manifest)
3. Record published digest and tags from the step summaries.
4. First publish of a NEW image only: GHCR creates new packages with private visibility. Set the package to public (org settings → Packages → the new package → Change visibility) and connect it to this repository, or cross-org consumers (e.g. `ScottMorris/*` repos) cannot pull it and `GITHUB_TOKEN`-based pulls outside the org will fail.

## Image Families

Published images:

1. `ghcr.io/liminal-hq/ci-rust`
   Current platforms: `linux/amd64`, `linux/arm64`
2. `ghcr.io/liminal-hq/ci-web`
   Current platforms: `linux/amd64`, `linux/arm64`
3. `ghcr.io/liminal-hq/tauri-ci-desktop`
   Current platforms: `linux/amd64`, `linux/arm64`
4. `ghcr.io/liminal-hq/tauri-ci-mobile`
   Current platforms: `linux/amd64`
5. `ghcr.io/liminal-hq/dev-rust`
   Current platforms: `linux/amd64`
6. `ghcr.io/liminal-hq/dev-web`
   Current platforms: `linux/amd64`
7. `ghcr.io/liminal-hq/tauri-dev-desktop`
   Current platforms: `linux/amd64`
8. `ghcr.io/liminal-hq/tauri-dev-mobile`
   Current platforms: `linux/amd64`
9. `ghcr.io/liminal-hq/tauri-dev-windows`
   Current platforms: `linux/amd64`

Downstream consumers should not assume ARM support exists for the mobile or dev image families unless that contract is expanded in a later change.

Docker targets:

1. `ci-rust`
2. `ci-web`
3. `ci-desktop`
4. `ci-mobile`
5. `dev-rust`
6. `dev-web`
7. `dev-desktop`
8. `dev-mobile`
9. `dev-windows`

Usage guidance:

1. Pick the leanest tier that covers the repo's toolchain: `*-rust` for pure Rust, `*-web` for JS/TS only, `tauri-*-desktop` for Tauri desktop, `tauri-*-mobile` for Android, `tauri-dev-windows` for cross-compiling Windows builds from Linux or WSL2.
2. Use CI images (`ci-rust`, `ci-web`, `tauri-ci-*`) for CI and other automated pipeline contexts.
3. Use dev images (`dev-rust`, `dev-web`, `tauri-dev-*`) for devcontainers and interactive local development or toolbox use.
4. Expect CI images to remain root-friendly and minimal.
5. Expect dev images to use a non-root home-directory layout for writable tool paths.

## Tag Policy

Each image publish produces:

1. `latest` (from `main`) or `staging` (from other refs)
2. `sha-<commit>`
3. `YYYYMMDD-<commit>` (every publish: push, manual, or scheduled)
4. `YYYYMMDD` (scheduled runs only)

Only the manifest digest (`sha256:...`) is immutable. Every tag above is mutable: a scheduled or manual rebuild at an unchanged commit re-points `sha-<commit>` at the new build, which picks up newer base packages. `YYYYMMDD-<commit>` is a readable record of when a build was made, not a guarantee that it never moves if the same commit is rebuilt on the same day. Pin consumers by digest, and keep the dated tag in a comment beside it.

## Consumer Rollout

1. Start with `latest` in non-critical CI or local testing.
2. For production rollout, pin consumer repos by digest, for example `image: ghcr.io/liminal-hq/tauri-ci-desktop@sha256:<digest>`, with a comment recording the dated tag it came from.
3. Take the digest from the `Digest` line in the publish workflow's step summary, or from `docs/reference/recommended-image-pins.md`.
4. Bump the pin deliberately, one consumer at a time, when the image's contents (Rust, Bun, Node, Android) need to change for that repo.
5. Keep the previous digest noted for immediate fallback.

## Rollback Procedure

1. Identify the last known-good digest. The dated tags in the package's version list (`gh api orgs/liminal-hq/packages/container/<image>/versions`) show which build each digest came from.
2. Update consumer workflow image references to that digest.
3. Re-run CI to validate recovery.
4. Open a follow-up issue in this repository documenting:
   - regression summary
   - affected repo/jobs
   - missing contract item or tool mismatch

## Contract Checks

The publish workflow runs `docker/ci/smoke-check.sh <profile> <image>` against every image before pushing; the same script can be run locally against a candidate image. Before promoting a new image to broad usage, validate:

1. Tool availability for the tier:
   - Rust tiers: `cargo`, `rustup`, `cargo-nextest`
   - JS tiers: `node`, `pnpm`, `bun`
   - Tauri tiers: `cargo-tauri`
   - mobile tiers: `sdkmanager`, `java`
   - `dev-windows`: `clang-cl`, `llvm-lib`, `llvm-ar`, `llvm-rc`, `lld-link`, `cargo-xwin`, `makensis`, and both `*-pc-windows-msvc` Rust targets
   - all tiers: `gh`
2. Leanness:
   - `ci-rust` must not contain `node` or `bun`
   - `ci-web` must not contain `cargo`
   - `dev-windows` must ship an empty xwin cache directory: the Microsoft CRT and Windows SDK are downloaded by the consumer on first use, never baked into the published image
3. Environment values:
   - `TAURI_BUNDLER_NEW_APPIMAGE_FORMAT=true` (Tauri tiers)
   - `JAVA_HOME` (mobile images)
   - `ANDROID_HOME` (mobile images)
   - `XWIN_CACHE_DIR` (`dev-windows`)
   - user-home tool paths for dev images (`CARGO_HOME`, `RUSTUP_HOME`, `PNPM_HOME`, `BUN_INSTALL` as applicable)
4. Writable-path checks for dev images:
   - `CARGO_HOME` (Rust tiers)
   - `PNPM_HOME`, `BUN_INSTALL` (JS tiers)
   - `ANDROID_HOME` (dev mobile)
