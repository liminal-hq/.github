# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is `liminal-hq/.github` — the shared home for Liminal HQ's GitHub infrastructure: reusable CI image pipelines, shared Docker container definitions, and reusable GitHub Actions workflows consumed by other Liminal HQ repos (Tauri desktop/mobile apps). There is no application source code here; this is an infrastructure-only repo. See `AGENTS.md` for the full set of contribution conventions — the highlights are summarized below.

## Commands

There is no app build/lint/test suite (no package.json, no source code to compile). Verification is done differently depending on what changed:

- **Workflow YAML changes** (`.github/workflows/*.yml`): validate syntax locally, e.g. `python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" .github/workflows/<file>.yml` or run it through `actionlint` if available.
- **Docker/image changes** (`docker/ci/Dockerfile`): build the affected target(s) locally before considering the change verified, e.g.:
  ```
  docker build --target ci-desktop -f docker/ci/Dockerfile .
  docker build --target ci-mobile -f docker/ci/Dockerfile .
  docker build --target dev-desktop -f docker/ci/Dockerfile .
  docker build --target dev-mobile -f docker/ci/Dockerfile .
  ```
  Call out explicitly which targets were built and which were not (mobile/Android targets are slow due to SDK/NDK downloads).
- **Smoke-testing a built image**: run `command -v cargo rustup node pnpm cargo-tauri gh` (add `sdkmanager java` for mobile targets) inside the built image — this mirrors the checks the `shared-tauri-ci-images.yml` workflow itself runs before publishing. See `docs/runbooks/image-publish-and-rollback.md` for the full contract-check list.
- If full verification isn't possible in the current environment (e.g. no Docker, no GitHub Actions run), say so explicitly rather than assuming success.

## Architecture

### Shared container images (`docker/ci/Dockerfile`)

A single multi-stage Dockerfile produces four published image targets, built from two parallel stage chains:

- `ci-base` → `ci-toolchain` → **`ci-desktop`** / **`ci-mobile`**: root-friendly images for GitHub Actions and other automated pipelines. Tool paths live under `/usr/local` (`CARGO_HOME`, `RUSTUP_HOME`); mobile adds Android SDK/NDK under `/opt/android-sdk`.
- `dev-base` → `dev-toolchain` → **`dev-desktop`** / **`dev-mobile`**: non-root devcontainer images (runs as `vscode` user) for interactive local development. Tool paths live under `/home/vscode` instead; mobile adds Android SDK/NDK under `$HOME/Android/Sdk`.

Both families install the GitHub CLI (`gh`) from GitHub's own apt repo (not the distro package) and pin Node/pnpm/Rust versions via build args at the top of the file. `cargo-tauri` is installed from a Tauri fork branch (`feat/truly-portable-appimage`) to get portable AppImage behaviour, paired with `TAURI_BUNDLER_NEW_APPIMAGE_FORMAT=true`. Images publish to `ghcr.io/liminal-hq/tauri-{ci,dev}-{desktop,mobile}`.

Keep version pins aligned across the CI and dev chains, and keep target names using the `ci-`/`dev-` prefixes — see `docs/reference/shared-image-layout.md` for the full layout contract and `docs/reference/shared-image-implementation-spec.md` for the implementation spec.

### Image publish workflow (`.github/workflows/shared-tauri-ci-images.yml`)

Builds and pushes the four images above on push to `main` (when `docker/ci/**` or the workflow itself changes), on `workflow_dispatch`, and on a weekly `schedule` gated to a two-week publish cadence (an ISO week-number parity check in the `cadence` job). Each image build does a local single-platform "smoke" build/run first, then the real (possibly multi-platform) build/push.

`ci-desktop` is the only multi-platform image (`linux/amd64` + `linux/arm64`) and is handled specially to avoid QEMU emulation: `build-ci-desktop` builds each platform natively on its own runner (including GitHub's native `ubuntu-24.04-arm` runner) and pushes by digest, then `merge-ci-desktop` combines the digests into one multi-arch manifest via `docker buildx imagetools create`. The other three images build directly in a single matrixed job (`publish-images`).

### Reusable AppImage packaging workflow (`.github/workflows/package-arch-appimage.yml`)

A `workflow_call`-only reusable workflow, called via `uses:` from a consumer repo's own release pipeline — not runnable standalone in this repo. It packages an already-built `.deb` (passed in as an artifact, not built here) into a Linux AppImage using `quick-sharun` on a pinned `ghcr.io/pkgforge-dev/archlinux` container, replacing Tauri's unmerged experimental AppImage bundler. Full inputs/outputs/usage example: `docs/reference/package-arch-appimage.md`. Rationale for Arch + `quick-sharun` over alternatives: `docs/proposals/archived/arch-experimental-ci-image.md`.

Non-obvious operational gotchas baked into this workflow (don't undo them without re-reading why):
- Never re-run `pacman -Syu` after the `anylinux-setup-action` setup step — it's already been done once, and a second run has been observed knocking `patchelf` back out.
- `quick-sharun` needs `OUTPATH` set explicitly or it writes into the cwd instead of `dist/`.
- Only one app icon is copied into the AppDir (largest, via sorted `find`), not a glob — Tauri's `.deb` ships multiple resolutions under the same basename, which collides with `cp`'s overwrite guard.

### Docs layout

- `docs/reference/` — stable contracts: image layout, implementation spec, AppImage packaging usage. Update these in the same change when the underlying workflow/image behaviour changes.
- `docs/runbooks/` — operational procedures (`image-publish-and-rollback.md`: publish steps, tag policy, rollback procedure, contract checks).
- `docs/tracking/cross-repo-ci-alignment.md` — rollout status of this shared infra across consumer repos, updated periodically (waves, version drift notes).
- `docs/proposals/archived/` — historical decision records, kept for rationale, not current instructions.

## Conventions (see `AGENTS.md` for full detail)

- **Spelling:** Canadian English in comments, docs, commits, and PRs (unless external tooling/API/identifier spelling dictates otherwise).
- **Commit messages:** Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`, `build:`, etc). Write multi-line/markdown-heavy bodies to a file and commit with `git commit -F <file>` rather than piping backticks/`$()` through `-m`; verify with `git log -1 --pretty=fuller` afterward.
- **PR titles:** human-readable outcome summaries, capitalized, *no* Conventional Commit prefix.
- **PR descriptions:** `## Summary` (flat bullets, bold lead-ins) + optional `###` subsections (`User-facing changes`, `Maintainer-facing changes`, `Packaging`, `Workflow and infrastructure`, `Documentation`, `Known limitations`) + `## Test plan` (checklist bullets, concrete commands, explicit gaps if verification is incomplete). Every PR needs at least one primary label (`enhancement`/`bug`/`documentation`/`testing`/`ci`/`build`/`chore`).
- **Licence headers:** only add to authored source-like files that already carry them as a repo convention — never to markdown, workflow YAML, JSON, or lockfiles.
- **Markdown formatting:** do not manually hard-wrap prose (no inserting line breaks mid-paragraph to hit a column width) — write each paragraph as one line and let the renderer/editor soft-wrap.
- Downstream consumer repos in scope for this shared infra: `liminal-hq/tauri-plugins-workspace`, `liminal-hq/threshold`, `liminal-hq/emoji-nook`, `liminal-hq/spindle`, `liminal-hq/foyer`, `ScottMorris/liminal-notes`. Evaluate changes here for their impact on these consumers.
