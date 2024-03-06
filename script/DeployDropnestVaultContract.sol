// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {DropnestVault} from "../src/DropnestVault.sol";

contract DeployDropnestVaultContract is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address ownerAddress = vm.addr(deployerPrivateKey);
        string memory protocolName = "MyProtocol";

        address[] memory addresses = new address[](1);
        addresses[0] = ownerAddress;
        string [] memory protocols = new string[](1);
        protocols[0] = protocolName;

        deployContract(ownerAddress, protocols, addresses);
    }

    function deployContract(address owner, string[] memory protocols, address[] memory addresses) public returns (DropnestVault) {
        vm.startBroadcast(owner);
        DropnestVault dropContract = new DropnestVault(protocols, addresses);
        vm.stopBroadcast();
        return dropContract;
    }
}
