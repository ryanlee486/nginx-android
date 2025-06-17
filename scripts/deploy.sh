#!/bin/bash

# Deploy nginx to Android device/emulator using ADB
# This script pushes nginx binary, config, and test content to Android

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project directories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
INSTALL_DIR="${BUILD_DIR}/install"
CONFIG_DIR="${PROJECT_ROOT}/config"
TEST_DIR="${PROJECT_ROOT}/test"
CERTS_DIR="${PROJECT_ROOT}/certs"

# Android paths
ANDROID_BASE="/data/local/tmp/nginx"
ANDROID_BIN="${ANDROID_BASE}/sbin"
ANDROID_CONF="${ANDROID_BASE}/conf"
ANDROID_HTML="${ANDROID_BASE}/html"
ANDROID_LOGS="${ANDROID_BASE}/logs"
ANDROID_CERTS="${ANDROID_BASE}/certs"
ANDROID_TMP="${ANDROID_BASE}/tmp"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  nginx Android Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Parse command line arguments
TARGET_ARCH="arm64-v8a"
DEVICE_ID=""
FORCE_DEPLOY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --arch)
            TARGET_ARCH="$2"
            shift 2
            ;;
        --device)
            DEVICE_ID="$2"
            shift 2
            ;;
        --force)
            FORCE_DEPLOY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --arch ARCH    Target architecture (default: arm64-v8a)"
            echo "  --device ID    Specific device ID (optional)"
            echo "  --force        Force deployment even if files exist"
            echo "  --help         Show this help message"
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

# Set up ADB command
ADB_CMD="adb"
if [ -n "$DEVICE_ID" ]; then
    ADB_CMD="adb -s $DEVICE_ID"
fi

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo -e "${RED}Error: ADB not found in PATH${NC}"
    echo "Please install Android SDK Platform Tools"
    exit 1
fi

# Check if device is connected
echo -e "${YELLOW}Checking device connection...${NC}"
if ! $ADB_CMD shell echo "Device connected" &> /dev/null; then
    echo -e "${RED}Error: No Android device/emulator connected${NC}"
    echo "Available devices:"
    adb devices
    exit 1
fi

# Get device info
DEVICE_INFO=$($ADB_CMD shell getprop ro.product.model 2>/dev/null || echo "Unknown Device")
ANDROID_VERSION=$($ADB_CMD shell getprop ro.build.version.release 2>/dev/null || echo "Unknown")
DEVICE_ARCH=$($ADB_CMD shell getprop ro.product.cpu.abi 2>/dev/null || echo "Unknown")

echo -e "${GREEN}Device connected:${NC}"
echo "  Model: $DEVICE_INFO"
echo "  Android: $ANDROID_VERSION"
echo "  Architecture: $DEVICE_ARCH"
echo "  Target: $TARGET_ARCH"
echo ""

# Check if nginx binary exists
NGINX_BINARY="${INSTALL_DIR}/${TARGET_ARCH}/nginx/sbin/nginx"
if [ ! -f "$NGINX_BINARY" ]; then
    echo -e "${RED}Error: nginx binary not found for $TARGET_ARCH${NC}"
    echo "Expected: $NGINX_BINARY"
    echo "Please run ./scripts/build-android.sh first"
    exit 1
fi

# Generate certificates if they don't exist
if [ ! -f "$CERTS_DIR/server.crt" ]; then
    echo -e "${YELLOW}Generating certificates...${NC}"
    "$PROJECT_ROOT/scripts/generate-certs.sh"
fi

# Generate test content if it doesn't exist
if [ ! -f "$TEST_DIR/html/index.html" ]; then
    echo -e "${YELLOW}Generating test content...${NC}"
    "$PROJECT_ROOT/scripts/generate-test-content.sh"
fi

# Create directories on Android
echo -e "${YELLOW}Creating directories on device...${NC}"
$ADB_CMD shell "mkdir -p $ANDROID_BIN $ANDROID_CONF $ANDROID_HTML $ANDROID_LOGS $ANDROID_CERTS $ANDROID_TMP"

# Set permissions
$ADB_CMD shell "chmod 755 $ANDROID_BASE"

