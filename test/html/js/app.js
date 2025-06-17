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
