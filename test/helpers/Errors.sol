// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

contract Errors {
    error DropnestVault_DepositLessThanMinimumAmount(string protocol, uint256 amount);
    error DropnestVault_ZeroAddressProvided();
    error DropnestVault_ProtocolIsNotWhitelisted();
    error DropnestVault_DepositDoesntMatchAmountProportion();
    error DropnestVault_ArraysLengthMissmatch();
    error DropnestVault_MaxNumberOfProtocolsReached();
    error DropnestVault_NotEnoughBalance();

    error DropVault_DepositLessThanMinimumAmount();
    error DropVault_LessThanInitialDepositAmount();
    error DropVault_VaultAlreadyOpened();
    error DropVault_SharesNotInitiated();
    error DropVault_NoSharesToClaim();
    error DropVault_AirdropTokenClaimFailed();
    error DropVault_EthWithdrawFailed();
    error DropVault_ZeroAddressProvided();
    error DropVault_StatusAlreadySet(bool status);
    error DropVault_ClaimNotOpen();

    error EnforcedPause();
    error OwnableUnauthorizedAccount(address account);
}
