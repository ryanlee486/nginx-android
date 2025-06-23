# nginx Android Build

A complete cross-compilation setup for building nginx for Android using Android NDK. This project successfully builds nginx binaries for all major Android architectures with full functionality including HTTP basic authentication.

## 🎯 Features

- ✅ **Full nginx functionality** on Android
- ✅ **HTTP basic authentication** with password hashing support
- ✅ **Cross-platform support** for all Android architectures
- ✅ **DIY libcrypt implementation** for Android compatibility
- ✅ **Automated build system** with comprehensive scripts
- ✅ **Production-ready binaries** optimized for size and performance

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
./scripts/build-android.sh --arch arm64-v8a
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

## 📁 Project Structure

```
nginx-android-build/
├── scripts/                    # Build automation scripts
│   ├── android-config.sh      # Android NDK configuration
│   ├── build-all-deps.sh      # Build all dependencies
│   ├── build-diy-crypt.sh     # Build custom libcrypt
│   ├── build-nginx.sh         # Build nginx
│   ├── build-openssl.sh       # Build OpenSSL
│   ├── build-pcre2.sh         # Build PCRE2
│   └── build-zlib.sh          # Build zlib
├── src/                       # Source code and patches
│   ├── diy-crypt/            # Custom libcrypt implementation
│   └── nginx_patches/        # nginx cross-compilation patches
├── build/                    # Build output (gitignored)
│   ├── sources/             # Downloaded source code
│   ├── install/             # Built libraries per architecture
│   └── nginx-*/             # nginx build directories
└── README.md                # This file
```

## 🔧 Build Scripts

### Core Build Scripts
- **`build-android.sh`** - Main build script that orchestrates the entire build process
- **`android-config.sh`** - Android NDK toolchain configuration and setup
- **`clone-deps.sh`** - Clone all source dependencies
- **`build-nginx.sh`** - Build nginx with cross-compilation patches
- **`build-diy-crypt.sh`** - Build custom libcrypt implementation

### Dependency Build Scripts
- **`build-openssl.sh`** - Build OpenSSL for Android
- **`build-pcre2.sh`** - Build PCRE2 regular expression library
- **`build-zlib.sh`** - Build zlib compression library
- **`build-libxcrypt.sh`** - Build alternative libxcrypt (optional)

### Utility Scripts
- **`test.sh`** - Test the built nginx binaries
- **`deploy.sh`** - Deploy nginx to Android device
- **`generate-certs.sh`** - Generate SSL certificates for testing
- **`generate-test-content.sh`** - Generate test content for nginx

## 🛠️ Technical Implementation

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

#### Testing the DIY libcrypt:
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

### Cross-Compilation Patches
The build system includes several patches to make nginx cross-compile successfully:

1. **`01-cross-compilation-sizeof.patch`** - Fix sizeof detection for cross-compilation
2. **`02-cross-compilation-feature.patch`** - Fix feature detection when cross-compiling
3. **`03-android-os-detection.patch`** - Proper Android OS detection
4. **`04-android-enable-diy-crypt.patch`** - Enable our OpenSSL-based DIY crypt
5. **`05-android-linux-config.patch`** - Android-specific Linux configuration
6. **`06-android-unix-crypt.patch`** - Additional crypt detection with OpenSSL libs
7. **`07-android-epoll-macros.patch`** - Fix epoll macros for Android

### Build Configuration
- **Static linking** - All dependencies statically linked for portability
- **Size optimization** - Binaries optimized for size with `-Os` flag
- **Function/data sections** - Enable garbage collection of unused code
- **Strip symbols** - Remove debug symbols for smaller binaries

## 📦 Dependencies

### Required Dependencies
- **nginx** - Latest stable version (1.26.x)
- **OpenSSL** - For TLS/SSL support
- **PCRE2** - Regular expression support
- **zlib** - Compression support

### Custom Components
- **DIY libcrypt** - OpenSSL DES-based password hashing implementation
- **Cross-compilation patches** - nginx modifications for Android compatibility

## 🚀 Build Results

After successful build, you'll find nginx binaries at:
```
build/install/{architecture}/data/local/tmp/nginx/sbin/nginx
```

The complete installation structure:
```
build/install/{architecture}/
├── data/local/tmp/nginx/
│   ├── sbin/nginx           # Main nginx binary
│   ├── conf/                # Configuration files
│   ├── html/                # Default web content
│   └── logs/                # Log directory
├── lib/                     # Static libraries (OpenSSL, zlib, PCRE2, libcrypt)
└── include/                 # Header files
```

### Binary Sizes (Optimized)
- **arm64-v8a**: ~5.2MB
- **armeabi-v7a**: ~4.2MB
- **x86_64**: ~5.2MB
- **x86**: ~5.4MB

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
# Rebuild dependencies
./scripts/build-all-deps.sh
```

**Missing Dependencies**
```bash
# Ensure you have required tools
which git make patch
```

## 📝 License

This project is open source. nginx is licensed under the 2-clause BSD license. Dependencies have their respective licenses.
