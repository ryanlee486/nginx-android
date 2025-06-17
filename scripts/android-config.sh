#!/bin/bash

# Android NDK Configuration Script
# This script sets up the Android NDK environment for cross-compilation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default Android NDK path (can be overridden by environment variable)
if [ -z "$ANDROID_NDK_ROOT" ]; then
    # Try common NDK locations
    if [ -d "$HOME/Library/Android/sdk/ndk" ]; then
        # macOS Android Studio default
        ANDROID_NDK_ROOT="$(find "$HOME/Library/Android/sdk/ndk" -maxdepth 1 -type d | tail -1)"
    elif [ -d "$HOME/Android/Sdk/ndk" ]; then
        # Linux Android Studio default
        ANDROID_NDK_ROOT="$(find "$HOME/Android/Sdk/ndk" -maxdepth 1 -type d | tail -1)"
    elif [ -d "/opt/android-ndk" ]; then
        # System-wide installation
        ANDROID_NDK_ROOT="/opt/android-ndk"
    else
        echo -e "${RED}Error: Android NDK not found!${NC}"
        echo "Please set ANDROID_NDK_ROOT environment variable or install Android NDK"
        echo "Download from: https://developer.android.com/ndk/downloads"
        exit 1
    fi
fi

# Verify NDK exists
if [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo -e "${RED}Error: Android NDK not found at: $ANDROID_NDK_ROOT${NC}"
    echo "Please set ANDROID_NDK_ROOT environment variable correctly"
    exit 1
fi

echo -e "${GREEN}Using Android NDK: $ANDROID_NDK_ROOT${NC}"

# Android API level (minimum for HTTP/3 and modern TLS)
export ANDROID_API_LEVEL=${ANDROID_API_LEVEL:-28}

# Target architectures
export ANDROID_ARCHS=${ANDROID_ARCHS:-"arm64-v8a armeabi-v7a x86_64 x86"}

# Project directories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export BUILD_DIR="${PROJECT_ROOT}/build"
export SRC_DIR="${PROJECT_ROOT}/src"
export INSTALL_DIR="${BUILD_DIR}/install"

# Create build directories
mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}"

# Function to set up toolchain for specific architecture
setup_toolchain() {
    local arch="$1"
    
    case "$arch" in
        "arm64-v8a")
            export ANDROID_ARCH="aarch64"
            export ANDROID_TRIPLE="aarch64-linux-android"
            ;;
        "armeabi-v7a")
            export ANDROID_ARCH="arm"
            export ANDROID_TRIPLE="armv7a-linux-androideabi"
            ;;
        "x86_64")
            export ANDROID_ARCH="x86_64"
            export ANDROID_TRIPLE="x86_64-linux-android"
            ;;
        "x86")
            export ANDROID_ARCH="i686"
            export ANDROID_TRIPLE="i686-linux-android"
            ;;
        *)
            echo -e "${RED}Error: Unsupported architecture: $arch${NC}"
            exit 1
            ;;
    esac
    
    # Set up toolchain paths
    local host_os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    if [ "$host_os" = "darwin" ]; then
        host_os="darwin"
    fi
    export TOOLCHAIN_DIR="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${host_os}-x86_64"
    export SYSROOT="${TOOLCHAIN_DIR}/sysroot"

    # Compiler and tools
    export CC="${TOOLCHAIN_DIR}/bin/${ANDROID_TRIPLE}${ANDROID_API_LEVEL}-clang"
    export CXX="${TOOLCHAIN_DIR}/bin/${ANDROID_TRIPLE}${ANDROID_API_LEVEL}-clang++"
    export AR="${TOOLCHAIN_DIR}/bin/llvm-ar"
    export RANLIB="${TOOLCHAIN_DIR}/bin/llvm-ranlib"
    export STRIP="${TOOLCHAIN_DIR}/bin/llvm-strip"
    export NM="${TOOLCHAIN_DIR}/bin/llvm-nm"
    export LD="${TOOLCHAIN_DIR}/bin/ld"

    # Add toolchain to PATH
    export PATH="${TOOLCHAIN_DIR}/bin:$PATH"
    
    # Compiler flags
    export CFLAGS="-fPIC -ffunction-sections -fdata-sections -Os"
    export CXXFLAGS="$CFLAGS"
    export LDFLAGS="-Wl,--gc-sections -Wl,--strip-all"
    
    # Architecture-specific install directory
    export ARCH_INSTALL_DIR="${INSTALL_DIR}/${arch}"
    mkdir -p "${ARCH_INSTALL_DIR}"
    
    echo -e "${GREEN}Toolchain configured for ${arch}${NC}"
    echo "  Triple: ${ANDROID_TRIPLE}"
    echo "  API Level: ${ANDROID_API_LEVEL}"
    echo "  Install Dir: ${ARCH_INSTALL_DIR}"
}

# Function to verify toolchain
verify_toolchain() {
    if [ ! -f "$CC" ]; then
        echo -e "${RED}Error: Compiler not found: $CC${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Toolchain verification successful${NC}"
    echo "Compiler: $($CC --version | head -1)"
}

# Export functions for use in other scripts
export -f setup_toolchain
export -f verify_toolchain

echo -e "${GREEN}Android NDK configuration loaded${NC}"
echo "Available architectures: $ANDROID_ARCHS"
echo "API Level: $ANDROID_API_LEVEL"
echo ""
echo "Usage in other scripts:"
echo "  source scripts/android-config.sh"
echo "  setup_toolchain arm64-v8a"
echo "  verify_toolchain"
