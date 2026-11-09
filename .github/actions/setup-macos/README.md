# Set Up macOS Tooling

This composite action sets up the shared image baseline on a native macOS runner. It reads the exact Bun and Rust versions from `docker/ci/Dockerfile` in the same revision as the action, installs both Apple Rust targets, and can restore and save the Cargo cache. The caller owns checkout, dependency installation, frontend builds, signing, packaging and artefact upload.

Check out the consumer repository before calling the action. Pin the action to a reviewed commit SHA to keep its versions and behaviour stable; update the ref when adopting a newer shared baseline.

```yaml
steps:
  - uses: actions/checkout@v6.0.3
    with:
      persist-credentials: false
  - uses: liminal-hq/.github/.github/actions/setup-macos@main
    with:
      rust-extra-targets: wasm32-unknown-unknown
      rust-cache-workspaces: |
        .
        apps/player/src-tauri
  - run: bun install --frozen-lockfile
```

The workspace list above is appropriate for a repository with separate root and Tauri app workspaces. For a single Cargo workspace, omit it and let `Swatinem/rust-cache` detect the workspace. Paths are relative to the caller's workspace.

| Input | Default | Purpose |
| --- | --- | --- |
| `install-bun` | `true` | Set to `false` to skip Bun installation. |
| `install-rust` | `true` | Set to `false` to skip Rust installation and caching. |
| `rust-extra-targets` | empty | Comma-separated targets to install alongside `aarch64-apple-darwin` and `x86_64-apple-darwin`. |
| `rust-cache` | `true` | Set to `false` to skip Cargo caching. |
| `rust-cache-workspaces` | empty | Workspace mappings passed to `Swatinem/rust-cache`; empty uses its defaults. |

The `bun-version` and `rust-toolchain` outputs report the versions in the shared baseline, including when installation of a tool is skipped. When Rust is enabled, the action sets `RUSTUP_TOOLCHAIN` for subsequent job steps to select the shared version, even if a repository's `rust-toolchain.toml` selects another version. List any additional targets required by that file, such as `wasm32-unknown-unknown`, in `rust-extra-targets`.

This action requires a native macOS runner. It does not configure ad-hoc signing, Developer ID signing or notarisation; continue to use the app's existing signing configuration.
