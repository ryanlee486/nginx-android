#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${PROJECT_ROOT}/src"
BUILD_DIR="${PROJECT_ROOT}/build"

# Source Android configuration
source "${PROJECT_ROOT}/scripts/android-config.sh"

# Function to build libxcrypt for a specific architecture
build_libxcrypt() {
    local arch="$1"
    
    echo -e "${GREEN}Building libxcrypt for $arch...${NC}"
    
    # Setup toolchain for this architecture
    setup_toolchain "$arch"
    verify_toolchain
    
    # Create build directory
    local build_dir="${BUILD_DIR}/libxcrypt-${arch}"
    mkdir -p "$build_dir"
    
    # Copy source to build directory
    echo -e "${YELLOW}Copying libxcrypt source...${NC}"
    cp -r "${SRC_DIR}/libxcrypt" "$build_dir"
    cd "$build_dir/libxcrypt"
    
    # Generate configure script
    echo -e "${YELLOW}Generating configure script...${NC}"
    ./autogen.sh
    
    # Configure libxcrypt
    echo -e "${YELLOW}Configuring libxcrypt for $arch...${NC}"
    
    # Set environment variables for cross-compilation
    export CC="${ANDROID_CC}"
    export CXX="${ANDROID_CXX}"
    export AR="${ANDROID_AR}"
    export RANLIB="${ANDROID_RANLIB}"
    export STRIP="${ANDROID_STRIP}"
    export CFLAGS="${ANDROID_CFLAGS}"
    export CXXFLAGS="${ANDROID_CXXFLAGS}"
    export LDFLAGS="${ANDROID_LDFLAGS}"
    export PKG_CONFIG_PATH="${INSTALL_DIR}/lib/pkgconfig"

    # Debug: Print environment variables
    echo "CC: $CC"
    echo "CXX: $CXX"
    echo "AR: $AR"
    echo "RANLIB: $RANLIB"
    
    # Configure with cross-compilation settings
    ./configure \
        --build=x86_64-apple-darwin \
        --host="${ANDROID_TRIPLE}" \
        --prefix="${INSTALL_DIR}" \
        --enable-shared \
        --enable-static \
        --disable-obsolete-api \
        --enable-hashes=strong,glibc \
        --disable-failure-tokens \
        --disable-xcrypt-compat-files
    
    # Build libxcrypt
    echo -e "${YELLOW}Building libxcrypt...${NC}"
    make -j"$(nproc)"
    
    # Install libxcrypt
    echo -e "${YELLOW}Installing libxcrypt...${NC}"
    make install
    
    echo -e "${GREEN}libxcrypt built and installed successfully for $arch${NC}"
}

# Main execution
if [ $# -eq 0 ]; then
    echo "Usage: $0 <architecture>"
    echo "Available architectures: arm64-v8a armeabi-v7a x86_64 x86"
    exit 1
fi

ARCH="$1"

# Validate architecture
case "$ARCH" in
    arm64-v8a|armeabi-v7a|x86_64|x86)
        ;;
    *)
        echo -e "${RED}Error: Unsupported architecture '$ARCH'${NC}"
        echo "Supported architectures: arm64-v8a armeabi-v7a x86_64 x86"
        exit 1
        ;;
esac

# Check if Android NDK is configured
if [ -z "$ANDROID_NDK_ROOT" ]; then
    echo -e "${RED}Error: ANDROID_NDK_ROOT not set${NC}"
    echo "Please set ANDROID_NDK_ROOT to your Android NDK installation path"
    exit 1
fi

# Check if libxcrypt source exists
if [ ! -d "${SRC_DIR}/libxcrypt" ]; then
    echo -e "${RED}Error: libxcrypt source not found${NC}"
    echo "Please run ./scripts/clone-deps.sh first"
    exit 1
fi

# Build libxcrypt
build_libxcrypt "$ARCH"

echo -e "${GREEN}libxcrypt build completed successfully!${NC}"
