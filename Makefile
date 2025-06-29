# nginx for Android Build System Makefile

.PHONY: help clean deps build test deploy certs content all

# Default target
help:
	@echo "nginx for Android Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  help     - Show this help message"
	@echo "  deps     - Clone all dependencies"
	@echo "  certs    - Generate test certificates"
	@echo "  content  - Generate test content"
	@echo "  build    - Build nginx and dependencies for Android"
	@echo "  deploy   - Deploy to Android device/emulator"
	@echo "  test     - Run comprehensive test suite"
	@echo "  clean    - Clean build directories"
	@echo "  all      - Run complete build pipeline"
	@echo ""
	@echo "Build options:"
	@echo "  ARCH=<arch>     - Build for specific architecture (arm64-v8a, armeabi-v7a, x86_64, x86)"
	@echo "  DEVICE=<id>     - Target specific device ID"
	@echo "  CLEAN=1         - Clean build before building"
	@echo ""
	@echo "Examples:"
	@echo "  make build ARCH=arm64-v8a"
	@echo "  make deploy DEVICE=emulator-5554"
	@echo "  make test DEVICE=emulator-5554"

# Clone dependencies
deps:
	@echo "Cloning dependencies..."
	./scripts/clone-deps.sh

# Generate certificates
certs:
	@echo "Generating test certificates..."
	./scripts/generate-certs.sh

# Generate test content
content:
	@echo "Generating test content..."
	./scripts/generate-test-content.sh

# Build nginx and dependencies
build: deps
	@echo "Building nginx for Android..."
ifdef CLEAN
	./scripts/build-android.sh --clean $(if $(ARCH),--arch $(ARCH))
else
	./scripts/build-android.sh $(if $(ARCH),--arch $(ARCH))
endif

# Deploy to Android device
deploy: certs content
	@echo "Deploying to Android device..."
	./scripts/deploy.sh $(if $(ARCH),--arch $(ARCH)) $(if $(DEVICE),--device $(DEVICE))

# Run tests
test:
	@echo "Running test suite..."
	./scripts/test.sh $(if $(DEVICE),--device $(DEVICE))

# Clean build directories
clean:
	@echo "Cleaning build directories..."
	rm -rf build/
	rm -rf src/
	@echo "Build directories cleaned"

# Complete build pipeline
all: clean deps certs content build deploy test
	@echo ""
	@echo "🎉 Complete build pipeline finished successfully!"
	@echo ""
	@echo "nginx for Android is ready with:"
	@echo "  ✅ HTTP/1.1, HTTP/2, HTTP/3 support"
	@echo "  ✅ TLS 1.3 and QUIC protocols"
	@echo "  ✅ Comprehensive test suite passed"
	@echo ""
	@echo "Access your nginx server:"
	@echo "  HTTP:  http://localhost:8080"
	@echo "  HTTPS: https://localhost:8443 (HTTP/2)"
	@echo "  HTTP/3: https://localhost:8444 (QUIC)"

# Development targets
dev-build: deps
	@echo "Development build (skip tests)..."
	./scripts/build-android.sh --skip-deps $(if $(ARCH),--arch $(ARCH))

dev-deploy: certs content
	@echo "Development deployment..."
	./scripts/deploy.sh --force $(if $(ARCH),--arch $(ARCH)) $(if $(DEVICE),--device $(DEVICE))

# Quick test (skip deployment)
quick-test:
	@echo "Quick test (skip deployment)..."
	./scripts/test.sh --skip-deploy $(if $(DEVICE),--device $(DEVICE))

# Architecture-specific targets
build-arm64:
	$(MAKE) build ARCH=arm64-v8a

build-arm:
	$(MAKE) build ARCH=armeabi-v7a

build-x86_64:
	$(MAKE) build ARCH=x86_64

build-x86:
	$(MAKE) build ARCH=x86

# Build all architectures
build-all:
	@echo "Building for all architectures..."
	./scripts/build-android.sh

# Status and info targets
status:
	@echo "Build Status:"
	@echo "============="
	@if [ -d "src/" ]; then \
		echo "✅ Dependencies cloned"; \
	else \
		echo "❌ Dependencies not cloned"; \
	fi
	@if [ -d "build/install" ]; then \
		echo "✅ Build artifacts present"; \
		echo "Built architectures:"; \
		for arch in arm64-v8a armeabi-v7a x86_64 x86; do \
			if [ -f "build/install/$$arch/nginx/sbin/nginx" ]; then \
				size=$$(ls -lh "build/install/$$arch/nginx/sbin/nginx" | awk '{print $$5}'); \
				echo "  ✅ $$arch - $$size"; \
			else \
				echo "  ❌ $$arch - Not built"; \
			fi; \
		done; \
	else \
		echo "❌ No build artifacts"; \
	fi
	@if [ -f "certs/server.crt" ]; then \
		echo "✅ Test certificates generated"; \
	else \
		echo "❌ Test certificates not generated"; \
	fi
	@if [ -f "test/html/index.html" ]; then \
		echo "✅ Test content generated"; \
	else \
		echo "❌ Test content not generated"; \
	fi

info:
	@echo "nginx for Android Build System"
	@echo "=============================="
	@echo ""
	@echo "Project structure:"
	@echo "  src/          - Source code (nginx, openssl, etc.)"
	@echo "  build/        - Build artifacts and intermediate files"
	@echo "  scripts/      - Build and deployment scripts"
	@echo "  config/       - nginx configuration files"
	@echo "  test/         - Test content and documentation"
	@echo "  certs/        - SSL/TLS certificates for testing"
	@echo ""
	@echo "Supported architectures:"
	@echo "  arm64-v8a     - 64-bit ARM (recommended)"
	@echo "  armeabi-v7a   - 32-bit ARM"
	@echo "  x86_64        - 64-bit x86 (emulator)"
	@echo "  x86           - 32-bit x86 (emulator)"
	@echo ""
	@echo "Features:"
	@echo "  ✅ nginx latest stable"
	@echo "  ✅ OpenSSL with TLS 1.3"
	@echo "  ✅ HTTP/2 and HTTP/3 support"
	@echo "  ✅ QUIC protocol"
	@echo "  ✅ Brotli and Gzip compression"
	@echo "  ✅ Static linking"
	@echo "  ✅ Comprehensive testing"

# Utility targets
logs:
	@echo "Fetching nginx logs from device..."
	adb shell cat /data/local/tmp/nginx/logs/error.log 2>/dev/null || echo "No error log"
	@echo "--- Access Log ---"
	adb shell cat /data/local/tmp/nginx/logs/access.log 2>/dev/null || echo "No access log"

start-nginx:
	@echo "Starting nginx on device..."
	adb shell /data/local/tmp/nginx/start-nginx.sh

stop-nginx:
	@echo "Stopping nginx on device..."
	adb shell /data/local/tmp/nginx/stop-nginx.sh

restart-nginx: stop-nginx start-nginx
	@echo "nginx restarted"
