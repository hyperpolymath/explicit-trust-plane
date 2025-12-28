#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# SPDX-FileCopyrightText: 2024 Hyperpolymath
#
# generate-cert.sh - Generate Ed25519 Server Certificate
#
# Usage: ./generate-cert.sh <domain> [validity-days] [--self-signed]

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly CERTS_DIR="${PROJECT_ROOT}/certs"
readonly CA_DIR="${PROJECT_ROOT}/ca"

DOMAIN="${1:-example.com}"
VALIDITY="${2:-365}"
SELF_SIGNED="${3:-}"

echo "=== Explicit Trust Plane - Server Certificate Generation ==="
echo "Domain: ${DOMAIN}"
echo "Validity: ${VALIDITY} days"
echo ""

mkdir -p "${CERTS_DIR}"

# Sanitize domain for filename
SAFE_DOMAIN="${DOMAIN//\*/_wildcard_}"

echo "[1/3] Generating Ed25519 private key..."
openssl genpkey -algorithm ED25519 -out "${CERTS_DIR}/${SAFE_DOMAIN}.key"
chmod 600 "${CERTS_DIR}/${SAFE_DOMAIN}.key"

echo "[2/3] Generating Certificate Signing Request..."
openssl req -new \
    -key "${CERTS_DIR}/${SAFE_DOMAIN}.key" \
    -out "${CERTS_DIR}/${SAFE_DOMAIN}.csr" \
    -subj "/CN=${DOMAIN}/O=${DOMAIN}"

echo "[3/3] Signing certificate..."
if [[ "${SELF_SIGNED}" == "--self-signed" ]] || [[ ! -f "${CA_DIR}/intermediate/intermediate-ed448.crt" ]]; then
    echo "  (Self-signing - no CA available or --self-signed specified)"
    openssl x509 -req \
        -in "${CERTS_DIR}/${SAFE_DOMAIN}.csr" \
        -signkey "${CERTS_DIR}/${SAFE_DOMAIN}.key" \
        -out "${CERTS_DIR}/${SAFE_DOMAIN}.crt" \
        -days "${VALIDITY}" \
        -extfile <(printf "subjectAltName=DNS:%s,DNS:*.%s\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=serverAuth,clientAuth" "${DOMAIN}" "${DOMAIN}")
else
    echo "  (Signing with Intermediate CA)"
    openssl x509 -req \
        -in "${CERTS_DIR}/${SAFE_DOMAIN}.csr" \
        -CA "${CA_DIR}/intermediate/intermediate-ed448.crt" \
        -CAkey "${CA_DIR}/intermediate/intermediate-ed448.key" \
        -CAcreateserial \
        -out "${CERTS_DIR}/${SAFE_DOMAIN}.crt" \
        -days "${VALIDITY}" \
        -extfile <(printf "subjectAltName=DNS:%s,DNS:*.%s\nkeyUsage=critical,digitalSignature\nextendedKeyUsage=serverAuth,clientAuth\nauthorityKeyIdentifier=keyid:always" "${DOMAIN}" "${DOMAIN}")

    # Create full chain
    cat "${CERTS_DIR}/${SAFE_DOMAIN}.crt" "${CA_DIR}/intermediate/chain.crt" > "${CERTS_DIR}/${SAFE_DOMAIN}.fullchain.crt"
fi

# Export DER for DNS CERT records
openssl x509 -in "${CERTS_DIR}/${SAFE_DOMAIN}.crt" -outform DER -out "${CERTS_DIR}/${SAFE_DOMAIN}.crt.der"
base64 -w0 < "${CERTS_DIR}/${SAFE_DOMAIN}.crt.der" > "${CERTS_DIR}/${SAFE_DOMAIN}.crt.b64"

# Generate TLSA record data
echo ""
echo "=== Certificate Generation Complete ==="
echo ""
echo "Files generated:"
echo "  Private key:  ${CERTS_DIR}/${SAFE_DOMAIN}.key"
echo "  Certificate:  ${CERTS_DIR}/${SAFE_DOMAIN}.crt"
echo "  CSR:          ${CERTS_DIR}/${SAFE_DOMAIN}.csr"
echo "  DER:          ${CERTS_DIR}/${SAFE_DOMAIN}.crt.der"
echo "  DNS (Base64): ${CERTS_DIR}/${SAFE_DOMAIN}.crt.b64"

if [[ -f "${CERTS_DIR}/${SAFE_DOMAIN}.fullchain.crt" ]]; then
    echo "  Full chain:   ${CERTS_DIR}/${SAFE_DOMAIN}.fullchain.crt"
fi

echo ""
echo "Certificate details:"
openssl x509 -in "${CERTS_DIR}/${SAFE_DOMAIN}.crt" -noout -subject -issuer -dates

echo ""
echo "TLSA Record (3 1 1 - DANE-EE, SPKI, SHA-256):"
echo "_443._tcp.${DOMAIN}. IN TLSA 3 1 1 $(openssl x509 -in "${CERTS_DIR}/${SAFE_DOMAIN}.crt" -noout -pubkey | openssl pkey -pubin -outform DER | sha256sum | cut -d' ' -f1)"

echo ""
echo "CERT Record (PKIX):"
echo "_cert.${DOMAIN}. IN CERT PKIX 0 0 $(cat "${CERTS_DIR}/${SAFE_DOMAIN}.crt.b64")"
