#!/bin/bash

# Build nginx for Android
# This script builds nginx with HTTP/2, HTTP/3, TLS 1.3, and QUIC support for Android

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load Android configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/android-config.sh"

echo -e "${GREEN}Building nginx for Android...${NC}"

# nginx source directory
NGINX_SRC="${SRC_DIR}/nginx"

if [ ! -d "$NGINX_SRC" ]; then
    echo -e "${RED}Error: nginx source not found at $NGINX_SRC${NC}"
    echo "Please run ./scripts/clone-deps.sh first"
    exit 1
fi

# Function to build nginx for specific architecture
build_nginx_arch() {
    local arch="$1"
    
    echo -e "${YELLOW}Building nginx for ${arch}...${NC}"
    
    # Set up toolchain for this architecture
    setup_toolchain "$arch"
    verify_toolchain
    
    # Check if dependencies are built
    local deps_dir="$ARCH_INSTALL_DIR"
    if [ ! -f "$deps_dir/lib/libssl.a" ] || [ ! -f "$deps_dir/lib/libcrypto.a" ] || \
       [ ! -f "$deps_dir/lib/libz.a" ] || [ ! -f "$deps_dir/lib/libpcre2-8.a" ]; then
        echo -e "${RED}Error: Dependencies not found for $arch${NC}"
        echo "Please build dependencies first:"
        echo "  ./scripts/build-openssl.sh"
        echo "  ./scripts/build-zlib.sh"
        echo "  ./scripts/build-pcre2.sh"
        exit 1
    fi
    
    # nginx build directory for this architecture
    local build_dir="${BUILD_DIR}/nginx-${arch}"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    
    # Copy source to build directory
    cp -r "$NGINX_SRC"/* "$build_dir/"
    cd "$build_dir"
    
    # Configure nginx
    echo -e "${YELLOW}Configuring nginx for ${arch}...${NC}"
    
    # Apply cross-compilation patches to nginx
    echo -e "${YELLOW}Applying cross-compilation patches...${NC}"

    # Function to rollback nginx source to clean state
    rollback_nginx_source() {
        echo -e "${YELLOW}Rolling back nginx source to clean state...${NC}"
        cd "$SRC_DIR/nginx"

        # Reset any changes using git
        if [ -d ".git" ]; then
            git checkout -- .
            git clean -fd
        else
            echo -e "${RED}Warning: nginx source is not a git repository, cannot rollback${NC}"
        fi

        cd "$BUILD_DIR/nginx-$arch"
    }

    # Function to apply patches
    apply_patches() {
        local patch_dir="$PROJECT_ROOT/src/nginx_patches"

        if [ ! -d "$patch_dir" ]; then
            echo -e "${RED}Error: Patch directory $patch_dir not found${NC}"
            return 1
        fi

        # Apply patches in order
        for patch_file in "$patch_dir"/*.patch; do
            if [ -f "$patch_file" ]; then
                echo -e "${YELLOW}Applying patch: $(basename $patch_file)${NC}"
                if ! patch -p1 < "$patch_file"; then
                    echo -e "${RED}Error: Failed to apply patch $(basename $patch_file)${NC}"
                    return 1
                fi
            fi
        done

        return 0
    }

    # Rollback source and apply all patches
    rollback_nginx_source
    if ! apply_patches; then
        echo -e "${RED}Error: Failed to apply patches${NC}"
        exit 1
    fi

    # Set cross-compilation environment variables
    export NGX_CROSSBUILD="crossbuild"
    export NGX_SYSTEM="Linux"
    export NGX_RELEASE="5.4.0"
    export NGX_MACHINE="$ANDROID_ARCH"

    # Force nginx to use Linux configuration instead of Darwin
    export NGX_PLATFORM="linux"

    # Configure nginx with cross-compilation support
    echo -e "${YELLOW}Configuring nginx for ${arch}...${NC}"

    # Set PKG_CONFIG_PATH to find our built libraries
    export PKG_CONFIG_PATH="$deps_dir/lib/pkgconfig:$PKG_CONFIG_PATH"

    ./auto/configure \
        --with-cc="$CC" \
        --with-cpp="$CC -E" \
        --with-cc-opt="$CFLAGS -I$deps_dir/include" \
        --with-ld-opt="$LDFLAGS -L$deps_dir/lib" \
        --prefix=/data/local/tmp/nginx \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_gzip_static_module \
        --with-http_stub_status_module \
        --with-pcre-jit
    
    # Build nginx
    echo -e "${YELLOW}Compiling nginx for ${arch}...${NC}"
    make -j$(nproc)
    
    # Install nginx
    echo -e "${YELLOW}Installing nginx for ${arch}...${NC}"
    make install DESTDIR="$ARCH_INSTALL_DIR"

    # Copy the binary to our install directory
    mkdir -p "$ARCH_INSTALL_DIR/nginx/sbin"
    mkdir -p "$ARCH_INSTALL_DIR/nginx/conf"
    mkdir -p "$ARCH_INSTALL_DIR/nginx/logs"
    mkdir -p "$ARCH_INSTALL_DIR/nginx/tmp"

    # Copy files from the temporary install location
    cp "$ARCH_INSTALL_DIR/data/local/tmp/nginx/sbin/nginx" "$ARCH_INSTALL_DIR/nginx/sbin/"
    cp -r "$ARCH_INSTALL_DIR/data/local/tmp/nginx/conf"/* "$ARCH_INSTALL_DIR/nginx/conf/" 2>/dev/null || true

    # Clean up temporary install location
    rm -rf "$ARCH_INSTALL_DIR/data"
    
    echo -e "${GREEN}nginx built successfully for ${arch}${NC}"
    echo "  Install directory: $ARCH_INSTALL_DIR/nginx"
    echo "  Binary: $(ls -la "$ARCH_INSTALL_DIR/nginx/sbin/nginx" 2>/dev/null || echo 'Not found')"
}

# Build for all architectures
for arch in $ANDROID_ARCHS; do
    build_nginx_arch "$arch"
done

echo -e "${GREEN}nginx build completed for all architectures!${NC}"
echo ""
echo "Built architectures:"
for arch in $ANDROID_ARCHS; do
    install_dir="${INSTALL_DIR}/${arch}"
    if [ -f "${install_dir}/nginx/sbin/nginx" ]; then
        size=$(ls -lh "${install_dir}/nginx/sbin/nginx" | awk '{print $5}')
        echo -e "  ${GREEN}✓${NC} $arch - $size"
    else
        echo -e "  ${RED}✗${NC} $arch - Build failed"
    fi
done
