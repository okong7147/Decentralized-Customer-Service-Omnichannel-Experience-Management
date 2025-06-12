;; Channel Integration Contract
;; Manages integration of customer service channels

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-channel-exists (err u201))
(define-constant err-channel-not-found (err u202))
(define-constant err-unauthorized (err u203))

;; Data maps
(define-map integrated-channels (string-ascii 50) {
  channel-type: (string-ascii 30),
  status: (string-ascii 20),
  integration-date: uint,
  manager: principal,
  config-hash: (buff 32)
})

(define-map channel-metrics (string-ascii 50) {
  total-interactions: uint,
  avg-response-time: uint,
  success-rate: uint,
  last-updated: uint
})

;; Public functions
(define-public (integrate-channel (channel-id (string-ascii 50)) (channel-type (string-ascii 30)) (manager principal) (config-hash (buff 32)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? integrated-channels channel-id)) err-channel-exists)
    (map-set integrated-channels channel-id {
      channel-type: channel-type,
      status: "active",
      integration-date: block-height,
      manager: manager,
      config-hash: config-hash
    })
    (map-set channel-metrics channel-id {
      total-interactions: u0,
      avg-response-time: u0,
      success-rate: u100,
      last-updated: block-height
    })
    (ok true)
  )
)

(define-public (update-channel-status (channel-id (string-ascii 50)) (new-status (string-ascii 20)))
  (let ((channel-data (unwrap! (map-get? integrated-channels channel-id) err-channel-not-found)))
    (asserts! (or (is-eq tx-sender contract-owner) (is-eq tx-sender (get manager channel-data))) err-unauthorized)
    (map-set integrated-channels channel-id (merge channel-data { status: new-status }))
    (ok true)
  )
)

(define-public (update-channel-metrics (channel-id (string-ascii 50)) (interactions uint) (response-time uint) (success-rate uint))
  (let ((channel-data (unwrap! (map-get? integrated-channels channel-id) err-channel-not-found)))
    (asserts! (is-eq tx-sender (get manager channel-data)) err-unauthorized)
    (map-set channel-metrics channel-id {
      total-interactions: interactions,
      avg-response-time: response-time,
      success-rate: success-rate,
      last-updated: block-height
    })
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-channel-info (channel-id (string-ascii 50)))
  (map-get? integrated-channels channel-id)
)

(define-read-only (get-channel-metrics (channel-id (string-ascii 50)))
  (map-get? channel-metrics channel-id)
)

(define-read-only (is-channel-active (channel-id (string-ascii 50)))
  (match (map-get? integrated-channels channel-id)
    channel-data (is-eq (get status channel-data) "active")
    false
  )
)
