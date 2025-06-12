;; Experience Manager Verification Contract
;; Validates and manages customer experience managers

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-verified (err u101))
(define-constant err-not-verified (err u102))
(define-constant err-invalid-manager (err u103))

;; Data maps
(define-map verified-managers principal {
  verified: bool,
  verification-date: uint,
  experience-level: (string-ascii 20),
  specialization: (string-ascii 50)
})

(define-map manager-metrics principal {
  customers-served: uint,
  satisfaction-score: uint,
  resolution-rate: uint
})

;; Public functions
(define-public (verify-manager (manager principal) (experience-level (string-ascii 20)) (specialization (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? verified-managers manager)) err-already-verified)
    (map-set verified-managers manager {
      verified: true,
      verification-date: block-height,
      experience-level: experience-level,
      specialization: specialization
    })
    (ok true)
  )
)

(define-public (update-manager-metrics (manager principal) (customers uint) (satisfaction uint) (resolution uint))
  (begin
    (asserts! (is-some (map-get? verified-managers manager)) err-not-verified)
    (map-set manager-metrics manager {
      customers-served: customers,
      satisfaction-score: satisfaction,
      resolution-rate: resolution
    })
    (ok true)
  )
)

(define-public (revoke-verification (manager principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? verified-managers manager)) err-not-verified)
    (map-delete verified-managers manager)
    (map-delete manager-metrics manager)
    (ok true)
  )
)

;; Read-only functions
(define-read-only (is-manager-verified (manager principal))
  (match (map-get? verified-managers manager)
    manager-data (get verified manager-data)
    false
  )
)

(define-read-only (get-manager-info (manager principal))
  (map-get? verified-managers manager)
)

(define-read-only (get-manager-metrics (manager principal))
  (map-get? manager-metrics manager)
)
