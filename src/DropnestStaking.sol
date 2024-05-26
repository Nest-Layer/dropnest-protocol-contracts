// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title DropnestStaking
/// @notice This contract is used for managing deposits to the Dropnest protocol.
contract DropnestStaking is Ownable, Pausable, ReentrancyGuard {

    ///////////////////
    // Libraries     //
    ///////////////////
    using SafeERC20 for IERC20;

    ///////////////////
    // Errors        //
    ///////////////////
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
    /////////////////////
    // State Variables //
    /////////////////////
    // protocolId => target address to move the liquidity
    mapping(uint256 => address) public farmAddresses;

    // protocolId => bool to check if the protocol is active or not
    mapping(uint256 => bool) public protocolStatus;

    // protocols list
    string[] public protocols;

    // number of protocols
    uint256 private protocolCounter;

    // maximum number of protocols to stake in one batch
    uint256 internal constant MAX_PROTOCOLS = 10;

    // mapping to store allowed ERC20 tokens
    mapping(address => bool) private supportedTokens;

    address[] private tokenList;

    ///////////////////
    // Events        //
    ///////////////////
    /// @notice Event emitted when ETH is deposited
    event Deposited(uint256 indexed protocolId, address indexed from, address to, uint256 amount);

    /// @notice Event emitted when ERC20 is deposited
    event ERC20Deposited(uint256 indexed protocolId, address indexed token, address indexed from, address to, uint256 amount);

    /// @notice Event emitted when a new protocol is added
    event ProtocolAdded(uint256 protocolId, string protocolName, address to);

    /// @notice Event emitted when an existing protocol is updated
    event ProtocolUpdated(uint256 protocolId, string protocolName, address to);

    /// @notice Event emitted when protocol status is updated
    event ProtocolStatusUpdated(uint256 protocolId, bool status);

    ///////////////////
    // Modifiers     //
    ///////////////////
    modifier nonZeroAmount(uint256 amount) {
        if (amount == 0) {
            revert DropnestStaking_AmountMustBeGreaterThanZero();
        }
        _;
    }

    modifier allowedToken(address token) {
        if (!supportedTokens[token]) {
            revert DropnestStaking_TokenNotAllowed(token);
        }
        _;
    }

    ///////////////////
    // Functions     //
    ///////////////////
    /// @notice Constructor to initialize the contract
    /// @param _supportedTokens List of supported tokens
    /// @param _protocols List of protocol names
    /// @param _addresses List of addresses corresponding to the protocols
    constructor(address[] memory _supportedTokens, string[] memory _protocols, address[] memory _addresses) Ownable(msg.sender) {
        if (_protocols.length != _addresses.length) {
            revert DropnestStaking_ArraysLengthMismatch();
        }
        for (uint256 i = 0; i < _protocols.length; i++) {
            _addProtocol(_protocols[i], _addresses[i]);
        }
        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            supportedTokens[_supportedTokens[i]] = true;
            tokenList.push(_supportedTokens[i]);
        }
    }

    /////////////////////////
    // External Functions  //
    /////////////////////////

    /// @notice Allows a user to stake ETH on multiple protocols
    /// @param _protocolIds Array of protocol IDs to stake on
    /// @param _protocolAmounts Array of amounts to stake on each protocol
    function stakeMultiple(uint256[] memory _protocolIds, uint256[] memory _protocolAmounts) external payable whenNotPaused nonReentrant {
        uint256 totalDepositAmount = msg.value;
        uint256 totalSum = 0;
        if (_protocolIds.length != _protocolAmounts.length) {
            revert DropnestStaking_ArraysLengthMismatch();
        }
        if (_protocolIds.length > MAX_PROTOCOLS) {
            revert DropnestStaking_MaxProtocolsReached();
        }
        for (uint256 i = 0; i < _protocolIds.length; i++) {
            totalSum += _protocolAmounts[i];
        }
        if (totalSum != totalDepositAmount) {
            revert DropnestStaking_DepositMismatch();
        }
        for (uint256 i = 0; i < _protocolIds.length; i++) {
            _stake(_protocolIds[i], _protocolAmounts[i]);
        }
    }

    /// @notice Allows a user to stake ETH
    /// @param protocolId Protocol ID to stake on
    function stake(uint256 protocolId) external payable whenNotPaused nonReentrant {
        _stake(protocolId, msg.value);
    }

    /// @notice Allows a user to stake ERC20 tokens on multiple protocols
    /// @param token ERC20 token address
    /// @param _protocolIds Array of protocol IDs to stake on
    /// @param _protocolAmounts Array of amounts to stake on each protocol
    function stakeMultipleERC20(address token, uint256[] memory _protocolIds, uint256[] memory _protocolAmounts) external whenNotPaused allowedToken(token) nonReentrant {
        if (_protocolIds.length != _protocolAmounts.length) {
            revert DropnestStaking_ArraysLengthMismatch();
        }
        if (_protocolIds.length > MAX_PROTOCOLS) {
            revert DropnestStaking_MaxProtocolsReached();
        }
        for (uint256 i = 0; i < _protocolIds.length; i++) {
            _stakeERC20(_protocolIds[i], token, _protocolAmounts[i]);
        }
    }

    /// @notice Allows a user to stake ERC20 tokens
    /// @param protocolId Protocol ID to stake on
    /// @param token ERC20 token address
    /// @param amount Amount of tokens to stake
    function stakeERC20(uint256 protocolId, address token, uint256 amount) external whenNotPaused allowedToken(token) nonReentrant {
        _stakeERC20(protocolId, token, amount);
    }

    /// @notice Allows the owner to add or update a protocol
    /// @param protocolName Protocol name to be added or updated
    /// @param farmerAddress Address corresponding to the protocol
    function addOrUpdateProtocol(string memory protocolName, address farmerAddress) external onlyOwner {
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
    /// @param protocolId Protocol ID
    /// @param status Protocol status
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

    //////////////////////////////////////////////////////
    // Private & Internal Functions                     //
    //////////////////////////////////////////////////////

    function _stakeERC20(uint256 protocolId, address tokenAddress, uint256 amount) private nonZeroAmount(amount) {
        if (tokenAddress == address(0)) {
            revert DropnestStaking_ZeroAddressProvided();
        }

        if (!protocolStatus[protocolId]) {
            revert DropnestStaking_ProtocolInactive(protocolId);
        }
        address to = farmAddresses[protocolId];
        if (to == address(0)) {
            revert DropnestStaking_ProtocolDoesNotExist();
        }
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit ERC20Deposited(protocolId, tokenAddress, msg.sender, to, amount);
    }

    function _stake(uint256 protocolId, uint256 protocolAmount) private nonZeroAmount(protocolAmount) {
        address to = farmAddresses[protocolId];
        if (to == address(0)) {
            revert DropnestStaking_ProtocolDoesNotExist();
        }
        if (!protocolStatus[protocolId]) {
            revert DropnestStaking_ProtocolInactive(protocolId);
        }
        emit Deposited(protocolId, msg.sender, to, protocolAmount);
        payable(to).transfer(protocolAmount);
    }

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

    /// @notice Adds a new ERC20 token to the list of supported deposit tokens
    /// @param token Token address
    function addSupportedToken(address token) external onlyOwner {
        if (supportedTokens[token]) {
            revert DropnestStaking_TokenAlreadySupported(token);
        }
        supportedTokens[token] = true;
        tokenList.push(token);
    }

    /// @notice Removes an ERC20 token from the list of supported deposit tokens
    /// @param token Token address
    function removeSupportedToken(address token) external onlyOwner {
        supportedTokens[token] = false;
        for (uint256 i = 0; i < tokenList.length; i++) {
            if (tokenList[i] == token) {
                tokenList[i] = tokenList[tokenList.length - 1];
                tokenList.pop();
                break;
            }
        }
    }

    //////////////////////////////////////////////////////////
    // External & Public View Functions                     //
    //////////////////////////////////////////////////////////

    /// @notice Returns the list of protocols
    function getProtocols() public view returns (string[] memory) {
        return protocols;
    }

    /// @notice Returns the address of the specified protocol
    /// @param protocolId Protocol ID
    function getFarmAddress(uint256 protocolId) public view returns (address) {
        return farmAddresses[protocolId];
    }

    /// @notice Returns the list of supported deposit tokens
    function getSupportedTokens() public view returns (address[] memory) {
        return tokenList;
    }
}
