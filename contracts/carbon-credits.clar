;; Carbon Credit Generation Contract
;; Converts verified renewable energy production into tradeable carbon credits

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-INVALID-ENERGY-AMOUNT (err u501))
(define-constant ERR-INSUFFICIENT-CREDITS (err u502))
(define-constant ERR-INVALID-RECIPIENT (err u503))
(define-constant ERR-CREDIT-NOT-FOUND (err u504))
(define-constant ERR-ALREADY-RETIRED (err u505))
(define-constant ERR-INVALID-SOURCE (err u506))

;; Data Variables
(define-data-var credit-counter uint u0)
(define-data-var total-credits-generated uint u0)
(define-data-var total-credits-retired uint u0)

;; Conversion rates (credits per MWh of renewable energy)
(define-data-var solar-conversion-rate uint u400) ;; 0.4 credits per MWh
(define-data-var wind-conversion-rate uint u450) ;; 0.45 credits per MWh
(define-data-var hydro-conversion-rate uint u350) ;; 0.35 credits per MWh

;; Data Maps
(define-map carbon-credits
  { credit-id: uint }
  {
    owner: principal,
    energy-source: (string-ascii 20),
    energy-amount-wh: uint,
    credit-amount: uint,
    generation-date: uint,
    source-installation-id: uint,
    verification-status: bool,
    retired: bool,
    retirement-date: (optional uint)
  }
)

(define-map credit-balances
  { owner: principal }
  { balance: uint }
)

(define-map credit-transfers
  { transfer-id: uint }
  {
    from: principal,
    to: principal,
    credit-amount: uint,
    transfer-date: uint,
    transfer-price: uint
  }
)

(define-map verification-records
  { credit-id: uint }
  {
    verifier: principal,
    verification-date: uint,
    energy-verified: bool,
    additionality-verified: bool,
    permanence-verified: bool
  }
)

;; Public Functions

;; Generate carbon credits from verified renewable energy
(define-public (generate-credits
  (energy-source (string-ascii 20))
  (energy-amount-wh uint)
  (source-installation-id uint))
  (let
    (
      (credit-id (+ (var-get credit-counter) u1))
      (credit-amount (calculate-credit-amount energy-source energy-amount-wh))
      (current-balance (default-to u0 (get balance (map-get? credit-balances { owner: tx-sender }))))
    )
    (asserts! (> energy-amount-wh u0) ERR-INVALID-ENERGY-AMOUNT)
    (asserts! (> credit-amount u0) ERR-INVALID-SOURCE)

    (map-set carbon-credits
      { credit-id: credit-id }
      {
        owner: tx-sender,
        energy-source: energy-source,
        energy-amount-wh: energy-amount-wh,
        credit-amount: credit-amount,
        generation-date: block-height,
        source-installation-id: source-installation-id,
        verification-status: false,
        retired: false,
        retirement-date: none
      }
    )

    ;; Update credit balance
    (map-set credit-balances
      { owner: tx-sender }
      { balance: (+ current-balance credit-amount) }
    )

    (var-set credit-counter credit-id)
    (var-set total-credits-generated (+ (var-get total-credits-generated) credit-amount))
    (ok credit-id)
  )
)

