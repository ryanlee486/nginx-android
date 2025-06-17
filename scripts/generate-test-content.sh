#!/bin/bash

# Generate test content for nginx testing
# This script creates HTML, CSS, JS, and other test files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project directories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="${PROJECT_ROOT}/test"
HTML_DIR="${TEST_DIR}/html"

echo -e "${GREEN}Generating test content...${NC}"

# Create test directories
mkdir -p "$HTML_DIR"/{css,js,images,api}

# Generate main index.html
cat > "$HTML_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>nginx Android Test Server</title>
    <link rel="stylesheet" href="/css/style.css">
    <link rel="icon" href="/images/favicon.ico" type="image/x-icon">
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 nginx for Android</h1>
            <p>HTTP/2, HTTP/3, TLS 1.3, and QUIC Test Server</p>
        </header>
        
        <main>
            <section class="protocol-tests">
                <h2>Protocol Tests</h2>
                <div class="test-grid">
                    <div class="test-card">
                        <h3>HTTP/1.1</h3>
                        <p>Port: 8080</p>
                        <button onclick="testProtocol('http', 8080)">Test HTTP/1.1</button>
                        <div id="http-result" class="result"></div>
                    </div>
                    
                    <div class="test-card">
                        <h3>HTTP/2</h3>
                        <p>Port: 8443 (HTTPS)</p>
                        <button onclick="testProtocol('https', 8443)">Test HTTP/2</button>
                        <div id="https-result" class="result"></div>
                    </div>
                    
                    <div class="test-card">
                        <h3>HTTP/3</h3>
                        <p>Port: 8444 (QUIC)</p>
                        <button onclick="testProtocol('https', 8444)">Test HTTP/3</button>
                        <div id="quic-result" class="result"></div>
                    </div>
                </div>
            </section>
            
            <section class="features">
                <h2>Features</h2>
                <ul>
                    <li>✅ nginx latest stable version</li>
                    <li>✅ OpenSSL with TLS 1.3 support</li>
                    <li>✅ HTTP/2 server push</li>
                    <li>✅ HTTP/3 and QUIC protocol</li>
                    <li>✅ Brotli and Gzip compression</li>
                    <li>✅ Static file serving</li>
                    <li>✅ Security headers</li>
                </ul>
            </section>
            
            <section class="server-info">
                <h2>Server Information</h2>
                <div id="server-info">
                    <p>Loading server information...</p>
                </div>
            </section>
        </main>
        
        <footer>
            <p>nginx for Android Build System</p>
        </footer>
    </div>
    
    <script src="/js/app.js"></script>
</body>
</html>
EOF

# Generate CSS
cat > "$HTML_DIR/css/style.css" << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: #333;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 20px;
}

header {
    text-align: center;
    color: white;
    margin-bottom: 40px;
}

header h1 {
    font-size: 3rem;
    margin-bottom: 10px;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
}

header p {
    font-size: 1.2rem;
    opacity: 0.9;
}

main {
    background: white;
    border-radius: 15px;
    padding: 40px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    margin-bottom: 20px;
}

section {
    margin-bottom: 40px;
}

h2 {
    color: #4a5568;
    margin-bottom: 20px;
    font-size: 1.8rem;
}

.test-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 20px;
    margin-bottom: 30px;
}

.test-card {
    background: #f7fafc;
    border: 2px solid #e2e8f0;
    border-radius: 10px;
    padding: 20px;
    text-align: center;
    transition: transform 0.2s, box-shadow 0.2s;
}

.test-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 5px 20px rgba(0,0,0,0.1);
}

.test-card h3 {
    color: #2d3748;
    margin-bottom: 10px;
}

.test-card p {
    color: #718096;
    margin-bottom: 15px;
}

button {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    padding: 12px 24px;
    border-radius: 25px;
    cursor: pointer;
    font-size: 1rem;
    transition: transform 0.2s, box-shadow 0.2s;
}

button:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(0,0,0,0.2);
}

button:active {
    transform: translateY(0);
}

.result {
    margin-top: 15px;
    padding: 10px;
    border-radius: 5px;
    font-family: monospace;
    font-size: 0.9rem;
}

