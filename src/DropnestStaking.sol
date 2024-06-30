// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title DropnestStaking
/// @notice This contract is used for managing deposits to the Dropnest protocol.
contract DropnestStaking is Ownable2Step, Pausable, ReentrancyGuard {

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
    error DropnestStaking_ETHTransferFailed();
    error DropnestStaking_CannotBeEmptyArray();
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

    /// @notice Event emitted when supported token is added
    event SupportedTokenAdded(address token);

    /// @notice Event emitted when supported token is removed
    event SupportedTokenRemoved(address token);

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
    constructor(address[] memory _supportedTokens, string[] memory _protocols, address[] memory _addresses) Ownable() {
        if (_supportedTokens.length == 0 || _protocols.length == 0 || _addresses.length == 0) {
            revert DropnestStaking_CannotBeEmptyArray();
        }

        if (_protocols.length != _addresses.length) {
            revert DropnestStaking_ArraysLengthMismatch();
        }
        for (uint256 i = 0; i < _protocols.length; i++) {
            _addProtocol(_protocols[i], _addresses[i]);
        }
        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            addSupportedToken(_supportedTokens[i]);
        }
    }

    /////////////////////////
    // External Functions  //
    /////////////////////////

    /// @notice Allows a user to stake ETH on multiple protocols
    /// @param protocolIds Array of protocol IDs to stake on
    /// @param protocolAmounts Array of amounts to stake on each protocol
    function stakeMultiple(uint256[] memory protocolIds, uint256[] memory protocolAmounts) external payable whenNotPaused nonReentrant {
        uint256 totalDepositAmount = msg.value;
        uint256 totalSum = 0;
        if (protocolIds.length != protocolAmounts.length) {
            revert DropnestStaking_ArraysLengthMismatch();
        }
        if (protocolIds.length > MAX_PROTOCOLS) {
            revert DropnestStaking_MaxProtocolsReached();
        }
        for (uint256 i = 0; i < protocolIds.length; i++) {
            totalSum += protocolAmounts[i];
        }
        if (totalSum != totalDepositAmount) {
            revert DropnestStaking_DepositMismatch();
        }
        for (uint256 i = 0; i < protocolIds.length; i++) {
            _stake(protocolIds[i], protocolAmounts[i]);
        }
    }

    /// @notice Allows a user to stake ETH
    /// @param protocolId Protocol ID to stake on
    function stake(uint256 protocolId) external payable whenNotPaused nonReentrant {
        _stake(protocolId, msg.value);
    }

    /// @notice Allows a user to stake ERC20 tokens on multiple protocols
    /// @param token ERC20 token address
    /// @param protocolIds Array of protocol IDs to stake on
    /// @param protocolAmounts Array of amounts to stake on each protocol
    function stakeMultipleERC20(address token, uint256[] memory protocolIds, uint256[] memory protocolAmounts) external whenNotPaused allowedToken(token) nonReentrant {
        if (protocolIds.length != protocolAmounts.length) {
            revert DropnestStaking_ArraysLengthMismatch();
        }
        if (protocolIds.length > MAX_PROTOCOLS) {
            revert DropnestStaking_MaxProtocolsReached();
        }
        for (uint256 i = 0; i < protocolIds.length; i++) {
            _stakeERC20(protocolIds[i], token, protocolAmounts[i]);
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
        uint256 length = protocols.length;
        for (uint256 i = 0; i < length; i++) {
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

    /// @notice Removes an ERC20 token from the list of supported deposit tokens
    /// @param token Token address
    function removeSupportedToken(address token) external onlyOwner allowedToken(token) {
        supportedTokens[token] = false;
        uint256 length = tokenList.length;
        for (uint256 i = 0; i < length; i++) {
            if (tokenList[i] == token) {
                tokenList[i] = tokenList[length - 1];
                tokenList.pop();
                break;
            }
        }
        emit SupportedTokenRemoved(token);
    }

    //////////////////////////////////////////////////////
    // Public Functions                                 //
    //////////////////////////////////////////////////////

    /// @notice Adds a new ERC20 token to the list of supported deposit tokens
    /// @param token Token address
    function addSupportedToken(address token) public onlyOwner {
        if (token == address(0)) {
            revert DropnestStaking_ZeroAddressProvided();
        }
        if (supportedTokens[token]) {
            revert DropnestStaking_TokenAlreadySupported(token);
        }
        supportedTokens[token] = true;
        tokenList.push(token);
        emit SupportedTokenAdded(token);
    }

    //////////////////////////////////////////////////////
    // Private & Internal Functions                     //
    //////////////////////////////////////////////////////

    function _stakeERC20(uint256 protocolId, address tokenAddress, uint256 amount) private nonZeroAmount(amount) {
        if (tokenAddress == address(0)) {
            revert DropnestStaking_ZeroAddressProvided();
        }

        address to = farmAddresses[protocolId];
        if (to == address(0)) {
            revert DropnestStaking_ProtocolDoesNotExist();
        }

        if (!protocolStatus[protocolId]) {
            revert DropnestStaking_ProtocolInactive(protocolId);
        }

        IERC20(tokenAddress).safeTransferFrom(msg.sender, to, amount);
        emit ERC20Deposited(protocolId, tokenAddress, msg.sender, to, amount);
    }

    function _stake(uint256 protocolId, uint256 protocolAmount) private nonZeroAmount(protocolAmount) {
        address payable to = payable(farmAddresses[protocolId]);
        if (to == address(0)) {
            revert DropnestStaking_ProtocolDoesNotExist();
        }
        if (!protocolStatus[protocolId]) {
            revert DropnestStaking_ProtocolInactive(protocolId);
        }
        emit Deposited(protocolId, msg.sender, to, protocolAmount);

        (bool success,) = to.call{value: protocolAmount}("");
        if (!success) {
            revert DropnestStaking_ETHTransferFailed();
        }
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
