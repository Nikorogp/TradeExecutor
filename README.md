TradeExecutor
=============

* * * * *

📄 **Introduction**
-------------------

The `TradeExecutor` smart contract is a secure and robust system designed to manage and execute algorithmic trading bots on the Stacks blockchain. It provides a comprehensive framework for users to register trading bots, manage their capital, execute trades, and track performance. The contract is built with security, efficiency, and transparency in mind, ensuring a reliable platform for automated trading strategies.

* * * * *

⚙️ **Functionality**
--------------------

### Bot Management

-   **Bot Registration**: Users can register a new trading bot with a unique ID, specifying its name, strategy, and maximum trade size.

-   **Bot Deactivation**: The contract owner can deactivate a bot, halting all trading activities.

-   **Bot Information Retrieval**: Anyone can query the details of a registered bot, including its owner, activity status, and performance metrics.

### Financial Operations

-   **Deposits**: Users can deposit STX tokens into their bot's dedicated balance, providing the necessary capital for trading.

-   **Trade Execution**: Bots can execute trades, with the contract automatically deducting the trade amount and a platform fee from the bot's balance.

-   **Portfolio Rebalancing**: A sophisticated function allows for the automatic rebalancing of a bot's portfolio based on predefined asset allocations, including built-in risk management features like slippage protection.

### Tracking and Analytics

-   **Balance Tracking**: Each bot's balance is meticulously tracked within the contract.

-   **Trade History**: Every trade executed is recorded in a detailed history, capturing critical data such as the trade ID, amount, type, timestamp, and profit/loss.

-   **Performance Metrics**: The contract tracks key performance indicators for each bot, including the total number of trades and cumulative profit or loss.

-   **Platform Fee Tracking**: The total fees collected by the platform are aggregated and stored.

* * * * *

💾 **Data Structures**
----------------------

### Maps

-   `trading-bots`: Stores detailed information about each registered bot, including its owner, name, strategy, and performance statistics.

-   `user-bot-count`: Tracks the number of bots owned by each user, enforcing a `max-bots-per-user` limit.

-   `bot-balances`: Holds the STX balance for each trading bot.

-   `trade-history`: A record of all trades executed, indexed by a unique trade ID.

### Variables

-   `next-bot-id`: A counter for assigning unique IDs to new bots.

-   `next-trade-id`: A counter for assigning unique IDs to new trades.

-   `total-platform-fees`: Accumulates the total fees collected from trades.

* * * * *

🛡️ **Error Handling**
----------------------

The contract uses a comprehensive set of error codes to provide clear feedback on failed transactions.

| Error Code | Description |
| --- | --- |
| `u100` | **err-owner-only**: The function can only be called by the contract owner. |
| `u101` | **err-not-found**: The specified bot or data entry was not found. |
| `u102` | **err-unauthorized**: The transaction sender is not authorized to perform this action. |
| `u103` | **err-invalid-amount**: The specified amount is not valid (e.g., zero or negative). |
| `u104` | **err-bot-inactive**: The target bot is currently inactive. |
| `u105` | **err-insufficient-balance**: The bot's balance is too low to cover the transaction. |
| `u106` | **err-max-bots-reached**: The user has reached the maximum limit for bot registration. |
| `u107` | **err-invalid-parameters**: The provided function parameters are invalid. |

* * * * *

🔒 **Security and Auditing**
----------------------------

The contract employs several security measures, including:

-   **Transaction Sender Authorization**: Critical functions like `deactivate-bot` and `execute-trade` are restricted to the bot's owner.

-   **Input Validation**: Public functions rigorously validate all input parameters, ensuring they fall within acceptable ranges and formats.

-   **Balance Checks**: All transactions that involve funds, such as `execute-trade`, include checks to prevent overdrafts.

-   **Hardcoded Constants**: Key parameters like minimum and maximum trade amounts and the platform fee rate are defined as constants, preventing runtime manipulation.

* * * * *

📋 **Developer Guide**
----------------------

### Private Functions

-   **`validate-trade-params`**: `(define-private (validate-trade-params (amount uint) (bot-id uint)))`

    -   **Description**: A private helper function that validates trade parameters against a bot's configuration, ensuring the trade amount is within limits and the bot is active.

-   **`calculate-fee`**: `(define-private (calculate-fee (amount uint)))`

    -   **Description**: A private helper function to calculate the platform fee based on the trade amount and a constant fee rate.

