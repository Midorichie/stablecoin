# Simple Stablecoin on Stacks

This project demonstrates a basic implementation of a stablecoin smart contract on the Stacks blockchain using Clarity. It includes:

- Minting & burning logic
- Mock oracle integration
- Collateralized deposits (STX)
- Price-based mint requirements

## Requirements
- [Clarinet](https://docs.hiro.so/clarity/clarinet/overview) installed
- Node.js (for running tests, optional)

## Setup
```bash
git clone <your-repo-url>
cd stablecoin
clarinet check
clarinet test
```

## File Structure
```
/contracts/stablecoin.clar     # Smart contract source code
/tests/stablecoin_test.ts      # Unit tests (optional)
README.md                      # Project guide
Clarinet.toml                  # Project config
```

## Functions Overview
- `mint(amount)` - Mints tokens by depositing STX at a 150% collateral ratio.
- `burn(amount)` - Burns tokens and releases STX back.
- `set-oracle-price(new-price)` - Sets mock oracle price.
- `get-price()` - Reads current oracle price.

## Notes
- Replace mock oracle logic with a trusted oracle integration for production.
- Collateral calculations assume `price` is scaled to base 100.
