#!/bin/bash

# Build OpenSSL for Android
# This script builds OpenSSL with TLS 1.3 support for Android

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load Android configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/android-config.sh"

echo -e "${GREEN}Building OpenSSL for Android...${NC}"

# OpenSSL source directory
OPENSSL_SRC="${SRC_DIR}/openssl"

if [ ! -d "$OPENSSL_SRC" ]; then
    echo -e "${RED}Error: OpenSSL source not found at $OPENSSL_SRC${NC}"
    echo "Please run ./scripts/clone-deps.sh first"
    exit 1
fi

# Function to build OpenSSL for specific architecture
build_openssl_arch() {
    local arch="$1"
    
    echo -e "${YELLOW}Building OpenSSL for ${arch}...${NC}"
    
    # Set up toolchain for this architecture
    setup_toolchain "$arch"
    verify_toolchain
    
    # OpenSSL build directory for this architecture
    local build_dir="${BUILD_DIR}/openssl-${arch}"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    # Copy source to build directory
    cp -r "$OPENSSL_SRC"/* "$build_dir/"
    cd "$build_dir"
    
    # Configure OpenSSL target based on architecture
    local openssl_target
    case "$arch" in
        "arm64-v8a")
            openssl_target="android-arm64"
            ;;
        "armeabi-v7a")
            openssl_target="android-arm"
            ;;
        "x86_64")
            openssl_target="android-x86_64"
            ;;
        "x86")
            openssl_target="android-x86"
            ;;
        *)
            echo -e "${RED}Error: Unsupported architecture: $arch${NC}"
            exit 1
            ;;
    esac
    
    # Configure OpenSSL
    echo -e "${YELLOW}Configuring OpenSSL for ${arch}...${NC}"

    # Set environment variables for OpenSSL build
    export ANDROID_NDK_ROOT="$ANDROID_NDK_ROOT"
    export PATH="$TOOLCHAIN_DIR/bin:$PATH"

    ./Configure "$openssl_target" \
        -D__ANDROID_API__="$ANDROID_API_LEVEL" \
        --prefix="$ARCH_INSTALL_DIR" \
        --openssldir="$ARCH_INSTALL_DIR/ssl" \
        no-shared \
        no-tests \
        no-ui-console \
        no-asm \
        -fPIC \
        -Os \
        CC="$CC" \
        CXX="$CXX" \
        AR="$AR" \
        RANLIB="$RANLIB"
    
    # Build OpenSSL
    echo -e "${YELLOW}Compiling OpenSSL for ${arch}...${NC}"
    make -j$(nproc) build_libs
    
    # Install OpenSSL
    echo -e "${YELLOW}Installing OpenSSL for ${arch}...${NC}"
    make install_dev
    
    echo -e "${GREEN}OpenSSL built successfully for ${arch}${NC}"
    echo "  Install directory: $ARCH_INSTALL_DIR"
    echo "  Libraries: $(ls -la "$ARCH_INSTALL_DIR/lib"/libssl.a "$ARCH_INSTALL_DIR/lib"/libcrypto.a 2>/dev/null || echo 'Not found')"
}

# Build for all architectures
for arch in $ANDROID_ARCHS; do
    build_openssl_arch "$arch"
done

echo -e "${GREEN}OpenSSL build completed for all architectures!${NC}"
echo ""
echo "Built architectures:"
for arch in $ANDROID_ARCHS; do
    install_dir="${INSTALL_DIR}/${arch}"
    if [ -f "${install_dir}/lib/libssl.a" ] && [ -f "${install_dir}/lib/libcrypto.a" ]; then
        echo -e "  ${GREEN}✓${NC} $arch - $(ls -lh "${install_dir}/lib/libssl.a" | awk '{print $5}') + $(ls -lh "${install_dir}/lib/libcrypto.a" | awk '{print $5}')"
    else
        echo -e "  ${RED}✗${NC} $arch - Build failed"
    fi
done
