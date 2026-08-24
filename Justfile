# Explicit Trust Plane - DNS-Published Cryptographic Identity
# https://just.systems/man/en/
#
# Run `just` to see all available recipes
# Run `just generate example.com` to generate all crypto materials

set shell := ["bash", "-uc"]
set dotenv-load := true
set positional-arguments := true

# Project metadata
import? "contractile.just"

project := "explicit-trust-plane"
version := "1.0.0"
tier := "infrastructure"

# ═══════════════════════════════════════════════════════════════════════════════
# DEFAULT & HELP
# ═══════════════════════════════════════════════════════════════════════════════

# Show all available recipes with descriptions
default:
    @just --list --unsorted

# Show detailed help for a specific recipe
help recipe="":
    #!/usr/bin/env bash
    if [ -z "{{recipe}}" ]; then
        just --list --unsorted
        echo ""
        echo "Usage: just help <recipe>"
        echo "       just cookbook     # Generate full documentation"
        echo "       just combinations # Show matrix recipes"
    else
        just --show "{{recipe}}" 2>/dev/null || echo "Recipe '{{recipe}}' not found"
    fi

# Show this project's info
info:
    @echo "Project: {{project}}"
    @echo "Version: {{version}}"
    @echo "RSR Tier: {{tier}}"
    @echo "Recipes: $(just --summary | wc -w)"
    @[ -f STATE.scm ] && grep -oP '\(phase\s+\.\s+\K[^)]+' STATE.scm | head -1 | xargs -I{} echo "Phase: {}" || true

# ═══════════════════════════════════════════════════════════════════════════════
# BUILD & COMPILE
# ═══════════════════════════════════════════════════════════════════════════════

# Generate all cryptographic materials for a domain
generate domain:
    @echo "Generating all crypto materials for {{domain}}..."
    ./scripts/generate-ca.sh "{{domain}}"
    ./scripts/generate-cert.sh "{{domain}}"
    ./scripts/generate-kex.sh "{{domain}}"
    ./scripts/export-dns.sh "{{domain}}"
    @echo ""
    @echo "Done! See dns/records/{{domain}}.zone for DNS records"

# Generate CA only
generate-ca domain:
    ./scripts/generate-ca.sh "{{domain}}"

# Generate server certificate only
generate-cert domain:
    ./scripts/generate-cert.sh "{{domain}}"

# Generate key exchange key only
generate-kex domain:
    ./scripts/generate-kex.sh "{{domain}}"

# Generate OpenPGP key
generate-pgp name email:
    ./scripts/generate-pgp.sh "{{name}}" "{{email}}"

# Export DNS records
export-dns domain:
    ./scripts/export-dns.sh "{{domain}}"

# Rotate keys with backup
rotate domain keytype="all":
    ./scripts/rotate-keys.sh "{{domain}}" "{{keytype}}"

