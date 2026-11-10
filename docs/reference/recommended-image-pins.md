# Recommended Image Pins

The digest to pin each shared image to today. Consumers should reference an image by digest (`image: ghcr.io/liminal-hq/<image>@sha256:<digest>`) so that this repository can update toolchains without changing what their CI runs. See `docs/runbooks/image-publish-and-rollback.md` for the tag policy and why tags alone are not stable pins.

Update this table in the same change whenever a publish is promoted as the new recommended build.

## Updating the Pins

1. Publish the new images (see `docs/runbooks/image-publish-and-rollback.md`) and read each image's digest from the `Digest` line in the workflow's step summary.
2. After the publish is checked and promoted as the recommended build, update the table below with the new digests, the tool versions in the notes, the `Last updated` date and the fallback publish, in one change. Never enter a digest that was not read from a completed publish.

## Current Pins

Last updated: 2026-11-10. All images except `tauri-ci-mobile` are from the `20261110-5bd2ede` publish; `tauri-ci-mobile` is still the `20261109-c22e7c8` build and moves when its publish completes. The `20261109-c22e7c8` publish remains available as a fallback.

| Image | Digest | Notes |
| --- | --- | --- |
| `tauri-ci-desktop` | `sha256:553180813ab6078f116ec456326629b29bf6af9eb167ce9bc6007fa64f3f8097` | Rust 1.98.0 with the `wasm32-unknown-unknown` target, `wasm-bindgen-cli` 0.2.125, Node 24.22.2, pnpm 10.32.1, Bun 1.4.4 |
| `ci-rust` | `sha256:0ef31efa5876407765cd5572a23323932183a5357eaac92eee67d79657d45c02` | Rust 1.98.0, cargo-deny |
| `ci-web` | `sha256:43db6bd804c801fda46586e6978407240dc5dd3509f85482a29d71ab87e49b5d` | Node 24.22.2, pnpm 10.32.1, Bun 1.4.4 |
| `ci-dos` | `sha256:6b8c6308baaa4d05ee0f1af25512bece544ef79bbe653c31c7b5cab54ff52e2a` | Rust 1.98.0, DJGPP 12.2, DOSBox Staging 0.83, CWSDPMI, Bun 1.4.4 |
| `tauri-ci-mobile` | `sha256:8c1669fc8eb38a1461cf3ee46964a43cfc73aae17cc9f3eac18d730960dcc0eb` | Desktop tier plus JDK 17, Android platform 36, build-tools 37.0.0 and NDK 30.0.16248370; build-tools 36.0.0 and NDK 28.2.13676358 also installed |
| `dev-rust` | `sha256:17b19e20d1726b8ebc36a7c5a706c2f8b8c0fc6950b784638a37c69b7faab95d` | Devcontainer family |
| `dev-web` | `sha256:084216037a867ebd5d43e58a97427aa8692550adfb448f7fce656cd2c52bf355` | Devcontainer family |
| `tauri-dev-desktop` | `sha256:2593d8c41b47a94db521dc3706047010aa576ec3871badf869eeb2920fd94ed1` | Devcontainer family |
| `tauri-dev-mobile` | `sha256:b375eb1336cf2f847fb8b2a1fdbff99d59c3b7dbd16a6858afa76450dc42a276` | Devcontainer family; Android platform 36, build-tools 37.0.0 and NDK 30.0.16248370, with the previous build-tools and NDK also installed |
| `tauri-dev-windows` | `sha256:12ef221970fa9165ac87663febdc710ee4c167daddcfcd47ff9b0b70f9ed1bce` | Windows cross-compile; the xwin cache is empty and downloaded on first use |
