// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

contract Errors {
    error DropnestStaking_DepositLessThanMinimumAmount(uint256 protocolId, uint256 amount);
    error DropnestStaking_ZeroAddressProvided();
    error DropnestStaking_ProtocolDoesNotExist();
    error DropnestStaking_DepositDoesntMatchAmountProportion();
    error DropnestStaking_ArraysLengthMismatch();
    error DropnestStaking_MaxNumberOfProtocolsReached();
    error DropnestStaking_NotEnoughBalance();
    error DropnestStaking_ProtocolIsNotActive(uint256 protocolId);
    error DropnestStaking_CannotChangeProtocolStatus(uint256 protocolId, bool status);
    error DropnestStaking_MinProtocolDepositAmountCannotBeZero();

    error EnforcedPause();
    error OwnableUnauthorizedAccount(address account);
}
