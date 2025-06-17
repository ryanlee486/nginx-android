# nginx Android Cross-Compilation Patches

This directory contains patches required to build nginx for Android using the Android NDK.

## Patch Files

### 01-cross-compilation-sizeof.patch
**Purpose**: Fix nginx's `auto/types/sizeof` script for cross-compilation.

**Problem**: nginx's configure script tries to execute compiled test programs to determine type sizes, which fails when cross-compiling because the target binaries can't run on the host system.

**Solution**: Replace the runtime size detection with compile-time size detection using preprocessor macros and compiler error messages.

### 02-cross-compilation-feature.patch
**Purpose**: Disable runtime feature tests when cross-compiling.

**Problem**: nginx's feature detection tries to run compiled test programs, which fails during cross-compilation.

**Solution**: Modify the feature test logic to skip runtime tests when `NGX_CROSSBUILD` is set.

### 03-android-os-detection.patch
**Purpose**: Force Linux configuration when cross-compiling for Android.

**Problem**: nginx detects the host OS (macOS/Darwin) and uses Darwin-specific configuration, but Android needs Linux configuration.

**Solution**: Override OS detection to use Linux configuration when cross-compiling for Android.

### 04-android-disable-crypt.patch
**Purpose**: Disable crypt_r() feature detection for Android.

**Problem**: Android doesn't provide the `crypt.h` header or `crypt_r()` function that nginx tries to detect.

**Solution**: Comment out the crypt_r() feature test in the Linux configuration.

### 05-android-linux-config.patch
**Purpose**: Adapt Linux configuration for Android compatibility.

**Problem**: 
- Android doesn't have `crypt.h`
- `NGX_CPU_CACHE_LINE` is not defined for Android
- nginx tries to use crypt functions that don't exist on Android

**Solution**: 
- Comment out `#include <crypt.h>`
- Define `NGX_CPU_CACHE_LINE` as 64 bytes (standard for ARM64)
- Set `NGX_CRYPT` to 0 to disable crypt functionality

### 06-android-disable-crypt-user.patch
**Purpose**: Disable crypt() usage in user authentication code.

**Problem**: nginx's user authentication code calls `crypt()` which doesn't exist on Android.

**Solution**: Replace the `crypt()` call with a NULL assignment, effectively disabling password authentication.

### 07-android-epoll-macros.patch
**Purpose**: Fix EPOLL macro compilation issues on Android.

**Problem**: Android NDK defines EPOLL constants with type casting that can't be used in preprocessor expressions, causing compilation errors.

**Solution**: Comment out the problematic preprocessor checks that compare nginx event constants with EPOLL constants.

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

## Notes

- All patches are designed to be **non-destructive** and **reversible**
- The build script automatically handles patch application and rollback
- Patches are based on nginx 1.26.2 - may need updates for other versions
- These patches specifically target Android NDK cross-compilation issues
