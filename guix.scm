; SPDX-License-Identifier: PMPL-1.0-or-later
;; guix.scm — GNU Guix package definition for explicit-trust-plane
;; Usage: guix shell -f guix.scm

(use-modules (guix packages)
             (guix build-system gnu)
             (guix licenses))

(package
  (name "explicit-trust-plane")
  (version "0.1.0")
  (source #f)
  (build-system gnu-build-system)
  (synopsis "explicit-trust-plane")
  (description "explicit-trust-plane — part of the hyperpolymath ecosystem.")
  (home-page "https://github.com/hyperpolymath/explicit-trust-plane")
  (license ((@@ (guix licenses) license) "PMPL-1.0-or-later"
             "https://github.com/hyperpolymath/palimpsest-license")))
