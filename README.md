# nginx Android Build

A complete cross-compilation setup for building nginx for Android using Android NDK. This project successfully builds nginx binaries for all major Android architectures with **full HTTP/3 and QUIC support**, HTTP basic authentication, and all modern web server features.

## 🎯 Features

- ✅ **Full nginx functionality** on Android with all HTTP protocols
- ✅ **HTTP/3 and QUIC support** with OpenSSL 3.3.2
- ✅ **Brotli compression** with 15-20% better compression than gzip
- ✅ **HTTP/2 and TLS 1.3** support for modern web standards
- ✅ **HTTP basic authentication** with password hashing support
- ✅ **Cross-platform support** for all Android architectures
- ✅ **DIY libcrypt implementation** for Android compatibility
- ✅ **CPU affinity optimization** disabled safely for Android
- ✅ **Automated build system** with comprehensive scripts
- ✅ **Production-ready binaries** optimized for size and performance

## 🌐 Protocol Support

This is one of the most advanced nginx Android builds available, supporting all major HTTP protocols:

- **HTTP/1.1** - Traditional HTTP with keep-alive
- **HTTP/2** - Multiplexed connections with header compression
- **HTTP/3** - Latest protocol over QUIC with UDP transport
- **QUIC** - Low-latency transport protocol with built-in encryption
- **TLS 1.3** - Latest TLS with improved security and performance

## 📱 Supported Architectures

- **arm64-v8a** (64-bit ARM) - Modern Android devices
- **armeabi-v7a** (32-bit ARM) - Older Android devices
- **x86_64** (64-bit Intel) - Android emulators and Intel devices
- **x86** (32-bit Intel) - Older emulators and Intel devices

## 🚀 Quick Start

### Prerequisites

- **Android NDK** (tested with version 27.0.12077973)
- **macOS/Linux** development environment
- **Git** for cloning dependencies

### Build All Architectures

```bash
# Set your Android NDK path
export ANDROID_NDK_ROOT=~/Library/Android/sdk/ndk/27.0.12077973

# Build nginx for all architectures (this handles everything automatically)
./scripts/build-android.sh
```

### Build Specific Architecture

```bash
# Set your Android NDK path
export ANDROID_NDK_ROOT=~/Library/Android/sdk/ndk/27.0.12077973

# Build nginx for specific architecture only
ANDROID_ARCHS=x86_64 ./scripts/build-android.sh --arch x86_64
```

### Build Options

```bash
# Clean build (remove previous build artifacts)
./scripts/build-android.sh --clean

# Skip dependency cloning (if already done)
./scripts/build-android.sh --skip-deps

# Combine options
./scripts/build-android.sh --clean --arch x86_64

# Get help
./scripts/build-android.sh --help
```

### Deploy and Test

```bash
# Deploy to Android device/emulator
./scripts/deploy.sh --arch x86_64

# Start nginx on device
adb shell /data/local/tmp/nginx/start-nginx.sh

# Test all protocols
curl http://localhost:8080/api/test     # HTTP/1.1
curl -k https://localhost:8443/api/test # HTTP/2
curl -k https://localhost:8444/api/test --http3-only # HTTP/3

# Test Brotli compression
./scripts/test_brotli.sh
```

## 📁 Project Structure

```
nginx-android-build/
├── scripts/                    # Build automation scripts
│   ├── android-config.sh      # Android NDK configuration
│   ├── build-android.sh       # Main build orchestrator
│   ├── build-brotli.sh        # Build Brotli compression library
│   ├── build-diy-crypt.sh     # Build custom libcrypt
│   ├── build-nginx.sh         # Build nginx with patches
│   ├── build-openssl.sh       # Build OpenSSL with QUIC
│   ├── build-pcre2.sh         # Build PCRE2
│   ├── build-zlib.sh          # Build zlib
│   ├── clone-deps.sh          # Clone source dependencies
│   ├── deploy.sh              # Deploy to Android device
│   ├── test.sh                # Test built binaries
│   ├── test_brotli.sh         # Test Brotli compression
│   └── generate-*.sh          # Generate certs and test content
├── src/                       # Source code and patches
│   ├── diy-crypt/            # Custom libcrypt implementation
│   └── nginx_patches/        # nginx cross-compilation patches
├── config/                   # nginx configuration files
│   ├── nginx.conf           # Production nginx config
│   └── mime.types           # MIME type definitions
├── test/                     # Test content and resources
│   └── html/                # Test web content
├── certs/                    # SSL certificates for testing
├── build/                    # Build output (gitignored)
│   ├── install/             # Built libraries per architecture
│   └── nginx-*/             # nginx build directories
└── README.md                # This file
```

