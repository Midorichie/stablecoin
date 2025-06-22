;; File: contracts/governance.clar
;; Stablecoin Governance Contract
;; Allows token holders to vote on protocol parameters

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u500))
(define-constant err-not-found (err u501))
(define-constant err-already-voted (err u502))
(define-constant err-proposal-closed (err u503))
(define-constant err-insufficient-balance (err u504))
(define-constant err-invalid-proposal (err u505))

;; Proposal types
(define-constant proposal-type-collateral-ratio u1)
(define-constant proposal-type-oracle-validity u2)
(define-constant proposal-type-emergency-pause u3)

;; Data structures
(define-data-var proposal-counter uint u0)
(define-data-var voting-period uint u1008) ;; ~1 week in blocks
(define-data-var minimum-quorum uint u1000000) ;; Minimum tokens needed for quorum

;; Maps
(define-map proposals 
  uint 
  {
    proposer: principal,
    proposal-type: uint,
    description: (string-ascii 256),
    new-value: uint,
    start-block: uint,
    end-block: uint,
    votes-for: uint,
    votes-against: uint,
    executed: bool
  })

(define-map votes {proposal-id: uint, voter: principal} {amount: uint, support: bool})
(define-map voter-snapshots {proposal-id: uint, voter: principal} uint)

;; We'll reference the stablecoin contract directly in contract calls

;; Create a new proposal
(define-public (create-proposal (proposal-type uint) (description (string-ascii 256)) (new-value uint))
  (let (
    (proposal-id (+ (var-get proposal-counter) u1))
    (start-block block-height)
    (end-block (+ block-height (var-get voting-period)))
  )
    (begin
      (asserts! (or (is-eq proposal-type proposal-type-collateral-ratio)
                    (is-eq proposal-type proposal-type-oracle-validity)
                    (is-eq proposal-type proposal-type-emergency-pause)) err-invalid-proposal)
      
      ;; Store proposal
      (map-set proposals proposal-id {
        proposer: tx-sender,
        proposal-type: proposal-type,
        description: description,
        new-value: new-value,
        start-block: start-block,
        end-block: end-block,
        votes-for: u0,
        votes-against: u0,
        executed: false
      })
      
      (var-set proposal-counter proposal-id)
      
      (print {event: "proposal-created", id: proposal-id, proposer: tx-sender, type: proposal-type})
      (ok proposal-id))))

;; Vote on a proposal
(define-public (vote (proposal-id uint) (support bool))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
    (voter-balance (contract-call? .stablecoin get-balance tx-sender))
    (existing-vote (map-get? votes {proposal-id: proposal-id, voter: tx-sender}))
  )
    (begin
      (asserts! (is-none existing-vote) err-already-voted)
      (asserts! (<= block-height (get end-block proposal)) err-proposal-closed)
      (asserts! (> voter-balance u0) err-insufficient-balance)
      
      ;; Record vote
      (map-set votes {proposal-id: proposal-id, voter: tx-sender} {amount: voter-balance, support: support})
      (map-set voter-snapshots {proposal-id: proposal-id, voter: tx-sender} voter-balance)
      
      ;; Update proposal vote counts
      (if support
        (map-set proposals proposal-id 
          (merge proposal {votes-for: (+ (get votes-for proposal) voter-balance)}))
        (map-set proposals proposal-id 
          (merge proposal {votes-against: (+ (get votes-against proposal) voter-balance)})))
      
      (print {event: "vote-cast", proposal-id: proposal-id, voter: tx-sender, support: support, amount: voter-balance})
      (ok true))))

;; Execute a proposal
(define-public (execute-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) err-not-found))
    (total-votes (+ (get votes-for proposal) (get votes-against proposal)))
    (quorum-met (>= total-votes (var-get minimum-quorum)))
    (proposal-passed (> (get votes-for proposal) (get votes-against proposal)))
  )
    (begin
      (asserts! (> block-height (get end-block proposal)) err-proposal-closed)
      (asserts! (not (get executed proposal)) err-proposal-closed)
      (asserts! quorum-met err-insufficient-balance)
      (asserts! proposal-passed err-invalid-proposal)
      
      ;; Mark as executed
      (map-set proposals proposal-id (merge proposal {executed: true}))
      
      ;; Execute based on proposal type and handle the result
      (begin
        (if (is-eq (get proposal-type proposal) proposal-type-collateral-ratio)
          (begin
            (try! (contract-call? .stablecoin set-collateral-ratio (get new-value proposal)))
            true)
          (if (is-eq (get proposal-type proposal) proposal-type-emergency-pause)
            (begin
              (try! (contract-call? .stablecoin set-contract-paused (> (get new-value proposal) u0)))
              true)
            true))
        
        (print {event: "proposal-executed", id: proposal-id, type: (get proposal-type proposal)})
        (ok true)))))

;; Administrative functions
(define-public (set-voting-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set voting-period new-period)
    (ok new-period)))

(define-public (set-minimum-quorum (new-quorum uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set minimum-quorum new-quorum)
    (ok new-quorum)))

;; Read-only functions
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id))

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes {proposal-id: proposal-id, voter: voter}))

(define-read-only (get-proposal-status (proposal-id uint))
  (let ((proposal (unwrap! (map-get? proposals proposal-id) err-not-found)))
    (ok {
      active: (<= block-height (get end-block proposal)),
      passed: (> (get votes-for proposal) (get votes-against proposal)),
      quorum-met: (>= (+ (get votes-for proposal) (get votes-against proposal)) (var-get minimum-quorum)),
      executed: (get executed proposal)
    })))

(define-read-only (get-voting-period)
  (var-get voting-period))

(define-read-only (get-minimum-quorum)
  (var-get minimum-quorum))

(define-read-only (get-proposal-count)
  (var-get proposal-counter))
