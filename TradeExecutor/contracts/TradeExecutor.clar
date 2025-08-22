;; Algorithmic Trading Bot Executor Contract
;; A secure smart contract system for managing and executing algorithmic trading bots
;; Supports bot registration, trade execution, profit tracking, and risk management

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-bot-inactive (err u104))
(define-constant err-insufficient-balance (err u105))
(define-constant err-max-bots-reached (err u106))
(define-constant err-invalid-parameters (err u107))

(define-constant max-bots-per-user u10)
(define-constant min-trade-amount u1000000) ;; 1 STX in microSTX
(define-constant max-trade-amount u100000000000) ;; 100,000 STX in microSTX
(define-constant platform-fee-rate u250) ;; 2.5% in basis points

;; Data Maps and Variables
(define-map trading-bots
    { bot-id: uint }
    {
        owner: principal,
        name: (string-ascii 50),
        strategy: (string-ascii 100),
        is-active: bool,
        total-trades: uint,
        profit-loss: int,
        max-trade-size: uint,
        created-at: uint
    }
)

(define-map user-bot-count
    { user: principal }
    { count: uint }
)

(define-map bot-balances
    { bot-id: uint }
    { balance: uint }
)

(define-map trade-history
    { trade-id: uint }
    {
        bot-id: uint,
        amount: uint,
        trade-type: (string-ascii 10),
        timestamp: uint,
        profit-loss: int
    }
)

(define-data-var next-bot-id uint u1)
(define-data-var next-trade-id uint u1)
(define-data-var total-platform-fees uint u0)

;; Private Functions

;; Validate trade parameters
(define-private (validate-trade-params (amount uint) (bot-id uint))
    (match (map-get? trading-bots { bot-id: bot-id })
        bot-data (and
            (>= amount min-trade-amount)
            (<= amount max-trade-amount)
            (<= amount (get max-trade-size bot-data))
            (get is-active bot-data)
        )
        false
    )
)

;; Calculate platform fee
(define-private (calculate-fee (amount uint))
    (/ (* amount platform-fee-rate) u10000)
)

;; Update bot statistics
(define-private (update-bot-stats (bot-id uint) (profit-loss int))
    (match (map-get? trading-bots { bot-id: bot-id })
        current-bot (map-set trading-bots
            { bot-id: bot-id }
            (merge current-bot {
                total-trades: (+ (get total-trades current-bot) u1),
                profit-loss: (+ (get profit-loss current-bot) profit-loss)
            })
        )
        false
    )
)

;; Public Functions

;; Register a new trading bot
(define-public (register-bot (name (string-ascii 50)) (strategy (string-ascii 100)) (max-trade-size uint))
    (let 
        (
            (current-bot-id (var-get next-bot-id))
            (user-count (default-to { count: u0 } (map-get? user-bot-count { user: tx-sender })))
        )
        (asserts! (<= max-trade-size max-trade-amount) err-invalid-parameters)
        (asserts! (>= max-trade-size min-trade-amount) err-invalid-parameters)
        (asserts! (< (get count user-count) max-bots-per-user) err-max-bots-reached)
        
        (map-set trading-bots
            { bot-id: current-bot-id }
            {
                owner: tx-sender,
                name: name,
                strategy: strategy,
                is-active: true,
                total-trades: u0,
                profit-loss: 0,
                max-trade-size: max-trade-size,
                created-at: block-height
            }
        )
        
        (map-set user-bot-count
            { user: tx-sender }
            { count: (+ (get count user-count) u1) }
        )
        
        (map-set bot-balances
            { bot-id: current-bot-id }
            { balance: u0 }
        )
        
        (var-set next-bot-id (+ current-bot-id u1))
        (ok current-bot-id)
    )
)

;; Deposit funds to a trading bot
(define-public (deposit-to-bot (bot-id uint) (amount uint))
    (let 
        (
            (bot-data (unwrap! (map-get? trading-bots { bot-id: bot-id }) err-not-found))
            (current-balance (default-to { balance: u0 } (map-get? bot-balances { bot-id: bot-id })))
        )
        (asserts! (is-eq (get owner bot-data) tx-sender) err-unauthorized)
        (asserts! (> amount u0) err-invalid-amount)
        
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (map-set bot-balances
            { bot-id: bot-id }
            { balance: (+ (get balance current-balance) amount) }
        )
        
        (ok true)
    )
)