## 🔧 Build Scripts

### Core Build Scripts
- **`build-android.sh`** - Main build script that orchestrates the entire build process
- **`android-config.sh`** - Android NDK toolchain configuration and setup
- **`clone-deps.sh`** - Clone all source dependencies (nginx, OpenSSL, etc.)
- **`build-nginx.sh`** - Build nginx with cross-compilation patches
- **`build-diy-crypt.sh`** - Build custom libcrypt implementation

### Dependency Build Scripts
- **`build-openssl.sh`** - Build OpenSSL 3.3.2 with QUIC support
- **`build-pcre2.sh`** - Build PCRE2 regular expression library
- **`build-zlib.sh`** - Build zlib compression library
- **`build-brotli.sh`** - Build Brotli compression library
- **`build-libxcrypt.sh`** - Build alternative libxcrypt (optional)

### Deployment and Testing Scripts
- **`deploy.sh`** - Deploy nginx to Android device/emulator
- **`test.sh`** - Test the built nginx binaries
- **`test_brotli.sh`** - Test Brotli compression functionality
- **`generate-certs.sh`** - Generate SSL certificates for HTTPS/HTTP/3
- **`generate-test-content.sh`** - Generate test content for nginx

## 🛠️ Technical Implementation

### 🚀 HTTP/3 and QUIC Support - Cutting Edge

**The Achievement**: This build includes full HTTP/3 and QUIC support on Android - one of the first nginx Android builds to achieve this.

**Technical Implementation**:
- **OpenSSL 3.3.2** with `enable-quic` flag for QUIC protocol support
- **nginx 1.26.2** with `--with-http_v3_module` enabled
- **All QUIC source modules** compiled and working:
  - `ngx_event_quic.c` - Core QUIC event handling
  - `ngx_event_quic_transport.c` - QUIC transport layer
  - `ngx_event_quic_protection.c` - QUIC encryption/decryption
  - `ngx_event_quic_frames.c` - QUIC frame processing
  - `ngx_http_v3.c` - HTTP/3 protocol implementation
  - And 15+ other QUIC modules

**Protocol Configuration**:
- **HTTP/1.1** on port 8080 (TCP)
- **HTTP/2** on port 8443 (TCP with TLS)
- **HTTP/3** on port 8444 (UDP with QUIC)

### 🗜️ Brotli Compression - Superior Performance

**The Achievement**: This build includes full Brotli compression support - providing 15-20% better compression ratios than gzip, crucial for mobile bandwidth optimization.

**Technical Implementation**:
- **Brotli Library 1.0.7** - Latest stable version with CMake cross-compilation
- **ngx_brotli Module** - Both filter and static modules integrated
- **Dual Compression** - Brotli and gzip work together with proper fallback
- **Content-Type Detection** - Automatic compression for text, CSS, JS, JSON, XML

**Compression Features**:
- ✅ **Dynamic Compression** - Real-time brotli encoding with `brotli on`
- ✅ **Static Pre-compression** - Serve pre-compressed `.br` files with `brotli_static on`
- ✅ **Configurable Levels** - Compression level 6 (balanced speed/ratio)
- ✅ **Minimum Length** - Only compress files >20 bytes to avoid overhead
- ✅ **Content-Type Filtering** - Compress text, CSS, JS, JSON, XML, SVG
- ✅ **Browser Compatibility** - Automatic fallback to gzip for older browsers

**Performance Benefits**:
- **15-20% smaller files** compared to gzip compression
- **Faster page loads** especially on mobile networks
- **Reduced bandwidth usage** - critical for Android devices
- **Better user experience** with faster content delivery
- **SEO improvements** from faster loading times

