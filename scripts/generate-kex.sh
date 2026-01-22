#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2024 Hyperpolymath
#
# generate-kex.sh - Generate X25519 Key Exchange Key
#
# Usage: ./generate-kex.sh <domain>

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly KEX_DIR="${PROJECT_ROOT}/kex"

DOMAIN="${1:-example.com}"

echo "=== Explicit Trust Plane - X25519 Key Exchange Generation ==="
echo "Domain: ${DOMAIN}"
echo ""

mkdir -p "${KEX_DIR}"

# Sanitize domain for filename
SAFE_DOMAIN="${DOMAIN//\*/_wildcard_}"

echo "[1/3] Generating X25519 private key..."
openssl genpkey -algorithm X25519 -out "${KEX_DIR}/${SAFE_DOMAIN}.x25519.key"
chmod 600 "${KEX_DIR}/${SAFE_DOMAIN}.x25519.key"

echo "[2/3] Extracting public key..."
openssl pkey -in "${KEX_DIR}/${SAFE_DOMAIN}.x25519.key" -pubout -out "${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub"

# Extract raw 32-byte public key for IPSECKEY record
# X25519 public key in DER format has a 12-byte header, so we take the last 32 bytes
openssl pkey -in "${KEX_DIR}/${SAFE_DOMAIN}.x25519.key" -pubout -outform DER | tail -c 32 > "${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub.raw"

echo "[3/3] Preparing DNS record data..."
base64 -w0 < "${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub.raw" > "${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub.b64"

echo ""
echo "=== Key Exchange Generation Complete ==="
echo ""
echo "Files generated:"
echo "  Private key:     ${KEX_DIR}/${SAFE_DOMAIN}.x25519.key"
echo "  Public key:      ${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub"
echo "  Raw public key:  ${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub.raw"
echo "  DNS (Base64):    ${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub.b64"

echo ""
echo "Public key (Base64, 32 bytes):"
cat "${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub.b64"
echo ""

echo ""
echo "Public key (Hex):"
xxd -p < "${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub.raw" | tr -d '\n'
echo ""

echo ""
echo "=== DNS Record ==="
echo ""
echo "IPSECKEY Record:"
echo "_ipsec.${DOMAIN}. IN IPSECKEY 10 0 2 . $(cat "${KEX_DIR}/${SAFE_DOMAIN}.x25519.pub.b64")"
echo ""
echo "Note: Algorithm '2' is a placeholder. X25519 is identified by the key format."
echo ""
echo "SECURITY NOTE:"
echo "  X25519 keys for key exchange should ideally be ephemeral."
echo "  This static key is suitable for:"
echo "    - IPsec VPN discovery"
echo "    - Initial key agreement bootstrap"
echo "    - Out-of-band key verification"
echo "  For TLS 1.3, ephemeral X25519 keys are generated per-session."
