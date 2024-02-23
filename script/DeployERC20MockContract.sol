// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DeployERC20MockContract is Script {
    function deployERC20Mock(address admin) public returns (ERC20Mock) {
        vm.startBroadcast(admin);
        ERC20Mock airdropTokenMock = new ERC20Mock();
        vm.stopBroadcast();
        return airdropTokenMock;
    }
}
