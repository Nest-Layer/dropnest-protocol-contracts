pragma solidity ^0.8.23;

contract Events {
    event Deposited(string indexed protocol, address from, address to, uint256 amount);
    event WhitelistSet(string protocol, address to);


    event ETHDeposited(address indexed caller, address indexed receiver, uint256 depositedAmount);
    event AirdropTokenSet(address indexed token);
    event FarmerAddressSet(address indexed farmerAddress);
    event AirdropClaimed(address indexed claimer, uint256 ethAmount, uint256 tokenAmount);
    event ClaimStatusChanged(bool status);
}