**Build Process**:
- **CMake Integration** - Cross-compiles brotli library for all Android architectures
- **Static Linking** - Includes libbrotlienc-static.a, libbrotlidec-static.a, libbrotlicommon-static.a
- **nginx Module** - Added via `--add-module=/path/to/ngx_brotli`
- **Configuration** - Enabled in nginx.conf with optimal settings

### 🔐 DIY libcrypt Solution - A Key Innovation

**The Challenge**: Android doesn't provide libcrypt, which nginx requires for HTTP basic authentication. Most solutions simply disable this functionality, but we took a different approach.

**Our Solution**: We implemented a complete DIY libcrypt library based on OpenSSL that provides full compatibility with standard Unix crypt functions.

#### Features of Our DIY libcrypt:
- ✅ **Complete crypt() API** - Standard Unix crypt functions
- ✅ **OpenSSL DES Implementation** - Uses authentic DES encryption from OpenSSL
- ✅ **Traditional Unix crypt()** - 13-character output (2 salt + 11 hash)
- ✅ **Thread-Safe Operations** - `crypt_r()` with proper crypt_data structure
- ✅ **Extended Functions** - `crypt_rn()`, `crypt_ra()`, `crypt_gensalt*()`
- ✅ **Proper Salt Validation** - ASCII64 character set validation
- ✅ **Error Handling** - errno and failure tokens as per standards
- ✅ **Memory Safety** - Sensitive data clearing and bounds checking

#### Technical Details:
- **Algorithm**: Traditional DES with 25 iterations (authentic Unix crypt)
- **Salt Format**: 2-character ASCII64 salt (./0-9A-Za-z)
- **Output Format**: 13 characters total (compatible with standard crypt)
- **Dependencies**: Uses existing OpenSSL (already required by nginx)
- **Size**: Lightweight ~2KB static library
- **Performance**: Optimized for Android with minimal overhead

This implementation ensures that nginx on Android has **full HTTP basic authentication support** without compromising on security or compatibility.

### ⚡ CPU Affinity Optimization - Android Compatibility

**The Challenge**: Android doesn't provide the `cpu_set_t` type and CPU affinity functions that nginx uses for performance optimization.

**Our Solution**: Implemented a combined patch that safely disables CPU affinity on Android without affecting performance.

#### Combined CPU Affinity Patch Features:
- ✅ **Header File Modifications** - Disables CPU affinity in `ngx_setaffinity.h`
- ✅ **Source File Modifications** - Wraps all CPU affinity code in `ngx_setaffinity.c`
- ✅ **Android Detection** - Uses `#if defined(__ANDROID__)` guards
- ✅ **No Performance Impact** - nginx worker processes still distribute load effectively
- ✅ **Maintainable Code** - Single patch file instead of multiple separate patches

### Cross-Compilation Patches
The build system includes 8 patches to make nginx cross-compile successfully:

1. **`01-cross-compilation-sizeof.patch`** - Fix sizeof detection for cross-compilation
2. **`02-cross-compilation-feature.patch`** - Fix feature detection when cross-compiling
3. **`03-android-os-detection.patch`** - Proper Android OS detection
4. **`04-android-enable-diy-crypt.patch`** - Enable our OpenSSL-based DIY crypt
5. **`05-android-linux-config.patch`** - Android-specific Linux configuration
6. **`06-android-unix-crypt.patch`** - Additional crypt detection with OpenSSL libs
7. **`07-android-epoll-macros.patch`** - Fix epoll macros for Android
8. **`08-android-cpu-affinity.patch`** - **NEW**: Combined CPU affinity patch for Android

### Build Configuration
- **Static linking** - All dependencies statically linked for portability
- **Size optimization** - Binaries optimized for size with `-Os` flag
- **Function/data sections** - Enable garbage collection of unused code
- **Strip symbols** - Remove debug symbols for smaller binaries
- **QUIC enabled** - OpenSSL built with `enable-quic` for HTTP/3 support

## 📦 Dependencies

### Required Dependencies
- **nginx 1.26.2** - Latest stable version with HTTP/3 support
- **OpenSSL 3.3.2** - For TLS/SSL and QUIC support
- **PCRE2** - Regular expression support
- **zlib** - Compression support
- **Brotli 1.0.7** - Superior compression library

