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

# Build dependencies for all architectures
./scripts/build-all-deps.sh

# Build nginx for all architectures
./scripts/build-nginx.sh
```

### Build Specific Architecture

```bash
# Build dependencies for specific architecture
./scripts/build-all-deps.sh arm64-v8a

# Build nginx for specific architecture
./scripts/build-nginx.sh arm64-v8a
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
- **`android-config.sh`** - Android NDK toolchain configuration and setup
- **`build-all-deps.sh`** - Build all dependencies for specified architectures
- **`build-nginx.sh`** - Build nginx with cross-compilation patches
- **`build-diy-crypt.sh`** - Build custom libcrypt implementation

### Dependency Build Scripts
- **`build-openssl.sh`** - Build OpenSSL for Android
- **`build-pcre2.sh`** - Build PCRE2 regular expression library
- **`build-zlib.sh`** - Build zlib compression library

## 🛠️ Technical Implementation

### DIY libcrypt Solution
One of the key challenges was that Android doesn't provide libcrypt, which nginx needs for HTTP basic authentication. Instead of disabling this functionality, we implemented a custom libcrypt that provides:

- `crypt()` function for password hashing
- `crypt_r()` thread-safe variant
- DES-based password hashing compatible with standard implementations
- Lightweight implementation optimized for Android

### Cross-Compilation Patches
The build system includes several patches to make nginx cross-compile successfully:

1. **`01-cross-compilation-sizeof.patch`** - Fix sizeof detection for cross-compilation
2. **`02-cross-compilation-feature.patch`** - Fix feature detection when cross-compiling
3. **`03-android-os-detection.patch`** - Proper Android OS detection
4. **`04-android-enable-diy-crypt.patch`** - Enable our custom crypt implementation
5. **`05-android-linux-config.patch`** - Android-specific Linux configuration
6. **`07-android-epoll-macros.patch`** - Fix epoll macros for Android

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
- **DIY libcrypt** - Custom password hashing implementation
- **Cross-compilation patches** - nginx modifications for Android

## 🚀 Build Results

After successful build, you'll find nginx binaries at:
```
build/install/{architecture}/nginx/sbin/nginx
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
