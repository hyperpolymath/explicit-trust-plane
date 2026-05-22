<!-- SPDX-License-Identifier: MPL-2.0 -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# Explicit Trust Plane — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              CRYPTO IDENTITY            │
                        │        (X.509, OpenPGP, X25519)         │
                        └──────────┬───────────────────┬──────────┘
                                   │                   │
                                   ▼                   ▼
                        ┌───────────────────┐  ┌───────────────────┐
                        │  CA HIERARCHY     │  │  KEY EXCHANGE     │
                        │  (Ed448 Root,     │  │  (X25519 keys)    │
                        │   Offline HSM)    │  │                   │
                        └──────────┬────────┘  └──────────┬────────┘
                                   │                      │
                                   └──────────┬───────────┘
                                              │
                                              ▼
                        ┌─────────────────────────────────────────┐
                        │           AUTOMATION SCRIPTS            │
                        │    (generate-ca, export-dns, rotate)    │
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           DNS ECOSYSTEM (DNSSEC)        │
                        │  ┌───────────┐  ┌───────────┐  ┌───────┐│
                        │  │ CERT      │  │ IPSECKEY  │  │ TLSA  ││
                        │  │ (PKIX/PGP)│  │ (RFC 4025)│  │ (DANE)││
                        │  └───────────┘  └───────────┘  └───────┘│
                        └───────────────────┬─────────────────────┘
                                            │
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │          VERIFYING CLIENTS              │
                        │      (TLS 1.3, VPN, PGP Mail)           │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile           .machine_readable/  │
                        │  OpenSSL 3.0+       GnuPG 2.2+          │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CRYPTO PRIMITIVES
  Ed448 Root CA (Offline)           ██████████ 100%    Hierarchy stable
  Ed25519 Identity Keys             ██████████ 100%    Signing proofs verified
  X25519 Key Exchange               ██████████ 100%    KEX material generated
  OpenPGP modern ECC                ██████████ 100%    GnuPG 2.2+ compatibility

AUTOMATION & EXPORT
  DNS Export Script                 ██████████ 100%    Zone file generation verified
  Key Rotation Script               ████████░░  80%    Backup verification refining
  CA Generation Scripts             ██████████ 100%    Reproducible hierarchy

DNS RECORDS
  CERT Records (RFC 4398)           ██████████ 100%    Base64 encoding verified
  IPSECKEY Records                  ██████████ 100%    Bootstrap data verified
  TLSA Records (DANE)               ██████████ 100%    SHA-256 fingerprints stable

REPO INFRASTRUCTURE
  Justfile                          ██████████ 100%    Standard build tasks
  .machine_readable/                ██████████ 100%    STATE.adoc tracking
  Design Documentation              ██████████ 100%    DESIGN.adoc & DEPLOY.adoc

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            █████████░  ~95%   Core framework production-ready
```

## Key Dependencies

```
Ed448 Root CA ───► Intermediate CA ───► Entity Cert ───► DNS CERT
     │                 │                   │                │
     ▼                 ▼                   ▼                ▼
  DNSSEC ────────► IPSECKEY ──────────► TLSA ──────────► DANE Verified
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
