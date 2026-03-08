# Shared Image Publish and Rollback Runbook

## Publish Workflow

1. Trigger `.github/workflows/shared-tauri-ci-images.yml` manually or via push/schedule.
2. Confirm both image jobs complete:
   - `Publish desktop image`
   - `Publish mobile image`
3. Record published digest and tags from the step summary.

## Tag Policy

Each image publish produces:

1. `latest`
2. `sha-<commit>`
3. `YYYYMMDD` schedule tag

## Consumer Rollout

1. Start with `latest` in non-critical CI.
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
   - `JAVA_HOME` (mobile)
   - `ANDROID_HOME` (mobile)
3. Smoke commands:
   - `cargo --version`
   - `node --version`
   - `pnpm --version`
   - `sdkmanager --version` (mobile)
