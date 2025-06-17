#!/bin/bash

# Generate test certificates for nginx TLS testing
# This script creates self-signed certificates for testing TLS 1.3, HTTP/2, and HTTP/3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project directories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERTS_DIR="${PROJECT_ROOT}/certs"

echo -e "${GREEN}Generating test certificates...${NC}"

# Create certs directory
mkdir -p "$CERTS_DIR"
cd "$CERTS_DIR"

# Certificate configuration
CERT_DAYS=365
CERT_BITS=2048
CERT_COUNTRY="US"
CERT_STATE="CA"
CERT_CITY="San Francisco"
CERT_ORG="nginx Android Test"
CERT_UNIT="IT Department"
CERT_COMMON_NAME="localhost"
CERT_EMAIL="test@example.com"

# Subject for certificate
CERT_SUBJECT="/C=${CERT_COUNTRY}/ST=${CERT_STATE}/L=${CERT_CITY}/O=${CERT_ORG}/OU=${CERT_UNIT}/CN=${CERT_COMMON_NAME}/emailAddress=${CERT_EMAIL}"

echo -e "${YELLOW}Certificate configuration:${NC}"
echo "  Common Name: $CERT_COMMON_NAME"
echo "  Organization: $CERT_ORG"
echo "  Valid for: $CERT_DAYS days"
echo "  Key size: $CERT_BITS bits"
echo ""

# Generate private key
echo -e "${YELLOW}Generating private key...${NC}"
openssl genrsa -out server.key $CERT_BITS

# Generate certificate signing request
echo -e "${YELLOW}Generating certificate signing request...${NC}"
openssl req -new -key server.key -out server.csr -subj "$CERT_SUBJECT"

# Create certificate extensions file for SAN (Subject Alternative Names)
cat > server.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
DNS.3 = 127.0.0.1
DNS.4 = ::1
IP.1 = 127.0.0.1
IP.2 = ::1
IP.3 = 10.0.2.15
IP.4 = 192.168.1.100
EOF

# Generate self-signed certificate
echo -e "${YELLOW}Generating self-signed certificate...${NC}"
openssl x509 -req -in server.csr -signkey server.key -out server.crt -days $CERT_DAYS -extfile server.ext

# Generate DH parameters for perfect forward secrecy
echo -e "${YELLOW}Generating DH parameters (this may take a while)...${NC}"
openssl dhparam -out dhparam.pem 2048

# Create combined certificate file
echo -e "${YELLOW}Creating combined certificate file...${NC}"
cat server.crt > server-combined.pem
cat server.key >> server-combined.pem

# Set appropriate permissions
chmod 600 server.key server-combined.pem
chmod 644 server.crt server.csr dhparam.pem server.ext

# Verify certificate
echo -e "${YELLOW}Verifying certificate...${NC}"
openssl x509 -in server.crt -text -noout > cert-info.txt

# Display certificate information
echo -e "${GREEN}Certificate generated successfully!${NC}"
echo ""
echo "Files created:"
echo "  server.key         - Private key"
echo "  server.crt         - Certificate"
echo "  server.csr         - Certificate signing request"
echo "  server-combined.pem - Combined certificate and key"
echo "  dhparam.pem        - DH parameters"
echo "  server.ext         - Certificate extensions"
echo "  cert-info.txt      - Certificate details"
echo ""

# Show certificate details
echo -e "${YELLOW}Certificate details:${NC}"
openssl x509 -in server.crt -noout -subject -issuer -dates -fingerprint

echo ""
echo -e "${GREEN}Certificates are ready for testing!${NC}"
echo "Location: $CERTS_DIR"
echo ""
echo "To use with nginx, add to your nginx.conf:"
echo "  ssl_certificate     $CERTS_DIR/server.crt;"
echo "  ssl_certificate_key $CERTS_DIR/server.key;"
echo "  ssl_dhparam         $CERTS_DIR/dhparam.pem;"