-   **`update-bot-stats`**: `(define-private (update-bot-stats (bot-id uint) (profit-loss int)))`

    -   **Description**: A private helper function to update a bot's total trade count and profit/loss.

-   **`get-percentage`**: `(define-private (get-percentage (allocation { asset: (string-ascii 10), percentage: uint })))`

    -   **Description**: A helper function used within `rebalance-portfolio` to extract the percentage from a list of allocations for summation.

### Public Functions

-   **`register-bot`**: `(define-public (register-bot (name (string-ascii 50)) (strategy (string-ascii 100)) (max-trade-size uint)))`

    -   **Description**: Registers a new trading bot.

    -   **Parameters**:

        -   `name`: The name of the bot.

        -   `strategy`: A description of the bot's trading strategy.

        -   `max-trade-size`: The maximum amount the bot is allowed to trade in a single transaction.

    -   **Returns**: `(ok uint)` with the new bot's ID, or an error.

-   **`deposit-to-bot`**: `(define-public (deposit-to-bot (bot-id uint) (amount uint)))`

    -   **Description**: Transfers STX from the sender to the specified bot's balance.

    -   **Parameters**:

        -   `bot-id`: The ID of the bot.

        -   `amount`: The amount of STX to deposit.

    -   **Returns**: `(ok bool)` indicating success, or an error.

-   **`execute-trade`**: `(define-public (execute-trade (bot-id uint) (amount uint) (trade-type (string-ascii 10))))`

    -   **Description**: Executes a trade, deducting the amount and platform fee from the bot's balance.

    -   **Parameters**:

        -   `bot-id`: The ID of the bot executing the trade.

        -   `amount`: The trade amount.

        -   `trade-type`: A string describing the trade type (e.g., "BUY", "SELL").

    -   **Returns**: `(ok uint)` with the new trade's ID, or an error.

-   **`deactivate-bot`**: `(define-public (deactivate-bot (bot-id uint)))`

    -   **Description**: Deactivates a bot, preventing it from executing further trades.

    -   **Parameters**: `bot-id`: The ID of the bot to deactivate.

    -   **Returns**: `(ok bool)` indicating success, or an error.

-   **`rebalance-portfolio`**: `(define-public (rebalance-portfolio (bot-id uint) (target-allocations (list 10 { asset: (string-ascii 10), percentage: uint })) (max-slippage uint) (rebalance-threshold uint)))`

    -   **Description**: An advanced function for automatically rebalancing a bot's portfolio.

    -   **Parameters**:

        -   `bot-id`: The ID of the bot to rebalance.

        -   `target-allocations`: A list of asset allocation targets.

        -   `max-slippage`: The maximum allowed slippage.

        -   `rebalance-threshold`: The percentage deviation that triggers a rebalance.

    -   **Returns**: `(ok { rebalance-id: uint, ... })` with rebalancing details, or an error.

### Read-Only Functions

-   **`get-bot-info`**: `(define-read-only (get-bot-info (bot-id uint)))`

    -   **Description**: Retrieves the full information struct for a given bot.

    -   **Parameters**: `bot-id`.

    -   **Returns**: `(optional { owner: principal, ... })`.

-   **`get-bot-balance`**: `(define-read-only (get-bot-balance (bot-id uint)))`

    -   **Description**: Retrieves the current balance of a bot.

    -   **Parameters**: `bot-id`.

    -   **Returns**: `(optional { balance: uint })`.

* * * * *

💡 **Getting Started**
----------------------

To interact with the contract, you'll need a Stacks wallet and a Stacks development environment.

### Deployment

1.  Set up your Stacks environment (e.g., with Clarinet).

2.  Copy the contract code into a `.clar` file.

3.  Use the `clarinet deploy` command to deploy the contract to a local or testnet environment.

### Example Usage

1.  **Register a bot**: `(contract-call? 'SP123... .trade-executor register-bot "MyFirstBot" "Scalping" u50000000)`

2.  **Deposit funds**: `(contract-call? 'SP123... .trade-executor deposit-to-bot u1 u100000000)`

3.  **Execute a trade**: `(contract-call? 'SP123... .trade-executor execute-trade u1 u2000000 "BUY")`

* * * * *

📜 **License**
--------------

This project is licensed under the MIT License. See the `LICENSE` file for details.

* * * * *

🤝 **Contribution**
-------------------

We welcome contributions from the community. Please read our `CONTRIBUTING.md` for guidelines on how to submit pull requests, report bugs, and suggest features.
