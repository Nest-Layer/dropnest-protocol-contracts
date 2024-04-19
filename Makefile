-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean install update build

# Clean the repo
clean  :; forge clean

install :; forge install foundry-rs/forge-std@v1.5.3 --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test -vvv

snapshot :; forge snapshot

slither :; slither .

format :; forge fmt

coverage :; forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1
