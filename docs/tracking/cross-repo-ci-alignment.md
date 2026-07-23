# Cross-repo CI Alignment Tracker

## Waves

- [x] Wave 0: Baseline and decision lock
- [x] Wave 1: Shared image production in `liminal-hq/.github`
- [x] Wave 2: `tauri-plugins-workspace` migration
- [x] Wave 3: `spindle` migration
- [x] Wave 4: `emoji-nook` migration
- [x] Wave 5: `foyer` migration
- [x] Wave 6: `threshold` migration
- [ ] Wave 7: `liminal-notes` migration
- [ ] Wave 8: Cross-repo normalisation
- [ ] Wave 9: Granular tier rollout (`ci-rust` / `ci-web` / Bun-in-Tauri-images; see liminal-hq/.github#22)

## Granular Tier Adoption Targets (issue #22)

- [ ] `liminal-hq/flow` → `ci-rust`
- [ ] `liminal-hq/flicker` → `ci-rust`
- [ ] `liminal-hq/libhdmv` → `ci-rust`
- [ ] `liminal-hq/libvc1` → `ci-rust` (CI) and `dev-rust` (local toolchain container)
- [ ] `liminal-hq/mudroom` → `ci-rust` (no CI today; adopt when CI is added)
- [ ] `liminal-hq/smdu` → `ci-web` (Linux jobs)
- [ ] `liminal-hq/coherence-chat-exporter` → `ci-web` (Linux jobs)
- [ ] `liminal-hq/the-lab` → `ci-web`
- [ ] `liminal-hq/liminal-hq.github.io` → `ci-web`
- [ ] `liminal-hq/foyer` → drop per-run Bun install (Bun now in `tauri-ci-mobile`)
- [ ] `liminal-hq/threshold` → move desktop jobs into `tauri-ci-desktop` (GStreamer/xvfb/fonts now included)
- [ ] `ScottMorris/city-sim-1000` → `tauri-ci-desktop` (drops per-run webkit apt installs)

## Repositories

- [x] `liminal-hq/tauri-plugins-workspace` — `ci.yml` consumes `tauri-ci-desktop:latest`
- [x] `liminal-hq/spindle` — `ci.yml` and `release.yml` consume `tauri-ci-desktop:latest`
- [x] `liminal-hq/emoji-nook` — `ci.yml` and `release.yml` consume `tauri-ci-desktop:latest`
- [x] `liminal-hq/foyer` — `test.yml` consumes `tauri-ci-mobile:latest`
- [x] `liminal-hq/threshold` — `test.yml` and `release-build.yml` consume `tauri-ci-mobile:latest`
- [ ] `ScottMorris/liminal-notes` — still maintains its own parallel `build-ci-images.yml`; has not adopted the shared images

## Monthly Alignment Notes

| Date | Versions | Drift | Actions |
| --- | --- | --- | --- |
| 2026-03-08 | Node 24.14.0, Rust 1.93.0, Java 17, Android 36 / NDK 28.2.13676358 | Initial baseline | Bootstrap shared infra |
| 2026-03-15 | Node 24.14.0, Rust 1.93.0, Java 17, Android 36 / NDK 28.2.13676358 | Baseline active; dev image split in progress on implementation branch | Close stale bootstrap issues, keep rollout tracker active, begin CI/dev image family split |
| 2026-07-14 | Node 24 (patch unpinned), pnpm 10.28.2, Rust 1.96.1, Java 17, Android 36 / NDK 28.2.13676358 | Rust bumped 1.93.0 → 1.96.1 since last note; four-month gap in this table with no monthly update in between. Audit found `tauri-plugins-workspace`, `spindle`, `emoji-nook`, `foyer`, and `threshold` already consuming the shared images — ahead of what the wave checklist previously showed. `liminal-notes` confirmed still on its own parallel image-build workflow, not the shared images. All five migrated consumers pin to the `:latest` tag rather than a versioned tag. | Decide whether `liminal-notes`'s parallel infra is an intentional divergence or outstanding migration work; consider whether consumers should pin a versioned image tag instead of `:latest`; resume monthly cadence on this table |
