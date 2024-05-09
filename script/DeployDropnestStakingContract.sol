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
        addresses[0] = 0x3B074a7c4DBE3C171758730eC53B26a42C0E0201;
        addresses[1] = 0xe1FcaAcA6f4F990AAab43BDEE31CAf233d41bb20;
        addresses[2] = 0xB31ebfEAe685bbE859B49DAA0AbB832150C6Af7D;

        deployContract(ownerAddress, protocols, addresses);
    }

    function deployContract(address owner, string[] memory protocols, address[] memory addresses) public returns (DropnestStaking) {
        vm.startBroadcast(owner);
        DropnestStaking dropnestContract = new DropnestStaking(protocols, addresses);
        vm.stopBroadcast();
        return dropnestContract;
    }
}
