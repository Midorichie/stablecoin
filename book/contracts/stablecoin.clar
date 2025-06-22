(define-data-var total-supply uint u0)
(define-map balances {account: principal} uint)
(define-map collateral {account: principal} uint)
(define-data-var oracle-price uint u100) ;; Mock oracle price (e.g., 1 token = 100 units)

(define-constant collateral-ratio u150) ;; 150% collateralization required

(define-public (set-oracle-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender tx-sender) (err u401)) ;; Replace with actual oracle check
    (var-set oracle-price new-price)
    (ok new-price)))

(define-public (get-price)
  (ok (var-get oracle-price)))

(define-public (mint (amount uint))
  (let (
    (price (var-get oracle-price))
    (required-collateral (/ (* amount price) u100))
    (min-collateral (/ (* required-collateral collateral-ratio) u100))
    (existing-collateral (default-to u0 (map-get? collateral {account: tx-sender})))
  )
    (begin
      ;; The contract must be called with a corresponding STX transfer using a separate transaction.
      ;; Track expected collateral externally or test with mocked values.
      (map-set balances {account: tx-sender} (+ amount (default-to u0 (map-get? balances {account: tx-sender}))))
      (map-set collateral {account: tx-sender} (+ min-collateral existing-collateral))
      (var-set total-supply (+ amount (var-get total-supply)))
      (ok true))))

(define-public (burn (amount uint))
  (let (
    (balance (default-to u0 (map-get? balances {account: tx-sender})))
    (price (var-get oracle-price))
    (user-collateral (default-to u0 (map-get? collateral {account: tx-sender})))
    (burn-value (/ (* amount price) u100))
    (collateral-to-release (/ (* burn-value u100) collateral-ratio))
  )
    (begin
      (asserts! (>= balance amount) (err u402))
      (asserts! (>= user-collateral collateral-to-release) (err u403))
      (map-set balances {account: tx-sender} (- balance amount))
      (map-set collateral {account: tx-sender} (- user-collateral collateral-to-release))
      (var-set total-supply (- (var-get total-supply) amount))
      ;; Actual STX transfer must be handled externally by a post-condition or wrapper
      (ok collateral-to-release))))