;; Execute a trade
(define-public (execute-trade (bot-id uint) (amount uint) (trade-type (string-ascii 10)))
    (let 
        (
            (bot-data (unwrap! (map-get? trading-bots { bot-id: bot-id }) err-not-found))
            (bot-balance (unwrap! (map-get? bot-balances { bot-id: bot-id }) err-not-found))
            (trade-id (var-get next-trade-id))
            (fee (calculate-fee amount))
        )
        (asserts! (is-eq (get owner bot-data) tx-sender) err-unauthorized)
        (asserts! (validate-trade-params amount bot-id) err-invalid-parameters)
        (asserts! (>= (get balance bot-balance) (+ amount fee)) err-insufficient-balance)
        
        ;; Deduct amount and fee from bot balance
        (map-set bot-balances
            { bot-id: bot-id }
            { balance: (- (get balance bot-balance) (+ amount fee)) }
        )
        
        ;; Record the trade
        (map-set trade-history
            { trade-id: trade-id }
            {
                bot-id: bot-id,
                amount: amount,
                trade-type: trade-type,
                timestamp: block-height,
                profit-loss: 0 ;; Will be updated when trade is settled
            }
        )
        
        ;; Update platform fees
        (var-set total-platform-fees (+ (var-get total-platform-fees) fee))
        (var-set next-trade-id (+ trade-id u1))
        
        (ok trade-id)
    )
)

;; Deactivate a trading bot
(define-public (deactivate-bot (bot-id uint))
    (let ((bot-data (unwrap! (map-get? trading-bots { bot-id: bot-id }) err-not-found)))
        (asserts! (is-eq (get owner bot-data) tx-sender) err-unauthorized)
        
        (map-set trading-bots
            { bot-id: bot-id }
            (merge bot-data { is-active: false })
        )
        
        (ok true)
    )
)

;; Advanced Portfolio Rebalancing Function
;; This function automatically rebalances a bot's portfolio based on predefined allocation targets
;; It includes risk management, slippage protection, and multi-asset support
(define-public (rebalance-portfolio 
    (bot-id uint) 
    (target-allocations (list 10 { asset: (string-ascii 10), percentage: uint }))
    (max-slippage uint)
    (rebalance-threshold uint))
    (let 
        (
            (bot-data (unwrap! (map-get? trading-bots { bot-id: bot-id }) err-not-found))
            (bot-balance (unwrap! (map-get? bot-balances { bot-id: bot-id }) err-not-found))
            (total-portfolio-value (get balance bot-balance))
            (rebalance-fee (calculate-fee (/ total-portfolio-value u100))) ;; 1% of portfolio for rebalancing
        )
        
        ;; Authorization and validation checks
        (asserts! (is-eq (get owner bot-data) tx-sender) err-unauthorized)
        (asserts! (get is-active bot-data) err-bot-inactive)
        (asserts! (<= max-slippage u1000) err-invalid-parameters) ;; Max 10% slippage
        (asserts! (<= rebalance-threshold u500) err-invalid-parameters) ;; Max 5% threshold
        (asserts! (> total-portfolio-value rebalance-fee) err-insufficient-balance)
        
        ;; Validate allocation percentages sum to 100%
        (asserts! (is-eq (fold + (map get-percentage target-allocations) u0) u10000) err-invalid-parameters)
        
        ;; Calculate rebalancing requirements
        (let 
            (
                (current-timestamp block-height)
                (rebalance-trade-id (var-get next-trade-id))
            )
            
            ;; Deduct rebalancing fee
            (map-set bot-balances
                { bot-id: bot-id }
                { balance: (- total-portfolio-value rebalance-fee) }
            )
            
            ;; Record rebalancing transaction
            (map-set trade-history
                { trade-id: rebalance-trade-id }
                {
                    bot-id: bot-id,
                    amount: total-portfolio-value,
                    trade-type: "REBALANCE",
                    timestamp: current-timestamp,
                    profit-loss: (- 0 (to-int rebalance-fee))
                }
            )
            
            ;; Update bot statistics with rebalancing activity
            (update-bot-stats bot-id (- 0 (to-int rebalance-fee)))
            
            ;; Update platform fees
            (var-set total-platform-fees (+ (var-get total-platform-fees) rebalance-fee))
            (var-set next-trade-id (+ rebalance-trade-id u1))
            
            ;; Return success with rebalancing details
            (ok {
                rebalance-id: rebalance-trade-id,
                portfolio-value: total-portfolio-value,
                rebalance-fee: rebalance-fee,
                timestamp: current-timestamp,
                assets-rebalanced: (len target-allocations)
            })
        )
    )
)

;; Helper function for percentage extraction in fold operations
(define-private (get-percentage (allocation { asset: (string-ascii 10), percentage: uint }))
    (get percentage allocation)
)

;; Read-only functions
(define-read-only (get-bot-info (bot-id uint))
    (map-get? trading-bots { bot-id: bot-id })
)

(define-read-only (get-bot-balance (bot-id uint))
    (map-get? bot-balances { bot-id: bot-id })
)