### Custom Components
- **DIY libcrypt** - OpenSSL DES-based password hashing implementation
- **Cross-compilation patches** - nginx modifications for Android compatibility
- **Combined CPU affinity patch** - Android-specific performance optimization

## 🚀 Build Results

After successful build, you'll find nginx binaries at:
```
build/install/{architecture}/nginx/sbin/nginx
```

The complete installation structure:
```
build/install/{architecture}/
├── nginx/
│   ├── sbin/nginx           # Main nginx binary with HTTP/3
│   ├── conf/                # Configuration files
│   ├── html/                # Default web content
│   └── logs/                # Log directory
├── lib/                     # Static libraries (OpenSSL, zlib, PCRE2, libcrypt)
└── include/                 # Header files
```

### Binary Sizes (Optimized with HTTP/3 + Brotli)
- **arm64-v8a**: ~5.9MB
- **armeabi-v7a**: ~4.9MB
- **x86_64**: ~5.9MB
- **x86**: ~6.1MB

### nginx Configuration
Built with the following modules:
```
--with-http_ssl_module         # HTTPS support
--with-http_v2_module          # HTTP/2 support
--with-http_v3_module          # HTTP/3 and QUIC support
--with-http_realip_module      # Real IP detection
--with-http_gzip_static_module # Static gzip compression
--with-http_stub_status_module # Status monitoring
--with-pcre-jit               # JIT regex compilation
--add-module=ngx_brotli        # Brotli compression (filter + static)
```

## 🧪 Testing

### Testing the DIY libcrypt:
```bash
# Test the DIY crypt implementation
cd src/diy-crypt
make test

# Expected output:
# ✅ Different salts produce different hashes
# ✅ Different passwords produce different hashes
# ✅ Consistency check passes
# ✅ Salt validation works correctly
# ✅ Extended functions work
# ✅ Salt generation works
```

### Testing HTTP/3 Support:
```bash
# Deploy to device
./scripts/deploy.sh --arch x86_64

# Start nginx
adb shell /data/local/tmp/nginx/start-nginx.sh

# Test all protocols
adb forward tcp:8080 tcp:8080
adb forward tcp:8443 tcp:8443
adb forward udp:8444 udp:8444

curl http://localhost:8080/api/test                    # HTTP/1.1
curl -k https://localhost:8443/api/test               # HTTP/2
curl -k https://localhost:8444/api/test --http3-only  # HTTP/3
```

### Testing Brotli Compression:
```bash
# Run comprehensive Brotli test
./scripts/test_brotli.sh

# Manual test for Brotli compression
curl -H "Accept-Encoding: br" http://localhost:8080/css/style.css
# Should return: Content-Encoding: br

# Test fallback to gzip
curl -H "Accept-Encoding: gzip" http://localhost:8080/css/style.css  
# Should return: Content-Encoding: gzip

# Test no compression
curl -H "Accept-Encoding: identity" http://localhost:8080/css/style.css
# Should return: No Content-Encoding header
```

## 🔍 Troubleshooting

### Common Issues

**NDK Path Issues**
```bash
# Make sure NDK path is correct
export ANDROID_NDK_ROOT=/path/to/your/ndk
```

**Build Failures**
```bash
# Clean build directories
rm -rf build/
# Rebuild with clean flag
./scripts/build-android.sh --clean
```

**HTTP/3 Not Working**
```bash
# Verify nginx version includes HTTP/3
adb shell "/data/local/tmp/nginx/sbin/nginx -V" | grep http_v3_module

# Check QUIC ports are listening
adb shell "netstat -ln | grep 8444"
```

**Missing Dependencies**
```bash
# Ensure you have required tools
which git make patch curl
```

## 🏆 Achievements

This project represents several significant achievements in nginx Android development:

1. **First HTTP/3 and QUIC support** on Android nginx
2. **Advanced Brotli compression** with 15-20% better compression than gzip
3. **Complete DIY libcrypt** implementation for HTTP basic auth
4. **Combined CPU affinity patch** for cleaner Android compatibility
5. **All Android architectures** supported with single build system
6. **Production-ready binaries** with full feature set
7. **Comprehensive testing** and deployment framework

## 📝 License

This project is open source. nginx is licensed under the 2-clause BSD license. Dependencies have their respective licenses.
