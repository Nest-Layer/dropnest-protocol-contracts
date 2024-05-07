// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {DropnestStaking} from "../src/DropnestStaking.sol";

contract DeployDropnestStakingContract is Script {
    function run() public {
        address ownerAddress = msg.sender;
        address farmerAddress = msg.sender;

        string[] memory protocols = new string[](10);
        protocols[0] = 'Mode';
        protocols[1] = 'Blast';
        protocols[2] = 'Taiko';
        protocols[3] = 'Bouncebit';
        protocols[4] = 'Dropnest';
        protocols[5] = 'Azuro';
        protocols[6] = 'Mantle';
        protocols[7] = 'Bsquared';
        protocols[8] = 'Ambient';
        protocols[9] = 'Karak';

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
