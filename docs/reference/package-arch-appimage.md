# Package Arch AppImage (reusable workflow)

`package-arch-appimage.yml` is a `workflow_call` reusable workflow that packages an already-built `.deb` into a Linux AppImage using `quick-sharun` on a pinned, purpose-built Arch Linux container, instead of Tauri's unmerged `feat/truly-portable-appimage` experimental branch. Consumer repos call it from their own release pipeline rather than reimplementing the packaging steps.

It is packaging-only: it does not build the `.deb` itself. The calling repo builds that as part of its own existing release job (with the stable, released `tauri-cli` — no experimental branch needed) and passes it in as an artifact.

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `deb-artifact-name` | Yes | — | Name of an already-uploaded artifact containing the `.deb` to package. |
| `runs-on` | No | `ubuntu-24.04` | Runner label. Matrix this at the call site for multi-arch (e.g. `ubuntu-24.04-arm`) against the same pinned, multi-arch container. |
| `app-version` | No | `''` | Version string used in the output AppImage filename. |
| `extra-pacman-packages` | No | `webkit2gtk-4.1 gtk3 libayatana-appindicator patchelf` | Space-separated official-repo packages the app needs beyond the shared baseline `anylinux-setup-action` already installs. |
| `extra-aur-packages` | No | `''` | Space-separated AUR packages, built via `make-aur-package`, for the rare case a dependency isn't in the official repos. |
| `arch-container-digest` | No | pinned digest, see workflow file | `ghcr.io/pkgforge-dev/archlinux` digest. Bump centrally here rather than per consumer repo. |

## Outputs

| Output | Description |
| --- | --- |
| `artifact-name` | Name of the uploaded AppImage artifact (`appimage-<runs-on>`), for the caller to download. |

## Usage

```yaml
jobs:
  package-appimage:
    needs: build-linux
    strategy:
      matrix:
        include:
          - runner: ubuntu-24.04
            deb-artifact: linux-release-assets-x64
          - runner: ubuntu-24.04-arm
            deb-artifact: linux-release-assets-arm64
    uses: liminal-hq/.github/.github/workflows/package-arch-appimage.yml@main
    with:
      runs-on: ${{ matrix.runner }}
      deb-artifact-name: ${{ matrix.deb-artifact }}
      app-version: ${{ needs.prepare-release.outputs.release_version }}
    secrets: inherit
```

On the caller's existing build job: drop `appimage` from the `tauri build --bundles` list (leave `deb`, and `rpm` if wanted) and drop `TAURI_BUNDLER_NEW_APPIMAGE_FORMAT` — AppImage production moves entirely to this workflow, so that build no longer touches the experimental Tauri branch at all.

## What it does

1. Downloads the `.deb` artifact and extracts it (`ar`, `tar`) into an `AppDir` matching Tauri's own `debian.rs` bundler layout.
2. Installs the app's runtime dependencies via `pacman`/`make-aur-package`.
3. Runs `quick-sharun` to deploy every shared library and runtime data file (fonts, GLib schemas, MIME data, X11 locale data, GLVND EGL vendor config, etc.) the app needs, patch hardcoded paths via `patchelf`, and wrap helper binaries.
4. Builds the AppImage as a DWARFS filesystem image via `quick-sharun --make-appimage`.
5. Smoke-tests the result under `xvfb-run` via `quick-sharun --test`.
6. Uploads the AppImage as an artifact and writes a step summary (packages installed, test outcome, artifact size).

## Operational notes

- **Don't re-run a full `pacman -Syu` after `anylinux-setup-action`.** The setup action already does one. Running it again immediately after was observed knocking `patchelf` out of the environment during development, breaking `quick-sharun` with `Missing dependency 'patchelf'!`. Use `pacman -S --noconfirm --needed` for anything extra instead.
- **Set `OUTPATH`.** `quick-sharun` writes the AppImage into the current working directory if `OUTPATH` isn't set, not a `dist/` subdirectory — this workflow sets `OUTPATH=./dist` explicitly.
- **Pick one icon, don't glob.** Tauri's `.deb` bundler ships multiple icon resolutions under the same basename. Copying them all into `AppDir/` in one `cp` invocation hits `cp`'s just-created-file overwrite guard. This workflow picks the largest via a version-sorted `find` instead.
- **`libayatana-appindicator3`'s Arch package is `libayatana-appindicator`**, in the official `extra` repo — not `libappindicator-gtk3`, which doesn't exist on Arch under that name at all (cloning it from the AUR silently produces an empty repository rather than a clear error).

## Design intent

- **Packaging-only, deliberately.** Building the `.deb` inside this workflow too would mean recompiling the same Rust project a second time per release; consumer repos already do that build as part of their own pipeline.
- **Pinned by digest, not tag.** `ghcr.io/pkgforge-dev/archlinux:latest` floats; every consumer pinning the same digest, bumped in one place, keeps this reproducible.
- **Arch, not Ubuntu.** `quick-sharun` is built and tested primarily for Arch by its own maintainer. See the decision record below for why this route was chosen over hand-rolling an Arch image around Tauri's own experimental bundler.

## Related docs

- Decision record and pilot history (archived): [`../proposals/archived/arch-experimental-ci-image.md`](../proposals/archived/arch-experimental-ci-image.md)
- Shared image layout: [`shared-image-layout.md`](./shared-image-layout.md)
- Shared image implementation spec: [`shared-image-implementation-spec.md`](./shared-image-implementation-spec.md)
