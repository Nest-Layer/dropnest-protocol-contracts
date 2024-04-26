// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {console} from "forge-std/Test.sol";

/// @title DropnestVault
/// @notice This contract is used for managing deposits to dropnest.
contract DropnestVault is Ownable, Pausable {

    ///////////////////
    // Errors        //
    ///////////////////
    error DropnestVault_DepositLessThanMinimumAmount(string protocol, uint256 amount);
    error DropnestVault_ZeroAddressProvided();
    error DropnestVault_ProtocolIsNotWhitelisted();
    error DropnestVault_DepositDoesntMatchAmountProportion();
    error DropnestVault_ArraysLengthMissmatch();
    error DropnestVault_MaxNumberOfProtocolsReached();
    error DropnestVault_NotEnoughBalance();

    /////////////////////
    // State Variables //
    /////////////////////
    // whitelisted protocol => the target address token transfer to
    mapping(string => address) public whitelist;

    // protocols list
    string[] public protocols;

    // minimum deposit amount
    uint256 internal constant MIN_PROTOCOL_DEPOSIT_AMOUNT = 0.1 ether;

    // maximum number of protocols in one batch
    uint256 internal constant MAX_NUMBER_OF_PROTOCOLS = 10;

    ///////////////////
    // Events        //
    ///////////////////
    /// @notice Event emitted when ETH is deposited
    event Deposited(string indexed protocol, address from, address to, uint256 amount);

    /// @notice Event emitted when new protocol added to whitelist
    event WhitelistSet(string protocol, address to);

    ///////////////////
    // Functions     //
    ///////////////////

    /// @notice Constructor to initialize the contract
    /// @param _protocols The list of protocols to be whitelisted
    /// @param _addresses The list of addresses corresponding to the protocols
    constructor(string[] memory _protocols, address[] memory _addresses) Ownable(msg.sender) {
        if (_protocols.length != _addresses.length) {
            revert DropnestVault_ArraysLengthMissmatch();
        }
        for (uint256 i = 0; i < _protocols.length; i++) {
            _setWhitelist(_protocols[i], _addresses[i]);
        }
    }

    /////////////////////////
    // External Functions  //
    /////////////////////////
    function stakeMultiple(string[] memory _protocols, uint256[] memory _protocolAmounts) external payable whenNotPaused {
        uint256 totalDepositAmount = msg.value;
        uint256 totalSum = 0;

        if (msg.sender.balance < totalDepositAmount) {
            revert DropnestVault_NotEnoughBalance();
        }

        if (_protocols.length != _protocolAmounts.length) {
            revert DropnestVault_ArraysLengthMissmatch();
        }
        if (_protocols.length > MAX_NUMBER_OF_PROTOCOLS) {
            revert DropnestVault_MaxNumberOfProtocolsReached();
        }
        for (uint256 i = 0; i < _protocols.length; i++) {
            totalSum += _protocolAmounts[i];
        }
        if (totalSum != totalDepositAmount) {
            revert DropnestVault_DepositDoesntMatchAmountProportion();
        }
        for (uint256 i = 0; i < _protocols.length; i++) {
            string memory protocol = protocols[i];
            uint256 amount = _protocolAmounts[i];
            _stake(protocol, amount);
        }
    }

    /// @notice Allows a user to stake their ETH
    /// @param protocol The protocol to stake on
    function stake(string memory protocol) external payable whenNotPaused {
        _stake(protocol, msg.value);
    }

    /// @notice Allows the owner to set the whitelist
    /// @param protocol The protocol to be whitelisted
    /// @param to The address corresponding to the protocol
    function setWhitelist(string memory protocol, address to) external onlyOwner {
        _setWhitelist(protocol, to);
    }

    /// @notice Allows the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allows the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    ///////////////////////
    // Public Functions  //
    ///////////////////////

    //////////////////////////////////////////////////////
    // Private & Internal View & Pure Functions         //
    //////////////////////////////////////////////////////
    /// @notice Allows a user to stake their ETH
    /// @param protocol The protocol to stake on
    /// @param protocolAmount The amount of ETH to stake
    function _stake(string memory protocol, uint256 protocolAmount) private {
        if (protocolAmount < MIN_PROTOCOL_DEPOSIT_AMOUNT) {
            revert DropnestVault_DepositLessThanMinimumAmount(protocol, protocolAmount);
        }
        address to = whitelist[protocol];
        if (to == address(0)) {
            revert DropnestVault_ProtocolIsNotWhitelisted();
        }
        payable(to).transfer(protocolAmount);
        emit Deposited(protocol, msg.sender, to, protocolAmount);
    }

    /// @notice Sets the whitelist
    /// @param protocol The protocol to be whitelisted
    /// @param to The address corresponding to the protocol
    function _setWhitelist(string memory protocol, address to) private {
        if (to == address(0)) {
            revert DropnestVault_ZeroAddressProvided();
        }
        whitelist[protocol] = to;
        protocols.push(protocol);
        emit WhitelistSet(protocol, to);
    }
    //////////////////////////////////////////////////////////
    // External & Public View & Pure Functions              //
    //////////////////////////////////////////////////////////
    function getProtocols() public view returns (string[] memory) {
        return protocols;
    }
}
