# Workflows

## `shared-tauri-ci-images.yml`

Builds and publishes the shared `tauri-ci-*`/`tauri-dev-*` container images consumer repos use for Tauri desktop and mobile CI/devcontainers.

- **Triggers:** push to `main` (when `docker/ci/**` or this workflow changes), `workflow_dispatch`, and a weekly `schedule` gated to a two-week publish cadence.
- **Docs:** [`../../docs/reference/shared-image-layout.md`](../../docs/reference/shared-image-layout.md), [`../../docs/reference/shared-image-implementation-spec.md`](../../docs/reference/shared-image-implementation-spec.md), [`../../docs/runbooks/image-publish-and-rollback.md`](../../docs/runbooks/image-publish-and-rollback.md)

## `package-arch-appimage.yml`

Reusable workflow (`workflow_call`) that packages an already-built `.deb` into a Linux AppImage via `quick-sharun` on a pinned Arch container, instead of Tauri's unmerged experimental AppImage bundler. Called from a consumer repo's own release pipeline — not runnable standalone.

- **Trigger:** `workflow_call` only.
- **Docs:** [`../../docs/reference/package-arch-appimage.md`](../../docs/reference/package-arch-appimage.md) (usage, inputs/outputs, example call site) and [`../../docs/proposals/archived/arch-experimental-ci-image.md`](../../docs/proposals/archived/arch-experimental-ci-image.md) (why this approach was chosen)
