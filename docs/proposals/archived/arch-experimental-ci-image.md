# Proposal: Experimental Arch-based `tauri-ci-desktop` Image

**Archived decision record.** This document captured the investigation and pilot that led to `package-arch-appimage.yml`. For current usage docs, see [`../../reference/package-arch-appimage.md`](../../reference/package-arch-appimage.md) — that's the maintained reference; this file is kept for the "why Route B and not Route A" reasoning and the specific bugs hit during the pilot, not as something to read to use the workflow.

Status: **validated and implemented.** Route B selected, piloted in `emoji-nook` (`experiment/arch-quick-sharun-appimage`), confirmed fixed by running the resulting AppImage directly, and generalised into the reusable workflow linked above.

## Problem

`tauri-ci-desktop` builds AppImages using `tauri-cli` installed from an unreleased, experimental upstream branch (`feat/truly-portable-appimage` on `tauri-apps/tauri`, [PR #12491](https://github.com/tauri-apps/tauri/pull/12491)), enabled via `TAURI_BUNDLER_NEW_APPIMAGE_FORMAT=true`. That branch's AppImage bundler (`crates/tauri-bundler/src/bundle/linux/appimage/sharun.rs`) shells out to a third-party tool, [`quick-sharun`](https://github.com/pkgforge-dev/Anylinux-AppImages), maintained by `Samueru-sama` under the `pkgforge-dev` org.

`quick-sharun` is built and tested primarily for **Arch Linux**. Its own maintainer has said as much directly in the PR thread: *"it is meant to be used on archlinux only... it can be used on ubuntu but I only know that because one person used it there lol."* Our current `ci-base`/`ci-toolchain` stages are Ubuntu 24.04. This produces AppImages that fail at runtime with:

```
Could not create default EGL display: EGL_BAD_PARAMETER. Aborting...
```

This is not a one-off — the identical error was reported by another PR participant (`debba`) building on a non-Arch host, and the PR author (`FabianLars`) independently hit different library issues (pixbuf/glycin) trying Ubuntu 26.04 as recently as 2026-07-02. His stated direction for the branch is to mark it **Arch-only, experimental**, not to broaden non-Arch support.

## Why this wasn't caught by pinning alone

Two independent things float, unpinned, in the current setup:

1. `docker/ci/Dockerfile` installs `tauri-cli` via `cargo install --git ... --branch feat/truly-portable-appimage --force`, with no commit SHA. Every image rebuild resolves to whatever the branch tip is at that moment.
2. Even with (1) pinned, `sharun.rs` downloads `quick-sharun.sh` directly from `pkgforge-dev/Anylinux-AppImages`'s `main` branch at build time, with no override env var, only skipping the download `if !quick_sharun.exists()` in the tool cache.

Both are out of scope for this proposal (tracked separately) — this document is about whether an Arch-based image is worth pursuing at all, independent of the pinning question.

## Blast radius if we change the shared `tauri-ci-desktop` image

| Image | Consumers | Affected by this bug? |
| --- | --- | --- |
| `tauri-ci-desktop` | `spindle`, `emoji-nook`, `tauri-plugins-workspace` | **Yes** — these build/publish AppImages |
| `tauri-dev-desktop` | `emoji-nook`, `tauri-plugins-workspace` | Indirectly (interactive shell only) |
| `tauri-ci-mobile` | `threshold`, `foyer` | No — Android builds never touch AppImage bundling |
| `tauri-dev-mobile` | `threshold`, `foyer`, `tauri-plugins-workspace` | No |
| — | `haptics-lab-app` | Not yet — no `Cargo.toml`/CI exists yet |

This proposal is scoped to `ci-desktop` only. Mobile images are untouched by construction.

## Two candidate routes

### Route A — Arch base image, keep using Tauri's experimental bundler

Hand-roll a new stage from `archlinux:base-devel`, install the GTK/WebKit toolchain via `pacman`, and keep installing `tauri-cli` from `feat/truly-portable-appimage` exactly as today, just on an Arch base instead of Ubuntu.

Findings while scoping this route:

- `archlinux:base-devel` is an official, dated Docker Hub tag — confirmed live.
- It is **amd64-only**. Mainline Arch does not target ARM; that's a separate, community-run project (Arch Linux ARM / ALARM) with no official Docker Hub image. Since `tauri-ci-desktop` is **already multi-arch today** (`linux/amd64` + `linux/arm64`, built on native ARM runners per [`shared-image-layout.md`](../../reference/shared-image-layout.md)), Route A would regress ARM support unless we additionally adopt ALARM for that leg — a second, less-official distro with its own risk profile.
- `libayatana-appindicator3`'s Arch equivalent is `libayatana-appindicator`, which **is** in the official `extra` repo (corrected during the pilot — an earlier pass at this research incorrectly searched for `libappindicator-gtk3`, a name that doesn't exist on Arch at all; cloning it from the AUR silently produces an empty repo rather than a clear 404, which is how that mistake surfaced). No AUR build needed for this dependency in either route.
- We would still be depending on the unmerged, actively-changing `feat/truly-portable-appimage` branch and its embedded `sharun.rs`, which has its own open, unresolved bugs reported by the PR author as recently as 2026-06-30 (a hang under `LD_DEBUG=libs` tracing caused by `set -m` failing without a controlling tty — notably, GitHub Actions runners are exactly that: non-interactive, no tty).

### Route B — Adopt the tool author's own published pattern

`Samueru-sama` (quick-sharun's maintainer) publishes a working reference setup at [`tabularis-appimage-demo`](https://github.com/Samueru-sama/tabularis-appimage-demo), which Scott linked in the PR thread back in March. It does **not** use Tauri's embedded experimental bundler at all:

- Container: `ghcr.io/pkgforge-dev/archlinux:latest` — a purpose-built, actively maintained image from the same org that ships `quick-sharun`. Confirmed via `docker manifest inspect`: genuinely multi-arch (`amd64`, `arm64`, `armv7`, `riscv64`), so ARM support comes for free instead of needing ALARM.
- Setup: [`pkgforge-dev/anylinux-setup-action`](https://github.com/pkgforge-dev/anylinux-setup-action) — a composite action that inits `pacman-key`, syncs a baseline package set, and installs three CLI tools (`quick-sharun`, `get-debloated-pkgs`, `make-aur-package`) fetched from `Anylinux-AppImages@main`.
- Build: a normal, **stable, released** `cargo tauri build --bundles deb` (no experimental branch, no `TAURI_BUNDLER_NEW_APPIMAGE_FORMAT` needed at all) — then the app's own script extracts the `.deb`, assembles an `AppDir`, and calls `quick-sharun` directly as a CLI tool against it.
- `make-aur-package` already wraps the AUR build problem — `libappindicator-gtk3` becomes a one-line call (`make-aur-package libappindicator-gtk3`) instead of hand-rolled `makepkg`/build-user plumbing.

Route B decouples us entirely from the unmerged, floating Tauri PR branch. The only remaining floating dependency is `quick-sharun`/`get-debloated-pkgs`/`make-aur-package` themselves (still fetched from `main` by the setup action) — a smaller, more auditable surface than Route A, and it's the actual path the tool's own author runs and tests.

### Comparison

| | Route A (hand-rolled Arch + Tauri experimental bundler) | Route B (pkgforge-dev container + direct `quick-sharun`) |
| --- | --- | --- |
| Base image | `archlinux:base-devel` (official, amd64-only) | `ghcr.io/pkgforge-dev/archlinux` (multi-arch: amd64/arm64/armv7/riscv64) |
| ARM64 | Needs ALARM (unofficial) as a second base | Included, same container |
| Depends on unmerged Tauri PR branch | Yes | No — uses the stable, released bundler for `.deb`, then `quick-sharun` directly |
| `libayatana-appindicator` | Official repo either way (see correction above) | Official repo either way |
| Matches a setup the tool's own maintainer actually runs | No — our own reimplementation | Yes — this is literally their demo repo's pattern |
| Build pipeline shape | `cargo tauri build --bundles appimage,deb,rpm` (all-in-one, same as today) | Split: `cargo tauri build --bundles deb`, then a separate AppDir-assembly + `quick-sharun` step |
| `.deb`/`.rpm` outputs | Native, same command | `.deb` still native; `.rpm` needs separate handling (not shown in the demo — open question) |

## Recommendation

Pilot **Route B** first. It removes the specific thing most likely to be unstable (the unmerged Tauri branch and its own embedded, still-buggy `sharun.rs` integration), gets ARM64 for free from a container actually built for this purpose, and matches what the tool's own author demonstrably runs rather than a reimplementation we'd be maintaining alone. Route A is worth keeping as a fallback note, not a parallel pilot — validating both at once would make it harder to isolate what actually fixed (or didn't fix) the crash.

## Pilot implementation

No changes to this repository were needed for the pilot itself — Route B points directly at `pkgforge-dev`'s own maintained container, so there was no new shared Docker image to build. All pilot changes lived in `emoji-nook`'s workflow, later generalised into the reusable workflow documented in [`../../reference/package-arch-appimage.md`](../../reference/package-arch-appimage.md).

**How the pinned container was chosen and verified:** resolved `ghcr.io/pkgforge-dev/archlinux:latest` to a digest (pinning by digest so it doesn't drift the same way the current `feat/truly-portable-appimage` branch install does), then confirmed via `docker manifest inspect --verbose` that it's a genuine multi-arch index (`amd64`, `arm64`, `armv7`, `riscv64`). Out of curiosity about how `pkgforge-dev` achieves multi-arch when mainline Arch doesn't target ARM at all, extracted `/etc/pacman.conf` and `/etc/pacman.d/mirrorlist` from the `arm64` platform image directly (via `docker create` + `docker cp`, no execution needed since the host can't run foreign-arch binaries without QEMU): it's not exotic at all — the `arm64` platform is literally **Arch Linux ARM (ALARM)**, a standard Docker manifest list where each platform is served by whichever native Arch-family distro exists for that architecture, unified under one tag.

**Validation — complete:**

- Pilot repo: `emoji-nook`, `experiment/arch-quick-sharun-appimage` (this is where the original crash was reproduced). Six iterations to green — see the branch history for the specific bugs hit and fixed (artifact path, icon collision, the `patchelf`/`-Syu` interaction, `OUTPATH`).
- The resulting AppImage was downloaded and run directly on the machine that originally hit the crash. Confirmed: no `EGL_BAD_PARAMETER`, process stable and idle after startup, webview initialised and logged from the app's own JS. The only portal error present (`bind_shortcuts ... Other`) is a pre-existing, separate issue — GNOME can't attribute a GlobalShortcuts request to an ad hoc, unintegrated AppImage run without an installed `.desktop` file, unrelated to this packaging change.
- The `set -m`/tty issue reported upstream on 2026-06-30 is moot for this route since it lives in Tauri's `sharun.rs`, which this route no longer uses, and did not reproduce in `quick-sharun`'s own CLI path under GitHub Actions' non-interactive runners.

## Reusable workflow

Route B was generalised into a `workflow_call` reusable workflow, `package-arch-appimage.yml`, hosted in this repository, rather than each consumer repo copy-pasting the pilot's YAML. Inputs, outputs, usage example, and operational notes are documented in [`../../reference/package-arch-appimage.md`](../../reference/package-arch-appimage.md) — not duplicated here.

## Explicitly deferred, not forgotten

- Pinning `feat/truly-portable-appimage` to a commit SHA, and pre-seeding `quick-sharun.sh` — both moot now that `ci-desktop`'s own build no longer needs that branch for AppImage production. Still relevant if anything else in the shared images depends on that branch; needs a check before closing this out entirely.
- `tauri-dev-desktop` migration — interactive shell only, not urgent.
- Mobile images — out of scope; unaffected by this bug.
- Once the reusable workflow is live in `spindle` and `tauri-plugins-workspace` too, revisit whether `ci-desktop`'s Dockerfile can drop the `feat/truly-portable-appimage` branch install entirely.

## Open questions

- `.rpm` output: still produced by the unchanged `build-linux` job (`--bundles deb,rpm`), untouched by this change. No open question here after all — resolved by construction once the reusable workflow only replaces the AppImage leg, not the whole build.
- Multi-arch validation: the pilot only exercised the `x86_64` leg. The `arm64` container platform (ALARM-backed) is confirmed to exist and be genuinely multi-arch, but hasn't been run end-to-end yet — first real test should happen through the reusable workflow's `runs-on: ubuntu-24.04-arm` matrix leg, not blind.

## References

- Tauri PR: <https://github.com/tauri-apps/tauri/pull/12491>
- `quick-sharun` / `Anylinux-AppImages`: <https://github.com/pkgforge-dev/Anylinux-AppImages>
- Reference demo: <https://github.com/Samueru-sama/tabularis-appimage-demo>
- Setup action: <https://github.com/pkgforge-dev/anylinux-setup-action>
- Related: [`shared-image-layout.md`](../../reference/shared-image-layout.md), [`shared-image-implementation-spec.md`](../../reference/shared-image-implementation-spec.md)
