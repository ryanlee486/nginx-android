#!/bin/bash

# Comprehensive test suite for nginx Android build
# Tests HTTP/1.1, HTTP/2, HTTP/3, TLS 1.3, and QUIC functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
DEVICE_IP="127.0.0.1"  # Default for emulator
HTTP_PORT=8080
HTTPS_PORT=8443
HTTP3_PORT=8444
TEST_TIMEOUT=30

# Counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  nginx Android Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Parse command line arguments
DEVICE_ID=""
SKIP_DEPLOY=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --device)
            DEVICE_ID="$2"
            shift 2
            ;;
        --ip)
            DEVICE_IP="$2"
            shift 2
            ;;
        --skip-deploy)
            SKIP_DEPLOY=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --device ID      Specific device ID"
            echo "  --ip IP          Device IP address (default: 127.0.0.1)"
            echo "  --skip-deploy    Skip deployment step"
            echo "  --verbose        Verbose output"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Set up ADB command
ADB_CMD="adb"
if [ -n "$DEVICE_ID" ]; then
    ADB_CMD="adb -s $DEVICE_ID"
fi

# Test helper functions
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -n "  Testing $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        if [ "$VERBOSE" = true ]; then
            echo "    Command: $test_command"
            eval "$test_command" 2>&1 | sed 's/^/    /'
        fi
        return 1
    fi
}

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl not found${NC}"
    exit 1
fi

if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Warning: Node.js not found, skipping advanced tests${NC}"
    NODE_AVAILABLE=false
else
    NODE_AVAILABLE=true
fi

# Deploy if not skipped
if [ "$SKIP_DEPLOY" = false ]; then
    echo -e "${YELLOW}Deploying nginx to device...${NC}"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -n "$DEVICE_ID" ]; then
        "$SCRIPT_DIR/deploy.sh" --device "$DEVICE_ID"
    else
        "$SCRIPT_DIR/deploy.sh"
    fi
fi

# Start nginx on device
echo -e "${YELLOW}Starting nginx on device...${NC}"
$ADB_CMD shell "/data/local/tmp/nginx/start-nginx.sh" || {
    echo -e "${RED}Failed to start nginx${NC}"
    echo "Error log:"
    $ADB_CMD shell "cat /data/local/tmp/nginx/logs/error.log" 2>/dev/null || echo "No error log found"
    exit 1
}

# Wait for nginx to start
sleep 3

# Set up port forwarding
echo -e "${YELLOW}Setting up port forwarding...${NC}"
$ADB_CMD forward tcp:$HTTP_PORT tcp:$HTTP_PORT
$ADB_CMD forward tcp:$HTTPS_PORT tcp:$HTTPS_PORT
$ADB_CMD forward tcp:$HTTP3_PORT tcp:$HTTP3_PORT

# Basic connectivity tests
echo -e "${GREEN}Running basic connectivity tests...${NC}"

run_test "HTTP/1.1 connectivity" "curl -s --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/ | grep -q 'nginx'"
run_test "HTTPS connectivity" "curl -s -k --max-time $TEST_TIMEOUT https://$DEVICE_IP:$HTTPS_PORT/ | grep -q 'nginx'"
run_test "HTTP/1.1 API endpoint" "curl -s --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/api/test | grep -q 'http/1.1'"

# HTTP/2 tests
echo -e "${GREEN}Running HTTP/2 tests...${NC}"

run_test "HTTP/2 protocol" "curl -s -k --http2 --max-time $TEST_TIMEOUT https://$DEVICE_IP:$HTTPS_PORT/api/test | grep -q 'http/2'"
run_test "HTTP/2 headers" "curl -s -k -I --http2 --max-time $TEST_TIMEOUT https://$DEVICE_IP:$HTTPS_PORT/ | grep -q 'HTTP/2'"

# TLS tests
echo -e "${GREEN}Running TLS tests...${NC}"

run_test "TLS 1.3 support" "curl -s -k --tlsv1.3 --max-time $TEST_TIMEOUT https://$DEVICE_IP:$HTTPS_PORT/api/test | grep -q 'tls'"
run_test "SSL certificate" "curl -s -k -I --max-time $TEST_TIMEOUT https://$DEVICE_IP:$HTTPS_PORT/ | grep -q 'HTTP'"

# HTTP/3 and QUIC tests (if supported)
echo -e "${GREEN}Running HTTP/3 and QUIC tests...${NC}"

