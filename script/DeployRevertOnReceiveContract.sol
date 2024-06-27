// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {RevertOnReceive} from "../script/helpers/RevertOnReceive.sol";


contract DeployRevertOnReceiveContract is Script {

    RevertOnReceive public revertOnReceive;


    function deployContract(address deployerAddress) public returns (RevertOnReceive){
        vm.startBroadcast(deployerAddress);
        revertOnReceive = new RevertOnReceive();
        vm.stopBroadcast();
        return revertOnReceive;
    }

}
