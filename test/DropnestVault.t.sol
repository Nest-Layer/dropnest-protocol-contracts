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
    string PROTOCOL_NAME3 = "PROTOCOL_NAME3";

    string NON_WHITELISTED_PROTOCOL = "NON_WHILTELISTED_PROTOCOL";

    uint256 STARTING_AMOUNT = 100 ether;

    uint256 internal constant BELOW_MINIMUM_DEPOSIT = 0.01 ether;
    uint256 internal constant MIN_PROTOCOL_DEPOSIT_AMOUNT = 0.1 ether;

    address public OWNER = makeAddr(("owner"));
    address public USER1 = makeAddr(("user1"));
    address public USER2 = makeAddr(("user2"));

    address public FARMER1 = makeAddr(("farmer1"));
    address public FARMER2 = makeAddr(("farmer2"));
    address public FARMER3 = makeAddr(("farmer3"));

    string [] public protocols = [PROTOCOL_NAME1, PROTOCOL_NAME2];
    address[] public farmers = [FARMER1, FARMER2];

    function setUp() public {
        deployer = new DeployDropnestVaultContract();

        vault = deployer.deployContract(OWNER, protocols, farmers);
    }

    modifier fundAddress(address fundAddress, uint256 amount) {
        vm.deal(fundAddress, amount);
        _;
    }

    function getProtocolId(string memory protocolName) private view returns (uint256) {
        string[] memory _protocols = vault.getProtocols();
        for (uint256 i = 0; i < _protocols.length; i++) {
            if (keccak256(abi.encodePacked(_protocols[i])) == keccak256(abi.encodePacked(protocolName))) {
                return i + 1;
            }
        }
        return 0;
    }

    function getProtocolIds() private view returns (uint256[] memory) {
        string[] memory _protocols = vault.getProtocols();
        uint256[] memory _protocolIds = new uint256[](_protocols.length);
        for (uint256 i = 0; i < _protocols.length; i++) {
            _protocolIds[i] = i + 1;
        }
        return _protocolIds;
    }

    function testInitialWhitelistIsSetCorrectly() public {
        string[] memory _protocols = vault.getProtocols();
        assertEq(_protocols.length, 2);
        assertEq(vault.whitelistAddresses(1), FARMER1);
        assertEq(vault.whitelistAddresses(2), FARMER2);
    }

    function testSetWhitelistUpdatesWhitelist() public {
        vm.prank(OWNER);
        vault.setWhitelist(PROTOCOL_NAME3, FARMER3);
        string[] memory _protocols = vault.getProtocols();
        assertEq(_protocols.length, 3);
        assertEq(vault.whitelistAddresses(3), FARMER3);
    }

    function testStakeTransfersFundsToFarmer(uint256 depositAmount) public fundAddress(USER1, STARTING_AMOUNT) {
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_AMOUNT);

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit Deposited(protocolId, USER1, FARMER1, depositAmount);
        vault.stake{value: depositAmount}(protocolId);
        assertEq(FARMER1.balance, depositAmount);
    }

    function testStakeFailsIfUserHasInsufficientBalance(uint256 exceedingBalanceAmount) public {
        exceedingBalanceAmount = bound(exceedingBalanceAmount, USER1.balance + 1 ether, UINT256_MAX);
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        vm.prank(USER1);
        vm.expectRevert();
        vault.stake{value: exceedingBalanceAmount}(protocolId);
    }

    function testFailStakeLessThanMinimum() public {
        vm.prank(USER1);
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        vault.stake{value: BELOW_MINIMUM_DEPOSIT}(protocolId);
        vm.expectRevert(abi.encodeWithSelector(DropnestVault_DepositLessThanMinimumAmount.selector));
    }

    function testStakeFailsWhenProtocolIsNotWhitelisted(uint256 depositAmount) public fundAddress(USER1, STARTING_AMOUNT) {
        uint256 protocolId = getProtocolId(NON_WHITELISTED_PROTOCOL);
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_AMOUNT);

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(DropnestVault_ProtocolIsNotWhitelisted.selector));
        vault.stake{value: depositAmount}(protocolId);

        assertEq(USER1.balance, STARTING_AMOUNT, 'Balance should not be affected!');
    }


    function testStakeFailsWhenContractIsPaused(uint256 depositAmount) public fundAddress(USER1, STARTING_AMOUNT) {
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_AMOUNT);
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);

        vm.prank(OWNER);
        vault.pause();
        assertTrue(vault.paused());

        vm.prank(USER1);
        vm.expectRevert();
        vault.stake{value: depositAmount}(protocolId);

        vm.prank(OWNER);
        vault.unpause();
        assertFalse(vault.paused());
    }

    function testSetWhitelistFailsWhenCallerIsNotOwner() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER1));
        vault.setWhitelist(NON_WHITELISTED_PROTOCOL, address(3));
    }


    function testStakeMultipleWithValidInputs(uint256 user1InitialAmount, uint256 depositAmount1, uint256 depositAmount2) public {
        depositAmount1 = bound(depositAmount1, MIN_PROTOCOL_DEPOSIT_AMOUNT, 1e30);
        depositAmount2 = bound(depositAmount2, MIN_PROTOCOL_DEPOSIT_AMOUNT, 1e30);
        user1InitialAmount = bound(user1InitialAmount, depositAmount1 + depositAmount2, UINT256_MAX);

        uint256[] memory amounts = new uint256[](2);
        uint256[] memory _protocolIds = getProtocolIds();
        amounts[0] = depositAmount1;
        amounts[1] = depositAmount2;
        vm.deal(USER1, user1InitialAmount);

        vm.startPrank(USER1);

        vault.stakeMultiple{value: depositAmount1 + depositAmount2}(_protocolIds, amounts);

        assertEq(address(vault).balance, 0, "Vault should not hold any ETH");
        assertEq(USER1.balance, user1InitialAmount - depositAmount1 - depositAmount2, "Incorrect balance for USER1");
        assertEq(farmers[0].balance, depositAmount1, "Incorrect balance for farmer1");
        assertEq(farmers[1].balance, depositAmount2, "Incorrect balance for farmer2");
    }

    function testStakeMultipleWithMismatchedArrays() public {
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = 1 ether;

        vm.deal(USER1, 10 ether);
        vm.startPrank(USER1);
        vm.expectRevert(DropnestVault_ArraysLengthMissmatch.selector);
        vault.stakeMultiple{value: 1 ether}(_protocolIds, amounts);
    }

    function testStakeMultipleWithExcessFunds() public {
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.deal(USER1, 10 ether);
        vm.startPrank(USER1);
        vm.expectRevert(DropnestVault_DepositDoesntMatchAmountProportion.selector);
        vault.stakeMultiple{value: 3 ether}(_protocolIds, amounts);
    }

    function testStakeMultipleWithInsufficientFunds(uint256 user1InitialAmount, uint256 depositAmount1, uint256 depositAmount2) public {
        depositAmount1 = bound(depositAmount1, MIN_PROTOCOL_DEPOSIT_AMOUNT, 1e30);
        depositAmount2 = bound(depositAmount2, MIN_PROTOCOL_DEPOSIT_AMOUNT, 1e30);

        uint256[] memory amounts = new uint256[](2);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = depositAmount1; // USER1 doesn't have this much ETH
        amounts[1] = depositAmount2;

        vm.startPrank(USER1);
        vm.expectRevert();
        vault.stakeMultiple{value: depositAmount1 + depositAmount2}(_protocolIds, amounts);
    }

    function testStakeMultipleWhenPaused() public {
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.deal(USER1, 10 ether);
        vm.prank(OWNER);
        vault.pause();

        vm.startPrank(USER1);
        vm.expectRevert(EnforcedPause.selector);
        vault.stakeMultiple{value: 2 ether}(_protocolIds, amounts);
    }

}
