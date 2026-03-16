ARG UBUNTU_VERSION=24.04
ARG DEVCONTAINER_BASE_IMAGE=mcr.microsoft.com/devcontainers/base:ubuntu-24.04
ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=24
ARG PNPM_VERSION=10.28.2
ARG RUST_TOOLCHAIN=1.93.0
ARG ANDROID_CMDLINE_TOOLS=11076708
ARG ANDROID_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK=28.2.13676358

# CI base: shared Linux packages for Tauri desktop builds in CI.
FROM ubuntu:${UBUNTU_VERSION} AS ci-base

ARG DEBIAN_FRONTEND

# Core Linux build dependencies required by Tauri desktop CI builds.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git file build-essential pkg-config patchelf \
    libssl-dev libglib2.0-dev libgtk-3-dev libwebkit2gtk-4.1-dev \
    libayatana-appindicator3-dev librsvg2-dev xdg-utils unzip \
    && rm -rf /var/lib/apt/lists/*

# CI toolchain: pinned Node, pnpm, Rust, and Tauri tooling for shared CI images.
FROM ci-base AS ci-toolchain

ARG DEBIAN_FRONTEND
ARG NODE_MAJOR
ARG PNPM_VERSION
ARG RUST_TOOLCHAIN

# Node + pnpm baseline pinned for workspace consistency.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "pnpm@${PNPM_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# Rust toolchain paths for root-friendly CI usage.
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:${PATH}

# Rust toolchain and lint/format components used by CI gates.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain "${RUST_TOOLCHAIN}" --no-modify-path \
    && rustup component add clippy rustfmt \
    && cargo install cargo-nextest --locked

# Keep parity with existing app repos for portable AppImage behaviour.
RUN cargo install tauri-cli \
    --git https://github.com/tauri-apps/tauri \
    --branch feat/truly-portable-appimage \
    --force

# Ensures portable AppImage behaviour matches existing repo expectations.
ENV TAURI_BUNDLER_NEW_APPIMAGE_FORMAT=true

# Final CI desktop image.
FROM ci-toolchain AS ci-desktop

# Final CI mobile image.
FROM ci-toolchain AS ci-mobile

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

# Dev base: interactive devcontainer-friendly system packages and Node baseline.
FROM ${DEVCONTAINER_BASE_IMAGE} AS dev-base

ARG DEBIAN_FRONTEND
ARG NODE_MAJOR
ARG PNPM_VERSION

ENV TZ=America/Toronto

# Align devcontainers with the expected studio timezone by default.
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone

# Desktop devcontainer dependencies and quality-of-life packages.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git file build-essential pkg-config patchelf \
    libssl-dev libglib2.0-dev libgtk-3-dev libwebkit2gtk-4.1-dev \
    libayatana-appindicator3-dev librsvg2-dev xdg-utils unzip \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-bad fonts-noto-color-emoji \
    xvfb vim \
    && rm -rf /var/lib/apt/lists/*

# Node + pnpm baseline pinned for shared devcontainer usage.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "pnpm@${PNPM_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

# Dev toolchain: Threshold-style user-home layout for writable devcontainer tooling.
FROM dev-base AS dev-toolchain

ARG RUST_TOOLCHAIN

# Tool paths live under the non-root user home for a smoother devcontainer DX.
ENV HOME=/home/vscode \
    EDITOR=vim \
    PNPM_HOME=/home/vscode/.local/share/pnpm \
    RUSTUP_HOME=/home/vscode/.rustup \
    CARGO_HOME=/home/vscode/.cargo \
    PATH=/home/vscode/.local/share/pnpm:/home/vscode/.cargo/bin:${PATH}

# Pre-create writable directories before switching to the devcontainer user.
RUN mkdir -p "${PNPM_HOME}" "${RUSTUP_HOME}" "${CARGO_HOME}" \
    && chown -R vscode:vscode /home/vscode/.local /home/vscode/.rustup /home/vscode/.cargo

USER vscode

# Rust toolchain and lint/format components used in interactive development.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain "${RUST_TOOLCHAIN}" --no-modify-path \
    && rustup component add clippy rustfmt \
    && cargo install cargo-nextest --locked

# Keep parity with existing app repos for portable AppImage behaviour.
RUN cargo install tauri-cli \
    --git https://github.com/tauri-apps/tauri \
    --branch feat/truly-portable-appimage \
    --force

# Ensures portable AppImage behaviour matches existing repo expectations.
ENV TAURI_BUNDLER_NEW_APPIMAGE_FORMAT=true

# Final dev desktop image.
FROM dev-toolchain AS dev-desktop

# Final dev mobile image.
FROM dev-toolchain AS dev-mobile

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
