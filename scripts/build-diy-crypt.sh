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

# Function to build DIY crypt for a specific architecture
build_diy_crypt() {
    local arch="$1"
    
    echo -e "${GREEN}Building DIY crypt for $arch...${NC}"
    
    # Setup toolchain for this architecture
    setup_toolchain "$arch"
    verify_toolchain
    
    # Create build directory
    local build_dir="${BUILD_DIR}/diy-crypt-${arch}"
    mkdir -p "$build_dir"
    
    # Copy source to build directory
    echo -e "${YELLOW}Copying DIY crypt source...${NC}"
    cp -r "${SRC_DIR}/diy-crypt" "$build_dir"
    cd "$build_dir/diy-crypt"
    
    # Build DIY crypt
    echo -e "${YELLOW}Building DIY crypt for $arch...${NC}"
    
    # Environment variables are already set by setup_toolchain
    # Just set PREFIX for the Makefile to the architecture-specific directory
    export PREFIX="${ARCH_INSTALL_DIR}"

    # Add OpenSSL include path to CFLAGS
    export CFLAGS="$CFLAGS -I${ARCH_INSTALL_DIR}/include"

    # Debug: Print environment variables
    echo "CC: $CC"
    echo "AR: $AR"
    echo "CFLAGS: $CFLAGS"
    echo "PREFIX: $PREFIX"

    # Build static library
    make clean
    make static
    
    # Install DIY crypt
    echo -e "${YELLOW}Installing DIY crypt...${NC}"
    make install
    
    echo -e "${GREEN}DIY crypt built and installed successfully for $arch${NC}"
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

# Check if DIY crypt source exists
if [ ! -d "${SRC_DIR}/diy-crypt" ]; then
    echo -e "${RED}Error: DIY crypt source not found${NC}"
    echo "Please ensure the DIY crypt source is in src/diy-crypt/"
    exit 1
fi

# Build DIY crypt
build_diy_crypt "$ARCH"

echo -e "${GREEN}DIY crypt build completed successfully!${NC}"
