// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

contract Errors {
    error DropnestStaking_ZeroAddressProvided();
    error DropnestStaking_ProtocolDoesNotExist();
    error DropnestStaking_DepositMismatch();
    error DropnestStaking_ArraysLengthMismatch();
    error DropnestStaking_MaxProtocolsReached();
    error DropnestStaking_ProtocolInactive(uint256 protocolId);
    error DropnestStaking_CannotChangeProtocolStatus(uint256 protocolId, bool status);
    error DropnestStaking_TokenNotAllowed(address token);
    error DropnestStaking_AmountMustBeGreaterThanZero();
    error DropnestStaking_TokenAlreadySupported(address token);

    error EnforcedPause();
    error OwnableUnauthorizedAccount(address account);
}
