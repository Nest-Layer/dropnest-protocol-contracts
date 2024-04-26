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

    uint256 internal constant BELOW_MINIMUM_DEPOSIT = 0.01 ether;
    uint256 internal constant MIN_PROTOCOL_DEPOSIT_AMOUNT = 0.1 ether;

    address public OWNER = makeAddr(("owner"));
    address public USER1 = makeAddr(("user1"));
    address public USER2 = makeAddr(("user2"));

    address public FARMER1 = makeAddr(("farmer1"));
    address public FARMER2 = makeAddr(("farmer2"));

    string [] public protocols = [PROTOCOL_NAME1, PROTOCOL_NAME2];
    address[] public farmers = [FARMER1, FARMER2];


    function setUp() public {
        vm.deal(OWNER, STARTING_AMOUNT);
        vm.deal(USER1, STARTING_AMOUNT);
        vm.deal(USER2, STARTING_AMOUNT);

        deployer = new DeployDropnestVaultContract();

        vault = deployer.deployContract(OWNER, protocols, farmers);
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
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_AMOUNT);
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
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_AMOUNT);
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


    function testStakeMultipleWithValidInputs() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;
        vm.deal(USER1, 10 ether);

        vm.startPrank(USER1);
        vault.stakeMultiple{value: 2 ether}(protocols, amounts);

        assertEq(address(vault).balance, 0, "Vault should not hold any ETH");
        assertEq(USER1.balance, 8 ether, "Incorrect balance for USER1");
        assertEq(farmers[0].balance, 1 ether, "Incorrect balance for farmer1");
        assertEq(farmers[1].balance, 1 ether, "Incorrect balance for farmer2");
    }

    function testStakeMultipleWithMismatchedArrays() public {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1 ether;

        vm.deal(USER1, 10 ether);
        vm.startPrank(USER1);
        vm.expectRevert(DropnestVault_ArraysLengthMissmatch.selector);
        vault.stakeMultiple{value: 1 ether}(protocols, amounts);
    }

    function testStakeMultipleWithExcessFunds() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.deal(USER1, 10 ether);
        vm.startPrank(USER1);
        vm.expectRevert(DropnestVault_DepositDoesntMatchAmountProportion.selector);
        vault.stakeMultiple{value: 3 ether}(protocols, amounts);
    }

    function testStakeMultipleWithInsufficientFunds() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 50 ether; // USER1 doesn't have this much ETH
        amounts[1] = 50 ether;

        vm.startPrank(USER1);
        vm.expectRevert(DropnestVault_NotEnoughBalance.selector);
        vault.stakeMultiple{value: 100 ether}(protocols, amounts);
    }

    function testStakeMultipleWhenPaused() public {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.deal(USER1, 10 ether);
        vm.prank(OWNER);
        vault.pause();

        vm.startPrank(USER1);
        vm.expectRevert(EnforcedPause.selector);
        vault.stakeMultiple{value: 2 ether}(protocols, amounts);
    }

}
