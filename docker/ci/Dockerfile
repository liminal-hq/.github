# Desktop target: base for Rust/Node/Tauri desktop CI workloads.
FROM ubuntu:24.04 AS desktop

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=24
ARG PNPM_VERSION=10.28.2
ARG ANDROID_CMDLINE_TOOLS=11076708
ARG ANDROID_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK=28.2.13676358

# Core Linux build dependencies required by Tauri desktop builds.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget git file build-essential pkg-config patchelf \
    libssl-dev libglib2.0-dev libgtk-3-dev libwebkit2gtk-4.1-dev \
    libayatana-appindicator3-dev librsvg2-dev xdg-utils unzip \
    && rm -rf /var/lib/apt/lists/*

# Node + pnpm baseline pinned for workspace consistency.
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "pnpm@${PNPM_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:${PATH}

# Rust toolchain and lint/format components used by CI gates.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain 1.93.0 --no-modify-path \
    && rustup component add clippy rustfmt \
    && cargo install cargo-nextest --locked

# Keep parity with existing app repos for portable AppImage behaviour.
RUN cargo install tauri-cli \
    --git https://github.com/tauri-apps/tauri \
    --branch feat/truly-portable-appimage \
    --force

# Ensures portable AppImage behaviour matches existing repo expectations.
ENV TAURI_BUNDLER_NEW_APPIMAGE_FORMAT=true

# Mobile target: extends desktop with Java + Android SDK/NDK.
FROM desktop AS mobile

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

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

# Pin Android platform/build-tools/NDK to repo baseline.
RUN yes | sdkmanager --licenses \
    && sdkmanager --channel=0 --install \
      "platform-tools" \
      "platforms;android-${ANDROID_PLATFORM}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" \
      "ndk;${ANDROID_NDK}" \
    && rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android \
    && rm -rf "${ANDROID_HOME}/cmdline-tools/latest/.downloadIntermediates"