.result.success {
    background: #c6f6d5;
    color: #22543d;
    border: 1px solid #9ae6b4;
}

.result.error {
    background: #fed7d7;
    color: #742a2a;
    border: 1px solid #fc8181;
}

.features ul {
    list-style: none;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 10px;
}

.features li {
    padding: 10px;
    background: #edf2f7;
    border-radius: 5px;
    border-left: 4px solid #667eea;
}

.server-info {
    background: #f7fafc;
    padding: 20px;
    border-radius: 10px;
    border: 1px solid #e2e8f0;
}

footer {
    text-align: center;
    color: white;
    opacity: 0.8;
}

@media (max-width: 768px) {
    .container {
        padding: 10px;
    }
    
    header h1 {
        font-size: 2rem;
    }
    
    main {
        padding: 20px;
    }
    
    .test-grid {
        grid-template-columns: 1fr;
    }
}
EOF

# Generate JavaScript
cat > "$HTML_DIR/js/app.js" << 'EOF'
// nginx Android Test Application

document.addEventListener('DOMContentLoaded', function() {
    loadServerInfo();
});

async function testProtocol(protocol, port) {
    const resultId = protocol === 'http' ? 'http-result' : 
                    port === 8443 ? 'https-result' : 'quic-result';
    const resultDiv = document.getElementById(resultId);
    
    resultDiv.innerHTML = 'Testing...';
    resultDiv.className = 'result';
    
    try {
        const url = `${protocol}://${window.location.hostname}:${port}/api/test`;
        const response = await fetch(url);
        const data = await response.json();
        
        resultDiv.innerHTML = `
            <strong>✅ Success!</strong><br>
            Protocol: ${data.protocol || 'Unknown'}<br>
            Status: ${data.status}<br>
            Server: ${data.server}<br>
            ${data.tls ? `TLS: ${data.tls}<br>` : ''}
            ${data.quic ? `QUIC: ${data.quic}<br>` : ''}
            Response Time: ${Date.now() - startTime}ms
        `;
        resultDiv.className = 'result success';
    } catch (error) {
        resultDiv.innerHTML = `
            <strong>❌ Error!</strong><br>
            ${error.message}
        `;
        resultDiv.className = 'result error';
    }
}

async function loadServerInfo() {
    const serverInfoDiv = document.getElementById('server-info');
    
    try {
        const response = await fetch('/api/test');
        const data = await response.json();
        
        serverInfoDiv.innerHTML = `
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">
                <div><strong>Server:</strong> ${data.server}</div>
                <div><strong>Protocol:</strong> ${data.protocol}</div>
                <div><strong>Status:</strong> ${data.status}</div>
                <div><strong>Timestamp:</strong> ${new Date().toLocaleString()}</div>
            </div>
        `;
    } catch (error) {
        serverInfoDiv.innerHTML = `
            <p style="color: #e53e3e;">Failed to load server information: ${error.message}</p>
        `;
    }
}

// Performance monitoring
let startTime;
document.addEventListener('click', function(e) {
    if (e.target.tagName === 'BUTTON') {
        startTime = Date.now();
    }
});
EOF

# Generate a simple favicon
cat > "$HTML_DIR/images/favicon.ico" << 'EOF'
# This would be a binary favicon file in a real implementation
# For now, we'll create a placeholder
EOF

# Generate test files for different sizes
echo -e "${YELLOW}Generating test files of various sizes...${NC}"

# Small file (1KB)
head -c 1024 /dev/urandom | base64 > "$HTML_DIR/test-1kb.txt"

# Medium file (100KB)
head -c 102400 /dev/urandom | base64 > "$HTML_DIR/test-100kb.txt"

# Large file (1MB)
head -c 1048576 /dev/urandom | base64 > "$HTML_DIR/test-1mb.txt"

echo -e "${GREEN}Test content generated successfully!${NC}"
echo ""
echo "Generated files:"
echo "  $HTML_DIR/index.html - Main test page"
echo "  $HTML_DIR/css/style.css - Stylesheet"
echo "  $HTML_DIR/js/app.js - JavaScript application"
echo "  $HTML_DIR/test-*.txt - Test files for performance testing"
echo ""
echo "Test content location: $HTML_DIR"
