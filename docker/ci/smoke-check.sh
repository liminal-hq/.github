#!/usr/bin/env bash
# Smoke checks for the shared CI/dev image families.
# Usage: smoke-check.sh <profile> <image-ref>
# Profiles mirror the published image tiers; each check runs inside the image
# and enforces the tier's tool availability, environment, and leanness contract.
set -euo pipefail

profile="${1:?usage: smoke-check.sh <profile> <image-ref>}"
image="${2:?usage: smoke-check.sh <profile> <image-ref>}"

run_in_image() {
  docker run --rm "${image}" bash -lc "set -euo pipefail; $1"
}

case "${profile}" in
  ci-rust)
    run_in_image '
      command -v cargo rustup cargo-nextest gh
      cargo --version
      rustup --version
      cargo nextest --version
      gh --version
      ! command -v node
      ! command -v bun
    '
    ;;
  ci-web)
    run_in_image '
      command -v node pnpm bun gh
      node --version
      pnpm --version
      bun --version
      gh --version
      ! command -v cargo
    '
    ;;
  ci-desktop)
    run_in_image '
      command -v cargo rustup node pnpm bun cargo-tauri gh
      cargo --version
      node --version
      pnpm --version
      bun --version
      gh --version
    '
    ;;
  ci-mobile)
    run_in_image '
      command -v cargo rustup node pnpm bun cargo-tauri gh sdkmanager java
      cargo --version
      node --version
      pnpm --version
      bun --version
      gh --version
      sdkmanager --version
    '
    ;;
  dev-rust)
    run_in_image '
      [[ "$(id -u)" != "0" ]]
      command -v cargo rustup cargo-nextest gh rg fd jq
      cargo --version
      gh --version
      [[ "$CARGO_HOME" == "$HOME/.cargo" ]]
      [[ "$RUSTUP_HOME" == "$HOME/.rustup" ]]
      touch "$CARGO_HOME/.smoke-write"
      rm "$CARGO_HOME/.smoke-write"
    '
    ;;
  dev-web)
    run_in_image '
      [[ "$(id -u)" != "0" ]]
      command -v node pnpm bun gh rg fd jq
      node --version
      pnpm --version
      bun --version
      gh --version
      [[ "$PNPM_HOME" == "$HOME/.local/share/pnpm" ]]
      [[ "$BUN_INSTALL" == "$HOME/.bun" ]]
      touch "$PNPM_HOME/.smoke-write"
      rm "$PNPM_HOME/.smoke-write"
      touch "$BUN_INSTALL/.smoke-write"
      rm "$BUN_INSTALL/.smoke-write"
    '
    ;;
  dev-desktop)
    run_in_image '
      [[ "$(id -u)" != "0" ]]
      command -v cargo rustup node pnpm bun cargo-tauri gh rg fd jq
      cargo --version
      node --version
      pnpm --version
      bun --version
      gh --version
      [[ "$CARGO_HOME" == "$HOME/.cargo" ]]
      [[ "$RUSTUP_HOME" == "$HOME/.rustup" ]]
      [[ "$PNPM_HOME" == "$HOME/.local/share/pnpm" ]]
      [[ "$BUN_INSTALL" == "$HOME/.bun" ]]
      touch "$CARGO_HOME/.smoke-write"
      rm "$CARGO_HOME/.smoke-write"
      touch "$PNPM_HOME/.smoke-write"
      rm "$PNPM_HOME/.smoke-write"
    '
    ;;
  dev-mobile)
    run_in_image '
      [[ "$(id -u)" != "0" ]]
      command -v cargo rustup node pnpm bun cargo-tauri gh sdkmanager java
      cargo --version
      node --version
      pnpm --version
      bun --version
      gh --version
      sdkmanager --version
      [[ "$ANDROID_HOME" == "$HOME/Android/Sdk" ]]
      touch "$CARGO_HOME/.smoke-write"
      rm "$CARGO_HOME/.smoke-write"
      mkdir -p "$ANDROID_HOME/.smoke"
      rmdir "$ANDROID_HOME/.smoke"
    '
    ;;
  *)
    echo "Unknown smoke profile: ${profile}" >&2
    exit 1
    ;;
esac
