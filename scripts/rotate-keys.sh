#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2024 Hyperpolymath
#
# rotate-keys.sh - Automated key rotation with backup
#
# Usage: ./rotate-keys.sh <domain> <key-type>
#   key-type: cert | kex | all

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly BACKUP_DIR="${PROJECT_ROOT}/backup"

DOMAIN="${1:-example.com}"
KEY_TYPE="${2:-all}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== Explicit Trust Plane - Key Rotation ==="
echo "Domain: ${DOMAIN}"
echo "Key type: ${KEY_TYPE}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

# Sanitize domain
SAFE_DOMAIN="${DOMAIN//\*/_wildcard_}"

# Create backup directory
mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"

backup_and_rotate_cert() {
    echo "[CERT] Rotating server certificate..."

    if [[ -f "${PROJECT_ROOT}/certs/${SAFE_DOMAIN}.key" ]]; then
        echo "  Backing up existing certificate..."
        cp -r "${PROJECT_ROOT}/certs" "${BACKUP_DIR}/${TIMESTAMP}/certs"
    fi

    echo "  Generating new certificate..."
    "${SCRIPT_DIR}/generate-cert.sh" "${DOMAIN}"

    echo "  [CERT] Rotation complete"
}

backup_and_rotate_kex() {
    echo "[KEX] Rotating X25519 key exchange key..."

    if [[ -f "${PROJECT_ROOT}/kex/${SAFE_DOMAIN}.x25519.key" ]]; then
        echo "  Backing up existing key..."
        cp -r "${PROJECT_ROOT}/kex" "${BACKUP_DIR}/${TIMESTAMP}/kex"
    fi

    echo "  Generating new key..."
    "${SCRIPT_DIR}/generate-kex.sh" "${DOMAIN}"

    echo "  [KEX] Rotation complete"
}

case "${KEY_TYPE}" in
    cert)
        backup_and_rotate_cert
        ;;
    kex)
        backup_and_rotate_kex
        ;;
    all)
        backup_and_rotate_cert
        echo ""
        backup_and_rotate_kex
        ;;
    *)
        echo "ERROR: Unknown key type '${KEY_TYPE}'"
        echo "Usage: $0 <domain> [cert|kex|all]"
        exit 1
        ;;
esac

echo ""
echo "=== Key Rotation Complete ==="
echo ""
echo "Backup location: ${BACKUP_DIR}/${TIMESTAMP}/"
echo ""
echo "NEXT STEPS:"
echo "  1. Run: ./export-dns.sh ${DOMAIN}"
echo "  2. Update DNS records with new values"
echo "  3. Deploy new certificates to servers"
echo "  4. Verify with: dig CERT _cert.${DOMAIN}"
echo "  5. Test TLS: openssl s_client -connect ${DOMAIN}:443"
echo ""
echo "SECURITY REMINDER:"
echo "  - Old keys in backup should be securely deleted after verification"
echo "  - Ensure new DNS records propagate before switching servers"
