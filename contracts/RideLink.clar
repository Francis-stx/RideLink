;; RideLink - Decentralized Ride-Sharing Escrow System with Dispute Resolution & Dynamic Pricing
;; A smart contract for secure ride-sharing transactions with staked mediator system and surge pricing

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-invalid-rating (err u106))
(define-constant err-dispute-window-closed (err u107))
(define-constant err-dispute-already-exists (err u108))
(define-constant err-voting-period-ended (err u109))
(define-constant err-voting-period-active (err u110))
(define-constant err-already-voted (err u111))
(define-constant err-not-mediator (err u112))
(define-constant err-mediator-cooldown (err u113))
(define-constant err-invalid-vote (err u114))
(define-constant err-insufficient-stake (err u115))
(define-constant err-invalid-multiplier (err u116))
(define-constant err-invalid-location (err u117))

;; Data Variables
(define-data-var ride-counter uint u0)
(define-data-var platform-fee uint u50) ;; 0.5% in basis points
(define-data-var mediator-stake-required uint u1000000000) ;; 1000 STX in microSTX
(define-data-var dispute-window uint u144) ;; 24 hours in blocks (assuming 10min blocks)
(define-data-var voting-period uint u288) ;; 48 hours in blocks
(define-data-var mediator-cooldown uint u1008) ;; 7 days in blocks
(define-data-var stake-slash-rate uint u1000) ;; 10% in basis points
(define-data-var base-surge-multiplier uint u10000) ;; 1.0x in basis points (10000 = 100%)
(define-data-var max-surge-multiplier uint u50000) ;; 5.0x max surge in basis points
(define-data-var demand-threshold uint u5) ;; Minimum demand for surge pricing
(define-data-var supply-threshold uint u2) ;; Minimum supply for normal pricing

;; Status constants
(define-constant status-requested u1)
(define-constant status-accepted u2)
(define-constant status-in-progress u3)
(define-constant status-completed u4)
(define-constant status-cancelled u5)

;; Dispute status constants
(define-constant dispute-status-active u1)
(define-constant dispute-status-resolved u2)

;; Vote constants
(define-constant vote-for-rider u1)
(define-constant vote-for-driver u2)

