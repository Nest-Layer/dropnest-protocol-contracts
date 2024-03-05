// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {DropnestVault} from "../src/DropnestVault.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployDropnestVaultContract} from "../script/DeployDropnestVaultContract.sol";

import {Events} from "./helpers/Events.sol";
import {Errors} from "./helpers/Errors.sol";


contract DropnestVaultTest is StdCheats, Test, Events, Errors {
    DropnestVault public vault;
    DeployDropnestVaultContract public deployer;


    string PROTOCOL_NAME = "BLAST";

    uint256 STARTING_AMOUNT = 100 ether;

    uint256 internal constant INITIAL_DEPOSIT_AMOUNT = 1000;
    uint256 internal constant MIN_DEPOSIT_AMOUNT = 0.01 ether;

    address public OWNER = makeAddr(("owner"));
    address public USER1 = makeAddr(("user1"));
    address public USER2 = makeAddr(("user2"));

    address public FARMER1 = makeAddr(("farmer1"));
    address public FARMER2 = makeAddr(("farmer1"));

    function setUp() public {
        vm.deal(OWNER, STARTING_AMOUNT);
        vm.deal(USER1, STARTING_AMOUNT);
        vm.deal(USER2, STARTING_AMOUNT);

        deployer = new DeployDropnestVaultContract();

        address[] memory addresses = new address[](1);
        addresses[0] = FARMER1;
        string [] memory protocols = new string[](1);
        protocols[0] = PROTOCOL_NAME;
        vault = deployer.deployContract(OWNER, protocols, addresses);
    }


    function testInitialWhitelist() public {
        assertEq(vault.whitelist(PROTOCOL_NAME), FARMER1);
    }

    function testSetWhitelist() public {
        vm.prank(OWNER);
        vault.setWhitelist("NewProtocol", FARMER2);
        assertEq(vault.whitelist("NewProtocol"), FARMER2);
    }

    function testStake() public {
        vault.stake{value: 1 ether}(PROTOCOL_NAME);
        assertEq(FARMER1.balance, 1 ether);
    }

    function testFailStakeLessThanMinimum() public {
        vault.stake{value: 0.001 ether}("TestProtocol");
    }

    function testFailStakeToNonWhitelistedProtocol() public {
        vault.stake{value: 1 ether}("NonWhitelistedProtocol");
    }

    function testPauseAndUnpause() public {
        vm.startPrank(OWNER);
        vault.pause();
        assertTrue(vault.paused());
        vault.unpause();
        assertFalse(vault.paused());
        vm.stopPrank();
    }

    function testFailSetWhitelistNotOwner() public {
        vm.prank(address(0)); // Simulate a call from a non-owner
        vault.setWhitelist("AnotherProtocol", address(3));
        vm.expectRevert();
    }


}
