# Dropnest protocol

## Description

The `DropnestStaking` protocol is a smart contract system for EVM chains. It is designed to manage deposits for the Dropnest protocol and record the deposits via emitting events into the blockchain.

## How it Works

1. **Adding Protocols**: The owner of the contract can add new protocols or update the farmer address for existing ones. Each protocol is identified by a unique protocol ID and has a corresponding farmer address where the staked funds are transferred.

2. **Staking**: Users can stake their ETH or predetermined ERC20 tokens on a specific protocol. The staked tokens are transferred to the farmer address of the protocol.

3. **Multiple Staking**: Users can also stake their ETH or ERC20 tokens on multiple protocols at once. The total amount of tokens staked should be equal to the sum of the individual amounts staked on each protocol.

4. **Protocol Status**: The owner can set the status of a protocol (active or inactive). Users can only stake their ETH or ERC20 on active protocols.

5. **Pausing**: The owner can pause or unpause the contract. When the contract is paused, users cannot stake their ETH or ERC 20 tokens.

## Supported Tokens

The `DropnestStaking` contract will supports the following ERC20 tokens from the bootstrap:

- **USDT (Tether USD)**
- **USDC (USD Coin)**

These tokens are approved for staking, ensuring compatibility and secure transactions within the protocol.

## Risk Mitigation Strategies

1. **Centralization Risks**: We acknowledge the potential risks associated with centralization and have implemented multi-signature wallets for key administrative functions to distribute control and reduce single points of failure. Regular audits and monitoring are in place to ensure secure and responsible use of administrative keys.

2. **Reliance on External Contracts**: The `farmAddresses` and `supportedTokens` mappings rely on external contracts. We carefully select and use the contracts that only were audited by top security firms to ensure their security and reliability. We also have a contingency plan to replace or modify these contracts if vulnerabilities are discovered.

3. **Transparency in Fund Transfers**: All funds transferred to `farmAddresses` are tracked transparently through on-chain events. We are committed to providing detailed documentation about the usage of staked funds and ensuring that users have access to comprehensive reports on fund allocation and outcomes.

4. **On-Chain Information and User Returns**: Although the staking protocol involves off-chain calculations for rewards and balances, we are working on implementing the mechanism to provide users with real-time information about their staking outcomes. This includes potential returns and other relevant metrics to enhance transparency.

5. **Handling Fee-on-Transfer Tokens**: We currently do not support fee-on-transfer tokens. However, we are designing our off-chain components to handle discrepancies between sent and received amounts, ensuring accurate tracking and calculations. If support for such tokens is introduced, our system will be adapted to prevent mismatches and maintain integrity.

We are committed to continuous improvement and regular audits to uphold these standards.

## Tests

1. Make sure Foundry is installed
<details>
  <summary> Install foundry (click to expand)</summary>

    curl -L https://foundry.paradigm.xyz | bash


This will install Foundryup, then simply follow the instructions on-screen, which will make the foundryup command
available in your CLI. You can then use 'foundryup' to install the rest of the Foundry tools.
</details>

2. Install submodules and dependencies
```bash
make
```

3. Run forge test to run tests against the contracts
```bash
make test
```
4. Static analysis:
```bash
make slither

```

## Deploy on testnet

1. Start anvil 
```bash
anvil
```

2. Deploy contract
```bash
make deploy
```

## Deploy on network

1. Import private key
```bash
cast wallet import key --interactive
```

2. Rename `.env.example` to `.env` and fill necessary variables:
```bash
ETHERSCAN_API_KEY=

# Network rpcs
SEPOLIA_RPC_URL=
ARBITRUM_RPC_URL=
OPTIMISM_RPC_URL=

# Deployer keys
DEPLOYER_PUBLIC_KEY=

```

3. Deploy contract
```bash
make deploy ARGS="--network {NETWORK_NAME}"

