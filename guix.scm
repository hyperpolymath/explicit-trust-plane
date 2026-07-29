; SPDX-License-Identifier: MPL-2.0
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
  (license mpl2.0))
