# Set Up Windows Tooling

This composite action installs a Rust toolchain and optional Bun on a native GitHub Actions Windows runner. It can also restore and save the Cargo cache. It supports x64 and ARM64 runners and does not build, sign or package an application.

Check out the repository before calling the action. Use a reviewed commit SHA as the action ref for a stable CI configuration.

```yaml
steps:
  - uses: actions/checkout@v6.0.3
    with:
      persist-credentials: false
  - uses: liminal-hq/.github/.github/actions/setup-windows@main
    with:
      rust-toolchain: '1.98.0'
      rust-components: clippy,rustfmt
      bun-version: '1.4.4'
  - run: bun install --frozen-lockfile
  - run: cargo test --workspace
```

| Input | Default | Purpose |
| --- | --- | --- |
| `rust-toolchain` | `stable` | Toolchain to install and select for the job. Set an exact version when the project requires one. |
| `rust-targets` | empty | Comma-separated additional Rust targets. The native host target is installed by rustup. |
| `rust-components` | empty | Comma-separated additional Rust components. |
| `bun-version` | empty | Bun version for `oven-sh/setup-bun`; empty skips Bun. |
| `rust-cache` | `true` | Set to `false` to skip Cargo caching. |
| `rust-cache-workspaces` | empty | Workspace mappings passed to `Swatinem/rust-cache`; empty uses its defaults. |

The `rust-toolchain` output reports the rustup toolchain name. The `bun-version` output reports the installed version and is empty when Bun is skipped. The action installs the requested toolchain and sets it as rustup's default; a project's `rust-toolchain.toml` can select a different toolchain. Projects that pin Rust in that file should pass the same version here to ensure the requested targets and components are installed for the toolchain they use. Restore the cache after checkout and before building; configure runner permissions according to the caller's needs.

The action requires a native Windows runner and fails on other operating systems. The Linux-based `tauri-dev-windows` image serves a different use case: cross-compilation from Linux.
