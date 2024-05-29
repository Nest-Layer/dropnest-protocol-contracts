# Dropnest protocol


## Description

The `DropnestStaking` protocol is a smart contract system for EVM chains. It is designed to manage deposits for the Dropnest protocol and record the deposits via emitting events into the blockchain.

## How it Works

1. **Adding Protocols**: The owner of the contract can add new protocols or update the farmer address for existing ones. Each protocol is identified by a unique protocol ID and has a corresponding farmer address where the staked funds are transferred.

2. **Staking**: Users can stake their ETH or predetermined ERC20 tokens on a specific protocol. The staked tokens are transferred to the farmer address of the protocol. The amount of tokens to be staked should be equal to or more than the minimum deposit amount.

3. **Multiple Staking**: Users can also stake their ETH or ERC20 tokens on multiple protocols at once. The total amount of tokens staked should be equal to the sum of the individual amounts staked on each protocol.

4. **Protocol Status**: The owner can set the status of a protocol (active or inactive). Users can only stake their ETH on active protocols.

5. **Pausing**: The owner can pause or unpause the contract. When the contract is paused, users cannot stake their ETH.

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

