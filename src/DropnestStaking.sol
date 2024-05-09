// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title DropnestStaking
/// @notice This contract is being used for managing deposits to dropnest protocool.
contract DropnestStaking is Ownable, Pausable, ReentrancyGuard {

    ///////////////////
    // Errors        //
    ///////////////////
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

    /////////////////////
    // State Variables //
    /////////////////////
    // protocolId => the target address to move the liquidity
    mapping(uint256 => address) public farmAddresses;

    //protocolId => bool to check if the protocol is active or not
    mapping(uint256 => bool) public protocolStatus;

    // protocols list
    string[] public protocols;

    // number of protocols
    uint256 private protocolCounter = 0;

    // minimum deposit amount
    uint256 internal minProtocolDepositAmount = 0.01 ether;

    // maximum number of protocols to stake in one batch
    uint256 internal constant MAX_NUMBER_OF_PROTOCOLS = 10;

    ///////////////////
    // Events        //
    ///////////////////
    /// @notice Event emitted when ETH is deposited
    event Deposited(uint256 indexed protocolId, address indexed from, address to, uint256 amount);

    /// @notice Event emitted when new project has been added to protocol
    event ProtocolAdded(uint256 protocolId, string protocolName, address to);

    /// @notice Event emitted when an existing project updates the farmer address
    event ProtocolUpdated(uint256 protocolId, string protocolName, address to);

    // @notice Event emitted when protocol status is updated
    event ProtocolStatusUpdated(uint256 protocolId, bool status);

    // @notice Event emitted when protocol status is updated
    event MinDepositAmountUpdated(uint256 newMinAmount);

    ///////////////////
    // Functions     //
    ///////////////////
    /// @notice Constructor to initialize the contract
    /// @param _protocols The list of protocols to be whitelisted
    /// @param _addresses The list of addresses corresponding to the protocols
    constructor(string[] memory _protocols, address[] memory _addresses) Ownable(msg.sender) {
        if (_protocols.length != _addresses.length) {
            revert DropnestStaking_ArraysLengthMismatch();
        }
        for (uint256 i = 0; i < _protocols.length; i++) {
            _addProtocol(_protocols[i], _addresses[i]);
        }
    }

    /////////////////////////
    // External Functions  //
    /////////////////////////

    /// @notice Allows a user to stake their ETH on multiple protocols
    /// @param _protocolIds The array of protocolIds to stake on
    /// @param _protocolAmounts The array of amounts to stake on each protocol
    function stakeMultiple(uint256[] memory _protocolIds, uint256[] memory _protocolAmounts) external payable whenNotPaused {
        uint256 totalDepositAmount = msg.value;
        uint256 totalSum = 0;

        if (_protocolIds.length != _protocolAmounts.length) {
            revert DropnestStaking_ArraysLengthMismatch();
        }
        if (_protocolIds.length > MAX_NUMBER_OF_PROTOCOLS) {
            revert DropnestStaking_MaxNumberOfProtocolsReached();
        }
        for (uint256 i = 0; i < _protocolIds.length; i++) {
            totalSum += _protocolAmounts[i];
        }
        if (totalSum != totalDepositAmount) {
            revert DropnestStaking_DepositDoesntMatchAmountProportion();
        }
        for (uint256 i = 0; i < _protocolIds.length; i++) {
            uint256 protocolId = _protocolIds[i];
            uint256 amount = _protocolAmounts[i];
            _stake(protocolId, amount);
        }
    }

    /// @notice Allows a user to stake their ETH
    /// @param protocolId The protocolId to stake on
    function stake(uint256 protocolId) external payable whenNotPaused {
        _stake(protocolId, msg.value);
    }

    /// @notice Allows the owner to add new protocol or update the farmerAddress for existing one
    /// @param protocolName The protocol name to be added
    /// @param farmerAddress The address corresponding to the farmer address of the protocol
    function addProtocolOrUpdate(string memory protocolName, address farmerAddress) external onlyOwner {
        for (uint256 i = 0; i < protocols.length; i++) {
            if (keccak256(abi.encodePacked(protocols[i])) == keccak256(abi.encodePacked(protocolName))) {
                uint256 id = i + 1;
                farmAddresses[id] = farmerAddress;
                emit ProtocolUpdated(id, protocolName, farmerAddress);
                return;
            }
        }
        _addProtocol(protocolName, farmerAddress);
    }

    /// @notice Allows the owner to set the protocol status
    /// @param protocolId The protocol unique identifier
    /// @param status The boolean depending on the status of the protocol
    function setProtocolStatus(uint256 protocolId, bool status) external onlyOwner {
        if (farmAddresses[protocolId] == address(0)) {
            revert DropnestStaking_ProtocolDoesNotExist();
        }
        if (protocolStatus[protocolId] == status) {
            revert DropnestStaking_CannotChangeProtocolStatus(protocolId, status);
        }
        protocolStatus[protocolId] = status;
        emit ProtocolStatusUpdated(protocolId, status);
    }

    /// @notice Allows the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allows the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    function setMinProtocolDepositAmount(uint256 amount) external onlyOwner {
        if (amount == 0) {
            revert DropnestStaking_MinProtocolDepositAmountCannotBeZero();
        }
        minProtocolDepositAmount = amount;
        emit MinDepositAmountUpdated(amount);
    }

    //////////////////////////////////////////////////////
    // Private & Internal View & Pure Functions         //
    //////////////////////////////////////////////////////

    /// @notice Allows a user to stake their ETH
    /// @param protocolId The protocol to stake on
    /// @param protocolAmount The amount of ETH to stake
    function _stake(uint256 protocolId, uint256 protocolAmount) nonReentrant private {
        if (protocolAmount < minProtocolDepositAmount) {
            revert DropnestStaking_DepositLessThanMinimumAmount(protocolId, protocolAmount);
        }
        address to = farmAddresses[protocolId];
        if (to == address(0)) {
            revert DropnestStaking_ProtocolDoesNotExist();
        }
        if (!protocolStatus[protocolId]) {
            revert DropnestStaking_ProtocolIsNotActive(protocolId);
        }
        emit Deposited(protocolId, msg.sender, to, protocolAmount);
        payable(to).transfer(protocolAmount);
    }

    /// @notice Sets the whitelist
    /// @param protocolName The protocol name to be whitelisted
    /// @param to The address corresponding to the protocol
    function _addProtocol(string memory protocolName, address to) private {
        if (to == address(0)) {
            revert DropnestStaking_ZeroAddressProvided();
        }
        protocolCounter++;
        protocols.push(protocolName);
        farmAddresses[protocolCounter] = to;
        protocolStatus[protocolCounter] = true;
        emit ProtocolAdded(protocolCounter, protocolName, to);
    }

    //////////////////////////////////////////////////////////
    // External & Public View & Pure Functions              //
    //////////////////////////////////////////////////////////

    /// @notice Returns the list of protocols
    function getProtocols() public view returns (string[] memory) {
        return protocols;
    }

    /// @notice Returns the address of the specified protocol
    /// @param protocolId The protocol unique identifier
    function getFarmAddress(uint256 protocolId) public view returns (address) {
        return farmAddresses[protocolId];
    }
}
