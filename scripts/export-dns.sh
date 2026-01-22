#!/usr/bin/env bash
# SPDX-License-Identifier: PMPL-1.0-or-later
# SPDX-FileCopyrightText: 2024 Hyperpolymath
#
# export-dns.sh - Export all cryptographic materials as DNS zone records
#
# Usage: ./export-dns.sh <domain>

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
readonly DNS_DIR="${PROJECT_ROOT}/dns"
readonly RECORDS_DIR="${DNS_DIR}/records"

DOMAIN="${1:-example.com}"
TIMESTAMP=$(date -Iseconds)

echo "=== Explicit Trust Plane - DNS Export ==="
echo "Domain: ${DOMAIN}"
echo "Timestamp: ${TIMESTAMP}"
echo ""

mkdir -p "${RECORDS_DIR}"

# Sanitize domain
SAFE_DOMAIN="${DOMAIN//\*/_wildcard_}"

# --- Header ---
cat > "${RECORDS_DIR}/${SAFE_DOMAIN}.zone" <<EOF
; SPDX-License-Identifier: PMPL-1.0-or-later
; Explicit Trust Plane - DNS Records for ${DOMAIN}
; Generated: ${TIMESTAMP}
;
; IMPORTANT: These records require DNSSEC to be secure!
;
; Include this file in your zone or copy records to your DNS provider.

\$ORIGIN ${DOMAIN}.
\$TTL 3600

EOF

# --- CERT Records (X.509) ---
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; X.509 Certificates (CERT PKIX)" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"

# Root CA
if [[ -f "${PROJECT_ROOT}/ca/root/ca-ed448.crt.b64" ]]; then
    echo "; Root CA Certificate (Ed448)" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo "_ca._cert            IN  CERT  PKIX 0 0 (" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    fold -w 64 < "${PROJECT_ROOT}/ca/root/ca-ed448.crt.b64" | sed 's/^/    /' >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo ")" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
fi

# Intermediate CA
if [[ -f "${PROJECT_ROOT}/ca/intermediate/intermediate-ed448.crt.b64" ]]; then
    echo "; Intermediate CA Certificate (Ed448)" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo "_intermediate._cert  IN  CERT  PKIX 0 0 (" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    fold -w 64 < "${PROJECT_ROOT}/ca/intermediate/intermediate-ed448.crt.b64" | sed 's/^/    /' >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo ")" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
fi

# Server certificate
if [[ -f "${PROJECT_ROOT}/certs/${SAFE_DOMAIN}.crt.b64" ]]; then
    echo "; Server Certificate (Ed25519)" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo "_server._cert        IN  CERT  PKIX 0 0 (" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    fold -w 64 < "${PROJECT_ROOT}/certs/${SAFE_DOMAIN}.crt.b64" | sed 's/^/    /' >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo ")" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
fi

# --- CERT Records (PGP) ---
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; OpenPGP Keys (CERT PGP)" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"

for pgp_file in "${PROJECT_ROOT}/pgp/"*.pgp.b64; do
    if [[ -f "${pgp_file}" ]]; then
        filename=$(basename "${pgp_file}" .pgp.b64)
        echo "; PGP Key: ${filename}" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
        echo "_pgp                 IN  CERT  PGP 0 0 (" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
        fold -w 64 < "${pgp_file}" | sed 's/^/    /' >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
        echo ")" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
        echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    fi
done

# --- IPSECKEY Records ---
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; Key Exchange (IPSECKEY)" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"

if [[ -f "${PROJECT_ROOT}/kex/${SAFE_DOMAIN}.x25519.pub.b64" ]]; then
    echo "; X25519 Key Exchange" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    PUBKEY=$(cat "${PROJECT_ROOT}/kex/${SAFE_DOMAIN}.x25519.pub.b64")
    echo "_ipsec               IN  IPSECKEY  10 0 2 . ${PUBKEY}" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
fi

# --- TLSA Records ---
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; DANE/TLSA Records" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"

if [[ -f "${PROJECT_ROOT}/certs/${SAFE_DOMAIN}.crt" ]]; then
    TLSA_HASH=$(openssl x509 -in "${PROJECT_ROOT}/certs/${SAFE_DOMAIN}.crt" -noout -pubkey 2>/dev/null | openssl pkey -pubin -outform DER 2>/dev/null | sha256sum | cut -d' ' -f1)
    echo "; DANE-EE TLSA for HTTPS (port 443)" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo "_443._tcp            IN  TLSA  3 1 1 ${TLSA_HASH}" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
    echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
fi

# --- CAA Records ---
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; Certificate Authority Authorization (CAA)" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "; ==============================================================================" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "@                    IN  CAA  0 issue \"letsencrypt.org\"" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "@                    IN  CAA  0 issuewild \";\"" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "@                    IN  CAA  0 iodef \"mailto:security@${DOMAIN}\"" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo "" >> "${RECORDS_DIR}/${SAFE_DOMAIN}.zone"

echo "=== DNS Export Complete ==="
echo ""
echo "Zone file: ${RECORDS_DIR}/${SAFE_DOMAIN}.zone"
echo ""
echo "Record types included:"
grep -c "IN  CERT" "${RECORDS_DIR}/${SAFE_DOMAIN}.zone" 2>/dev/null | xargs -I{} echo "  CERT:     {} records"
grep -c "IN  IPSECKEY" "${RECORDS_DIR}/${SAFE_DOMAIN}.zone" 2>/dev/null | xargs -I{} echo "  IPSECKEY: {} records"
grep -c "IN  TLSA" "${RECORDS_DIR}/${SAFE_DOMAIN}.zone" 2>/dev/null | xargs -I{} echo "  TLSA:     {} records"
grep -c "IN  CAA" "${RECORDS_DIR}/${SAFE_DOMAIN}.zone" 2>/dev/null | xargs -I{} echo "  CAA:      {} records"
echo ""
echo "IMPORTANT: Enable DNSSEC before deploying these records!"
