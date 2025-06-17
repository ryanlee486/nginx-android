#!/bin/bash

# Build PCRE2 for Android
# This script builds PCRE2 regex library for Android

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load Android configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/android-config.sh"

echo -e "${GREEN}Building PCRE2 for Android...${NC}"

# PCRE2 source directory
PCRE2_SRC="${SRC_DIR}/pcre2"

if [ ! -d "$PCRE2_SRC" ]; then
    echo -e "${RED}Error: PCRE2 source not found at $PCRE2_SRC${NC}"
    echo "Please run ./scripts/clone-deps.sh first"
    exit 1
fi

# Function to build PCRE2 for specific architecture
build_pcre2_arch() {
    local arch="$1"
    
    echo -e "${YELLOW}Building PCRE2 for ${arch}...${NC}"
    
    # Set up toolchain for this architecture
    setup_toolchain "$arch"
    verify_toolchain
    
    # PCRE2 build directory for this architecture
    local build_dir="${BUILD_DIR}/pcre2-${arch}"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    # Copy source to build directory
    cp -r "$PCRE2_SRC"/* "$build_dir/"
    cd "$build_dir"
    
    # Generate configure script if it doesn't exist
    if [ ! -f "configure" ]; then
        echo -e "${YELLOW}Generating configure script...${NC}"
        ./autogen.sh
    fi
    
    # Configure PCRE2
    echo -e "${YELLOW}Configuring PCRE2 for ${arch}...${NC}"
    
    ./configure \
        --host="$ANDROID_TRIPLE" \
        --prefix="$ARCH_INSTALL_DIR" \
        --enable-static \
        --disable-shared \
        --enable-pcre2-8 \
        --enable-pcre2-16 \
        --enable-pcre2-32 \
        --enable-unicode \
        --disable-pcre2grep-libz \
        --disable-pcre2grep-libbz2 \
        --disable-pcre2test-libreadline \
        CC="$CC" \
        CXX="$CXX" \
        AR="$AR" \
        RANLIB="$RANLIB" \
        STRIP="$STRIP" \
        CFLAGS="$CFLAGS" \
        CXXFLAGS="$CXXFLAGS" \
        LDFLAGS="$LDFLAGS"
    
    # Build PCRE2
    echo -e "${YELLOW}Compiling PCRE2 for ${arch}...${NC}"
    make -j$(nproc)
    
    # Install PCRE2
    echo -e "${YELLOW}Installing PCRE2 for ${arch}...${NC}"
    make install
    
    echo -e "${GREEN}PCRE2 built successfully for ${arch}${NC}"
    echo "  Install directory: $ARCH_INSTALL_DIR"
    echo "  Libraries: $(ls -la "$ARCH_INSTALL_DIR/lib"/libpcre2*.a 2>/dev/null || echo 'Not found')"
}

# Build for all architectures
for arch in $ANDROID_ARCHS; do
    build_pcre2_arch "$arch"
done

echo -e "${GREEN}PCRE2 build completed for all architectures!${NC}"
echo ""
echo "Built architectures:"
for arch in $ANDROID_ARCHS; do
    install_dir="${INSTALL_DIR}/${arch}"
    if [ -f "${install_dir}/lib/libpcre2-8.a" ]; then
        echo -e "  ${GREEN}✓${NC} $arch - $(ls -lh "${install_dir}/lib/libpcre2-8.a" | awk '{print $5}')"
    else
        echo -e "  ${RED}✗${NC} $arch - Build failed"
    fi
done
