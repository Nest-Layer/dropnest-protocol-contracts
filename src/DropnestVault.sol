// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title DropnestVault
/// @notice This contract is used for managing deposits to dropnest.
contract DropnestVault is Ownable, Pausable {

    ///////////////////
    // Errors        //
    ///////////////////
    error DropnestVault_DepositLessThanMinimumAmount();
    error DropnestVault_ZeroAddressProvided();
    error DropnestVault_ProtocolIsNotWhitelisted();

    /////////////////////
    // State Variables //
    /////////////////////
    // whitelisted protocol => the target address token transfer to
    mapping(string => address) public whitelist;

    // minimum deposit amount
    uint256 internal constant MIN_DEPOSIT_AMOUNT = 0.01 ether;

    ///////////////////
    // Events        //
    ///////////////////
    /// @notice Event emitted when ETH is deposited
    event Deposited(string indexed protocol, address from, address to, uint256 amount);

    /// @notice Event emitted when new protocol added to whitelist
    event WhitelistSet(string protocol, address to);

    ///////////////////
    // Modifiers
    ///////////////////

    ///////////////////
    // Functions     //
    ///////////////////

    constructor(string[] memory protocols, address[] memory addresses) Ownable(msg.sender) {
        for (uint256 i = 0; i < protocols.length; i++) {
            _setWhitelist(protocols[i], addresses[i]);
        }
    }

    /////////////////////////
    // External Functions  //
    /////////////////////////
    function stake(string memory protocol) external payable whenNotPaused {
        uint256 depositAmount = msg.value;
        if (depositAmount < MIN_DEPOSIT_AMOUNT) {
            revert DropnestVault_DepositLessThanMinimumAmount();
        }
        address to = whitelist[protocol];
        if (to == address(0)) {
            revert DropnestVault_ProtocolIsNotWhitelisted();
        }
        emit Deposited(protocol, msg.sender, to, depositAmount);
        payable(to).transfer(depositAmount);
    }


    function setWhitelist(string memory protocol, address to) external onlyOwner {
        _setWhitelist(protocol, to);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    ///////////////////////
    // Public Functions  //
    ///////////////////////

    //////////////////////////////////////////////////////
    // Private & Internal View & Pure Functions         //
    //////////////////////////////////////////////////////
    function _setWhitelist(string memory protocol, address to) private {
        if (to == address(0)) {
            revert DropnestVault_ZeroAddressProvided();
        }
        whitelist[protocol] = to;
        emit WhitelistSet(protocol, to);
    }
    //////////////////////////////////////////////////////////
    // External & Public View & Pure Functions              //
    //////////////////////////////////////////////////////////

}



