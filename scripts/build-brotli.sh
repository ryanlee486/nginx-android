#!/bin/bash

# Build brotli library for Android
# This script builds the brotli compression library for use with nginx

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load Android configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/android-config.sh"

echo -e "${GREEN}Building brotli for Android...${NC}"

# brotli source directory
BROTLI_SRC="${SRC_DIR}/ngx_brotli/deps/brotli"

if [ ! -d "$BROTLI_SRC" ]; then
    echo -e "${RED}Error: brotli source not found at $BROTLI_SRC${NC}"
    echo "Please run ./scripts/clone-deps.sh first"
    exit 1
fi

# Function to build brotli for specific architecture
build_brotli_arch() {
    local arch="$1"
    
    echo -e "${YELLOW}Building brotli for ${arch}...${NC}"
    
    # Set up toolchain for this architecture
    setup_toolchain "$arch"
    verify_toolchain
    
    # brotli build directory for this architecture
    local build_dir="${BUILD_DIR}/brotli-${arch}"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    # Copy source to build directory
    cp -r "$BROTLI_SRC"/* "$build_dir/"
    cd "$build_dir"
    
    # Configure brotli
    echo -e "${YELLOW}Configuring brotli for ${arch}...${NC}"
    
    # Create CMake toolchain file for Android
    cat > android-toolchain.cmake << EOF
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR ${ANDROID_ARCH})

set(CMAKE_C_COMPILER ${CC})
set(CMAKE_CXX_COMPILER ${CXX})

set(CMAKE_C_FLAGS "${CFLAGS}")
set(CMAKE_CXX_FLAGS "${CXXFLAGS}")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
EOF

    # Configure with CMake
    cmake . \
        -DCMAKE_TOOLCHAIN_FILE=android-toolchain.cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$ARCH_INSTALL_DIR" \
        -DBUILD_SHARED_LIBS=OFF \
        -DBROTLI_DISABLE_TESTS=ON \
        -DBROTLI_BUILD_TOOLS=OFF \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    
    # Build brotli
    echo -e "${YELLOW}Compiling brotli for ${arch}...${NC}"
    make -j$(nproc)
    
    # Install brotli
    echo -e "${YELLOW}Installing brotli for ${arch}...${NC}"
    make install
    
    echo -e "${GREEN}brotli built successfully for ${arch}${NC}"
    echo "  Install directory: $ARCH_INSTALL_DIR"
    echo "  Libraries: $(ls -la "$ARCH_INSTALL_DIR/lib/libbrotli"*.a 2>/dev/null || echo 'Not found')"
}

# Build for all architectures
for arch in $ANDROID_ARCHS; do
    build_brotli_arch "$arch"
done

echo -e "${GREEN}brotli build completed for all architectures!${NC}"
echo ""
echo "Built architectures:"
for arch in $ANDROID_ARCHS; do
    install_dir="${INSTALL_DIR}/${arch}"
    if [ -f "${install_dir}/lib/libbrotlienc-static.a" ] && [ -f "${install_dir}/lib/libbrotlidec-static.a" ]; then
        enc_size=$(ls -lh "${install_dir}/lib/libbrotlienc-static.a" | awk '{print $5}')
        dec_size=$(ls -lh "${install_dir}/lib/libbrotlidec-static.a" | awk '{print $5}')
        echo -e "  ${GREEN}✓${NC} $arch - enc: $enc_size, dec: $dec_size"
    else
        echo -e "  ${RED}✗${NC} $arch - Build failed"
    fi
done 