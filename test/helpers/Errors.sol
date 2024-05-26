// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

contract Errors {
    error DropnestStaking_DepositLessThanMinimumAmount(uint256 protocolId, uint256 amount);
    error DropnestStaking_ZeroAddressProvided();
    error DropnestStaking_ProtocolDoesNotExist();
    error DropnestStaking_DepositMismatch();
    error DropnestStaking_ArraysLengthMismatch();
    error DropnestStaking_MaxProtocolsReached();
    error DropnestStaking_InsufficientBalance();
    error DropnestStaking_ProtocolInactive(uint256 protocolId);
    error DropnestStaking_CannotChangeProtocolStatus(uint256 protocolId, bool status);
    error DropnestStaking_TokenNotAllowed(address token);
    error DropnestStaking_AmountMustBeGreaterThanZero();

    error EnforcedPause();
    error OwnableUnauthorizedAccount(address account);
}
