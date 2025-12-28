#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2024 Hyperpolymath
#
# generate-ca.sh - Generate Ed448 Root and Intermediate Certificate Authorities
#
# Usage: ./generate-ca.sh <domain> [root-validity-days] [intermediate-validity-days]

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly CA_DIR="${PROJECT_ROOT}/ca"

DOMAIN="${1:-example.com}"
ROOT_VALIDITY="${2:-3650}"      # 10 years
INTER_VALIDITY="${3:-1825}"     # 5 years

echo "=== Explicit Trust Plane - CA Generation ==="
echo "Domain: ${DOMAIN}"
echo "Root validity: ${ROOT_VALIDITY} days"
echo "Intermediate validity: ${INTER_VALIDITY} days"
echo ""

# --- Root CA ---
echo "[1/4] Generating Ed448 Root CA private key..."
mkdir -p "${CA_DIR}/root"
openssl genpkey -algorithm ED448 -out "${CA_DIR}/root/ca-ed448.key"
chmod 600 "${CA_DIR}/root/ca-ed448.key"

echo "[2/4] Generating Root CA certificate..."
openssl req -new -x509 \
    -key "${CA_DIR}/root/ca-ed448.key" \
    -out "${CA_DIR}/root/ca-ed448.crt" \
    -days "${ROOT_VALIDITY}" \
    -subj "/CN=${DOMAIN} Root CA/O=${DOMAIN}/C=US" \
    -addext "basicConstraints=critical,CA:TRUE,pathlen:1" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -addext "subjectKeyIdentifier=hash"

# --- Intermediate CA ---
echo "[3/4] Generating Ed448 Intermediate CA private key..."
mkdir -p "${CA_DIR}/intermediate"
openssl genpkey -algorithm ED448 -out "${CA_DIR}/intermediate/intermediate-ed448.key"
chmod 600 "${CA_DIR}/intermediate/intermediate-ed448.key"

echo "[4/4] Generating Intermediate CA certificate..."
# Create CSR for intermediate
openssl req -new \
    -key "${CA_DIR}/intermediate/intermediate-ed448.key" \
    -out "${CA_DIR}/intermediate/intermediate-ed448.csr" \
    -subj "/CN=${DOMAIN} Intermediate CA/O=${DOMAIN}/C=US"

# Sign intermediate with root
openssl x509 -req \
    -in "${CA_DIR}/intermediate/intermediate-ed448.csr" \
    -CA "${CA_DIR}/root/ca-ed448.crt" \
    -CAkey "${CA_DIR}/root/ca-ed448.key" \
    -CAcreateserial \
    -out "${CA_DIR}/intermediate/intermediate-ed448.crt" \
    -days "${INTER_VALIDITY}" \
    -extfile <(printf "basicConstraints=critical,CA:TRUE,pathlen:0\nkeyUsage=critical,keyCertSign,cRLSign\nsubjectKeyIdentifier=hash\nauthorityKeyIdentifier=keyid:always")

# Create certificate chain
cat "${CA_DIR}/intermediate/intermediate-ed448.crt" "${CA_DIR}/root/ca-ed448.crt" > "${CA_DIR}/intermediate/chain.crt"

# Export DER for DNS CERT records
openssl x509 -in "${CA_DIR}/root/ca-ed448.crt" -outform DER -out "${CA_DIR}/root/ca-ed448.crt.der"
openssl x509 -in "${CA_DIR}/intermediate/intermediate-ed448.crt" -outform DER -out "${CA_DIR}/intermediate/intermediate-ed448.crt.der"

# Create Base64 for DNS
base64 -w0 < "${CA_DIR}/root/ca-ed448.crt.der" > "${CA_DIR}/root/ca-ed448.crt.b64"
base64 -w0 < "${CA_DIR}/intermediate/intermediate-ed448.crt.der" > "${CA_DIR}/intermediate/intermediate-ed448.crt.b64"

echo ""
echo "=== CA Generation Complete ==="
echo ""
echo "Root CA:"
echo "  Private key: ${CA_DIR}/root/ca-ed448.key (KEEP OFFLINE!)"
echo "  Certificate: ${CA_DIR}/root/ca-ed448.crt"
echo "  DNS (Base64): ${CA_DIR}/root/ca-ed448.crt.b64"
echo ""
echo "Intermediate CA:"
echo "  Private key: ${CA_DIR}/intermediate/intermediate-ed448.key"
echo "  Certificate: ${CA_DIR}/intermediate/intermediate-ed448.crt"
echo "  Chain:       ${CA_DIR}/intermediate/chain.crt"
echo "  DNS (Base64): ${CA_DIR}/intermediate/intermediate-ed448.crt.b64"
echo ""
echo "Root CA fingerprint (SHA256):"
openssl x509 -in "${CA_DIR}/root/ca-ed448.crt" -noout -fingerprint -sha256
echo ""

echo "SECURITY REMINDER:"
echo "  - Move ca-ed448.key to offline/HSM storage immediately"
echo "  - Never store root CA key on networked systems"
