// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {DropnestStaking} from "../src/DropnestStaking.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DeployDropnestStakingContract} from "../script/DeployDropnestStakingContract.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Events} from "./helpers/Events.sol";
import {Errors} from "./helpers/Errors.sol";

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DropnestStakingTest is StdCheats, Test, Events, Errors {
    DropnestStaking public stakingContract;
    DeployDropnestStakingContract public deployer;

    string PROTOCOL_NAME1 = "PROTOCOL_NAME1";
    string PROTOCOL_NAME2 = "PROTOCOL_NAME2";
    string PROTOCOL_NAME3 = "PROTOCOL_NAME3";

    string NOT_ADDED_PROTOCOL = "NON_WHILTELISTED_PROTOCOL";


    uint256 internal constant BELOW_MINIMUM_DEPOSIT = 0.01 ether;
    uint256 internal constant MIN_PROTOCOL_DEPOSIT_AMOUNT = 0.01 ether;
    uint256 internal constant MAX_NUMBER_OF_PROTOCOLS = 10;

    uint256 internal constant STARTING_AMOUNT = 100 ether;
    uint256 internal constant STARTING_ERC20_BALANCE = 100 ether;

    address public OWNER = makeAddr(("owner"));
    address public USER1 = makeAddr(("user1"));
    address public USER2 = makeAddr(("user2"));

    address public FARMER1 = makeAddr(("farmer1"));
    address public FARMER2 = makeAddr(("farmer2"));
    address public FARMER3 = makeAddr(("farmer3"));

    string [] public protocols = [PROTOCOL_NAME1, PROTOCOL_NAME2];
    address[] public farmers = [FARMER1, FARMER2];
    address[] public depositTokens;

    function setUp() public {
        deployer = new DeployDropnestStakingContract();
        depositTokens = deployer.deployERC20Mock(OWNER, 2);
        stakingContract = deployer.deployContract(OWNER, depositTokens, protocols, farmers);
    }

    modifier fundAddress(address _fundAddress, uint256 _amount) {
        vm.deal(_fundAddress, _amount);
        _;
    }

    function getProtocolId(string memory protocolName) private view returns (uint256) {
        string[] memory _protocols = stakingContract.getProtocols();
        for (uint256 i = 0; i < _protocols.length; i++) {
            if (keccak256(abi.encodePacked(_protocols[i])) == keccak256(abi.encodePacked(protocolName))) {
                return i + 1;
            }
        }
        return 0;
    }

    function deployERC20Mock(address owner, uint256 amount) public returns (address){
        vm.startBroadcast(owner);
        ERC20Mock token = new ERC20Mock();
        token.mint(owner, amount);
        vm.stopBroadcast();
        return address(token);
    }

    function getProtocolIds() private view returns (uint256[] memory) {
        string[] memory _protocols = stakingContract.getProtocols();
        uint256[] memory _protocolIds = new uint256[](_protocols.length);
        for (uint256 i = 0; i < _protocols.length; i++) {
            _protocolIds[i] = i + 1;
        }
        return _protocolIds;
    }

    function testInitialProtocolsIsSetCorrectly() public {
        string[] memory _protocols = stakingContract.getProtocols();
        assertEq(_protocols.length, 2);
        assertEq(stakingContract.getFarmAddress(1), FARMER1);
        assertEq(stakingContract.getFarmAddress(2), FARMER2);
    }

    function testAddProtocolOrUpdateAddsCorrectly() public {
        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true);
        emit ProtocolAdded(3, PROTOCOL_NAME3, FARMER3);
        stakingContract.addOrUpdateProtocol(PROTOCOL_NAME3, FARMER3);
        string[] memory _protocols = stakingContract.getProtocols();
        assertEq(_protocols.length, 3);
        assertEq(stakingContract.farmAddresses(3), FARMER3);
    }

    function testAddProtocolOrUpdateUpdatesCorrectly() public {
        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true);
        emit ProtocolUpdated(1, PROTOCOL_NAME1, FARMER3);
        stakingContract.addOrUpdateProtocol(PROTOCOL_NAME1, FARMER3);
        string[] memory _protocols = stakingContract.getProtocols();
        assertEq(_protocols.length, 2);
        assertEq(stakingContract.farmAddresses(1), FARMER3);
    }

    function testStakeTransfersFundsToFarmer(uint256 depositAmount) public fundAddress(USER1, STARTING_AMOUNT) {
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_AMOUNT);

        vm.prank(USER1);
        vm.expectEmit(true, true, true, true);
        emit Deposited(protocolId, USER1, FARMER1, depositAmount);
        stakingContract.stake{value: depositAmount}(protocolId);
        assertEq(FARMER1.balance, depositAmount);
    }

    function testStakeFailsIfUserHasInsufficientBalance(uint256 exceedingBalanceAmount) public {
        exceedingBalanceAmount = bound(exceedingBalanceAmount, USER1.balance + 1 ether, UINT256_MAX);
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        vm.prank(USER1);
        vm.expectRevert();
        stakingContract.stake{value: exceedingBalanceAmount}(protocolId);
    }

    function testFailStakeLessThanMinimum() public {
        vm.prank(USER1);
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        stakingContract.stake{value: BELOW_MINIMUM_DEPOSIT}(protocolId);
        vm.expectRevert(abi.encodeWithSelector(DropnestStaking_DepositLessThanMinimumAmount.selector, protocolId, BELOW_MINIMUM_DEPOSIT));
    }

    function testStakeFailsWhenProtocolIsNotAdded(uint256 depositAmount) public fundAddress(USER1, STARTING_AMOUNT) {
        uint256 protocolId = getProtocolId(NOT_ADDED_PROTOCOL);
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_AMOUNT);

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(DropnestStaking_ProtocolDoesNotExist.selector));
        stakingContract.stake{value: depositAmount}(protocolId);

        assertEq(USER1.balance, STARTING_AMOUNT, 'Balance should not be affected!');
    }


    function testStakeFailsWhenContractIsPaused(uint256 depositAmount) public fundAddress(USER1, STARTING_AMOUNT) {
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_AMOUNT);
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);

        vm.prank(OWNER);
        stakingContract.pause();
        assertTrue(stakingContract.paused());

        vm.prank(USER1);
        vm.expectRevert();
        stakingContract.stake{value: depositAmount}(protocolId);

        vm.prank(OWNER);
        stakingContract.unpause();
        assertFalse(stakingContract.paused());
    }

    function testAddProtocolOrUpdateFailsWhenCallerIsNotOwner() public {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER1));
        stakingContract.addOrUpdateProtocol(NOT_ADDED_PROTOCOL, address(3));
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

        stakingContract.stakeMultiple{value: depositAmount1 + depositAmount2}(_protocolIds, amounts);

        assertEq(address(stakingContract).balance, 0, "staking should not hold any ETH");
        assertEq(USER1.balance, user1InitialAmount - depositAmount1 - depositAmount2, "Incorrect balance for USER1");
        assertEq(farmers[0].balance, depositAmount1, "Incorrect balance for farmer1");
        assertEq(farmers[1].balance, depositAmount2, "Incorrect balance for farmer2");
    }

    function testStakeMultipleShouldFailIfMaxNumberOfProtocolsReached() public {
        uint256[] memory amounts = new uint256[](MAX_NUMBER_OF_PROTOCOLS + 1);
        uint256[] memory ids = new uint256[](MAX_NUMBER_OF_PROTOCOLS + 1);

        vm.deal(USER1, MAX_NUMBER_OF_PROTOCOLS * 1 ether);

        vm.startPrank(OWNER);
        for (uint256 i = 0; i < MAX_NUMBER_OF_PROTOCOLS + 1; i++) {
            stakingContract.addOrUpdateProtocol(string(abi.encodePacked("Protocol_", Strings.toString(i))), address(1));
        }
        for (uint256 i = 0; i < MAX_NUMBER_OF_PROTOCOLS + 1; i++) {
            amounts[i] = 1 ether;
        }

        vm.startPrank(USER1);
        vm.expectRevert(DropnestStaking_MaxProtocolsReached.selector);
        stakingContract.stakeMultiple{value: MAX_NUMBER_OF_PROTOCOLS * 1 ether}(ids, amounts);
    }


    function testStakeMultipleWithMismatchedArrays() public {
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = 1 ether;

        vm.deal(USER1, 10 ether);
        vm.startPrank(USER1);
        vm.expectRevert(DropnestStaking_ArraysLengthMismatch.selector);
        stakingContract.stakeMultiple{value: 1 ether}(_protocolIds, amounts);
    }

    function testStakeMultipleWithExcessFunds() public {
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.deal(USER1, 10 ether);
        vm.startPrank(USER1);
        vm.expectRevert(DropnestStaking_DepositMismatch.selector);
        stakingContract.stakeMultiple{value: 3 ether}(_protocolIds, amounts);
    }

    function testStakeMultipleWithInsufficientFunds(uint256 depositAmount1, uint256 depositAmount2) public {
        depositAmount1 = bound(depositAmount1, MIN_PROTOCOL_DEPOSIT_AMOUNT, 1e30);
        depositAmount2 = bound(depositAmount2, MIN_PROTOCOL_DEPOSIT_AMOUNT, 1e30);

        uint256[] memory amounts = new uint256[](2);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = depositAmount1; // USER1 doesn't have this much ETH
        amounts[1] = depositAmount2;

        vm.startPrank(USER1);
        vm.expectRevert();
        stakingContract.stakeMultiple{value: depositAmount1 + depositAmount2}(_protocolIds, amounts);
    }

    function testStakeMultipleWhenPaused(uint256 user1InitialAmount, uint256 depositAmount1, uint256 depositAmount2) public {
        depositAmount1 = bound(depositAmount1, MIN_PROTOCOL_DEPOSIT_AMOUNT, 1e30);
        depositAmount2 = bound(depositAmount2, MIN_PROTOCOL_DEPOSIT_AMOUNT, 1e30);
        user1InitialAmount = bound(user1InitialAmount, depositAmount1 + depositAmount2, UINT256_MAX);

        uint256[] memory amounts = new uint256[](2);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = depositAmount1;
        amounts[1] = depositAmount2;

        vm.deal(USER1, user1InitialAmount);
        vm.prank(OWNER);
        stakingContract.pause();

        vm.startPrank(USER1);
        vm.expectRevert(EnforcedPause.selector);
        stakingContract.stakeMultiple{value: depositAmount1 + depositAmount2}(_protocolIds, amounts);
    }

    function testStakeDoesntWorkWhenProtocolIsNotActive(uint256 depositAmount) public fundAddress(USER1, STARTING_AMOUNT) {
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_AMOUNT);

        vm.prank(OWNER);
        vm.expectEmit(true, true, true, true);
        emit ProtocolStatusUpdated(protocolId, false);
        stakingContract.setProtocolStatus(protocolId, false);

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(DropnestStaking_ProtocolInactive.selector, protocolId));
        stakingContract.stake{value: depositAmount}(protocolId);
    }

    function testStakeERC20TransfersFundsToFarmer(uint256 depositAmount) public {
        address token = depositTokens[0];
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_ERC20_BALANCE);

        deal(token, USER1, STARTING_ERC20_BALANCE);

        vm.startPrank(USER1);
        IERC20(token).approve(address(stakingContract), depositAmount);
        vm.expectEmit(true, true, true, true);
        emit ERC20Deposited(protocolId, token, USER1, FARMER1, depositAmount);
        stakingContract.stakeERC20(protocolId, token, depositAmount);

        assertEq(IERC20(token).balanceOf(FARMER1), depositAmount);
    }

    function testStakeERC20FailsIfUserHasInsufficientBalance(uint256 exceedingBalanceAmount) public {
        exceedingBalanceAmount = bound(exceedingBalanceAmount, STARTING_ERC20_BALANCE + 1 ether, UINT256_MAX);
        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        address token = depositTokens[0];

        deal(token, USER1, STARTING_ERC20_BALANCE);

        vm.startPrank(USER1);
        IERC20(token).approve(address(stakingContract), exceedingBalanceAmount);
        vm.expectRevert();
        stakingContract.stakeERC20(protocolId, token, exceedingBalanceAmount);
    }

    function testStakeMultipleERC20WithValidInputs(uint256 user1InitialAmount, uint256 depositAmount1, uint256 depositAmount2) public {
        address token = depositTokens[0];
        depositAmount1 = bound(depositAmount1, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_ERC20_BALANCE);
        depositAmount2 = bound(depositAmount2, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_ERC20_BALANCE);
        user1InitialAmount = bound(user1InitialAmount, depositAmount1 + depositAmount2, UINT256_MAX);

        uint256[] memory amounts = new uint256[](2);
        uint256[] memory _protocolIds = getProtocolIds();
        amounts[0] = depositAmount1;
        amounts[1] = depositAmount2;

        deal(token, USER1, user1InitialAmount);

        vm.startPrank(USER1);
        IERC20(token).approve(address(stakingContract), depositAmount1 + depositAmount2);
        stakingContract.stakeMultipleERC20(token, _protocolIds, amounts);

        assertEq(IERC20(token).balanceOf(FARMER1), depositAmount1);
        assertEq(IERC20(token).balanceOf(FARMER2), depositAmount2);
    }

    function testStakeMultipleERC20FailsWithMismatchedArrays() public {
        address token = depositTokens[0];
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = 1 ether;

        deal(token, USER1, 10 ether);
        vm.startPrank(USER1);
        IERC20(token).approve(address(stakingContract), 1 ether);
        vm.expectRevert(DropnestStaking_ArraysLengthMismatch.selector);
        stakingContract.stakeMultipleERC20(token, _protocolIds, amounts);
    }

    function testAddSupportedToken() public {
        address newToken = makeAddr("newToken");

        vm.prank(OWNER);
        stakingContract.addSupportedToken(newToken);

        address[] memory supportedTokens = stakingContract.getSupportedTokens();
        bool found = false;
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == newToken) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Token should be supported");
    }

    function testRemoveSupportedToken() public {
        address token = depositTokens[0];

        vm.prank(OWNER);
        stakingContract.removeSupportedToken(token);

        address[] memory supportedTokens = stakingContract.getSupportedTokens();
        bool found = false;
        for (uint256 i = 0; i < supportedTokens.length; i++) {
            if (supportedTokens[i] == token) {
                found = true;
                break;
            }
        }
        assertFalse(found, "Token should not be supported");
    }

    function testStakeERC20FailsWhenTokenIsNotSupported(uint256 depositAmount) public {
        address token = deployERC20Mock(USER1, 1 ether);

        uint256 protocolId = getProtocolId(PROTOCOL_NAME1);
        depositAmount = bound(depositAmount, MIN_PROTOCOL_DEPOSIT_AMOUNT, STARTING_ERC20_BALANCE);

        vm.startPrank(USER1);
        IERC20(token).approve(address(stakingContract), depositAmount);
        vm.expectRevert(abi.encodeWithSelector(DropnestStaking_TokenNotAllowed.selector, token));
        stakingContract.stakeERC20(protocolId, token, depositAmount);
    }

    function testStakeMultipleERC20FailsWhenTokenIsNotSupported() public {
        address token = deployERC20Mock(USER1, 2 ether);

        uint256[] memory amounts = new uint256[](2);
        uint256[] memory _protocolIds = getProtocolIds();

        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.startPrank(USER1);
        IERC20(token).approve(address(stakingContract), 2 ether);
        vm.expectRevert(abi.encodeWithSelector(DropnestStaking_TokenNotAllowed.selector, token));
        stakingContract.stakeMultipleERC20(token, _protocolIds, amounts);
    }

}
