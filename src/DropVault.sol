// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title DropVault
/// @notice This contract is used for managing airdrops and claims.
contract DropVault is Ownable, Pausable, ReentrancyGuard {
    ///////////////////
    // Errors        //
    ///////////////////
    error DropVault_ZeroDeposit();
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

    /////////////////////
    // State Variables //
    /////////////////////
    /// @notice Address of the airdrop token
    address public airdropTokenAddress;
    /// @notice Address of the farmer
    address public farmerAddress;
    /// @notice Total shares in the vault
    uint256 public totalShares;
    /// @notice Name of the protocol
    string public protocolName;
    /// @notice Status of the airdrop claim
    bool public airdropClaimStatus;

    /// @notice Initial deposit amount required to open the vault
    uint256 internal constant INITIAL_DEPOSIT_AMOUNT = 1000;

    /// @notice Mapping of addresses to their share amounts
    mapping(address => uint256) public shares;

    ///////////////////
    // Events        //
    ///////////////////
    /// @notice Event emitted when ETH is deposited
    event ETHDeposited(address indexed caller, address indexed receiver, uint256 depositedAmount);
    /// @notice Event emitted when airdrop token is set
    event AirdropTokenSet(address indexed token);
    /// @notice Event emitted when farmer address is set
    event FarmerAddressSet(address indexed farmerAddress);
    // @notice Event emitted when airdrop is claimed
    event AirdropClaimed(address indexed claimer, uint256 ethAmount, uint256 tokenAmount);
    /// @notice Event emitted when claim status is changed
    event ClaimStatusChanged(bool status);

    ///////////////////
    // Modifiers
    ///////////////////

    /// @notice Modifier to make a function callable only when claim is open
    modifier whenClaimable() {
        if (!airdropClaimStatus) {
            revert DropVault_ClaimNotOpen();
        }
        _;
    }

    ///////////////////
    // Functions     //
    ///////////////////
    /// @notice Constructor for creating a new DropVault
    /// @param _protocolName The name of the protocol
    /// @param _farmerAddress The address of the farmer
    constructor(string memory _protocolName, address _farmerAddress) Ownable(msg.sender) {
        protocolName = _protocolName;
        if (_farmerAddress == address(0)) {
            revert DropVault_ZeroAddressProvided();
        }
        farmerAddress = _farmerAddress;
        _pause();
        airdropClaimStatus = false;
    }

    /////////////////////////
    // External Functions  //
    /////////////////////////

    /// @notice Sets the airdrop token address and opens the claim
    /// @param _airdropTokenAddress The address of the airdrop token
    function setAirdropTokenAddressAndOpenClaim(address _airdropTokenAddress) external onlyOwner {
        updateAirdropTokenAddress(_airdropTokenAddress);
        setClaimStatus(true);
    }

    /// @notice Opens the vault for deposits
    function openVault() external payable onlyOwner {
        if (totalShares != 0) {
            revert DropVault_VaultAlreadyOpened();
        }

        if (msg.value < INITIAL_DEPOSIT_AMOUNT) {
            revert DropVault_LessThanInitialDepositAmount();
        }
        _mintShares(msg.sender, msg.value);
        _unpause();
    }

    /// @notice Unpauses the contract, allowing deposits and claims
    function unpause() external onlyOwner whenPaused {
        if (totalShares == 0) {
            revert DropVault_SharesNotInitiated();
        }
        _unpause();
    }

    /// @notice Pauses the contract, preventing deposits and claims
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Allows a user to claim their airdrop and withdraw their ETH
    function claimAirdropAndWithdrawETH() external whenNotPaused nonReentrant whenClaimable {
        if (shares[msg.sender] == 0) {
            revert DropVault_NoSharesToClaim();
        }

        uint256 _shares = shares[msg.sender];
        shares[msg.sender] = 0;
        uint256 _totalShares = totalShares;
        totalShares -= _shares;

        uint256 ethAmount = _withdrawETH(msg.sender, _totalShares, _shares);
        uint256 tokenAmount = _claimAirdrop(msg.sender, _totalShares, _shares);
        emit AirdropClaimed(msg.sender, ethAmount, tokenAmount);
    }

    /// @notice Allows the contract to receive ETH
    receive() external payable {
        depositETH(msg.sender);
    }

    /// @notice Funds the farmer with the contract's balance
    function fundFarmer() external onlyOwner {
        uint256 fundAmount = address(this).balance;
        if (fundAmount == 0) {
            revert DropVault_NoBalanceToFund();
        }
        payable(farmerAddress).transfer(fundAmount);
        emit FarmerAddressSet(farmerAddress);
    }

    /// @notice Updates the farmer's address
    /// @param _farmerAddress The new farmer's address
    function updateFarmerAddress(address _farmerAddress) external onlyOwner {
        if (_farmerAddress == address(0)) {
            revert DropVault_ZeroAddressProvided();
        }
        farmerAddress = _farmerAddress;
    }

    ///////////////////////
    // Public Functions  //
    ///////////////////////
    /// @notice Allows a user to deposit ETH into the contract
    /// @param receiver The address that will receive the shares
    function depositETH(address receiver) public payable {
        if (msg.value == 0) {
            revert DropVault_ZeroDeposit();
        }
        _recordDepositETH(receiver, msg.value);
    }

    /// @notice Sets the claim status
    /// @param status The new claim status
    function setClaimStatus(bool status) public onlyOwner {
        if (airdropClaimStatus == status) {
            revert DropVault_StatusAlreadySet(status);
        }
        if (airdropTokenAddress == address(0)) {
            revert DropVault_ZeroAddressProvided();
        }
        airdropClaimStatus = status;
        emit ClaimStatusChanged(status);
    }

    /// @notice Updates the airdrop token address
    /// @param _airdropTokenAddress The new airdrop token address
    function updateAirdropTokenAddress(address _airdropTokenAddress) public onlyOwner {
        if (_airdropTokenAddress == address(0)) {
            revert DropVault_ZeroAddressProvided();
        }
        airdropTokenAddress = _airdropTokenAddress;
        emit AirdropTokenSet(_airdropTokenAddress);
    }

    ///////////////////////
    // Private Functions //
    ///////////////////////
    /// @notice Claims the airdrop for a user based on their shares.
    /// @param user The address of the user claiming the airdrop.
    /// @param _totalShares The total shares in the vault.
    /// @param _shares The number of shares owned by the user.
    /// @return The amount of tokens withdrawn by the user.
    function _claimAirdrop(address user, uint256 _totalShares, uint256 _shares) internal returns (uint256) {
        uint256 totalAirdropBalance = airdropTotalBalance();
        uint256 withdrawAmount = (totalAirdropBalance * _shares) / _totalShares;
        bool success = IERC20(airdropTokenAddress).transfer(user, withdrawAmount);
        if (!success) {
            revert DropVault_AirdropTokenClaimFailed();
        }
        return withdrawAmount;
    }

    /// @notice Withdraws ETH for a user based on their shares.
    /// @param user The address of the user withdrawing ETH.
    /// @param _totalShares The total shares in the vault.
    /// @param _shares The number of shares owned by the user.
    /// @return The amount of ETH withdrawn by the user.
    function _withdrawETH(address user, uint256 _totalShares, uint256 _shares) internal returns (uint256){
        uint256 withdrawAmount = (address(this).balance * _shares) / _totalShares;
        (bool success,) = payable(user).call{value: withdrawAmount}("");
        if (!success) {
            revert DropVault_EthWithdrawFailed();
        }
        return withdrawAmount;
    }

    /// @notice Mints new shares for a user.
    /// @param user The address of the user for whom to mint shares.
    /// @param _shares The number of shares to mint for the user.
    function _mintShares(address user, uint256 _shares) internal {
        shares[user] += _shares;
        totalShares += _shares;
    }

    /// @notice Records a deposit of ETH and mints shares for the receiver.
    /// @param receiver The address that will receive the shares.
    /// @param depositAmount The amount of ETH deposited.
    function _recordDepositETH(address receiver, uint256 depositAmount) internal whenNotPaused {
        _mintShares(receiver, depositAmount);
        emit ETHDeposited(msg.sender, receiver, depositAmount);
    }

    //////////////////////////////////////////////////////
    // Private & Internal View & Pure Functions         //
    //////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////
    // External & Public View & Pure Functions              //
    //////////////////////////////////////////////////////////

    /// @notice Returns the balance of a user
    /// @param user The address of the user
    /// @return The balance of the user
    function balanceOf(address user) public view returns (uint256) {
        return shares[user];
    }

    /// @notice Returns the claimable amount of ETH and tokens for a user
    /// @param user The address of the user
    /// @return The claimable amount of ETH and tokens
    function getClaimableAmount(address user) public view returns (uint256, uint256) {
        // If airdrop claim status is not open, return zero amounts
        if (!airdropClaimStatus) {
            return (0, 0);
        }

        // Get the number of shares for the user
        uint256 userShares = shares[user];

        // Calculate the amount of tokens and ETH the user can claim based on their shares
        uint256 claimableTokenAmount = (airdropTotalBalance() * userShares) / totalShares;
        uint256 claimableEthAmount = (address(this).balance * userShares) / totalShares;

        // Return the claimable amounts
        return (claimableEthAmount, claimableTokenAmount);
    }

    /// @notice Returns the total balance of the airdrop token
    /// @return The total balance of the airdrop token
    function airdropTotalBalance() public view returns (uint256) {
        if (airdropTokenAddress == address(0)) {
            return 0;
        }
        return IERC20(airdropTokenAddress).balanceOf(address(this));
    }
}