;; Verify carbon credits
(define-public (verify-credits (credit-id uint))
  (let
    (
      (credit (unwrap! (map-get? carbon-credits { credit-id: credit-id }) ERR-CREDIT-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED) ;; Only authorized verifiers
    (asserts! (not (get verification-status credit)) ERR-ALREADY-RETIRED)

    (map-set carbon-credits
      { credit-id: credit-id }
      (merge credit { verification-status: true })
    )

    (map-set verification-records
      { credit-id: credit-id }
      {
        verifier: tx-sender,
        verification-date: block-height,
        energy-verified: true,
        additionality-verified: true,
        permanence-verified: true
      }
    )
    (ok true)
  )
)

;; Transfer carbon credits between parties
(define-public (transfer-credits
  (recipient principal)
  (credit-amount uint)
  (transfer-price uint))
  (let
    (
      (sender-balance (default-to u0 (get balance (map-get? credit-balances { owner: tx-sender }))))
      (recipient-balance (default-to u0 (get balance (map-get? credit-balances { owner: recipient }))))
      (transfer-id (+ (var-get credit-counter) u1))
    )
    (asserts! (not (is-eq tx-sender recipient)) ERR-INVALID-RECIPIENT)
    (asserts! (>= sender-balance credit-amount) ERR-INSUFFICIENT-CREDITS)
    (asserts! (> credit-amount u0) ERR-INVALID-ENERGY-AMOUNT)

    ;; Update balances
    (map-set credit-balances
      { owner: tx-sender }
      { balance: (- sender-balance credit-amount) }
    )

    (map-set credit-balances
      { owner: recipient }
      { balance: (+ recipient-balance credit-amount) }
    )

    ;; Record transfer
    (map-set credit-transfers
      { transfer-id: transfer-id }
      {
        from: tx-sender,
        to: recipient,
        credit-amount: credit-amount,
        transfer-date: block-height,
        transfer-price: transfer-price
      }
    )

    (ok transfer-id)
  )
)

;; Retire carbon credits for compliance
(define-public (retire-credits
  (credit-id uint)
  (retirement-reason (string-ascii 50)))
  (let
    (
      (credit (unwrap! (map-get? carbon-credits { credit-id: credit-id }) ERR-CREDIT-NOT-FOUND))
      (owner-balance (default-to u0 (get balance (map-get? credit-balances { owner: (get owner credit) }))))
    )
    (asserts! (is-eq (get owner credit) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (get retired credit)) ERR-ALREADY-RETIRED)
    (asserts! (get verification-status credit) ERR-INVALID-SOURCE) ;; Must be verified
    (asserts! (>= owner-balance (get credit-amount credit)) ERR-INSUFFICIENT-CREDITS)

    ;; Mark credit as retired
    (map-set carbon-credits
      { credit-id: credit-id }
      (merge credit {
        retired: true,
        retirement-date: (some block-height)
      })
    )

    ;; Update balance
    (map-set credit-balances
      { owner: tx-sender }
      { balance: (- owner-balance (get credit-amount credit)) }
    )

    (var-set total-credits-retired (+ (var-get total-credits-retired) (get credit-amount credit)))
    (ok true)
  )
)

;; Batch generate credits from multiple energy sources
(define-public (batch-generate-credits
  (energy-records (list 10 { source: (string-ascii 20), amount: uint, installation-id: uint })))
  (let
    (
      (results (map generate-single-credit energy-records))
    )
    (ok results)
  )
)

;; Get credit portfolio for an owner
(define-public (get-credit-portfolio (owner principal))
  (let
    (
      (balance (default-to u0 (get balance (map-get? credit-balances { owner: owner }))))
    )
    (ok {
      owner: owner,
      total-balance: balance,
      verified-credits: balance, ;; Simplified - in practice would filter verified credits
      retired-credits: u0 ;; Would calculate from retired credits owned by this principal
    })
  )
)

;; Read-only Functions

;; Get carbon credit data
(define-read-only (get-carbon-credit-data (credit-id uint))
  (map-get? carbon-credits { credit-id: credit-id })
)

;; Get credit balance for an owner
(define-read-only (get-credit-balance (owner principal))
  (default-to u0 (get balance (map-get? credit-balances { owner: owner })))
)

;; Get transfer record
(define-read-only (get-transfer-record (transfer-id uint))
  (map-get? credit-transfers { transfer-id: transfer-id })
)

;; Get verification record
(define-read-only (get-verification-record (credit-id uint))
  (map-get? verification-records { credit-id: credit-id })
)

;; Get total credits generated
(define-read-only (get-total-credits-generated)
  (var-get total-credits-generated)
)

;; Get total credits retired
(define-read-only (get-total-credits-retired)
  (var-get total-credits-retired)
)

;; Get credit count
(define-read-only (get-credit-count)
  (var-get credit-counter)
)

;; Get conversion rates
(define-read-only (get-conversion-rates)
  {
    solar: (var-get solar-conversion-rate),
    wind: (var-get wind-conversion-rate),
    hydro: (var-get hydro-conversion-rate)
  }
)

;; Private Functions

;; Calculate credit amount based on energy source and amount
(define-private (calculate-credit-amount (energy-source (string-ascii 20)) (energy-wh uint))
  (let
    (
      (energy-mwh (/ energy-wh u1000000)) ;; Convert Wh to MWh
      (conversion-rate (get-source-conversion-rate energy-source))
    )
    (/ (* energy-mwh conversion-rate) u1000) ;; Convert rate from per-1000 to actual
  )
)

;; Get conversion rate for specific energy source
(define-private (get-source-conversion-rate (energy-source (string-ascii 20)))
  (if (is-eq energy-source "solar")
    (var-get solar-conversion-rate)
    (if (is-eq energy-source "wind")
      (var-get wind-conversion-rate)
      (if (is-eq energy-source "hydro")
        (var-get hydro-conversion-rate)
        u0 ;; Unknown source
      )
    )
  )
)

;; Helper function for batch generation
(define-private (generate-single-credit (record { source: (string-ascii 20), amount: uint, installation-id: uint }))
  (generate-credits (get source record) (get amount record) (get installation-id record))
)

;; Update conversion rates (only contract owner)
(define-public (update-conversion-rates
  (solar-rate uint)
  (wind-rate uint)
  (hydro-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set solar-conversion-rate solar-rate)
    (var-set wind-conversion-rate wind-rate)
    (var-set hydro-conversion-rate hydro-rate)
    (ok true)
  )
)
