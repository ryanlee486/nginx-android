# Build nginx web server for android

## Key Features
- Use nginx as the web server for static content delivery.
- Support for HTTP/2 and HTTP/3.
- Support for TLS 1.3.
- Support for QUIC.

## Implementation
- Use most recent version of nginx, clone the stable release to project.
- Use openssl for TLS 1.3 support, since android missing openssl, clone the stable release of openssl to project.
- Clone other required libraries to project.
- Libraries are static linked to nginx.
- Create scripts to build nginx and openssl for android, use build directory for all build and build each library and install to build directory.
- Assume the host already have android ndk and android studio installed.

## Test
- Generate test certificates to use for TLS testing.
- Generate test content to use for testing.
- Generate nginx config file to use for testing.
- Use ADB to push test content and config file to android emulator.
- Use ADB for debugging.
- Run nginx on android emulator.
- Use node.js for complex testing, use curl for simple testing.
- Implement test cases for each feature.
