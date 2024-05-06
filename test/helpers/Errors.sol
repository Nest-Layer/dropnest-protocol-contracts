// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

contract Errors {
    error DropnestStaking_DepositLessThanMinimumAmount(string protocol, uint256 amount);
    error DropnestStaking_ZeroAddressProvided();
    error DropnestStaking_ProtocolIsNotWhitelisted();
    error DropnestStaking_DepositDoesntMatchAmountProportion();
    error DropnestStaking_ArraysLengthMissmatch();
    error DropnestStaking_MaxNumberOfProtocolsReached();
    error DropnestStaking_NotEnoughBalance();

    error EnforcedPause();
    error OwnableUnauthorizedAccount(address account);
}
