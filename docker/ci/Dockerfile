ARG UBUNTU_VERSION=24.04
ARG DEVCONTAINER_BASE_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu-24.04
ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=24
ARG PNPM_VERSION=10.28.2
ARG BUN_VERSION=1.3.14
ARG RUST_TOOLCHAIN=1.96.1
ARG ANDROID_CMDLINE_TOOLS=11076708
ARG ANDROID_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK=28.2.13676358

# CI base: universal CLI tooling shared by every CI image tier.
# GUI/Tauri system libraries intentionally live in the desktop tier, not here,
# so lean tiers (ci-rust, ci-web) never inherit them.
FROM ubuntu:${UBUNTU_VERSION} AS ci-base

ARG DEBIAN_FRONTEND

# Install GitHub CLI from the official GitHub package repository so shared images
# track the supported upstream release channel instead of the distro package lag.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget \
    && mkdir -p -m 755 /etc/apt/keyrings /etc/apt/sources.list.d \
    && wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg \
      https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    git gh file build-essential pkg-config zip unzip \
    && rm -rf /var/lib/apt/lists/*

# CI Rust tier: pinned Rust toolchain and Rust QA tooling on the universal base.
# Published as ghcr.io/liminal-hq/ci-rust for pure-Rust consumers.
FROM ci-base AS ci-rust

ARG RUST_TOOLCHAIN

# Rust toolchain paths for root-friendly CI usage.
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:${PATH}

# Rust toolchain and lint/format components used by CI gates.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain "${RUST_TOOLCHAIN}" --no-modify-path \
    && rustup component add clippy rustfmt \
    && cargo install cargo-nextest --locked

# CI web tier: pinned Node, pnpm, and Bun on the universal base.
# Published as ghcr.io/liminal-hq/ci-web for JS/TS-only consumers.
# Bun ships alongside Node/pnpm because consumer repos mix runtimes
# (pnpm or npm for dependencies, Bun for compiled release binaries).
FROM ci-base AS ci-web

ARG DEBIAN_FRONTEND
ARG NODE_MAJOR
ARG PNPM_VERSION
ARG BUN_VERSION

# Node + pnpm baseline pinned for workspace consistency.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "pnpm@${PNPM_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# Bun pinned for root-friendly CI usage.
ENV BUN_INSTALL=/usr/local/bun \
    PATH=/usr/local/bun/bin:${PATH}

RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v${BUN_VERSION}"

# Final CI desktop image: Tauri desktop toolchain on the Rust tier.
# Adds the JS runtimes (same pins as ci-web), the GTK/webkit system stack,
# and GStreamer/xvfb/emoji fonts so desktop test jobs need no host apt installs.
FROM ci-rust AS ci-desktop

ARG DEBIAN_FRONTEND
ARG NODE_MAJOR
ARG PNPM_VERSION
ARG BUN_VERSION

# Tauri desktop system dependencies, kept at this tier so lean images stay lean.
RUN apt-get update && apt-get install -y --no-install-recommends \
    patchelf libssl-dev libglib2.0-dev libgtk-3-dev libwebkit2gtk-4.1-dev \
    libayatana-appindicator3-dev librsvg2-dev xdg-utils \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-bad fonts-noto-color-emoji \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# Node + pnpm baseline pinned for workspace consistency.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "pnpm@${PNPM_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# Bun pinned for root-friendly CI usage.
ENV BUN_INSTALL=/usr/local/bun \
    PATH=/usr/local/bun/bin:${PATH}

RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v${BUN_VERSION}"

# Keep parity with existing app repos for portable AppImage behaviour.
RUN cargo install tauri-cli \
    --git https://github.com/tauri-apps/tauri \
    --branch feat/truly-portable-appimage \
    --force

# Ensures portable AppImage behaviour matches existing repo expectations.
ENV TAURI_BUNDLER_NEW_APPIMAGE_FORMAT=true

# Final CI mobile image.
FROM ci-desktop AS ci-mobile

ARG DEBIAN_FRONTEND
ARG ANDROID_CMDLINE_TOOLS
ARG ANDROID_PLATFORM
ARG ANDROID_BUILD_TOOLS
ARG ANDROID_NDK

# Mobile CI target extends the desktop toolchain with Java + Android SDK/NDK.
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Android environment for root-friendly CI usage.
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS}:${PATH}

# Android command-line tools install (sdkmanager).
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && cd "${ANDROID_HOME}/cmdline-tools" \
    && wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
    && unzip -q "commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
    && rm "commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
    && mv cmdline-tools latest

# Pin Android platform/build-tools/NDK to the shared CI baseline.
RUN yes | sdkmanager --licenses \
    && sdkmanager --channel=0 --install \
      "platform-tools" \
      "platforms;android-${ANDROID_PLATFORM}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" \
      "ndk;${ANDROID_NDK}" \
    && rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android \
    && rm -rf "${ANDROID_HOME}/cmdline-tools/latest/.downloadIntermediates"

# Dev base: universal interactive tooling on the devcontainer base image.
# GUI/Tauri system libraries intentionally live in the dev desktop tier, not here.
FROM ${DEVCONTAINER_BASE_IMAGE} AS dev-base

ARG DEBIAN_FRONTEND

ENV TZ=America/Toronto \
    EDITOR=vim

# Align devcontainers with the expected studio timezone by default.
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

# Universal CLI tooling plus interactive quality-of-life packages
# (editor, fast search, JSON inspection) for toolbox-style container use.
# Install GitHub CLI from the official GitHub package repository so devcontainers
# get the supported upstream release channel for interactive GitHub workflows.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget \
    && mkdir -p -m 755 /etc/apt/keyrings /etc/apt/sources.list.d \
    && wget -nv -O /etc/apt/keyrings/githubcli-archive-keyring.gpg \
      https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    git gh file build-essential pkg-config zip unzip \
    vim ripgrep fd-find jq \
    && ln -s "$(command -v fdfind)" /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Dev Rust tier: pinned Rust toolchain under the devcontainer user home.
# Published as ghcr.io/liminal-hq/dev-rust for pure-Rust devcontainers and
# host-side toolbox use.
FROM dev-base AS dev-rust

ARG RUST_TOOLCHAIN

# Tool paths live under the non-root user home for a smoother devcontainer DX.
ENV HOME=/home/vscode \
    RUSTUP_HOME=/home/vscode/.rustup \
    CARGO_HOME=/home/vscode/.cargo \
    PATH=/home/vscode/.cargo/bin:${PATH}

# Pre-create writable directories before switching to the devcontainer user.
RUN mkdir -p "${RUSTUP_HOME}" "${CARGO_HOME}" \
    && chown -R vscode:vscode "${RUSTUP_HOME}" "${CARGO_HOME}"

USER vscode

# Rust toolchain and lint/format components used in interactive development.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain "${RUST_TOOLCHAIN}" --no-modify-path \
    && rustup component add clippy rustfmt \
    && cargo install cargo-nextest --locked

# Dev web tier: pinned Node, pnpm, and Bun with user-home tool paths.
# Published as ghcr.io/liminal-hq/dev-web for JS/TS devcontainers and
# host-side toolbox use.
FROM dev-base AS dev-web

ARG DEBIAN_FRONTEND
ARG NODE_MAJOR
ARG PNPM_VERSION
ARG BUN_VERSION

# Node + pnpm baseline pinned for shared devcontainer usage.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "pnpm@${PNPM_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# Writable JS tool paths under the non-root user home.
ENV HOME=/home/vscode \
    PNPM_HOME=/home/vscode/.local/share/pnpm \
    BUN_INSTALL=/home/vscode/.bun \
    PATH=/home/vscode/.local/share/pnpm:/home/vscode/.bun/bin:${PATH}

# Pre-create writable directories before switching to the devcontainer user.
RUN mkdir -p "${PNPM_HOME}" \
    && chown -R vscode:vscode /home/vscode/.local

USER vscode

# Bun pinned under the devcontainer user home.
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v${BUN_VERSION}"

# Final dev desktop image: Tauri desktop toolchain on the dev Rust tier.
# Adds the JS runtimes (same pins as dev-web), the GTK/webkit system stack,
# GStreamer/xvfb/emoji fonts, and X11 inspection tools for Linux desktop
# integration debugging from the container.
FROM dev-rust AS dev-desktop

ARG DEBIAN_FRONTEND
ARG NODE_MAJOR
ARG PNPM_VERSION
ARG BUN_VERSION

USER root

# Tauri desktop system dependencies and desktop-debugging tools, kept at this
# tier so lean dev images stay lean.
RUN apt-get update && apt-get install -y --no-install-recommends \
    patchelf libssl-dev libglib2.0-dev libgtk-3-dev libwebkit2gtk-4.1-dev \
    libayatana-appindicator3-dev librsvg2-dev xdg-utils \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-bad fonts-noto-color-emoji \
    xvfb x11-utils wmctrl xdotool \
    && rm -rf /var/lib/apt/lists/*

# Node + pnpm baseline pinned for shared devcontainer usage.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "pnpm@${PNPM_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# Writable JS tool paths under the non-root user home.
ENV PNPM_HOME=/home/vscode/.local/share/pnpm \
    BUN_INSTALL=/home/vscode/.bun \
    PATH=/home/vscode/.local/share/pnpm:/home/vscode/.bun/bin:${PATH}

# Pre-create writable directories before switching back to the devcontainer user.
RUN mkdir -p "${PNPM_HOME}" \
    && chown -R vscode:vscode /home/vscode/.local

USER vscode

# Bun pinned under the devcontainer user home.
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v${BUN_VERSION}"

# Keep parity with existing app repos for portable AppImage behaviour.
RUN cargo install tauri-cli \
    --git https://github.com/tauri-apps/tauri \
    --branch feat/truly-portable-appimage \
    --force

# Ensures portable AppImage behaviour matches existing repo expectations.
ENV TAURI_BUNDLER_NEW_APPIMAGE_FORMAT=true

# Final dev mobile image.
FROM dev-desktop AS dev-mobile

ARG DEBIAN_FRONTEND
ARG ANDROID_CMDLINE_TOOLS
ARG ANDROID_PLATFORM
ARG ANDROID_BUILD_TOOLS
ARG ANDROID_NDK

USER root

# Mobile dev target extends the dev desktop toolchain with Java.
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

USER vscode

# Android environment lives under the devcontainer user home.
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    ANDROID_HOME=/home/vscode/Android/Sdk \
    ANDROID_SDK_ROOT=/home/vscode/Android/Sdk \
    PATH=/home/vscode/Android/Sdk/cmdline-tools/latest/bin:/home/vscode/Android/Sdk/platform-tools:/home/vscode/Android/Sdk/build-tools/${ANDROID_BUILD_TOOLS}:${PATH}

# Android command-line tools install (sdkmanager).
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && cd "${ANDROID_HOME}/cmdline-tools" \
    && wget -q "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
    && unzip -q "commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
    && rm "commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
    && mv cmdline-tools latest

# Pin Android platform/build-tools/NDK to the shared dev baseline.
RUN yes | sdkmanager --licenses \
    && sdkmanager --channel=0 --install \
      "platform-tools" \
      "platforms;android-${ANDROID_PLATFORM}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" \
      "ndk;${ANDROID_NDK}" \
    && rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android \
    && rm -rf "${ANDROID_HOME}/cmdline-tools/latest/.downloadIntermediates"
