// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RightMessageRegistry {
    mapping(bytes32 => uint64) public registeredMessages;

    event MessageRegistered(address indexed user, bytes32 message, uint64 blockNumber, uint64 timestamp);

    function registerMessage(bytes32 message) external {
        require(registeredMessages[message]==0, "Message Already registered");
        registeredMessages[message] =  uint64(block.number);
        emit MessageRegistered(msg.sender, message, uint64(block.number), uint64(block.timestamp));
    }

    function isMessageRegistered(bytes32 message) external view returns (bool) {
        return registeredMessages[message]!=0;
    }

    function getBlockNumber(bytes32 message) external view returns (uint64) {
        return registeredMessages[message];
    }
}