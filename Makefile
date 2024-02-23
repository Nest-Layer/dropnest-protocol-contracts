-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean install update build

# Clean the repo
clean  :; forge clean

install :; forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit && forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test -vvv

snapshot :; forge snapshot

slither :; slither .

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

COMMON_NETWORK_ARGS := --account lyvelyKey --sender ${DEPLOYER_PUBLIC_KEY} --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) $(COMMON_NETWORK_ARGS)
endif

ifeq ($(findstring --network arbitrum,$(ARGS)),--network arbitrum)
	NETWORK_ARGS := --rpc-url $(ARBITRUM_RPC_URL) $(COMMON_NETWORK_ARGS)
endif

ifeq ($(findstring --network optimism,$(ARGS)),--network optimism)
	NETWORK_ARGS := --rpc-url $(OPTIMISM_RPC_URL) $(COMMON_NETWORK_ARGS)
endif


deploy:
	@forge script script/DeployLyvelyToken.s.sol:DeployLyvelyToken $(NETWORK_ARGS)
