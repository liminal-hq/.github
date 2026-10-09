# Recommended Image Pins

The digest to pin each shared image to today. Consumers should reference an image by digest (`image: ghcr.io/liminal-hq/<image>@sha256:<digest>`) so that this repository can update toolchains without changing what their CI runs. See `docs/runbooks/image-publish-and-rollback.md` for the tag policy and why tags alone are not stable pins.

Update this table in the same change whenever a publish is promoted as the new recommended build.

## Current Pins

Last updated: 2026-10-09. All images are from the `20261009-f0da749` publish, the first with Rust 1.98.0 and pnpm 10.32.1. The previous publish (`20261009-2d6e4fc`, Rust 1.96.1, pnpm 10.28.2) remains available by its dated tag as the fallback.

| Image | Digest | Notes |
| --- | --- | --- |
| `tauri-ci-desktop` | `sha256:c527f63db992593c30d419be0dbb2b91cc27646c33a1f83b30d683da771cf6df` | Rust 1.98.0, Node 24, pnpm 10.32.1, Bun 1.3.14 |
| `ci-rust` | `sha256:052e029f1eaccb837cb16c0262ebc2df1789e31a3ab574074f2ae35b0979c9af` | Rust 1.98.0 |
| `ci-web` | `sha256:d8f1aea50550b444f6fbbf90d36c80086cd68d361cf5cbfbd7ad7c3b90a9d1a9` | Node 24, pnpm 10.32.1, Bun 1.3.14 |
| `tauri-ci-mobile` | `sha256:791f523db56a5bc3bf6ca02ff28f3b961a2f4d13fc44320434017d98e8e8ada0` | Desktop tier plus JDK 17, Android platform 36, NDK 28.2.13676358 |
| `dev-rust` | `sha256:7a4ea0db70a45014e75656dd8fb27252bcecbc348c64957be038c7ff4681bf2b` | Devcontainer family |
| `dev-web` | `sha256:5e5d2c8b2ef7e195760f2cb5c8b4f301c3117e0bdb4ba064ecb26aab35bea4e5` | Devcontainer family |
| `tauri-dev-desktop` | `sha256:3e67ccbbf61e50aa7dab6a15e48e42c1a69fb8d3428c071adbb255bf64ac7562` | Devcontainer family |
| `tauri-dev-mobile` | `sha256:bb3d4be7be03c2aebf94424afb20a7f674426284bdcdee0232b1c349bfe19640` | Devcontainer family |
| `tauri-dev-windows` | `sha256:d5beb4180968584a024799295904166466c40f5ee4a97ef70ac20178bb851d6e` | Windows cross-compile; the xwin cache is empty and downloaded on first use |