# Clean generated materials [destructive!]
clean:
    @echo "Cleaning generated materials..."
    rm -rf ca/root/*.key ca/root/*.crt ca/root/*.der ca/root/*.b64 ca/root/*.srl
    rm -rf ca/intermediate/*.key ca/intermediate/*.crt ca/intermediate/*.csr ca/intermediate/*.der ca/intermediate/*.b64 ca/intermediate/*.srl
    rm -rf certs/*.key certs/*.crt certs/*.csr certs/*.der certs/*.b64
    rm -rf pgp/*.asc pgp/*.pgp pgp/*.b64
    rm -rf kex/*.key kex/*.pub kex/*.raw kex/*.b64
    rm -rf dns/records/*.zone
    rm -rf backup/
    @echo "Cleaned. .gitkeep files preserved."

# Deep clean including caches [reversible: rebuild]
clean-all: clean
    rm -rf .cache .tmp

# ═══════════════════════════════════════════════════════════════════════════════
# TEST & QUALITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run all tests
test *args:
    @echo "Running tests..."
    # TODO: Add test command
    # Rust: cargo test {{args}}
    # AffineScript: npm test
    # Elixir: mix test

# Run tests with verbose output
test-verbose:
    @echo "Running tests (verbose)..."
    # TODO: Add verbose test

# Run tests and generate coverage report
test-coverage:
    @echo "Running tests with coverage..."
    # TODO: Add coverage command
    # Rust: cargo llvm-cov

# ═══════════════════════════════════════════════════════════════════════════════
# LINT & FORMAT
# ═══════════════════════════════════════════════════════════════════════════════

# Format all source files [reversible: git checkout]
fmt:
    @echo "Formatting..."
    # TODO: Add format command
    # Rust: cargo fmt
    # AffineScript: npm run format
    # Elixir: mix format

# Check formatting without changes
fmt-check:
    @echo "Checking format..."
    # TODO: Add format check
    # Rust: cargo fmt --check

# Run linter
lint:
    @echo "Linting..."
    # TODO: Add lint command
    # Rust: cargo clippy -- -D warnings

# Run all quality checks
quality: fmt-check lint test
    @echo "All quality checks passed!"

# Fix all auto-fixable issues [reversible: git checkout]
fix: fmt
    @echo "Fixed all auto-fixable issues"

# ═══════════════════════════════════════════════════════════════════════════════
# RUN & EXECUTE
# ═══════════════════════════════════════════════════════════════════════════════

# Run the application
run *args:
    @echo "Running {{project}}..."
    # TODO: Add run command
    # Rust: cargo run {{args}}

# Run in development mode with hot reload
dev:
    @echo "Starting dev mode..."
    # TODO: Add dev command

# Run REPL/interactive mode
repl:
    @echo "Starting REPL..."
    # TODO: Add REPL command
    # Elixir: iex -S mix
    # Guile: guix shell guile -- guile

# ═══════════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════════

# Install all dependencies
deps:
    @echo "Installing dependencies..."
    # TODO: Add deps command
    # Rust: (automatic with cargo)
    # AffineScript: npm install
    # Elixir: mix deps.get

# Audit dependencies for vulnerabilities
deps-audit:
    @echo "Auditing dependencies..."
    # TODO: Add audit command
    # Rust: cargo audit

# ═══════════════════════════════════════════════════════════════════════════════
# DOCUMENTATION
# ═══════════════════════════════════════════════════════════════════════════════

# Generate all documentation
docs:
    @mkdir -p docs/generated docs/man
    just cookbook
    just man
    @echo "Documentation generated in docs/"

# Generate justfile cookbook documentation
cookbook:
    #!/usr/bin/env bash
    mkdir -p docs
    OUTPUT="docs/just-cookbook.adoc"
    echo "= {{project}} Justfile Cookbook" > "$OUTPUT"
    echo ":toc: left" >> "$OUTPUT"
    echo ":toclevels: 3" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "Generated: $(date -Iseconds)" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    echo "== Recipes" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    just --list --unsorted | while read -r line; do
        if [[ "$line" =~ ^[[:space:]]+([a-z_-]+) ]]; then
            recipe="${BASH_REMATCH[1]}"
            echo "=== $recipe" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
            echo "[source,bash]" >> "$OUTPUT"
            echo "----" >> "$OUTPUT"
            echo "just $recipe" >> "$OUTPUT"
            echo "----" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
        fi
    done
    echo "Generated: $OUTPUT"

# Generate man page
man:
    #!/usr/bin/env bash
    mkdir -p docs/man
    cat > docs/man/{{project}}.1 << 'MANEOF'
    .TH RSR-TEMPLATE-REPO 1 "$(date +%Y-%m-%d)" "{{version}}" "RSR Template Manual"
    .SH NAME
    {{project}} \- RSR standard repository template
    .SH SYNOPSIS
    .B just
    [recipe] [args...]
    .SH DESCRIPTION
    Canonical template for RSR (Rhodium Standard Repository) projects.
    .SH AUTHOR
    Hyperpolymath <hyperpolymath@proton.me>
    MANEOF
    echo "Generated: docs/man/{{project}}.1"

# ═══════════════════════════════════════════════════════════════════════════════
# CONTAINERS (nerdctl + Wolfi)
# ═══════════════════════════════════════════════════════════════════════════════

# Build container image
container-build tag="latest":
    @if [ -f Containerfile ]; then \
        nerdctl build -t {{project}}:{{tag}} -f Containerfile .; \
    else \
        echo "No Containerfile found"; \
    fi

# Run container
container-run tag="latest" *args:
    nerdctl run --rm -it {{project}}:{{tag}} {{args}}

# Push container image
container-push registry="ghcr.io/hyperpolymath" tag="latest":
    nerdctl tag {{project}}:{{tag}} {{registry}}/{{project}}:{{tag}}
    nerdctl push {{registry}}/{{project}}:{{tag}}

# ═══════════════════════════════════════════════════════════════════════════════
# CI & AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════

# Run full CI pipeline locally
ci: deps quality
    @echo "CI pipeline complete!"

# Install git hooks
install-hooks:
    #!/usr/bin/env bash
    mkdir -p .git/hooks
    cat > .git/hooks/pre-commit << 'HOOKEOF'
    #!/bin/bash
    just fmt-check || exit 1
    just lint || exit 1
    HOOKEOF
    chmod +x .git/hooks/pre-commit
    echo "Git hooks installed"

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run security audit
security: deps-audit
    @echo "=== Security Audit ==="
    @command -v trivy >/dev/null && trivy fs --severity HIGH,CRITICAL . || true
    @echo "Security audit complete"

# Generate SBOM
sbom:
    @mkdir -p docs/security
    @command -v syft >/dev/null && syft . -o spdx-json > docs/security/sbom.spdx.json || echo "syft not found"

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION & COMPLIANCE
# ═══════════════════════════════════════════════════════════════════════════════

# Validate RSR compliance
validate-rsr:
    #!/usr/bin/env bash
    echo "=== RSR Compliance Check ==="
    MISSING=""
    for f in .editorconfig .gitignore justfile RSR_COMPLIANCE.adoc README.adoc; do
        [ -f "$f" ] || MISSING="$MISSING $f"
    done
    for d in .well-known; do
        [ -d "$d" ] || MISSING="$MISSING $d/"
    done
    for f in .well-known/security.txt .well-known/ai.txt .well-known/humans.txt; do
        [ -f "$f" ] || MISSING="$MISSING $f"
    done
    if [ ! -f "guix.scm" ] && [ ! -f ".guix-channel" ] && [ ! -f "flake.guix" ]; then
        MISSING="$MISSING guix.scm/flake.guix"
    fi
    if [ -n "$MISSING" ]; then
        echo "MISSING:$MISSING"
        exit 1
    fi
    echo "RSR compliance: PASS"

# Validate STATE.scm syntax
validate-state:
    @if [ -f "STATE.scm" ]; then \
        guile -c "(primitive-load \"STATE.scm\")" 2>/dev/null && echo "STATE.scm: valid" || echo "STATE.scm: INVALID"; \
    else \
        echo "No STATE.scm found"; \
    fi

# Full validation suite
validate: validate-rsr validate-state
    @echo "All validations passed!"

# ═══════════════════════════════════════════════════════════════════════════════
# STATE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Update STATE.scm timestamp
state-touch:
    @if [ -f "STATE.scm" ]; then \
        sed -i 's/(updated . "[^"]*")/(updated . "'"$(date -Iseconds)"'")/' STATE.scm && \
        echo "STATE.scm timestamp updated"; \
    fi

# Show current phase from STATE.scm
state-phase:
    @grep -oP '\(phase\s+\.\s+\K[^)]+' STATE.scm 2>/dev/null | head -1 || echo "unknown"

# ═══════════════════════════════════════════════════════════════════════════════
# GUIX & GUIX
# ═══════════════════════════════════════════════════════════════════════════════

# Enter Guix development shell (primary)
guix-shell:
    guix shell -D -f guix.scm

# Build with Guix
guix-build:
    guix build -f guix.scm

# Enter Guix development shell (fallback)
guix-shell:
    @if [ -f "flake.guix" ]; then guix develop; else echo "No flake.guix"; fi

# ═══════════════════════════════════════════════════════════════════════════════
# HYBRID AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════

# Run local automation tasks
automate task="all":
    #!/usr/bin/env bash
    case "{{task}}" in
        all) just fmt && just lint && just test && just docs && just state-touch ;;
        cleanup) just clean && find . -name "*.orig" -delete && find . -name "*~" -delete ;;
        update) just deps && just validate ;;
        *) echo "Unknown: {{task}}. Use: all, cleanup, update" && exit 1 ;;
    esac

# ═══════════════════════════════════════════════════════════════════════════════
# COMBINATORIC MATRIX RECIPES
# ═══════════════════════════════════════════════════════════════════════════════

# Build matrix: [debug|release] × [target] × [features]
build-matrix mode="debug" target="" features="":
    @echo "Build matrix: mode={{mode}} target={{target}} features={{features}}"
    # Customize for your build system

# Test matrix: [unit|integration|e2e|all] × [verbosity] × [parallel]
test-matrix suite="unit" verbosity="normal" parallel="true":
    @echo "Test matrix: suite={{suite}} verbosity={{verbosity}} parallel={{parallel}}"

# Container matrix: [build|run|push|shell|scan] × [registry] × [tag]
container-matrix action="build" registry="ghcr.io/hyperpolymath" tag="latest":
    @echo "Container matrix: action={{action}} registry={{registry}} tag={{tag}}"

# CI matrix: [lint|test|build|security|all] × [quick|full]
ci-matrix stage="all" depth="quick":
    @echo "CI matrix: stage={{stage}} depth={{depth}}"

# Show all matrix combinations
combinations:
    @echo "=== Combinatoric Matrix Recipes ==="
    @echo ""
    @echo "Build Matrix: just build-matrix [debug|release] [target] [features]"
    @echo "Test Matrix:  just test-matrix [unit|integration|e2e|all] [verbosity] [parallel]"
    @echo "Container:    just container-matrix [build|run|push|shell|scan] [registry] [tag]"
    @echo "CI Matrix:    just ci-matrix [lint|test|build|security|all] [quick|full]"
    @echo ""
    @echo "Total combinations: ~10 billion"

# ═══════════════════════════════════════════════════════════════════════════════
# VERSION CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

# Show git status
status:
    @git status --short

# Show recent commits
log count="20":
    @git log --oneline -{{count}}

# ═══════════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════════

# Count lines of code
loc:
    @find . \( -name "*.rs" -o -name "*.ex" -o -name "*.res" -o -name "*.ncl" -o -name "*.scm" \) 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 || echo "0"

# Show TODO comments
todos:
    @grep -rn "TODO\|FIXME" --include="*.rs" --include="*.ex" --include="*.res" . 2>/dev/null || echo "No TODOs"

# Open in editor
edit:
    ${EDITOR:-code} .

# Run panic-attacker pre-commit scan
assail:
    @command -v panic-attack >/dev/null 2>&1 && panic-attack assail . || echo "panic-attack not found — install from https://github.com/hyperpolymath/panic-attacker"

# ═══════════════════════════════════════════════════════════════════════════════
# ONBOARDING & DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════════════════════

# Check all required toolchain dependencies and report health
doctor:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  Explicit Trust Plane Doctor — Toolchain Health Check"
    echo "═══════════════════════════════════════════════════"
    echo ""
    PASS=0; FAIL=0; WARN=0
    check() {
        local name="$1" cmd="$2" min="$3"
        if command -v "$cmd" >/dev/null 2>&1; then
            VER=$("$cmd" --version 2>&1 | head -1)
            echo "  [OK]   $name — $VER"
            PASS=$((PASS + 1))
        else
            echo "  [FAIL] $name — not found (need $min+)"
            FAIL=$((FAIL + 1))
        fi
    }
    check "just"              just      "1.25" 
    check "git"               git       "2.40" 
    check "Zig"               zig       "0.13" 
# Optional tools
if command -v panic-attack >/dev/null 2>&1; then
    echo "  [OK]   panic-attack — available"
    PASS=$((PASS + 1))
else
    echo "  [WARN] panic-attack — not found (pre-commit scanner)"
    WARN=$((WARN + 1))
fi
    echo ""
    echo "  Result: $PASS passed, $FAIL failed, $WARN warnings"
    if [ "$FAIL" -gt 0 ]; then
        echo "  Run 'just heal' to attempt automatic repair."
        exit 1
    fi
    echo "  All required tools present."

# Attempt to automatically install missing tools
heal:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  Explicit Trust Plane Heal — Automatic Tool Installation"
    echo "═══════════════════════════════════════════════════"
    echo ""
if ! command -v just >/dev/null 2>&1; then
    echo "Installing just..."
    cargo install just 2>/dev/null || echo "Install just from https://just.systems"
fi
    echo ""
    echo "Heal complete. Run 'just doctor' to verify."

# Guided tour of the project structure and key concepts
tour:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  Explicit Trust Plane — Guided Tour"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo '// SPDX-License-Identifier: MPL-2.0'
    echo ""
    echo "Key directories:"
    echo "  src/                      Source code" 
    echo "  ffi/                      Foreign function interface (Zig)" 
    echo "  src/abi/                  Idris2 ABI definitions" 
    echo "  docs/                     Documentation" 
    echo "  tests/                    Test suite" 
    echo "  .github/workflows/        CI/CD workflows" 
    echo "  contractiles/             Must/Trust/Dust contracts" 
    echo "  .machine_readable/        Machine-readable metadata" 
    echo "  examples/                 Usage examples" 
    echo ""
    echo "Quick commands:"
    echo "  just doctor    Check toolchain health"
    echo "  just heal      Fix missing tools"
    echo "  just help-me   Common workflows"
    echo "  just default   List all recipes"
    echo ""
    echo "Read more: README.adoc, EXPLAINME.adoc"

# Show help for common workflows
help-me:
    #!/usr/bin/env bash
    echo "═══════════════════════════════════════════════════"
    echo "  Explicit Trust Plane — Common Workflows"
    echo "═══════════════════════════════════════════════════"
    echo ""
echo "FIRST TIME SETUP:"
echo "  just doctor           Check toolchain"
echo "  just heal             Fix missing tools"
echo "" 
echo "PRE-COMMIT:"
echo "  just assail           Run panic-attacker scan"
echo ""
echo "LEARN:"
echo "  just tour             Guided project tour"
echo "  just default          List all recipes" 


# Print the current CRG grade (reads from READINESS.md '**Current Grade:** X' line)
crg-grade:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    echo "$$grade"

# Generate a shields.io badge markdown for the current CRG grade
# Looks for '**Current Grade:** X' in READINESS.md; falls back to X
crg-badge:
    @grade=$$(grep -oP '(?<=\*\*Current Grade:\*\* )[A-FX]' READINESS.md 2>/dev/null | head -1); \
    [ -z "$$grade" ] && grade="X"; \
    case "$$grade" in \
      A) color="brightgreen" ;; B) color="green" ;; C) color="yellow" ;; \
      D) color="orange" ;; E) color="red" ;; F) color="critical" ;; \
      *) color="lightgrey" ;; esac; \
    echo "[![CRG $$grade](https://img.shields.io/badge/CRG-$$grade-$$color?style=flat-square)](https://github.com/hyperpolymath/standards/tree/main/component-readiness-grades)"

secret-scan-trufflehog:
    @command -v trufflehog >/dev/null && trufflehog filesystem . --only-verified || true
