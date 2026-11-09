# Recommended Image Pins

The digest to pin each shared image to today. Consumers should reference an image by digest (`image: ghcr.io/liminal-hq/<image>@sha256:<digest>`) so that this repository can update toolchains without changing what their CI runs. See `docs/runbooks/image-publish-and-rollback.md` for the tag policy and why tags alone are not stable pins.

Update this table in the same change whenever a publish is promoted as the new recommended build.

## Current Pins

Last updated: 2026-11-09. All images are from the `20261109-c22e7c8` publish. The preceding `20261109-5cb26d7` publish remains available as a fallback.

| Image | Digest | Notes |
| --- | --- | --- |
| `tauri-ci-desktop` | `sha256:e581c02c5239ea7e72c60289aea8ba587f0436a427630b1b7df38317879da45a` | Rust 1.98.0, Node 24.22.2, pnpm 10.32.1, Bun 1.4.4 |
| `ci-rust` | `sha256:cd15133f73b5937459f456f4c73ec914229dd0872ede5987105545d2e272074f` | Rust 1.98.0 |
| `ci-web` | `sha256:fb5497b9492801581d728f5a17ad6d489b8797826cd3e1cd42b1af3c40b5c449` | Node 24.22.2, pnpm 10.32.1, Bun 1.4.4 |
| `ci-dos` | `sha256:17537ff37796132ccd1f803c93880c85677b05df2f34d6304e5198ae7ba956e1` | Rust 1.98.0, DJGPP 12.2, DOSBox Staging 0.83, CWSDPMI, Bun 1.4.4 |
| `tauri-ci-mobile` | `sha256:8c1669fc8eb38a1461cf3ee46964a43cfc73aae17cc9f3eac18d730960dcc0eb` | Desktop tier plus JDK 17, Android platform 36, build-tools 37.0.0 and NDK 30.0.16248370; build-tools 36.0.0 and NDK 28.2.13676358 also installed |
| `dev-rust` | `sha256:a40f5ad0f871fd54c3b5f2bce3664b263c14fa9eb95187b94b874e41ee9d6cec` | Devcontainer family |
| `dev-web` | `sha256:f63672308c99541db352a959357ed773226aa7691763b6c6fa93140bd8ff98ed` | Devcontainer family |
| `tauri-dev-desktop` | `sha256:8234294d3116bf5be36700bf75cc641bf93b3dd301029224538271d25f532192` | Devcontainer family |
| `tauri-dev-mobile` | `sha256:f75826d2c1f63d105b33e928832c6d71462c64617e461642da94c6ca1c63e9dc` | Devcontainer family; Android platform 36, build-tools 37.0.0 and NDK 30.0.16248370, with the previous build-tools and NDK also installed |
| `tauri-dev-windows` | `sha256:da3e56c70d683b6c60f05ceb8cdffbfe374a34ca3ea9bae54a970cfbe2e18742` | Windows cross-compile; the xwin cache is empty and downloaded on first use |
