pragma solidity ^0.8.23;

contract Events {
    event Deposited(uint256 indexed protocolId, address indexed from, address to, uint256 amount);
    event WhitelistSet(uint256 protocolId, string protocolName, address to);
}
