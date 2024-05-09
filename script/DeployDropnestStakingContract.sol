// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {DropnestStaking} from "../src/DropnestStaking.sol";

contract DeployDropnestStakingContract is Script {
    function run() public {
        address ownerAddress = msg.sender;
        address farmerAddress = msg.sender;

        string[] memory protocols = new string[](3);
        protocols[0] = 'Karak Network';
        protocols[1] = 'Linea';
        protocols[2] = 'Monad';

        address[] memory addresses = new address[](protocols.length);
        for (uint i = 0; i < protocols.length; ++i) {
            addresses[i] = farmerAddress;
        }

        deployContract(ownerAddress, protocols, addresses);
    }

    function deployContract(address owner, string[] memory protocols, address[] memory addresses) public returns (DropnestStaking) {
        vm.startBroadcast(owner);
        DropnestStaking dropnestContract = new DropnestStaking(protocols, addresses);
        vm.stopBroadcast();
        return dropnestContract;
    }
}
