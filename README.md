# ORBEATX (OBX) Token & Vesting Protocol

A production-grade implementation of the ORBEATX (OBX) ecosystem, featuring a fixed-supply ERC-20 token and a decentralized, factory-patterned vesting architecture.

## Project Overview
This protocol was designed to automate complex tokenomics for multiple stakeholder groups (Team, Advisors, Rewards, etc.) while ensuring maximum security through contract isolation.

* **Network:** Ethereum Mainnet
* **Token Standard:** ERC-20 (OpenZeppelin 5.0)
* **Architecture:** Factory-Vesting Pattern
* **Development Stack:** Foundry, WSL2, Solidity 0.8.20

## Architecture & Security
Instead of a monolithic vesting contract, this project utilizes a **Factory-Vesting Pattern**:
1.  **OBXToken.sol**: The core contract that manages the 1B supply and automates the deployment of individual vesting instances during construction.
2.  **OBXVesting.sol**: A standalone, linear vesting contract with:
    * **SafeERC20**: To handle non-standard token transfers safely.
    * **ReentrancyGuard**: Protection against recursive call attacks.
    * **Cliff & Duration**: Fully customizable linear release schedules.

## Testing & Validation
The protocol is verified using the **Foundry** testing framework. To run the test suite:


# Install dependencies
forge install

# Run unit tests
forge test
Test Coverage Includes:
Total supply verification post-deployment.

Factory deployment validation for stakeholder instances.

State mutability and access control checks.

## License
This project is licensed under the MIT License.