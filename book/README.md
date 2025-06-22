# Enhanced Stablecoin Protocol on Stacks (Phase 2)

A comprehensive, collateralized stablecoin implementation with governance features on the Stacks blockchain using Clarity smart contracts.

## 🚀 New Features (Phase 2)

### Major Improvements:
- **Fixed Critical Bugs**: Proper oracle authorization, accurate collateral calculations, and secure STX transfers
- **Enhanced Security**: Pausable contract, oracle staleness checks, emergency functions
- **Governance System**: Token holder voting on protocol parameters
- **ERC-20 Compatibility**: Transfer, approve, and allowance functions
- **Better Oracle Management**: Multiple authorized oracles with freshness validation
- **Administrative Controls**: Adjustable parameters and emergency functions

## 📋 Requirements

- [Clarinet](https://docs.hiro.so/clarity/clarinet/overview) v1.5.0+
- Node.js 16+ (for advanced testing)
- Stacks CLI (optional, for deployment)

## 🛠️ Setup

```bash
git clone <your-repo-url>
cd stablecoin
clarinet check
clarinet test
```

### Quick Start
```bash
# Check contract syntax
clarinet check

# Run interactive console
clarinet console

# Test contracts
clarinet test

# Start local devnet
clarinet integrate
```

## 📁 Project Structure

```
/contracts/
  ├── stablecoin.clar      # Main stablecoin contract (enhanced)
  └── governance.clar      # Governance and voting system
/tests/
  ├── stablecoin_test.ts   # Comprehensive unit tests
  └── governance_test.ts   # Governance functionality tests
/settings/
  └── Devnet.toml         # Local network configuration
Clarinet.toml             # Updated project configuration
README.md                 # This file
```

## 🔧 Contract Functions

### Stablecoin Contract (`stablecoin.clar`)

#### Core Functions:
- `deposit-collateral()` - Deposit STX as collateral
- `mint(amount)` - Mint stablecoins (requires sufficient collateral)
- `burn(amount)` - Burn tokens and release collateral
- `transfer(to, amount)` - Transfer tokens between accounts
- `approve(spender, amount)` - Approve spending allowance
- `transfer-from(from, to, amount)` - Transfer on behalf of another user

#### Oracle Functions:
- `set-oracle-price(new-price)` - Update price (authorized oracles only)
- `get-price()` - Get current oracle price
- `authorize-oracle(oracle)` - Add authorized oracle (owner only)
- `revoke-oracle(oracle)` - Remove oracle authorization (owner only)

#### Administrative Functions:
- `set-contract-paused(paused)` - Pause/unpause contract (owner only)
- `set-collateral-ratio(new-ratio)` - Adjust collateralization requirement
- `emergency-withdraw()` - Emergency collateral withdrawal

#### Read-Only Functions:
- `get-balance(account)` - Get token balance
- `get-collateral(account)` - Get collateral amount
- `get-total-supply()` - Get total token supply
- `calculate-max-mint(account)` - Calculate maximum mintable tokens
- `is-oracle-fresh()` - Check if oracle data is recent

### Governance Contract (`governance.clar`)

#### Proposal Functions:
- `create-proposal(type, description, new-value)` - Create new proposal
- `vote(proposal-id, support)` - Vote on proposal
- `execute-proposal(proposal-id)` - Execute passed proposal

#### Proposal Types:
1. **Collateral Ratio**: Adjust minimum collateralization requirement
2. **Oracle Validity**: Change oracle data freshness period
3. **Emergency Pause**: Pause/unpause the protocol

#### Administrative Functions:
- `set-voting-period(new-period)` - Adjust voting duration
- `set-minimum-quorum(new-quorum)` - Set minimum votes for validity

## 🔒 Security Features

### Bug Fixes from Phase 1:
1. **Fixed Oracle Authorization**: Replaced broken check with proper oracle mapping
2. **Accurate Collateral Calculations**: Fixed decimal precision and ratio calculations
3. **Proper STX Transfers**: Implemented actual STX deposit and withdrawal mechanics
4. **Overflow Protection**: Added bounds checking for all arithmetic operations

### New Security Measures:
- **Pausable Contract**: Emergency stop functionality
- **Oracle Staleness Checks**: Prevents using outdated price data
- **Multi-Oracle Support**: Reduces single point of failure
- **Reentrancy Protection**: Proper state updates before external calls
- **Access Control**: Role-based permissions for sensitive functions
- **Event Logging**: Comprehensive transaction logging for transparency

## 💡 Usage Examples

### Basic Operations
```clarity
;; Deposit 1000 STX as collateral
(contract-call? .stablecoin deposit-collateral)

;; Mint 500 tokens (assuming sufficient collateral)
(contract-call? .stablecoin mint u500)

;; Transfer 100 tokens to another user
(contract-call? .stablecoin transfer 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u100)

;; Burn 200 tokens and reclaim collateral
(contract-call? .stablecoin burn u200)
```

### Governance Operations
```clarity
;; Create proposal to change collateral ratio to 175%
(contract-call? .governance create-proposal u1 "Increase collateral ratio for stability" u175)

;; Vote in favor of proposal #1
(contract-call? .governance vote u1 true)

;; Execute proposal after voting period
(contract-call? .governance execute-proposal u1)
```

### Oracle Management
```clarity
;; Update price to $1.00 (in micro-units)
(contract-call? .stablecoin set-oracle-price u100000000)

;; Check if oracle data is fresh
(contract-call? .stablecoin is-oracle-fresh)
```

## 🧪 Testing

The project includes comprehensive test suites:

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/stablecoin_test.ts

# Run with coverage
clarinet test --coverage
```

### Test Coverage:
- ✅ Mint/burn functionality with proper collateralization
- ✅ Oracle price updates and authorization
- ✅ Transfer and allowance mechanisms
- ✅ Governance proposal creation and voting
- ✅ Security controls (pause, emergency functions)
- ✅ Edge cases and error conditions

## 🌐 Deployment

### Testnet Deployment
```bash
# Deploy to testnet
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment
```bash
# Deploy to mainnet (use with caution)
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## ⚠️ Important Notes

### Collateralization:
- Default collateral ratio: 150% (adjustable via governance)
- Minimum collateral ratio: 100%
- Oracle prices use 8 decimal precision (micro-units)

### Oracle System:
- Multiple oracles can be authorized for redundancy
- Oracle data expires after ~24 hours (adjustable)
- Price updates require proper authorization

### Governance:
- Token holders can vote on protocol parameters
- Minimum quorum required for proposal execution
- Voting period: ~1 week (adjustable)

### Security Considerations:
- Always verify oracle data freshness before minting
- Monitor collateralization ratios during market volatility
- Use governance for parameter adjustments, not emergency responses

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Submit a pull request

## 📞 Support

For questions or issues:
- Create an issue on GitHub
- Check the [Clarity documentation](https://docs.stacks.co/clarity)
- Join the [Stacks Discord](https://discord.gg/stacks)

---

*This project demonstrates advanced Clarity development patterns and is intended for educational purposes. Always conduct thorough testing and audits before deploying to mainnet.*
