#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2024 Hyperpolymath
#
# generate-pgp.sh - Generate Modern OpenPGP Key (Ed25519 + CV25519)
#
# Usage: ./generate-pgp.sh "Real Name" "email@example.com" [expiry]

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly PGP_DIR="${PROJECT_ROOT}/pgp"

NAME="${1:-Example User}"
EMAIL="${2:-user@example.com}"
EXPIRY="${3:-2y}"

echo "=== Explicit Trust Plane - OpenPGP Key Generation ==="
echo "Name: ${NAME}"
echo "Email: ${EMAIL}"
echo "Expiry: ${EXPIRY}"
echo ""

mkdir -p "${PGP_DIR}"

# Sanitize email for filename
SAFE_EMAIL="${EMAIL//@/_at_}"
SAFE_EMAIL="${SAFE_EMAIL//./_}"

# Check if key already exists
if gpg --list-keys "${EMAIL}" &>/dev/null; then
    echo "WARNING: Key for ${EMAIL} already exists!"
    echo "Delete it first with: gpg --delete-secret-and-public-key ${EMAIL}"
    exit 1
fi

echo "[1/4] Generating Ed25519 primary key with CV25519 encryption subkey..."

# Generate key batch
gpg --batch --generate-key <<EOF
Key-Type: eddsa
Key-Curve: ed25519
Key-Usage: sign,cert
Subkey-Type: ecdh
Subkey-Curve: cv25519
Subkey-Usage: encrypt
Name-Real: ${NAME}
Name-Email: ${EMAIL}
Expire-Date: ${EXPIRY}
%no-protection
%commit
EOF

echo "[2/4] Adding signing subkey..."
# Get the key fingerprint
KEY_FP=$(gpg --list-keys --with-colons "${EMAIL}" | grep '^fpr' | head -1 | cut -d: -f10)

# Add a signing subkey for daily use
gpg --batch --quick-add-key "${KEY_FP}" ed25519 sign "${EXPIRY}"

echo "[3/4] Exporting public key..."
gpg --armor --export "${EMAIL}" > "${PGP_DIR}/${SAFE_EMAIL}.asc"
gpg --export "${EMAIL}" > "${PGP_DIR}/${SAFE_EMAIL}.pgp"

echo "[4/4] Preparing DNS record data..."
base64 -w0 < "${PGP_DIR}/${SAFE_EMAIL}.pgp" > "${PGP_DIR}/${SAFE_EMAIL}.pgp.b64"

# Generate WKD hash
LOCAL_PART="${EMAIL%%@*}"
WKD_HASH=$(printf '%s' "${LOCAL_PART}" | sha1sum | cut -c1-40 | xxd -r -p | base32 | tr 'A-Z' 'a-z' | tr -d '=')

echo ""
echo "=== OpenPGP Key Generation Complete ==="
echo ""
echo "Key fingerprint:"
gpg --fingerprint "${EMAIL}"

echo ""
echo "Files generated:"
echo "  ASCII armor:  ${PGP_DIR}/${SAFE_EMAIL}.asc"
echo "  Binary:       ${PGP_DIR}/${SAFE_EMAIL}.pgp"
echo "  DNS (Base64): ${PGP_DIR}/${SAFE_EMAIL}.pgp.b64"

echo ""
echo "Key structure:"
gpg --list-keys --with-subkey-fingerprints "${EMAIL}"

echo ""
echo "=== DNS Records ==="
echo ""
echo "CERT Record (PGP):"
echo "_pgp.${EMAIL#*@}. IN CERT PGP 0 0 $(cat "${PGP_DIR}/${SAFE_EMAIL}.pgp.b64")"

echo ""
echo "Alternative: OPENPGPKEY Record (RFC 7929):"
DOMAIN_PART="${EMAIL#*@}"
echo "${WKD_HASH}._openpgpkey.${DOMAIN_PART}. IN OPENPGPKEY $(cat "${PGP_DIR}/${SAFE_EMAIL}.pgp.b64")"

echo ""
echo "WKD Path (Web Key Directory):"
echo "https://${DOMAIN_PART}/.well-known/openpgpkey/hu/${WKD_HASH}"

echo ""
echo "SECURITY REMINDER:"
echo "  - Back up your private key securely"
echo "  - Consider using a hardware token (YubiKey, etc.)"
echo "  - The primary key should be kept offline; use subkeys for daily operations"
