// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract RevertOnReceive {
    constructor() payable {}

    receive() external payable {
        revert("Mock contract: receive function reverted");
    }
}
