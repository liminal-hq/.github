# Recommended Image Pins

The digest to pin each shared image to today. Consumers should reference an image by digest (`image: ghcr.io/liminal-hq/<image>@sha256:<digest>`) so that this repository can update toolchains without changing what their CI runs. See `docs/runbooks/image-publish-and-rollback.md` for the tag policy and why tags alone are not stable pins.

Update this table in the same change whenever a publish is promoted as the new recommended build.

## Current Pins

Last updated: 2026-10-09. All images are from the `20261009-2d6e4fc` publish, which is the first publish where every image, mobile included, built from `main` since 2026-09-14.

| Image | Digest | Notes |
| --- | --- | --- |
| `tauri-ci-desktop` | `sha256:f35ef8c593216e0135ee3fccd3ae16a7c90d428fd92992db01a0bcff13f1c3ea` | Rust 1.96.1, Node 24, pnpm 10.28.2, Bun 1.3.14 |
| `ci-rust` | `sha256:f12097be8cc22eb5145a46bc9f75b38a67fedd5833add4392e11ce85023e64df` | Rust 1.96.1 |
| `ci-web` | `sha256:0810aefe705cab4486bf1630249a30aa5e2f9295498cf67636bc8fb4ea2bf763` | Node 24, pnpm 10.28.2, Bun 1.3.14 |
| `tauri-ci-mobile` | `sha256:6b6b1a2046b207d2004f01099bd4f8a87c4545c7e657292d2a7cb079df4d824a` | Desktop tier plus JDK 17, Android platform 36, NDK 28.2.13676358 |
| `dev-rust` | `sha256:c96b3e1db91847dcd92c4b6e2ec534e2b31cdf5989aa7cc64bb78fecfe1f780c` | Devcontainer family |
| `dev-web` | `sha256:64978ed423d66decc27d84222f54f969249961dc0ee5b97c49d4d3ae0a14fc63` | Devcontainer family |
| `tauri-dev-desktop` | `sha256:e3fdb3732c5ca77b65e2bc3b76e63230d3384c6d10a75ab3294a7967436f881e` | Devcontainer family |
| `tauri-dev-mobile` | `sha256:eda2ede0b894157a8fa8071187548f15577a4f6d71159fb52a72d9f2b367bdcf` | Devcontainer family |
| `tauri-dev-windows` | `sha256:4eb814f0cc2006c593e8d61c80b33560bf6974f5f30021fdbac632c1e747837f` | Windows cross-compile; the xwin cache is empty and downloaded on first use |
