# Shared Image Layout

This repository publishes two related Tauri image families:

1. CI images for automated pipelines
2. Dev images for devcontainers and interactive local development

## Published Images

| Image | Docker target | Primary use |
| --- | --- | --- |
| `ghcr.io/liminal-hq/tauri-ci-desktop` | `ci-desktop` | Desktop CI jobs |
| `ghcr.io/liminal-hq/tauri-ci-mobile` | `ci-mobile` | Android/mobile CI jobs |
| `ghcr.io/liminal-hq/tauri-dev-desktop` | `dev-desktop` | Desktop devcontainers |
| `ghcr.io/liminal-hq/tauri-dev-mobile` | `dev-mobile` | Android/mobile devcontainers |

## Platform Coverage

| Image | Platforms | Notes |
| --- | --- | --- |
| `ghcr.io/liminal-hq/tauri-ci-desktop` | `linux/amd64`, `linux/arm64` | Multi-arch because downstream Linux desktop release jobs already run on both x64 and ARM runners. |
| `ghcr.io/liminal-hq/tauri-ci-mobile` | `linux/amd64` | ARM is not part of the current shared mobile CI contract. |
| `ghcr.io/liminal-hq/tauri-dev-desktop` | `linux/amd64` | Devcontainer ARM support is a possible follow-up, not a current baseline. |
| `ghcr.io/liminal-hq/tauri-dev-mobile` | `linux/amd64` | Devcontainer ARM support is a possible follow-up, not a current baseline. |

Only the desktop CI image is multi-arch today. Consumers that need Linux ARM should use `tauri-ci-desktop` and should not assume ARM variants exist for the mobile or dev image families.

## Design Intent

### CI Images

- Keep them lean and predictable
- Keep them suitable for root-friendly automation
- Preserve the existing CI contract for shared consumers

### Dev Images

- Use a devcontainer-friendly base image
- Default to a non-root user model
- Put writable tool paths under the user home
- Reduce repo-local overrides for Cargo, Rustup, pnpm, and Android SDK paths

## Expected Environment Model

### CI Images

- `CARGO_HOME=/usr/local/cargo`
- `RUSTUP_HOME=/usr/local/rustup`
- mobile images install Android tooling under `/opt/android-sdk`

### Dev Images

- `HOME=/home/vscode`
- `CARGO_HOME=$HOME/.cargo`
- `RUSTUP_HOME=$HOME/.rustup`
- `PNPM_HOME=$HOME/.local/share/pnpm`
- mobile images install Android tooling under `$HOME/Android/Sdk`

## Layout Rules

1. Keep version pins aligned across CI and dev image families.
2. Keep final CI targets clearly named with the `ci-` prefix.
3. Keep final dev targets clearly named with the `dev-` prefix.
4. Keep emulator tooling out of the shared mobile dev image unless a real consumer need appears.
5. Prefer shared intermediate stages where that does not compromise CI or dev ergonomics.

## Validation Expectations

Every published image should be smoke-validated for:

- core tool availability: `cargo`, `rustup`, `node`, `pnpm`, `cargo-tauri`
- Android tooling on mobile images
- writable user-home paths on dev images
- expected environment variables for the image family
- expected platform coverage for the image family, especially the `linux/arm64` variant on `tauri-ci-desktop`

## Related Docs

- Implementation spec: [`shared-image-implementation-spec.md`](./shared-image-implementation-spec.md)
- Publish and rollback runbook: [`../runbooks/image-publish-and-rollback.md`](../runbooks/image-publish-and-rollback.md)
