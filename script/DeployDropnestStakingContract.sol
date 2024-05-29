// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {DropnestStaking} from "../src/DropnestStaking.sol";
import {ERC20Test} from "./helpers/ERC20Test.sol";
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


            address[] memory _supportedTokens = new address[](3);
            _supportedTokens[0] = deployERC20Mock(vm.addr(DEFAULT_ANVIL_PRIVATE_KEY), "USDT", "USDT", 6);
            _supportedTokens[1] = deployERC20Mock(vm.addr(DEFAULT_ANVIL_PRIVATE_KEY), "USDC", "USDC", 6);
            _supportedTokens[2] = deployERC20Mock(vm.addr(DEFAULT_ANVIL_PRIVATE_KEY), "WBTC", "WBTC", 8);
            supportedTokens = _supportedTokens;

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


    function deployERC20Mock(address deployer, string memory name_, string memory symbol_, uint8 decimals_) public returns (address){
        vm.startBroadcast(deployer);
        ERC20Test token = new ERC20Test(name_, symbol_, decimals_);
        vm.stopBroadcast();
        console.log("Deployed ERC20 token at address: %s, name: %s", address(token), name_);
        return address(token);

    }
}


