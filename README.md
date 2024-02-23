# Drop protocol


## Description


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

