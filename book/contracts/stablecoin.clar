;; File: contracts/stablecoin.clar
;; Enhanced Stablecoin Contract - Phase 2
;; Fixes bugs, adds security features, and improves functionality

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-insufficient-funds (err u401))
(define-constant err-insufficient-collateral (err u402))
(define-constant err-unauthorized (err u403))
(define-constant err-invalid-amount (err u404))
(define-constant err-oracle-stale (err u405))
(define-constant err-contract-paused (err u406))

;; State variables
(define-data-var total-supply uint u0)
(define-data-var oracle-price uint u100000000) ;; Price in micro-units (8 decimals)
(define-data-var oracle-last-update uint u0)
(define-data-var contract-paused bool false)
(define-data-var collateral-ratio uint u150) ;; 150% - now adjustable
(define-data-var oracle-validity-period uint u144) ;; blocks (~24 hours)

;; Maps
(define-map balances principal uint)
(define-map collateral-deposits principal uint)
(define-map allowances {owner: principal, spender: principal} uint)
(define-map authorized-oracles principal bool)

;; Initialize contract owner as authorized oracle
(map-set authorized-oracles contract-owner true)

;; Administrative functions
(define-public (set-contract-paused (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set contract-paused paused)
    (ok paused)))

(define-public (set-collateral-ratio (new-ratio uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= new-ratio u100) err-invalid-amount) ;; Minimum 100%
    (var-set collateral-ratio new-ratio)
    (ok new-ratio)))

(define-public (authorize-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-oracles oracle true)
    (ok true)))

(define-public (revoke-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-delete authorized-oracles oracle)
    (ok true)))

;; Oracle functions (FIXED: proper authorization check)
(define-public (set-oracle-price (new-price uint))
  (begin
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (default-to false (map-get? authorized-oracles tx-sender)) err-unauthorized)
    (asserts! (> new-price u0) err-invalid-amount)
    (var-set oracle-price new-price)
    (var-set oracle-last-update block-height)
    (ok new-price)))

(define-read-only (get-price)
  (ok (var-get oracle-price)))

(define-read-only (is-oracle-fresh)
  (let ((last-update (var-get oracle-last-update))
        (current-block block-height)
        (validity-period (var-get oracle-validity-period)))
    (<= (- current-block last-update) validity-period)))

;; Core stablecoin functions (ENHANCED with security checks)
(define-public (deposit-collateral)
  (let ((amount (stx-get-balance tx-sender)))
    (begin
      (asserts! (not (var-get contract-paused)) err-contract-paused)
      (asserts! (> amount u0) err-invalid-amount)
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (map-set collateral-deposits 
        tx-sender 
        (+ amount (default-to u0 (map-get? collateral-deposits tx-sender))))
      (ok amount))))

(define-public (mint (amount uint))
  (let (
    (price (var-get oracle-price))
    (ratio (var-get collateral-ratio))
    (user-collateral (default-to u0 (map-get? collateral-deposits tx-sender)))
    (current-balance (default-to u0 (map-get? balances tx-sender)))
    (total-tokens-after-mint (+ current-balance amount))
    (required-collateral (/ (* (* total-tokens-after-mint price) ratio) u10000000000)) ;; Adjusted for 8 decimal places
  )
    (begin
      (asserts! (not (var-get contract-paused)) err-contract-paused)
      (asserts! (> amount u0) err-invalid-amount)
      (asserts! (is-oracle-fresh) err-oracle-stale)
      (asserts! (>= user-collateral required-collateral) err-insufficient-collateral)
      
      ;; Update balances
      (map-set balances tx-sender total-tokens-after-mint)
      (var-set total-supply (+ amount (var-get total-supply)))
      
      ;; Emit mint event (via print)
      (print {event: "mint", user: tx-sender, amount: amount, price: price})
      (ok amount))))

