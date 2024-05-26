// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {DropnestStaking} from "../src/DropnestStaking.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {console} from "forge-std/Test.sol";

contract DeployDropnestStakingContract is Script {

    uint256 public deployerKey;
    string[] public protocols;
    address[] public farmerAddresses;
    address[] public supportedTokens;
    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function run() public returns (DropnestStaking, address[] memory, string[] memory, address[] memory){
        if (block.chainid == 11155111) {
            deployerKey = vm.envUint("PRIVATE_KEY");
            protocols = vm.envString("SUPPORTED_PROTOCOLS", ", ");
            farmerAddresses = vm.envAddress("FARMER_ADDRESSES", ", ");
            supportedTokens = vm.envAddress("SUPPORTED_TOKENS", ", ");
        } else {
            console.log("Using Anvil Config");

            supportedTokens = deployERC20Mock(vm.addr(DEFAULT_ANVIL_PRIVATE_KEY), 2);

            deployerKey = DEFAULT_ANVIL_PRIVATE_KEY;
            protocols = vm.envString("SUPPORTED_PROTOCOLS", ", ");
            farmerAddresses = vm.envAddress("FARMER_ADDRESSES", ", ");
        }

        address ownerAddress = vm.addr(deployerKey);

        vm.startBroadcast(ownerAddress);
        DropnestStaking dropnestContract = new DropnestStaking(supportedTokens, protocols, farmerAddresses);
        vm.stopBroadcast();
        return (dropnestContract, supportedTokens, protocols, farmerAddresses);

    }

    function deployContract(address owner, address[] memory _supportedTokens, string[] memory _protocols, address[] memory _addresses) public returns (DropnestStaking) {
        vm.startBroadcast(owner);
        DropnestStaking dropnestContract = new DropnestStaking(_supportedTokens, _protocols, _addresses);
        vm.stopBroadcast();
        return dropnestContract;
    }


    function deployERC20Mock(address owner, uint256 number) public returns (address[] memory){
        address[] memory tokens = new address[](number);
        for (uint256 i = 0; i < number; i++) {
            vm.startBroadcast(owner);
            ERC20Mock token = new ERC20Mock();
            vm.stopBroadcast();
            tokens[i] = address(token);
        }
        return tokens;
    }
}


