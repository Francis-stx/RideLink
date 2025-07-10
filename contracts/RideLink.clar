;; RideLink - Decentralized Ride-Sharing Escrow System
;; A smart contract for secure ride-sharing transactions

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-already-exists (err u105))

;; Data Variables
(define-data-var ride-counter uint u0)
(define-data-var platform-fee uint u50) ;; 0.5% in basis points

;; Ride status enum
(define-constant status-requested u1)
(define-constant status-accepted u2)
(define-constant status-in-progress u3)
(define-constant status-completed u4)
(define-constant status-cancelled u5)

;; Data Maps
(define-map rides
  uint
  {
    rider: principal,
    driver: (optional principal),
    pickup-location: (string-ascii 100),
    destination: (string-ascii 100),
    fare: uint,
    status: uint,
    created-at: uint,
    completed-at: (optional uint)
  }
)

(define-map driver-ratings
  principal
  {
    total-rating: uint,
    ride-count: uint
  }
)

(define-map escrow-balances
  uint
  uint
)

;; Private Functions
(define-private (get-next-ride-id)
  (begin
    (var-set ride-counter (+ (var-get ride-counter) u1))
    (var-get ride-counter)
  )
)

(define-private (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee)) u10000)
)

;; Public Functions

;; Request a ride
(define-public (request-ride (pickup (string-ascii 100)) (destination (string-ascii 100)) (fare uint))
  (let (
    (ride-id (get-next-ride-id))
    (platform-fee-amount (calculate-platform-fee fare))
    (total-amount (+ fare platform-fee-amount))
  )
    (asserts! (> fare u0) err-insufficient-funds)
    (asserts! (> (len pickup) u0) err-invalid-status)
    (asserts! (> (len destination) u0) err-invalid-status)
    (try! (stx-transfer? total-amount tx-sender (as-contract tx-sender)))
    (map-set rides ride-id {
      rider: tx-sender,
      driver: none,
      pickup-location: pickup,
      destination: destination,
      fare: fare,
      status: status-requested,
      created-at: stacks-block-height,
      completed-at: none
    })
    (map-set escrow-balances ride-id total-amount)
    (ok ride-id)
  )
)

;; Accept a ride (driver)
(define-public (accept-ride (ride-id uint))
  (let (
    (ride-data (unwrap! (map-get? rides ride-id) err-not-found))
  )
    (asserts! (is-eq (get status ride-data) status-requested) err-invalid-status)
    (map-set rides ride-id (merge ride-data {
      driver: (some tx-sender),
      status: status-accepted
    }))
    (ok true)
  )
)

;; Start ride (driver)
(define-public (start-ride (ride-id uint))
  (let (
    (ride-data (unwrap! (map-get? rides ride-id) err-not-found))
  )
    (asserts! (is-eq (some tx-sender) (get driver ride-data)) err-unauthorized)
    (asserts! (is-eq (get status ride-data) status-accepted) err-invalid-status)
    (map-set rides ride-id (merge ride-data {
      status: status-in-progress
    }))
    (ok true)
  )
)

;; Complete ride (driver)
(define-public (complete-ride (ride-id uint))
  (let (
    (ride-data (unwrap! (map-get? rides ride-id) err-not-found))
    (escrowed-amount (unwrap! (map-get? escrow-balances ride-id) err-not-found))
    (platform-fee-amount (calculate-platform-fee (get fare ride-data)))
    (driver-payment (- (get fare ride-data) u0))
  )
    (asserts! (is-eq (some tx-sender) (get driver ride-data)) err-unauthorized)
    (asserts! (is-eq (get status ride-data) status-in-progress) err-invalid-status)
    
    ;; Transfer payment to driver
    (try! (as-contract (stx-transfer? driver-payment tx-sender (unwrap! (get driver ride-data) err-not-found))))
    
    ;; Transfer platform fee to contract owner
    (try! (as-contract (stx-transfer? platform-fee-amount tx-sender contract-owner)))
    
    ;; Update ride status
    (map-set rides ride-id (merge ride-data {
      status: status-completed,
      completed-at: (some stacks-block-height)
    }))
    
    ;; Clear escrow
    (map-delete escrow-balances ride-id)
    
    (ok true)
  )
)

;; Rate driver (rider)
(define-public (rate-driver (ride-id uint) (rating uint))
  (let (
    (ride-data (unwrap! (map-get? rides ride-id) err-not-found))
    (driver-principal (unwrap! (get driver ride-data) err-not-found))
    (current-rating (default-to {total-rating: u0, ride-count: u0} (map-get? driver-ratings driver-principal)))
  )
    (asserts! (is-eq tx-sender (get rider ride-data)) err-unauthorized)
    (asserts! (is-eq (get status ride-data) status-completed) err-invalid-status)
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-status)
    
    (map-set driver-ratings driver-principal {
      total-rating: (+ (get total-rating current-rating) rating),
      ride-count: (+ (get ride-count current-rating) u1)
    })
    (ok true)
  )
)

;; Cancel ride (rider or driver)
(define-public (cancel-ride (ride-id uint))
  (let (
    (ride-data (unwrap! (map-get? rides ride-id) err-not-found))
    (escrowed-amount (unwrap! (map-get? escrow-balances ride-id) err-not-found))
  )
    (asserts! (or 
      (is-eq tx-sender (get rider ride-data))
      (is-eq (some tx-sender) (get driver ride-data))
    ) err-unauthorized)
    (asserts! (< (get status ride-data) status-in-progress) err-invalid-status)
    
    ;; Refund to rider
    (try! (as-contract (stx-transfer? escrowed-amount tx-sender (get rider ride-data))))
    
    ;; Update ride status
    (map-set rides ride-id (merge ride-data {
      status: status-cancelled
    }))
    
    ;; Clear escrow
    (map-delete escrow-balances ride-id)
    
    (ok true)
  )
)

;; Read-only functions

;; Get ride details
(define-read-only (get-ride (ride-id uint))
  (map-get? rides ride-id)
)

;; Get driver rating
(define-read-only (get-driver-rating (driver principal))
  (let (
    (rating-data (default-to {total-rating: u0, ride-count: u0} (map-get? driver-ratings driver)))
  )
    (if (> (get ride-count rating-data) u0)
      (some (/ (get total-rating rating-data) (get ride-count rating-data)))
      none
    )
  )
)

;; Get escrow balance
(define-read-only (get-escrow-balance (ride-id uint))
  (map-get? escrow-balances ride-id)
)

;; Get platform fee
(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

;; Get total rides
(define-read-only (get-total-rides)
  (var-get ride-counter)
)