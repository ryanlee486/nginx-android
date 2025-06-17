#!/bin/bash

# Build zlib for Android
# This script builds zlib compression library for Android

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load Android configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/android-config.sh"

echo -e "${GREEN}Building zlib for Android...${NC}"

# zlib source directory
ZLIB_SRC="${SRC_DIR}/zlib"

if [ ! -d "$ZLIB_SRC" ]; then
    echo -e "${RED}Error: zlib source not found at $ZLIB_SRC${NC}"
    echo "Please run ./scripts/clone-deps.sh first"
    exit 1
fi

# Function to build zlib for specific architecture
build_zlib_arch() {
    local arch="$1"
    
    echo -e "${YELLOW}Building zlib for ${arch}...${NC}"
    
    # Set up toolchain for this architecture
    setup_toolchain "$arch"
    verify_toolchain
    
    # zlib build directory for this architecture
    local build_dir="${BUILD_DIR}/zlib-${arch}"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    # Copy source to build directory
    cp -r "$ZLIB_SRC"/* "$build_dir/"
    cd "$build_dir"
    
    # Configure zlib
    echo -e "${YELLOW}Configuring zlib for ${arch}...${NC}"

    # Set environment variables for cross-compilation
    export CROSS_PREFIX="${ANDROID_TRIPLE}-"

    # Configure with Android-specific settings
    ./configure \
        --prefix="$ARCH_INSTALL_DIR" \
        --static

    # Fix the Makefile for llvm-ar
    sed -i.bak 's/AR=libtool/AR='"${AR//\//\\/}"'/' Makefile
    sed -i.bak2 's/ARFLAGS=-o/ARFLAGS=rc/' Makefile

    # Build zlib
    echo -e "${YELLOW}Compiling zlib for ${arch}...${NC}"
    make -j$(nproc) \
        CC="$CC" \
        AR="$AR" \
        ARFLAGS="rc" \
        RANLIB="$RANLIB" \
        CFLAGS="$CFLAGS"
    
    # Install zlib
    echo -e "${YELLOW}Installing zlib for ${arch}...${NC}"
    make install
    
    echo -e "${GREEN}zlib built successfully for ${arch}${NC}"
    echo "  Install directory: $ARCH_INSTALL_DIR"
    echo "  Library: $(ls -la "$ARCH_INSTALL_DIR/lib"/libz.a 2>/dev/null || echo 'Not found')"
}

# Build for all architectures
for arch in $ANDROID_ARCHS; do
    build_zlib_arch "$arch"
done

echo -e "${GREEN}zlib build completed for all architectures!${NC}"
echo ""
echo "Built architectures:"
for arch in $ANDROID_ARCHS; do
    install_dir="${INSTALL_DIR}/${arch}"
    if [ -f "${install_dir}/lib/libz.a" ]; then
        echo -e "  ${GREEN}✓${NC} $arch - $(ls -lh "${install_dir}/lib/libz.a" | awk '{print $5}')"
    else
        echo -e "  ${RED}✗${NC} $arch - Build failed"
    fi
done
