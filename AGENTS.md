# AGENTS.md

## Purpose

This repository is the shared home for Liminal HQ GitHub infrastructure, including reusable CI image pipelines, shared container definitions, and supporting runbooks and tracking documents.

## Coding Standards

- **Spelling:** Use Canadian English for comments, documentation, commit messages, and pull request descriptions unless exact external spelling is required by tooling, APIs, platform interfaces, or published identifiers.
- **Naming:** Keep public names outcome-focused and readable. Prefer clear infrastructure terms like `shared image`, `publish workflow`, `rollback`, and `devcontainer` over internal planning shorthand.

## Repository Layout

- `.github/workflows/`: shared GitHub Actions workflows for image publication and related automation
- `docker/ci/`: shared Docker definitions for CI and dev image families
- `docs/runbooks/`: operational runbooks such as publish and rollback guidance
- `docs/reference/`: stable reference documentation for image layout and other shared contracts
- `docs/tracking/`: cross-repository tracking documents and rollout status
- `assets/`: authored visual assets used by repository documentation
- `profile/`: organisation profile content surfaced by GitHub

## Commit Messages

**Requirement:** Use Conventional Commits format (for example: `feat: ...`, `fix: ...`, `docs: ...`, `test: ...`, `ci: ...`, `build: ...`).

- Use `test:` for test-related changes, including changes that only fix tests.
- Use `ci:` or `build:` when the primary change is workflow or image-pipeline behaviour.
- Keep each commit focused on the specific unit of work completed in that commit.

Body requirements:

- Explain what changed and why.
- Use markdown where helpful: `code`, **bold**, and flat bullets.
- Do not use markdown headings inside commit bodies.
- Prefer short labelled paragraphs or bullet groups when a commit touches multiple related areas.

Shell safety:

- Do not pass markdown-heavy commit bodies directly through `git commit -m "..."` when they contain backticks, `$()`, or other shell-sensitive characters.
- Prefer writing the message to a file and committing with `git commit -F <file>`.
- If using `-m`, escape shell-sensitive characters explicitly.
- Verify the stored commit message with `git log -1 --pretty=fuller` and amend immediately if shell interpolation altered it.

## Pull Request Titles

**Requirement:** PR titles must be human-readable summaries of the behavioural or operational change.

- Start with a capital letter.
- Do not use Conventional Commit prefixes in PR titles.
- Describe the outcome or contract change, not internal implementation process.
- Keep title style consistent across related PRs in the same stack.
- Do not mention internal planning documents, local worksheet names, or internal-only process artefacts in PR titles.

## Pull Request Content

**Requirement:** Pull request descriptions should explain the repo-facing outcome clearly and follow the established Liminal HQ structure.

Use this default structure:

- `## Summary`
- optional `### User-facing changes`
- optional `### Maintainer-facing changes`
- optional `### Packaging`
- optional `### Workflow and infrastructure`
- optional `### Documentation`
- optional `### Known limitations`
- `## Test plan`

Formatting rules:

- Under `## Summary`, use flat bullets with **bold** lead-ins for scanability.
- Use `###` subsections only when they help separate materially different kinds of changes.
- Keep the summary focused on behaviour, operational impact, and contract changes rather than commit chronology.
- Under `## Test plan`, use checklist bullets (`- [x]` / `- [ ]`) with concrete commands, validations, or explicit gaps.
- If verification is incomplete, say so plainly in `## Test plan`.
- Do not mention local planning files, internal queue notes, or other workflow-only artefacts unless explicitly requested by the user.

## Pull Request Labels

**Requirement:** Every PR must include at least one primary category label and any useful scope labels.

Primary categories:

- `enhancement`
- `bug`
- `documentation`
- `testing`
- `ci`
- `build`
- `chore`

Helpful scope and operational labels for this repo may include:

- `infrastructure`
- `docker`
- `developer-experience`
- `security`
- `tauri`
- `release`
- `internal`
- `skip-changelog`

Keep labels accurate as the PR scope changes.

## Git Workflow

- Do not push or force-push unless explicitly requested by the user.
- Use focused commits with clear messages that describe the now, not the whole branch history.
- When a task naturally splits into implementation, validation, and docs work, prefer separate contextual commits.
- Do not commit local planning or scratch files unless the user explicitly asks for them to become part of the repository.

## Testing

- Always verify relevant changes before considering the work complete.
- For workflow-only changes, at minimum validate YAML syntax locally.
- For Docker/image changes, prefer building the affected targets locally when feasible.
- For shared image changes, call out exactly which targets were built and which were not.
- If a full end-to-end GitHub Actions run was not executed, say so clearly.
- If verification is blocked by environment limits or long-running external toolchains, state the current verification status explicitly.

## Documentation

- When shared image names, Docker targets, workflow behaviour, or operational contracts change, update the relevant repo docs in the same branch.
- Keep README, runbooks, and reference documents aligned with the actual workflow and Docker layout.
- Prefer adding stable reference docs for cross-repo contracts instead of burying important behaviour only in workflow YAML or issue threads.

## Project Structure

- This is an infrastructure repository, not an application runtime repository.
- The most important public contracts are:
  - published image names
  - Docker target names
  - workflow trigger and cadence behaviour
  - smoke-check and rollback expectations
- Changes here should be evaluated for downstream impact on consumer repos that depend on shared images or automation.

## Licence and Copyright

- **Requirement:** New source-like files should include a short header when that is already the pattern for the relevant file type in the repo.
- **Applies to:** authored source files and scripts where the repository already follows that convention.
- **Do not add headers to:** markdown docs, workflow YAML files, JSON files, lockfiles, generated files, or other config-only files unless the repository later adopts a broader rule.
