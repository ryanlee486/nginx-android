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

echo -e "${GREEN}Cloning dependencies for nginx Android build...${NC}"

# Create src directory if it doesn't exist
mkdir -p "${SRC_DIR}"
cd "${SRC_DIR}"

# Function to clone or update repository
clone_or_update() {
    local repo_url="$1"
    local dir_name="$2"
    local branch="$3"
    
    if [ -d "${dir_name}" ]; then
        echo -e "${YELLOW}Updating ${dir_name}...${NC}"
        cd "${dir_name}"
        git fetch origin
        git checkout "${branch}"
        git pull origin "${branch}"
        cd ..
    else
        echo -e "${GREEN}Cloning ${dir_name}...${NC}"
        git clone --branch "${branch}" --depth 1 "${repo_url}" "${dir_name}"
    fi
}

# Clone nginx (stable release)
echo -e "${GREEN}Cloning nginx stable release...${NC}"
clone_or_update "https://github.com/nginx/nginx.git" "nginx" "release-1.26.2"

# Clone OpenSSL (stable release)
echo -e "${GREEN}Cloning OpenSSL stable release...${NC}"
clone_or_update "https://github.com/openssl/openssl.git" "openssl" "openssl-3.3.2"

# Clone zlib (stable release)
echo -e "${GREEN}Cloning zlib stable release...${NC}"
clone_or_update "https://github.com/madler/zlib.git" "zlib" "v1.3.1"

# Clone PCRE2 (stable release)
echo -e "${GREEN}Cloning PCRE2 stable release...${NC}"
clone_or_update "https://github.com/PCRE2Project/pcre2.git" "pcre2" "pcre2-10.44"

# Clone libxcrypt (stable release)
echo -e "${GREEN}Cloning libxcrypt stable release...${NC}"
clone_or_update "https://github.com/besser82/libxcrypt.git" "libxcrypt" "v4.4.38"

# Clone ngx_brotli (stable release)
echo -e "${GREEN}Cloning ngx_brotli stable release...${NC}"
clone_or_update "https://github.com/google/ngx_brotli.git" "ngx_brotli" "v1.0.0rc"

# Initialize and update submodules for ngx_brotli
if [ -d "ngx_brotli" ]; then
    cd ngx_brotli
    git submodule update --init --recursive
    cd ..
fi

echo -e "${GREEN}All dependencies cloned successfully!${NC}"
echo -e "${YELLOW}Dependencies location: ${SRC_DIR}${NC}"
echo ""
echo "Next steps:"
echo "1. Run ./scripts/build-android.sh to build for Android"
echo "2. Run ./scripts/test.sh to run tests"
