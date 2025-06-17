#!/bin/bash

# Main Android build script
# This script orchestrates the complete build process for nginx on Android

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  nginx for Android Build System${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Parse command line arguments
CLEAN_BUILD=false
SKIP_DEPS=false
TARGET_ARCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --arch)
            TARGET_ARCH="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --clean      Clean build directories before building"
            echo "  --skip-deps  Skip dependency cloning (assume already done)"
            echo "  --arch ARCH  Build only for specific architecture"
            echo "  --help       Show this help message"
            echo ""
            echo "Supported architectures: arm64-v8a, armeabi-v7a, x86_64, x86"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Load Android configuration
source "${SCRIPT_DIR}/android-config.sh"

# Override architectures if specific arch requested
if [ -n "$TARGET_ARCH" ]; then
    export ANDROID_ARCHS="$TARGET_ARCH"
    echo -e "${YELLOW}Building only for architecture: $TARGET_ARCH${NC}"
fi

# Clean build directories if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}Cleaning build directories...${NC}"
    rm -rf "$BUILD_DIR"
    rm -rf "$INSTALL_DIR"
    mkdir -p "$BUILD_DIR" "$INSTALL_DIR"
fi

# Step 1: Clone dependencies
if [ "$SKIP_DEPS" = false ]; then
    echo -e "${GREEN}Step 1: Cloning dependencies...${NC}"
    "${SCRIPT_DIR}/clone-deps.sh"
else
    echo -e "${YELLOW}Step 1: Skipping dependency cloning (--skip-deps)${NC}"
fi

# Step 2: Build OpenSSL
echo -e "${GREEN}Step 2: Building OpenSSL...${NC}"
"${SCRIPT_DIR}/build-openssl.sh"

# Step 3: Build zlib
echo -e "${GREEN}Step 3: Building zlib...${NC}"
"${SCRIPT_DIR}/build-zlib.sh"

# Step 4: Build PCRE2
echo -e "${GREEN}Step 4: Building PCRE2...${NC}"
"${SCRIPT_DIR}/build-pcre2.sh"

# Step 5: Build DIY crypt
echo -e "${GREEN}Step 5: Building DIY crypt...${NC}"
if [ -n "$TARGET_ARCH" ]; then
    "${SCRIPT_DIR}/build-diy-crypt.sh" "$TARGET_ARCH"
else
    for arch in $ANDROID_ARCHS; do
        "${SCRIPT_DIR}/build-diy-crypt.sh" "$arch"
    done
fi

# Step 6: Build nginx
echo -e "${GREEN}Step 6: Building nginx...${NC}"
"${SCRIPT_DIR}/build-nginx.sh"

# Build summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Build Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

total_success=0
total_archs=0

for arch in $ANDROID_ARCHS; do
    total_archs=$((total_archs + 1))
    install_dir="${INSTALL_DIR}/${arch}"
    
    echo -e "${YELLOW}Architecture: $arch${NC}"
    
    # Check OpenSSL
    if [ -f "${install_dir}/lib/libssl.a" ] && [ -f "${install_dir}/lib/libcrypto.a" ]; then
        echo -e "  OpenSSL: ${GREEN}✓${NC}"
    else
        echo -e "  OpenSSL: ${RED}✗${NC}"
    fi
    
    # Check zlib
    if [ -f "${install_dir}/lib/libz.a" ]; then
        echo -e "  zlib: ${GREEN}✓${NC}"
    else
        echo -e "  zlib: ${RED}✗${NC}"
    fi
    
    # Check PCRE2
    if [ -f "${install_dir}/lib/libpcre2-8.a" ]; then
        echo -e "  PCRE2: ${GREEN}✓${NC}"
    else
        echo -e "  PCRE2: ${RED}✗${NC}"
    fi

    # Check DIY crypt
    if [ -f "${install_dir}/lib/libcrypt.a" ]; then
        echo -e "  DIY crypt: ${GREEN}✓${NC}"
    else
        echo -e "  DIY crypt: ${RED}✗${NC}"
    fi

    # Check nginx
    if [ -f "${install_dir}/nginx/sbin/nginx" ]; then
        echo -e "  nginx: ${GREEN}✓${NC}"
        size=$(ls -lh "${install_dir}/nginx/sbin/nginx" | awk '{print $5}')
        echo -e "  Binary size: $size"
        total_success=$((total_success + 1))
    else
        echo -e "  nginx: ${RED}✗${NC}"
    fi
    
    echo ""
done

# Final status
if [ $total_success -eq $total_archs ]; then
    echo -e "${GREEN}🎉 Build completed successfully for all architectures!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run tests: ./scripts/test.sh"
    echo "2. Deploy to device: ./scripts/deploy.sh"
else
    echo -e "${RED}❌ Build failed for some architectures ($total_success/$total_archs successful)${NC}"
    exit 1
fi

echo ""
echo "Build artifacts location: $INSTALL_DIR"