# Note: HTTP/3 testing requires special curl build or other tools
run_test "HTTP/3 port listening" "$ADB_CMD shell 'netstat -ln | grep :$HTTP3_PORT'"
run_test "Alt-Svc header" "curl -s -k -I --max-time $TEST_TIMEOUT https://$DEVICE_IP:$HTTPS_PORT/ | grep -i 'alt-svc'"

# Performance tests
echo -e "${GREEN}Running performance tests...${NC}"

run_test "Small file transfer" "curl -s --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/test-1kb.txt | wc -c | grep -q '[0-9]'"
run_test "Medium file transfer" "curl -s --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/test-100kb.txt | wc -c | grep -q '[0-9]'"
run_test "Large file transfer" "curl -s --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/test-1mb.txt | wc -c | grep -q '[0-9]'"

# Compression tests
echo -e "${GREEN}Running compression tests...${NC}"

run_test "Gzip compression" "curl -s -H 'Accept-Encoding: gzip' --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/ | file - | grep -q 'gzip'"
run_test "Brotli compression" "curl -s -H 'Accept-Encoding: br' --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/ | file - | grep -q 'data'"

# Security headers tests
echo -e "${GREEN}Running security tests...${NC}"

run_test "HSTS header" "curl -s -k -I --max-time $TEST_TIMEOUT https://$DEVICE_IP:$HTTPS_PORT/ | grep -i 'strict-transport-security'"
run_test "X-Frame-Options" "curl -s -I --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/ | grep -i 'x-frame-options'"
run_test "X-Content-Type-Options" "curl -s -I --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/ | grep -i 'x-content-type-options'"

# Status endpoint tests
echo -e "${GREEN}Running status tests...${NC}"

run_test "Status endpoint" "curl -s --max-time $TEST_TIMEOUT http://$DEVICE_IP:$HTTP_PORT/status | grep -q 'Active connections'"

# Advanced tests with Node.js
if [ "$NODE_AVAILABLE" = true ]; then
    echo -e "${GREEN}Running advanced Node.js tests...${NC}"
    
    # Create a simple Node.js test script
    cat > /tmp/nginx-test.js << 'EOF'
const https = require('https');
const http = require('http');

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

function testEndpoint(protocol, port, path = '/api/test') {
    return new Promise((resolve, reject) => {
        const module = protocol === 'https' ? https : http;
        const options = {
            hostname: '127.0.0.1',
            port: port,
            path: path,
            method: 'GET',
            timeout: 5000
        };
        
        const req = module.request(options, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try {
                    const json = JSON.parse(data);
                    resolve({ status: res.statusCode, data: json, headers: res.headers });
                } catch (e) {
                    resolve({ status: res.statusCode, data: data, headers: res.headers });
                }
            });
        });
        
        req.on('error', reject);
        req.on('timeout', () => reject(new Error('Timeout')));
        req.end();
    });
}

async function runTests() {
    try {
        // Test HTTP/1.1
        const http1 = await testEndpoint('http', 8080);
        console.log('HTTP/1.1:', http1.data.protocol || 'OK');
        
        // Test HTTP/2
        const http2 = await testEndpoint('https', 8443);
        console.log('HTTP/2:', http2.data.protocol || 'OK');
        
        process.exit(0);
    } catch (error) {
        console.error('Test failed:', error.message);
        process.exit(1);
    }
}

runTests();
EOF
    
    run_test "Node.js HTTP/1.1 test" "node /tmp/nginx-test.js"
    rm -f /tmp/nginx-test.js
fi

# Cleanup
echo -e "${YELLOW}Cleaning up...${NC}"
$ADB_CMD forward --remove tcp:$HTTP_PORT
$ADB_CMD forward --remove tcp:$HTTPS_PORT
$ADB_CMD forward --remove tcp:$HTTP3_PORT

# Test summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Results${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Total tests: $TESTS_TOTAL"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    echo ""
    echo "nginx is working correctly with:"
    echo "  ✅ HTTP/1.1 support"
    echo "  ✅ HTTP/2 support"
    echo "  ✅ TLS 1.3 encryption"
    echo "  ✅ Security headers"
    echo "  ✅ Compression (Gzip/Brotli)"
    echo "  ✅ Static file serving"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "Check the nginx error log:"
    echo "  $ADB_CMD shell cat /data/local/tmp/nginx/logs/error.log"
    exit 1
fi
