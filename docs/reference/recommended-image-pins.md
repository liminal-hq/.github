# Recommended Image Pins

The digest to pin each shared image to today. Consumers should reference an image by digest (`image: ghcr.io/liminal-hq/<image>@sha256:<digest>`) so that this repository can update toolchains without changing what their CI runs. See `docs/runbooks/image-publish-and-rollback.md` for the tag policy and why tags alone are not stable pins.

Update this table in the same change whenever a publish is promoted as the new recommended build.

## Current Pins

Last updated: 2026-10-09.

| Image | Digest | Built from | Notes |
| --- | --- | --- | --- |
| `tauri-ci-desktop` | `sha256:80599068a60868d309be1a6c63716df052c0599716e4bb90e01fbc94c7df119f` | `sha-e92450c` (2026-10-06) | Rust 1.96.1, Node 24, pnpm 10.28.2, Bun 1.3.14 |
| `ci-rust` | `sha256:45fc1a5f8698293019d4f60b9953af8f79328316fe8a5d81838b1dc334d99104` | `sha-e92450c` (2026-10-06) | Rust 1.96.1 |
| `ci-web` | `sha256:5cf14c8bb38b28b3e02376e2fad72e0293fcdf06bf06582785b9f49058020df4` | `sha-e92450c` (2026-10-06) | Node 24, pnpm 10.28.2, Bun 1.3.14 |
| `tauri-dev-desktop` | `sha256:36624f836e672cdf72e817315b22af1c97f0778fe7c7da22c6cd640497fd8ecd` | `sha-e92450c` (2026-10-06) | Devcontainer family |
| `tauri-ci-mobile` | `sha256:1deb258a3a7bfceb76048f449aa16ece76b6671212581e6ce4b65e2712e07e59` | `sha-00d0596` (2026-09-14) | Interim: later mobile builds failed until the `sdkmanager` licence fix; replace once the fixed build publishes |
| `tauri-dev-mobile` | `sha256:ae165bc0c818ef4647aa0df75bfa19e111d1a4b7b1a9d263b8d997836c0aa08b` | `sha-00d0596` (2026-09-14) | Interim, as above |

`dev-rust`, `dev-web` and `tauri-dev-windows` have no recommended pin yet; their first pinned digests are recorded here once a consumer adopts them.
