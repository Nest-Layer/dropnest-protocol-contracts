// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {DropVault} from "../src/DropVault.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DeployDropVaultContract is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ownerAddress = vm.addr(deployerPrivateKey);
        string memory protocolName = "MyProtocol";
        deployContract(protocolName, ownerAddress, ownerAddress);
    }

    function deployContract(string memory protocolName, address admin, address farmerAddress) public returns (DropVault) {
        vm.startBroadcast(admin);
        DropVault dropContract = new DropVault(protocolName, farmerAddress);
        vm.stopBroadcast();
        return dropContract;
    }
}
