# nginx Android Cross-Compilation Patches

This directory contains patches required to build nginx for Android using the Android NDK.

## Patch Files

### 01-cross-compilation-sizeof.patch
**Purpose**: Fix nginx's `auto/types/sizeof` script for cross-compilation.

**Problem**: nginx's configure script tries to execute compiled test programs to determine type sizes, which fails when cross-compiling because the target binaries can't run on the host system.

**Solution**: Replace the runtime size detection with compile-time size detection using preprocessor macros and compiler error messages.

### 02-cross-compilation-feature.patch
**Purpose**: Disable runtime feature tests when cross-compilation.

**Problem**: nginx's feature detection tries to run compiled test programs, which fails during cross-compilation.

**Solution**: Modify the feature test logic to skip runtime tests when `NGX_CROSSBUILD` is set.

### 03-android-os-detection.patch
**Purpose**: Force Linux configuration when cross-compiling for Android.

**Problem**: nginx detects the host OS (macOS/Darwin) and uses Darwin-specific configuration, but Android needs Linux configuration.

**Solution**: Override OS detection to use Linux configuration when cross-compiling for Android.

### 04-android-enable-diy-crypt.patch
**Purpose**: Enable DIY crypt library for Android HTTP basic authentication.

**Problem**: Android doesn't provide the `crypt.h` header or `crypt_r()` function that nginx needs for HTTP basic auth.

**Solution**: Configure nginx to use our custom DIY crypt library that provides crypt functionality for Android.

### 05-android-linux-config.patch
**Purpose**: Adapt Linux configuration for Android compatibility.

**Problem**: 
- Android doesn't have `crypt.h`
- `NGX_CPU_CACHE_LINE` is not defined for Android
- nginx tries to use crypt functions that don't exist on Android

**Solution**: 
- Comment out `#include <crypt.h>`
- Define `NGX_CPU_CACHE_LINE` as 64 bytes (standard for ARM64)
- Configure for DIY crypt library usage

### 06-android-unix-crypt.patch
**Purpose**: Configure nginx to use DIY crypt library instead of system crypt.

**Problem**: nginx's user authentication code calls `crypt()` which doesn't exist on Android.

**Solution**: Configure nginx to use our DIY crypt implementation for password hashing and verification.

### 07-android-epoll-macros.patch
**Purpose**: Fix EPOLL macro compilation issues on Android.

**Problem**: Android NDK defines EPOLL constants with type casting that can't be used in preprocessor expressions, causing compilation errors.

**Solution**: Comment out the problematic preprocessor checks that compare nginx event constants with EPOLL constants.

### 08-android-cpu-affinity.patch
**Purpose**: Disable CPU affinity functionality on Android.

**Problem**: 
- Android doesn't provide the `cpu_set_t` type required for CPU affinity functions
- nginx's CPU affinity code fails to compile on Android NDK
- Functions like `sched_setaffinity()` behave differently on Android

**Solution**: 
- Disable CPU affinity in header file (`ngx_setaffinity.h`) by defining `NGX_HAVE_CPU_AFFINITY` as 0
- Wrap all CPU affinity functions in source file (`ngx_setaffinity.c`) with `#if defined(__ANDROID__)` guards
- Provide empty stub definitions for Android builds

## Usage

These patches are automatically applied by the `build-nginx.sh` script in the correct order. The script will:

1. Roll back the nginx source to a clean state using `git checkout`
2. Apply patches in numerical order (01, 02, 03, etc.)
3. Continue with the nginx build process

## Maintenance

When updating nginx versions or modifying patches:

1. **Test each patch individually** to ensure it applies cleanly
2. **Update patch content** if nginx source code changes
3. **Maintain numerical order** for patch application sequence
4. **Document any new patches** in this README

## Patch Creation

To create new patches:

1. Make changes to the nginx source in `src/nginx/`
2. Generate patch with: `git diff > new-patch.patch`
3. Test the patch on clean source: `git checkout -- . && patch -p1 < new-patch.patch`
4. Add to this directory with appropriate numbering

## Architecture Support

These patches enable nginx to build successfully for all Android architectures:
- **arm64-v8a** (64-bit ARM)
- **armeabi-v7a** (32-bit ARM)
- **x86_64** (64-bit Intel)
- **x86** (32-bit Intel)

## Features Enabled

The patched nginx build includes:
- **HTTP/1.1** support
- **HTTP/2** support  
- **HTTP/3** and **QUIC** support (requires OpenSSL with QUIC)
- **TLS 1.3** support
- **HTTP Basic Authentication** (via DIY crypt library)
- **Gzip compression**
- **Real IP module**
- **Stub status module**

## Notes

- All patches are designed to be **non-destructive** and **reversible**
- The build script automatically handles patch application and rollback
- Patches are based on nginx 1.26.2 - may need updates for other versions
- These patches specifically target Android NDK cross-compilation issues
- CPU affinity is safely disabled on Android without affecting performance
- DIY crypt library provides secure password hashing for HTTP basic auth