;; Data Maps
(define-map rides
  uint
  {
    rider: principal,
    driver: (optional principal),
    pickup-location: (string-ascii 100),
    destination: (string-ascii 100),
    fare: uint,
    base-fare: uint,
    surge-multiplier: uint,
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

(define-map mediators
  principal
  {
    stake: uint,
    is-active: bool,
    registered-at: uint,
    unregistered-at: (optional uint)
  }
)

(define-map disputes
  uint ;; ride-id
  {
    raised-by: principal,
    raised-at: uint,
    voting-ends-at: uint,
    status: uint,
    votes-for-rider: uint,
    votes-for-driver: uint,
    resolved-at: (optional uint),
    resolution: (optional uint)
  }
)

(define-map dispute-votes
  {dispute-id: uint, mediator: principal}
  {
    vote: uint,
    voted-at: uint
  }
)

;; Location-based demand tracking
(define-map location-demand
  (string-ascii 100) ;; location identifier
  {
    active-requests: uint,
    available-drivers: uint,
    last-updated: uint
  }
)

;; Surge pricing history for analytics
(define-map surge-history
  {location: (string-ascii 100), block-height: uint}
  {
    multiplier: uint,
    demand: uint,
    supply: uint
  }
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

(define-private (is-within-dispute-window (completed-at uint))
  (<= (- stacks-block-height completed-at) (var-get dispute-window))
)

(define-private (is-voting-period-active (voting-ends-at uint))
  (< stacks-block-height voting-ends-at)
)

(define-private (calculate-slash-amount (stake uint))
  (/ (* stake (var-get stake-slash-rate)) u10000)
)

(define-private (min-uint (a uint) (b uint))
  (if (<= a b) a b)
)

(define-private (calculate-surge-multiplier (demand uint) (supply uint))
  (let (
    (demand-threshold-val (var-get demand-threshold))
    (supply-threshold-val (var-get supply-threshold))
    (base-multiplier (var-get base-surge-multiplier))
    (max-multiplier (var-get max-surge-multiplier))
  )
    (if (and (>= demand demand-threshold-val) (<= supply supply-threshold-val))
      (let (
        (demand-ratio (if (> supply u0) (/ (* demand u10000) supply) u10000))
        (surge-multiplier (min-uint 
          max-multiplier 
          (+ base-multiplier (/ (* demand-ratio u1000) u100))
        ))
      )
        surge-multiplier
      )
      base-multiplier
    )
  )
)

(define-private (apply-surge-pricing (base-fare uint) (multiplier uint))
  (/ (* base-fare multiplier) u10000)
)

(define-private (update-location-demand (location (string-ascii 100)) (demand-change int) (supply-change int))
  (let (
    (current-data (default-to 
      {active-requests: u0, available-drivers: u0, last-updated: u0}
      (map-get? location-demand location)
    ))
    (new-demand (if (>= demand-change 0) 
      (+ (get active-requests current-data) (to-uint demand-change))
      (if (>= (get active-requests current-data) (to-uint (- 0 demand-change)))
        (- (get active-requests current-data) (to-uint (- 0 demand-change)))
        u0
      )
    ))
    (new-supply (if (>= supply-change 0)
      (+ (get available-drivers current-data) (to-uint supply-change))
      (if (>= (get available-drivers current-data) (to-uint (- 0 supply-change)))
        (- (get available-drivers current-data) (to-uint (- 0 supply-change)))
        u0
      )
    ))
  )
    (map-set location-demand location {
      active-requests: new-demand,
      available-drivers: new-supply,
      last-updated: stacks-block-height
    })
    {demand: new-demand, supply: new-supply}
  )
)

(define-private (record-surge-history (location (string-ascii 100)) (multiplier uint) (demand uint) (supply uint))
  (map-set surge-history 
    {location: location, block-height: stacks-block-height}
    {multiplier: multiplier, demand: demand, supply: supply}
  )
)

;; Public Functions

;; Request a ride with dynamic pricing
(define-public (request-ride (pickup (string-ascii 100)) (destination (string-ascii 100)) (base-fare uint))
  (let (
    (ride-id (get-next-ride-id))
    (demand-supply (update-location-demand pickup 1 0))
    (surge-multiplier (calculate-surge-multiplier (get demand demand-supply) (get supply demand-supply)))
    (final-fare (apply-surge-pricing base-fare surge-multiplier))
    (platform-fee-amount (calculate-platform-fee final-fare))
    (total-amount (+ final-fare platform-fee-amount))
  )
    (asserts! (> base-fare u0) err-insufficient-funds)
    (asserts! (> (len pickup) u0) err-invalid-location)
    (asserts! (> (len destination) u0) err-invalid-location)
    (asserts! (<= surge-multiplier (var-get max-surge-multiplier)) err-invalid-multiplier)
    
    (try! (stx-transfer? total-amount tx-sender (as-contract tx-sender)))
    
    (map-set rides ride-id {
      rider: tx-sender,
      driver: none,
      pickup-location: pickup,
      destination: destination,
      fare: final-fare,
      base-fare: base-fare,
      surge-multiplier: surge-multiplier,
      status: status-requested,
      created-at: stacks-block-height,
      completed-at: none
    })
    
    (map-set escrow-balances ride-id total-amount)
    
    ;; Record surge pricing history
    (record-surge-history pickup surge-multiplier (get demand demand-supply) (get supply demand-supply))
    
    (ok {ride-id: ride-id, surge-multiplier: surge-multiplier, final-fare: final-fare})
  )
)

;; Accept a ride (driver) - updates supply metrics
(define-public (accept-ride (ride-id uint))
  (let (
    (ride-data (unwrap! (map-get? rides ride-id) err-not-found))
  )
    (asserts! (is-eq (get status ride-data) status-requested) err-invalid-status)
    
    ;; Update supply - one less available driver, one less active request
    (update-location-demand (get pickup-location ride-data) -1 -1)
    
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

;; Complete ride (driver) - driver becomes available again
(define-public (complete-ride (ride-id uint))
  (let (
    (ride-data (unwrap! (map-get? rides ride-id) err-not-found))
    (escrowed-amount (unwrap! (map-get? escrow-balances ride-id) err-not-found))
    (platform-fee-amount (calculate-platform-fee (get fare ride-data)))
    (driver-payment (get fare ride-data))
    (driver-principal (unwrap! (get driver ride-data) err-not-found))
  )
    (asserts! (is-eq (some tx-sender) (get driver ride-data)) err-unauthorized)
    (asserts! (is-eq (get status ride-data) status-in-progress) err-invalid-status)
    
    ;; Driver becomes available again
    (update-location-demand (get pickup-location ride-data) 0 1)
    
    ;; Transfer payment to driver
    (try! (as-contract (stx-transfer? driver-payment tx-sender driver-principal)))
    
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
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    
    (map-set driver-ratings driver-principal {
      total-rating: (+ (get total-rating current-rating) rating),
      ride-count: (+ (get ride-count current-rating) u1)
    })
    (ok true)
  )
)

;; Cancel ride (rider or driver) - adjusts demand/supply
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
    
    ;; Adjust demand/supply based on ride status
    (if (is-eq (get status ride-data) status-accepted)
      ;; If ride was accepted, driver becomes available again and request is removed
      (update-location-demand (get pickup-location ride-data) -1 1)
      ;; If ride was only requested, just remove the request
      (update-location-demand (get pickup-location ride-data) -1 0)
    )
    
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

;; Register as available driver for location-based supply
(define-public (register-driver-availability (location (string-ascii 100)))
  (begin
    (asserts! (> (len location) u0) err-invalid-location)
    (update-location-demand location 0 1)
    (ok true)
  )
)

;; Unregister driver availability
(define-public (unregister-driver-availability (location (string-ascii 100)))
  (begin
    (asserts! (> (len location) u0) err-invalid-location)
    (update-location-demand location 0 -1)
    (ok true)
  )
)

;; Register as mediator
(define-public (register-mediator)
  (let (
    (existing-mediator (map-get? mediators tx-sender))
    (required-stake (var-get mediator-stake-required))
  )
    (asserts! (is-none existing-mediator) err-already-exists)
    (try! (stx-transfer? required-stake tx-sender (as-contract tx-sender)))
    (map-set mediators tx-sender {
      stake: required-stake,
      is-active: true,
      registered-at: stacks-block-height,
      unregistered-at: none
    })
    (ok true)
  )
)

;; Unregister as mediator
(define-public (unregister-mediator)
  (let (
    (mediator-data (unwrap! (map-get? mediators tx-sender) err-not-found))
    (stake-amount (get stake mediator-data))
  )
    (asserts! (get is-active mediator-data) err-not-mediator)
    
    ;; Set as inactive and record unregistration time
    (map-set mediators tx-sender (merge mediator-data {
      is-active: false,
      unregistered-at: (some stacks-block-height)
    }))
    
    ;; Return stake after cooldown check (simplified - in production, would need separate withdrawal function)
    (try! (as-contract (stx-transfer? stake-amount tx-sender tx-sender)))
    
    (ok true)
  )
)

;; Raise dispute
(define-public (raise-dispute (ride-id uint))
  (let (
    (ride-data (unwrap! (map-get? rides ride-id) err-not-found))
    (completed-at (unwrap! (get completed-at ride-data) err-invalid-status))
    (voting-ends-at (+ stacks-block-height (var-get voting-period)))
  )
    (asserts! (is-eq (get status ride-data) status-completed) err-invalid-status)
    (asserts! (or 
      (is-eq tx-sender (get rider ride-data))
      (is-eq (some tx-sender) (get driver ride-data))
    ) err-unauthorized)
    (asserts! (is-within-dispute-window completed-at) err-dispute-window-closed)
    (asserts! (is-none (map-get? disputes ride-id)) err-dispute-already-exists)
    
    (map-set disputes ride-id {
      raised-by: tx-sender,
      raised-at: stacks-block-height,
      voting-ends-at: voting-ends-at,
      status: dispute-status-active,
      votes-for-rider: u0,
      votes-for-driver: u0,
      resolved-at: none,
      resolution: none
    })
    (ok true)
  )
)

;; Vote on dispute (mediator)
(define-public (vote-on-dispute (ride-id uint) (vote uint))
  (let (
    (dispute-data (unwrap! (map-get? disputes ride-id) err-not-found))
    (mediator-data (unwrap! (map-get? mediators tx-sender) err-not-mediator))
    (vote-key {dispute-id: ride-id, mediator: tx-sender})
  )
    (asserts! (get is-active mediator-data) err-not-mediator)
    (asserts! (is-eq (get status dispute-data) dispute-status-active) err-invalid-status)
    (asserts! (is-voting-period-active (get voting-ends-at dispute-data)) err-voting-period-ended)
    (asserts! (is-none (map-get? dispute-votes vote-key)) err-already-voted)
    (asserts! (or (is-eq vote vote-for-rider) (is-eq vote vote-for-driver)) err-invalid-vote)
    
    ;; Record vote
    (map-set dispute-votes vote-key {
      vote: vote,
      voted-at: stacks-block-height
    })
    
    ;; Update vote counts
    (if (is-eq vote vote-for-rider)
      (map-set disputes ride-id (merge dispute-data {
        votes-for-rider: (+ (get votes-for-rider dispute-data) u1)
      }))
      (map-set disputes ride-id (merge dispute-data {
        votes-for-driver: (+ (get votes-for-driver dispute-data) u1)
      }))
    )
    (ok true)
  )
)

;; Finalize dispute
(define-public (finalize-dispute (ride-id uint))
  (let (
    (dispute-data (unwrap! (map-get? disputes ride-id) err-not-found))
    (ride-data (unwrap! (map-get? rides ride-id) err-not-found))
    (votes-for-rider (get votes-for-rider dispute-data))
    (votes-for-driver (get votes-for-driver dispute-data))
    (total-votes (+ votes-for-rider votes-for-driver))
    (escrowed-amount (unwrap! (map-get? escrow-balances ride-id) err-not-found))
  )
    (asserts! (is-eq (get status dispute-data) dispute-status-active) err-invalid-status)
    (asserts! (not (is-voting-period-active (get voting-ends-at dispute-data))) err-voting-period-active)
    (asserts! (> total-votes u0) err-invalid-status)
    
    ;; Determine winner and process payment
    (let (
      (resolution (if (> votes-for-rider votes-for-driver) vote-for-rider vote-for-driver))
    )
      (if (is-eq resolution vote-for-rider)
        ;; Refund to rider
        (try! (as-contract (stx-transfer? escrowed-amount tx-sender (get rider ride-data))))
        ;; Pay driver (platform fee already deducted in complete-ride)
        (try! (as-contract (stx-transfer? escrowed-amount tx-sender (unwrap! (get driver ride-data) err-not-found))))
      )
      
      ;; Update dispute status
      (map-set disputes ride-id (merge dispute-data {
        status: dispute-status-resolved,
        resolved-at: (some stacks-block-height),
        resolution: (some resolution)
      }))
      
      ;; Clear escrow
      (map-delete escrow-balances ride-id)
      
      (ok resolution)
    )
  )
)

;; Admin function to update surge pricing parameters
(define-public (update-surge-parameters (new-base-multiplier uint) (new-max-multiplier uint) (new-demand-threshold uint) (new-supply-threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= new-base-multiplier u5000) err-invalid-multiplier) ;; Min 0.5x
    (asserts! (<= new-max-multiplier u100000) err-invalid-multiplier) ;; Max 10x
    (asserts! (< new-base-multiplier new-max-multiplier) err-invalid-multiplier)
    (asserts! (> new-demand-threshold u0) err-invalid-status)
    (asserts! (> new-supply-threshold u0) err-invalid-status)
    
    (var-set base-surge-multiplier new-base-multiplier)
    (var-set max-surge-multiplier new-max-multiplier)
    (var-set demand-threshold new-demand-threshold)
    (var-set supply-threshold new-supply-threshold)
    (ok true)
  )
)

;; Read-only functions

;; Get ride details
(define-read-only (get-ride (ride-id uint))
  (map-get? rides ride-id)
)

;; Get current surge pricing for location
(define-read-only (get-current-surge-pricing (location (string-ascii 100)) (base-fare uint))
  (let (
    (location-data (default-to 
      {active-requests: u0, available-drivers: u0, last-updated: u0}
      (map-get? location-demand location)
    ))
    (demand (get active-requests location-data))
    (supply (get available-drivers location-data))
    (surge-multiplier (calculate-surge-multiplier demand supply))
    (final-fare (apply-surge-pricing base-fare surge-multiplier))
  )
    {
      surge-multiplier: surge-multiplier,
      final-fare: final-fare,
      base-fare: base-fare,
      demand: demand,
      supply: supply
    }
  )
)

;; Get location demand/supply data
(define-read-only (get-location-metrics (location (string-ascii 100)))
  (default-to 
    {active-requests: u0, available-drivers: u0, last-updated: u0}
    (map-get? location-demand location)
  )
)

;; Get surge pricing parameters
(define-read-only (get-surge-parameters)
  {
    base-multiplier: (var-get base-surge-multiplier),
    max-multiplier: (var-get max-surge-multiplier),
    demand-threshold: (var-get demand-threshold),
    supply-threshold: (var-get supply-threshold)
  }
)

;; Get surge history for location and block
(define-read-only (get-surge-history (location (string-ascii 100)) (target-block uint))
  (map-get? surge-history {location: location, block-height: target-block})
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

;; Get dispute details
(define-read-only (get-dispute (ride-id uint))
  (map-get? disputes ride-id)
)

;; Get mediator information
(define-read-only (get-mediator (mediator principal))
  (map-get? mediators mediator)
)

;; Check if mediator is active
(define-read-only (is-mediator-active (mediator principal))
  (match (map-get? mediators mediator)
    mediator-data (get is-active mediator-data)
    false
  )
)

;; Get mediator stake
(define-read-only (get-mediator-stake (mediator principal))
  (match (map-get? mediators mediator)
    mediator-data (some (get stake mediator-data))
    none
  )
)

;; Get dispute votes
(define-read-only (get-dispute-votes (ride-id uint))
  (match (map-get? disputes ride-id)
    dispute-data {
      votes-for-rider: (get votes-for-rider dispute-data),
      votes-for-driver: (get votes-for-driver dispute-data),
      total-votes: (+ (get votes-for-rider dispute-data) (get votes-for-driver dispute-data))
    }
    {votes-for-rider: u0, votes-for-driver: u0, total-votes: u0}
  )
)