// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {DropVault} from "../src/DropVault.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployDropVaultContract} from "../script/DeployDropVaultContract.sol";
import {DeployERC20MockContract} from "../script/DeployERC20MockContract.sol";

import {Events} from "./helpers/Events.sol";
import {Errors} from "./helpers/Errors.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DropVaultTest is StdCheats, Test, Events, Errors {
    DropVault public dropVault;
    DeployDropVaultContract public deployer;
    DeployERC20MockContract public ERC20Deployer;

    ERC20Mock public airdropTokenMock;

    string PROTOCOL_NAME = "BLAST";

    uint256 STARTING_AMOUNT = 100 ether;

    uint256 internal constant INITIAL_DEPOSIT_AMOUNT = 1000;
    uint256 internal constant MIN_DEPOSIT_AMOUNT = 0.01 ether;

    address public OWNER = makeAddr(("owner"));
    address public USER1 = makeAddr(("user1"));
    address public USER2 = makeAddr(("user2"));

    address public FARMER = makeAddr(("farmer"));

    function setUp() public {
        vm.deal(OWNER, STARTING_AMOUNT);
        vm.deal(USER1, STARTING_AMOUNT);
        vm.deal(USER2, STARTING_AMOUNT);

        deployer = new DeployDropVaultContract();
        ERC20Deployer = new DeployERC20MockContract();
        dropVault = deployer.deployContract(PROTOCOL_NAME, OWNER, FARMER);
        airdropTokenMock = ERC20Deployer.deployERC20Mock(OWNER);
    }

    modifier openVault() {
        vm.startPrank(OWNER);
        dropVault.openVault{value: INITIAL_DEPOSIT_AMOUNT}();
        vm.stopPrank();
        _;
    }


    modifier openClaim() {
        _openClaim();
        _;
    }

    //////////////////////////////////////////
    //            Test Cases                //
    //////////////////////////////////////////

    //////////////////////////////////////////
    //            openVault                 //
    //////////////////////////////////////////

    function testOpenVault(uint256 depositAmount) public {
        vm.assume(depositAmount >= INITIAL_DEPOSIT_AMOUNT && depositAmount <= OWNER.balance);
        vm.startPrank(OWNER);
        dropVault.openVault{value: depositAmount}();
        vm.stopPrank();
        assert(dropVault.paused() == false);
    }

    function testOpenVaultTwiceShouldFail() public {
        vm.startPrank(OWNER);
        dropVault.openVault{value: INITIAL_DEPOSIT_AMOUNT}();
        vm.expectRevert(abi.encodeWithSelector(DropVault_VaultAlreadyOpened.selector));
        dropVault.openVault{value: INITIAL_DEPOSIT_AMOUNT}();
        vm.stopPrank();
    }

    function testOpenVaultShouldFailIfLessThanInitialDepositAmount(uint256 depositAmount) public {
        vm.assume(depositAmount < INITIAL_DEPOSIT_AMOUNT);
        vm.startPrank(OWNER);
        vm.expectRevert(abi.encodeWithSelector(DropVault_LessThanInitialDepositAmount.selector));
        dropVault.openVault{value: depositAmount}();
        vm.stopPrank();
    }

    //////////////////////////////////////////
    //            depositETH                //
    //////////////////////////////////////////

    function testUnableToDepositBeforeOpeningVault(uint256 depositAmount) public {
        vm.assume(depositAmount > MIN_DEPOSIT_AMOUNT && depositAmount < USER1.balance);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(EnforcedPause.selector));
        dropVault.depositETH{value: depositAmount}(USER1);
        vm.stopPrank();
    }

    function testShouldFailOnDepositLessThanMinimum(uint256 depositAmount) public openVault {
        vm.assume(depositAmount < MIN_DEPOSIT_AMOUNT);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(DropVault_DepositLessThanMinimumAmount.selector));
        dropVault.depositETH{value: depositAmount}(USER1);
        vm.stopPrank();
    }

    function testDepositETH(uint256 depositAmount) public openVault {
        depositAmount = bound(depositAmount, MIN_DEPOSIT_AMOUNT, USER1.balance);
        vm.startPrank(USER1);
        vm.expectEmit(true, true, true, true);
        emit ETHDeposited(USER1, USER1, depositAmount);
        dropVault.depositETH{value: depositAmount}(USER1);
        vm.stopPrank();
        assertEq(dropVault.balanceOf(USER1), depositAmount);
        assertEq(FARMER.balance, depositAmount);
    }

    ///////////////////////////////////////////////////////
    //          setAirdropTokenAddressAndOpenClaim       //
    ///////////////////////////////////////////////////////
    function testSetAirdropTokenAddressAndOpenClaim() public openVault {
        vm.startPrank(OWNER);
        emit AirdropTokenSet(address(airdropTokenMock));
        dropVault.setAirdropTokenAddressAndOpenClaim(address(airdropTokenMock));
        vm.stopPrank();
        assertEq(dropVault.airdropTokenAddress(), address(airdropTokenMock));
        assertEq(dropVault.airdropClaimStatus(), true);
    }

    function testSetAirdropTokenAddressAndOpenClaimShouldFailIfNotOwner() public openVault {
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER1));
        dropVault.setAirdropTokenAddressAndOpenClaim(address(airdropTokenMock));
        vm.stopPrank();
    }

    function testSetAirdropTokenAddressAndOpenClaimShouldFailIfAirdropTokenAddressIsZero() public openVault {
        vm.startPrank(OWNER);
        vm.expectRevert(abi.encodeWithSelector(DropVault_ZeroAddressProvided.selector));
        dropVault.setAirdropTokenAddressAndOpenClaim(address(0));
        vm.stopPrank();
    }

    function testSetAirdropTokenAddressAndOpenClaimShouldFailIfAirdropClaimStatusIsTrue() public openVault openClaim {
        vm.startPrank(OWNER);
        vm.expectRevert(abi.encodeWithSelector(DropVault_StatusAlreadySet.selector, true));
        dropVault.setAirdropTokenAddressAndOpenClaim(address(airdropTokenMock));
        vm.stopPrank();
    }

    ///////////////////////////////////////////////////////
    //          claimAirdrop                             //
    ///////////////////////////////////////////////////////
    function testClaimAirdropShouldSucceed(uint256 airdropAmount, uint256 userAmount) public openVault {
        userAmount = bound(userAmount, MIN_DEPOSIT_AMOUNT, USER1.balance);
        airdropAmount = bound(airdropAmount, userAmount, userAmount * userAmount);

        vm.prank(USER1);
        dropVault.depositETH{value: userAmount}(USER1);

        _fundWithAirdrop(airdropAmount);
        _openClaim();

        (uint256 claimableEthAmount, uint256 claimableTokenAmount) = dropVault.getClaimableAmount(USER1);

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit AirdropClaimed(USER1, claimableEthAmount, claimableTokenAmount);
        dropVault.claimAirdropAndWithdrawETH();

        assertEq(airdropTokenMock.balanceOf(USER1), claimableTokenAmount);
    }

    function testClaimWithMultipleUsersAirdrop(uint256 user1Amount, uint256 user2Amount, uint256 fundAirdrop) public openVault openClaim {
        user1Amount = bound(user1Amount, MIN_DEPOSIT_AMOUNT, USER1.balance);
        user2Amount = bound(user2Amount, MIN_DEPOSIT_AMOUNT, USER2.balance);
        fundAirdrop = bound(fundAirdrop, 0, user1Amount * user2Amount);

        vm.prank(USER1);
        dropVault.depositETH{value: user1Amount}(USER1);

        vm.prank(USER2);
        dropVault.depositETH{value: user2Amount}(USER2);

        _fundWithAirdrop(fundAirdrop);

        (uint256 claimableEthAmount, uint256 claimableTokenAmount) = dropVault.getClaimableAmount(USER1);

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit AirdropClaimed(USER1, claimableEthAmount, claimableTokenAmount);
        dropVault.claimAirdropAndWithdrawETH();

        assertEq(airdropTokenMock.balanceOf(USER1), claimableTokenAmount);

        vm.prank(USER2);
        dropVault.claimAirdropAndWithdrawETH();

        vm.prank(OWNER);
        dropVault.claimAirdropAndWithdrawETH();

        assertEq(fundAirdrop, airdropTokenMock.balanceOf(USER1) + airdropTokenMock.balanceOf(USER2) + airdropTokenMock.balanceOf(OWNER));


    }

    function testClaimAirdropShouldFailIfNoSharesToClaim(uint256 fundAirdrop) public openVault openClaim {
        _fundWithAirdrop(fundAirdrop);
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(DropVault_NoSharesToClaim.selector));
        dropVault.claimAirdropAndWithdrawETH();
        vm.stopPrank();
    }

    ///////////////////////////////////////////////////////
    //          airdropTotalBalance                      //
    ///////////////////////////////////////////////////////
    function testAirdropTotalBalance(uint256 fundAirdrop) public openVault openClaim {
        _fundWithAirdrop(fundAirdrop);
        uint256 totalBalance = dropVault.airdropTotalBalance();
        assertEq(totalBalance, fundAirdrop);
    }

    function testAirdropTotalBalanceShouldFailIfNoAirdropTokenAddress() public openVault {
        assertEq(dropVault.airdropTotalBalance(), 0);
    }

    ///////////////////////////////////////////////////////
    //          updateFarmerAddress                      //
    ///////////////////////////////////////////////////////
    function testUpdateFarmerAddress(address newFarmerAddress) public openVault {
        vm.assume(newFarmerAddress != address(0) && newFarmerAddress != FARMER);
        vm.prank(OWNER);
        dropVault.updateFarmerAddress(newFarmerAddress);
        assertEq(dropVault.farmerAddress(), newFarmerAddress);
    }

    function testUpdateFarmerAddressShouldFailIfNotOwner(address newFarmerAddress) public openVault {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER1));
        dropVault.updateFarmerAddress(newFarmerAddress);
    }

    function testUpdateFarmerAddressShouldFailIfNewFarmerAddressIsZero() public openVault {
        address newFarmerAddress = address(0);
        vm.prank(OWNER);
        vm.expectRevert(abi.encodeWithSelector(DropVault_ZeroAddressProvided.selector));
        dropVault.updateFarmerAddress(newFarmerAddress);
    }


    function _fundWithAirdrop(uint256 airdropAmount) internal {
        vm.startPrank(OWNER);
        airdropTokenMock.mint(address(dropVault), airdropAmount);
        vm.stopPrank();
    }

    function _openClaim() internal {
        vm.startPrank(OWNER);
        dropVault.setAirdropTokenAddressAndOpenClaim(address(airdropTokenMock));
        vm.stopPrank();
    }

}
