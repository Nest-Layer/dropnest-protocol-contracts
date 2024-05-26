pragma solidity ^0.8.23;

contract Events {
    event Deposited(uint256 indexed protocolId, address indexed from, address to, uint256 amount);
    event ERC20Deposited(uint256 indexed protocolId, address indexed token, address indexed from, address to, uint256 amount);
    event ProtocolAdded(uint256 protocolId, string protocolName, address to);
    event ProtocolUpdated(uint256 protocolId, string protocolName, address to);
    event ProtocolStatusUpdated(uint256 protocolId, bool status);
}
