pragma solidity ^0.8.23;

contract Events {
    event Deposited(uint256 indexed protocolId, address indexed from, address to, uint256 amount);
    event WhitelistSet(uint256 protocolId, string protocolName, address to);


    event ETHDeposited(address indexed caller, address indexed receiver, uint256 depositedAmount);
    event AirdropTokenSet(address indexed token);
    event FarmerAddressSet(address indexed farmerAddress);
    event AirdropClaimed(address indexed claimer, uint256 ethAmount, uint256 tokenAmount);
    event ClaimStatusChanged(bool status);
}