# Push nginx binary
echo -e "${YELLOW}Pushing nginx binary...${NC}"
$ADB_CMD push "$NGINX_BINARY" "$ANDROID_BIN/"
$ADB_CMD shell "chmod 755 $ANDROID_BIN/nginx"

# Push configuration files
echo -e "${YELLOW}Pushing configuration files...${NC}"
$ADB_CMD push "$CONFIG_DIR/nginx.conf" "$ANDROID_CONF/"
$ADB_CMD push "$CONFIG_DIR/mime.types" "$ANDROID_CONF/"

# Push certificates
echo -e "${YELLOW}Pushing certificates...${NC}"
$ADB_CMD push "$CERTS_DIR/server.crt" "$ANDROID_CERTS/"
$ADB_CMD push "$CERTS_DIR/server.key" "$ANDROID_CERTS/"
$ADB_CMD push "$CERTS_DIR/dhparam.pem" "$ANDROID_CERTS/"
$ADB_CMD shell "chmod 600 $ANDROID_CERTS/server.key"

# Push test content
echo -e "${YELLOW}Pushing test content...${NC}"
$ADB_CMD push "$TEST_DIR/html/." "$ANDROID_HTML/"

# Create startup script
echo -e "${YELLOW}Creating startup script...${NC}"
cat > /tmp/start-nginx.sh << 'EOF'
#!/system/bin/sh

NGINX_BASE="/data/local/tmp/nginx"
NGINX_BIN="$NGINX_BASE/sbin/nginx"
NGINX_CONF="$NGINX_BASE/conf/nginx.conf"
NGINX_PID="$NGINX_BASE/logs/nginx.pid"

# Stop existing nginx if running
if [ -f "$NGINX_PID" ]; then
    echo "Stopping existing nginx..."
    kill $(cat "$NGINX_PID") 2>/dev/null || true
    rm -f "$NGINX_PID"
fi

# Start nginx
echo "Starting nginx..."
"$NGINX_BIN" -c "$NGINX_CONF"

if [ $? -eq 0 ]; then
    echo "nginx started successfully!"
    echo "HTTP:  http://localhost:8080"
    echo "HTTPS: https://localhost:8443 (HTTP/2)"
    echo "HTTP/3: https://localhost:8444 (QUIC)"
else
    echo "Failed to start nginx"
    exit 1
fi
EOF

$ADB_CMD push /tmp/start-nginx.sh "$ANDROID_BASE/"
$ADB_CMD shell "chmod 755 $ANDROID_BASE/start-nginx.sh"
rm /tmp/start-nginx.sh

# Create stop script
cat > /tmp/stop-nginx.sh << 'EOF'
#!/system/bin/sh

NGINX_PID="/data/local/tmp/nginx/logs/nginx.pid"

if [ -f "$NGINX_PID" ]; then
    echo "Stopping nginx..."
    kill $(cat "$NGINX_PID") 2>/dev/null
    rm -f "$NGINX_PID"
    echo "nginx stopped"
else
    echo "nginx is not running"
fi
EOF

$ADB_CMD push /tmp/stop-nginx.sh "$ANDROID_BASE/"
$ADB_CMD shell "chmod 755 $ANDROID_BASE/stop-nginx.sh"
rm /tmp/stop-nginx.sh

# Verify deployment
echo -e "${YELLOW}Verifying deployment...${NC}"
NGINX_VERSION=$($ADB_CMD shell "$ANDROID_BIN/nginx -v" 2>&1 | head -1)

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo ""
echo "Deployment summary:"
echo "  nginx version: $NGINX_VERSION"
echo "  Binary: $ANDROID_BIN/nginx"
echo "  Config: $ANDROID_CONF/nginx.conf"
echo "  Content: $ANDROID_HTML/"
echo "  Certificates: $ANDROID_CERTS/"
echo ""
echo "To start nginx on device:"
echo "  $ADB_CMD shell $ANDROID_BASE/start-nginx.sh"
echo ""
echo "To stop nginx on device:"
echo "  $ADB_CMD shell $ANDROID_BASE/stop-nginx.sh"
echo ""
echo "To view logs:"
echo "  $ADB_CMD shell cat $ANDROID_LOGS/error.log"
echo "  $ADB_CMD shell cat $ANDROID_LOGS/access.log"
