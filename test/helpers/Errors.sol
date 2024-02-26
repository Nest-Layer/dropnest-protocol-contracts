// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

contract Errors {
    error DropVault_DepositLessThanMinimumAmount();
    error DropVault_LessThanInitialDepositAmount();
    error DropVault_VaultAlreadyOpened();
    error DropVault_ZeroSharesIssued();
    error DropVault_SharesNotInitiated();
    error DropVault_NoSharesToClaim();
    error DropVault_AirdropTokenClaimFailed();
    error DropVault_EthWithdrawFailed();
    error DropVault_ZeroAddressProvided();
    error DropVault_StatusAlreadySet(bool status);
    error DropVault_ClaimNotOpen();
    error DropVault_NoBalanceToFund();

    error EnforcedPause();
    error OwnableUnauthorizedAccount(address account);
}
