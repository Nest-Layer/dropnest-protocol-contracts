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

    string PROTOCOL_NAME1 = "PROTOCOL_NAME1";
    string PROTOCOL_NAME2 = "PROTOCOL_NAME2";

    string NON_WHITELISTED_PROTOCOL = "NON_WHILTELISTED_PROTOCOL";

    uint256 STARTING_AMOUNT = 100 ether;

    uint256 internal constant BELOW_MINIMUM_DEPOSIT = 0.001 ether;
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
        protocols[0] = PROTOCOL_NAME1;
        vault = deployer.deployContract(OWNER, protocols, addresses);
    }

    function testInitialWhitelistIsSetCorrectly() public {
        assertEq(vault.whitelist(PROTOCOL_NAME1), FARMER1);
    }

    function testSetWhitelistUpdatesWhitelist() public {
        vm.prank(OWNER);
        vault.setWhitelist(PROTOCOL_NAME2, FARMER2);
        assertEq(vault.whitelist(PROTOCOL_NAME2), FARMER2);
    }

    function testStakeTransfersFundsToFarmer(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, MIN_DEPOSIT_AMOUNT, STARTING_AMOUNT);
        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit Deposited(PROTOCOL_NAME1, USER1, FARMER1, depositAmount);
        vault.stake{value: depositAmount}(PROTOCOL_NAME1);
        assertEq(FARMER1.balance, depositAmount);
    }

    function testStakeFailsIfUserHasInsufficientBalance() public {
        uint256 depositAmount = USER1.balance + 1 ether;

        vm.prank(USER1);
        vm.expectRevert();
        vault.stake{value: depositAmount}(PROTOCOL_NAME1);
    }

    function testFailStakeLessThanMinimum() public {
        vm.prank(USER1);
        vault.stake{value: BELOW_MINIMUM_DEPOSIT}(PROTOCOL_NAME1);
        vm.expectRevert(abi.encodeWithSelector(DropnestVault_DepositLessThanMinimumAmount.selector));
    }

    function testStakeFailsWhenProtocolIsNotWhitelisted(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, MIN_DEPOSIT_AMOUNT, STARTING_AMOUNT);
        uint256 initialUserBalance = USER1.balance;

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(DropnestVault_ProtocolIsNotWhitelisted.selector));
        vault.stake{value: depositAmount}(NON_WHITELISTED_PROTOCOL);

        assertEq(USER1.balance, initialUserBalance);
    }


    function testStakeFailsWhenContractIsPaused(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, BELOW_MINIMUM_DEPOSIT, STARTING_AMOUNT);

        vm.prank(OWNER);
        vault.pause();
        assertTrue(vault.paused());

        vm.prank(USER1);
        vm.expectRevert();
        vault.stake{value: depositAmount}(PROTOCOL_NAME1);

        vm.prank(OWNER);
        vault.unpause();
        assertFalse(vault.paused());
    }

    function testSetWhitelistFailsWhenCallerIsNotOwner() public {
        address initialWhitelistedProtocol = vault.whitelist(NON_WHITELISTED_PROTOCOL);

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER1));
        vault.setWhitelist(NON_WHITELISTED_PROTOCOL, address(3));

        assertEq(vault.whitelist(NON_WHITELISTED_PROTOCOL), initialWhitelistedProtocol);
    }


}
