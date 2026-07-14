# Workflows

## `shared-tauri-ci-images.yml`

Builds and publishes the shared `tauri-ci-*`/`tauri-dev-*` container images consumer repos use for Tauri desktop and mobile CI/devcontainers.

- **Triggers:** push to `main` (when `docker/ci/**` or this workflow changes), `workflow_dispatch`, and a weekly `schedule` gated to a two-week publish cadence.
- **Docs:** [`../../docs/reference/shared-image-layout.md`](../../docs/reference/shared-image-layout.md), [`../../docs/reference/shared-image-implementation-spec.md`](../../docs/reference/shared-image-implementation-spec.md), [`../../docs/runbooks/image-publish-and-rollback.md`](../../docs/runbooks/image-publish-and-rollback.md)

## `package-arch-appimage.yml`

Reusable workflow (`workflow_call`) that packages an already-built `.deb` into a Linux AppImage via `quick-sharun` on a pinned Arch container, instead of Tauri's unmerged experimental AppImage bundler. Called from a consumer repo's own release pipeline — not runnable standalone.

- **Trigger:** `workflow_call` only.
- **Docs:** [`../../docs/reference/package-arch-appimage.md`](../../docs/reference/package-arch-appimage.md) (usage, inputs/outputs, example call site) and [`../../docs/proposals/archived/arch-experimental-ci-image.md`](../../docs/proposals/archived/arch-experimental-ci-image.md) (why this approach was chosen)

## `ci-lint.yml`

Quality gate for this repo's own files: `actionlint` (with its built-in shellcheck integration) against workflow YAML, `hadolint` against `docker/ci/Dockerfile`, and `markdownlint-cli2` against all markdown docs. Blocking on PRs.

- **Trigger:** `pull_request`.
- **Config:** `../../.hadolint.yaml` (failure threshold set to `error` — a backlog of pre-existing `warning`-level hadolint findings is intentionally untriaged for now) and `../../.markdownlint.jsonc`. The actionlint step suppresses a fixed set of already-triaged shellcheck codes (SC2129, SC2016, SC2012, SC2046) via `actionlint_flags: -ignore <code>` (no quotes — the action's entrypoint word-splits this value without stripping them), since reviewdog reports every actionlint diagnostic as `error` regardless of shellcheck's own embedded severity.

## `security-audit.yml`

Runs [`zizmor`](https://docs.zizmor.sh/) against this repo's workflows and uploads findings as SARIF to the Security tab.

- **Trigger:** `pull_request` and push to `main`.
- **Non-blocking today:** `continue-on-error: true` on the zizmor step. The existing workflows carry an untriaged backlog of findings (unpinned actions, template-injection-shaped `run:` steps, one overly broad `permissions:` block) — findings are visible in the Security tab, but don't fail the check yet. Remove `continue-on-error` once that backlog is worked through.
