// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RMRegistry {

    /*
     * Right Message Registry 消息注册模块
     */

    mapping(bytes32 => uint64) public registeredMessages;

    event MessageRegistered(address indexed user, bytes32 message, uint64 blockNumber, uint64 timestamp);

    function registerMessage(bytes32 message) external {
        require(registeredMessages[message]==0, "Message Already registered");
        registeredMessages[message] =  uint64(block.timestamp);
        emit MessageRegistered(msg.sender, message, uint64(block.number), uint64(block.timestamp));
    }

    function isMessageRegistered(bytes32 message) external view returns (bool) {
        return registeredMessages[message]!=0;
    }

    function getBlockNumber(bytes32 message) external view returns (uint64) {
        return registeredMessages[message];
    }


    /*
     * Right Message Block 与 OTS 共识模块
     */

    /* ========== RMBlock 信息结构 ========== */
    struct RMBlockInfo {
        // - 用于显示
        bytes32 rmbRootHash;
        uint64 startTime;
        uint64 endTime;
        // - 奖励机制
        address committer;
        uint64 committedAt;


        // OTS 证明 用于显示
        bytes32 otsRootHash;
        uint64 otsRootIndex;
        uint64 timestamp;
        // 可能用于提交receipt
        string txHash;
        // - 惩罚与奖赏
        address otsCommitter;
        uint64 otsCommittedAt;
    }

    mapping(uint64 => RMBlockInfo) public rmBlocks;
    uint64 public rmBlockCount;

    event RMBlockCommitted(uint64 indexed index, bytes32 rootHash, uint64 startTime, uint64 endTime, uint64 messageCount);
    event OTSProofCommitted(uint64 indexed index, bytes32 rootHash, string txHash, uint64 timestamp);

    uint64 public constant OTS_SUBMIT_WINDOW = 24 * 60 * 60; // 24小时

    /* ========== RMBlock 提交 ========== */
    function commitRMBlock(
        uint64 rootIndex,
        bytes32 rootHash,
        uint64 startTime,
        uint64 endTime,
        uint64 messageCount
    ) external {
        require(rmBlocks[rootIndex].committedAt == 0, "Already committed");

        RMBlockInfo storage info = rmBlocks[rootIndex];
        info.rmbRootHash = rootHash;
        info.startTime = startTime;
        info.endTime = endTime;
        info.committer = msg.sender;
        info.committedAt = uint64(block.timestamp);

        rmBlockCount++;
        emit RMBlockCommitted(rootIndex, rootHash, startTime, endTime, messageCount);
    }

    /* ========== OTS 证明提交 ========== */
    function commitOTSProof(
        uint64 rmRootIndex,
        bytes32 otsRootHash,
        uint64 otsRootIndex,
        uint64 timestamp,
        string calldata txHash
    ) external {

        RMBlockInfo storage info = rmBlocks[rmRootIndex];
        require(info.committedAt!=0, "RMBlock not comitted");


        info.otsRootIndex = otsRootIndex;
        info.otsRootHash = otsRootHash;
        info.timestamp = timestamp;
        info.txHash = txHash;
        info.otsCommitter = msg.sender;
        info.otsCommittedAt = uint64(block.timestamp);

        emit OTSProofCommitted(otsRootIndex, otsRootHash, txHash, timestamp);
    }

    /* ========== 查询接口 ========== */
    function getRMBlockByRUID(bytes32 message) external view returns (RMBlockInfo memory) {
        uint64 index = uint64(registeredMessages[message]/OTS_SUBMIT_WINDOW);
        return rmBlocks[index];
    }

}