(define-public (burn (amount uint))
  (let (
    (current-balance (default-to u0 (map-get? balances tx-sender)))
    (price (var-get oracle-price))
    (user-collateral (default-to u0 (map-get? collateral-deposits tx-sender)))
    (collateral-to-release (/ (* amount price) u100000000)) ;; Adjusted for 8 decimal places
  )
    (begin
      (asserts! (not (var-get contract-paused)) err-contract-paused)
      (asserts! (> amount u0) err-invalid-amount)
      (asserts! (>= current-balance amount) err-insufficient-funds)
      (asserts! (>= user-collateral collateral-to-release) err-insufficient-collateral)
      
      ;; Update balances
      (map-set balances tx-sender (- current-balance amount))
      (map-set collateral-deposits tx-sender (- user-collateral collateral-to-release))
      (var-set total-supply (- (var-get total-supply) amount))
      
      ;; Return collateral
      (try! (as-contract (stx-transfer? collateral-to-release tx-sender tx-sender)))
      
      ;; Emit burn event
      (print {event: "burn", user: tx-sender, amount: amount, collateral-released: collateral-to-release})
      (ok collateral-to-release))))

;; ERC-20 like functions for better interoperability
(define-public (transfer (to principal) (amount uint))
  (let ((sender-balance (default-to u0 (map-get? balances tx-sender))))
    (begin
      (asserts! (not (var-get contract-paused)) err-contract-paused)
      (asserts! (>= sender-balance amount) err-insufficient-funds)
      (asserts! (> amount u0) err-invalid-amount)
      
      (map-set balances tx-sender (- sender-balance amount))
      (map-set balances to (+ amount (default-to u0 (map-get? balances to))))
      
      (print {event: "transfer", from: tx-sender, to: to, amount: amount})
      (ok true))))

(define-public (approve (spender principal) (amount uint))
  (begin
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (map-set allowances {owner: tx-sender, spender: spender} amount)
    (print {event: "approval", owner: tx-sender, spender: spender, amount: amount})
    (ok true)))

(define-public (transfer-from (from principal) (to principal) (amount uint))
  (let (
    (allowance (default-to u0 (map-get? allowances {owner: from, spender: tx-sender})))
    (from-balance (default-to u0 (map-get? balances from)))
  )
    (begin
      (asserts! (not (var-get contract-paused)) err-contract-paused)
      (asserts! (>= allowance amount) err-unauthorized)
      (asserts! (>= from-balance amount) err-insufficient-funds)
      (asserts! (> amount u0) err-invalid-amount)
      
      (map-set allowances {owner: from, spender: tx-sender} (- allowance amount))
      (map-set balances from (- from-balance amount))
      (map-set balances to (+ amount (default-to u0 (map-get? balances to))))
      
      (print {event: "transfer", from: from, to: to, amount: amount})
      (ok true))))

;; Read-only functions
(define-read-only (get-balance (account principal))
  (default-to u0 (map-get? balances account)))

(define-read-only (get-collateral (account principal))
  (default-to u0 (map-get? collateral-deposits account)))

(define-read-only (get-total-supply)
  (var-get total-supply))

(define-read-only (get-allowance (owner principal) (spender principal))
  (default-to u0 (map-get? allowances {owner: owner, spender: spender})))

(define-read-only (get-collateral-ratio)
  (var-get collateral-ratio))

(define-read-only (is-contract-paused)
  (var-get contract-paused))

(define-read-only (calculate-max-mint (account principal))
  (let (
    (user-collateral (default-to u0 (map-get? collateral-deposits account)))
    (current-balance (default-to u0 (map-get? balances account)))
    (price (var-get oracle-price))
    (ratio (var-get collateral-ratio))
    (max-total-tokens (/ (* user-collateral u10000000000) (* price ratio)))
  )
    (if (> max-total-tokens current-balance)
      (- max-total-tokens current-balance)
      u0)))

;; Emergency functions
(define-public (emergency-withdraw)
  (let ((user-collateral (default-to u0 (map-get? collateral-deposits tx-sender))))
    (begin
      (asserts! (> user-collateral u0) err-insufficient-funds)
      (map-delete collateral-deposits tx-sender)
      (try! (as-contract (stx-transfer? user-collateral tx-sender tx-sender)))
      (ok user-collateral))))
