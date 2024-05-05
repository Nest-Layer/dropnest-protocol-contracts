// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {DropnestVault} from "../src/DropnestVault.sol";

contract DeployDropnestVaultContract is Script {
    function run() public {
        address ownerAddress = msg.sender;
        address farmerAddress = msg.sender;
        string[] memory protocols = new string[](3);
        protocols[0] = "Blast";
        protocols[1] = "Bouncebit";
        protocols[2] = "Bsquared";

        address[] memory addresses = new address[](protocols.length);
        for (uint i = 0; i < protocols.length; ++i) {
            addresses[i] = farmerAddress;
        }

        deployContract(ownerAddress, protocols, addresses);
    }

    function deployContract(address owner, string[] memory protocols, address[] memory addresses) public returns (DropnestVault) {
        vm.startBroadcast(owner);
        DropnestVault dropnestContract = new DropnestVault(protocols, addresses);
        vm.stopBroadcast();
        return dropnestContract;
    }
}
