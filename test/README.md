# nginx Android Testing Guide

This directory contains comprehensive testing tools and content for the nginx Android build.

## Test Components

### 1. Automated Test Suite (`../scripts/test.sh`)

The main test script performs comprehensive testing of all nginx features:

```bash
# Run all tests
./scripts/test.sh

# Test specific device
./scripts/test.sh --device emulator-5554

# Skip deployment (if already deployed)
./scripts/test.sh --skip-deploy

# Verbose output for debugging
./scripts/test.sh --verbose
```

### 2. Test Content (`html/`)

- **index.html** - Interactive test page with protocol testing
- **css/style.css** - Responsive stylesheet
- **js/app.js** - JavaScript for protocol testing
- **test-*.txt** - Files of various sizes for performance testing

### 3. Manual Testing

#### HTTP/1.1 Testing
```bash
# Basic connectivity
curl http://localhost:8080/

# API endpoint
curl http://localhost:8080/api/test

# File download
curl -o /dev/null http://localhost:8080/test-1mb.txt
```

#### HTTP/2 Testing
```bash
# HTTP/2 with curl
curl --http2 -k https://localhost:8443/

# Check HTTP/2 headers
curl --http2 -k -I https://localhost:8443/

# HTTP/2 API test
curl --http2 -k https://localhost:8443/api/test
```

#### TLS 1.3 Testing
```bash
# Force TLS 1.3
curl --tlsv1.3 -k https://localhost:8443/

# Check TLS version
openssl s_client -connect localhost:8443 -tls1_3
```

#### HTTP/3 and QUIC Testing
```bash
# Check if HTTP/3 port is listening
adb shell "netstat -ln | grep :8444"

# Check Alt-Svc header
curl -k -I https://localhost:8443/ | grep -i alt-svc
```

### 4. Performance Testing

#### Compression Testing
```bash
# Test Gzip compression
curl -H "Accept-Encoding: gzip" http://localhost:8080/ | file -

# Test Brotli compression
curl -H "Accept-Encoding: br" http://localhost:8080/ | file -
```

#### Load Testing with curl
```bash
# Concurrent requests
for i in {1..10}; do
  curl -s http://localhost:8080/ &
done
wait
```

#### File Transfer Performance
```bash
# Time file downloads
time curl -o /dev/null http://localhost:8080/test-1mb.txt
time curl -o /dev/null --http2 -k https://localhost:8443/test-1mb.txt
```

### 5. Security Testing

#### SSL/TLS Testing
```bash
# SSL Labs style testing
testssl.sh localhost:8443

# Check certificate
openssl x509 -in ../certs/server.crt -text -noout
```

#### Security Headers
```bash
# Check security headers
curl -I http://localhost:8080/ | grep -E "(X-Frame-Options|X-Content-Type-Options|Strict-Transport-Security)"
```

### 6. Node.js Advanced Testing

Create a Node.js test script for more advanced testing:

```javascript
const http = require('http');
const https = require('https');

// Disable certificate validation for testing
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

async function testProtocol(protocol, port) {
    const module = protocol === 'https' ? https : http;
    
    return new Promise((resolve, reject) => {
        const req = module.request({
            hostname: 'localhost',
            port: port,
            path: '/api/test',
            method: 'GET'
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                resolve({
                    status: res.statusCode,
                    headers: res.headers,
                    data: JSON.parse(data)
                });
            });
        });
        
        req.on('error', reject);
        req.end();
    });
}

// Test all protocols
Promise.all([
    testProtocol('http', 8080),
    testProtocol('https', 8443)
]).then(results => {
    console.log('HTTP/1.1:', results[0].data);
    console.log('HTTP/2:', results[1].data);
}).catch(console.error);
```

## Test Scenarios

### 1. Basic Functionality
- [x] HTTP/1.1 server responds
- [x] HTTPS server responds
- [x] Static file serving
- [x] API endpoints work
- [x] Error pages display

### 2. Protocol Support
- [x] HTTP/2 negotiation
- [x] TLS 1.3 handshake
- [x] HTTP/3 port listening
- [x] QUIC protocol support
- [x] Protocol upgrade headers

### 3. Performance
- [x] Gzip compression
- [x] Brotli compression
- [x] Keep-alive connections
- [x] Concurrent requests
- [x] Large file transfers

### 4. Security
- [x] TLS certificate validation
- [x] Security headers present
- [x] HSTS enforcement
- [x] No information disclosure
- [x] Proper error handling

### 5. Android Specific
- [x] Binary runs on target architecture
- [x] File permissions correct
- [x] Log files accessible
- [x] Process management
- [x] Resource usage acceptable

## Troubleshooting

### Common Issues

1. **nginx fails to start**
   ```bash
   # Check error log
   adb shell cat /data/local/tmp/nginx/logs/error.log
   
   # Check permissions
   adb shell ls -la /data/local/tmp/nginx/sbin/nginx
   ```

2. **Port binding errors**
   ```bash
   # Check if ports are in use
   adb shell netstat -ln | grep -E "(8080|8443|8444)"
   
   # Kill existing processes
   adb shell pkill nginx
   ```

3. **Certificate errors**
   ```bash
   # Regenerate certificates
   ./scripts/generate-certs.sh
   
   # Check certificate validity
   openssl x509 -in certs/server.crt -noout -dates
   ```

4. **HTTP/3 not working**
   - Ensure nginx was compiled with HTTP/3 support
   - Check if QUIC modules are loaded
   - Verify UDP port 8444 is accessible

### Debug Mode

Enable debug logging in nginx.conf:
```nginx
error_log /data/local/tmp/nginx/logs/error.log debug;
```

### Performance Monitoring

Monitor nginx performance:
```bash
# Check status
curl http://localhost:8080/status

# Monitor logs in real-time
adb shell tail -f /data/local/tmp/nginx/logs/access.log
```

## Test Results

The test suite validates:
- ✅ HTTP/1.1, HTTP/2, HTTP/3 protocol support
- ✅ TLS 1.3 encryption
- ✅ QUIC protocol functionality
- ✅ Compression algorithms (Gzip, Brotli)
- ✅ Security headers and HSTS
- ✅ Static file serving performance
- ✅ API endpoint functionality
- ✅ Android compatibility and stability
