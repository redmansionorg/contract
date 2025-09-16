// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title CopyrightRegistry
/// @notice 注册所有文学、图像、视频等作品的版权声明（RUID），作为红楼链OTS与图谱系统的基础入口。
contract CopyrightRegistry {

    struct Registration {
        bytes32 puid;             // 作者身份哈希
        bytes32[] wuid;           // 作品相关的hash，如小说buid、章节cuid等
        string opusType;          // 类型：literature、chapter、artpiece、video等
        uint64 registeredAt;      // 注册时间
        address registeredBy;     // 注册发起者（通常为Opus合约地址）
    }

    /// @notice 版权声明 RUID → 注册信息
    mapping(bytes32 => Registration) public ruidToRegistration;

    /// @notice 注册成功后事件（供OTS共识监听，供图谱校验节点合法性）
    event CopyrightClaimed(
        bytes32 indexed ruid,
        bytes32 puid,
        bytes32[] wuid,
        string opusType,
        uint64 registeredAt,
        address indexed registeredBy
    );

    /**
     * @notice 注册版权声明
     * @param ruid keccak256(wuid + puid)
     * @param puid 作者身份哈希
     * @param wuid 内容哈希数组（可为[小说buid]或[小说buid,章节cuid]）
     * @param opusType 内容类型字符串
     */
    function registerCopyright(
        bytes32 ruid,
        bytes32 puid,
        bytes32[] calldata wuid,
        string calldata opusType
    ) external {
        require(ruid != bytes32(0), "Invalid ruid");
        require(ruidToRegistration[ruid].registeredAt == 0, "Already registered");

        ruidToRegistration[ruid] = Registration({
            puid: puid,
            wuid: wuid,
            opusType: opusType,
            registeredAt: uint64(block.timestamp),
            registeredBy: msg.sender
        });

        emit CopyrightClaimed(
            ruid,
            puid,
            wuid,
            opusType,
            uint64(block.timestamp),
            msg.sender
        );
    }

    /**
     * @notice 查询注册信息（供合约或前端查阅）
     */
    function getRegistration(bytes32 ruid) external view returns (
        bytes32 puid,
        bytes32[] memory wuid,
        string memory opusType,
        uint64 registeredAt,
        address registeredBy
    ) {
        Registration memory reg = ruidToRegistration[ruid];
        return (reg.puid, reg.wuid, reg.opusType, reg.registeredAt, reg.registeredBy);
    }

    /**
     * @notice 校验某个RUID是否已注册
     */
    function isRegistered(bytes32 ruid) external view returns (bool) {
        return ruidToRegistration[ruid].registeredAt > 0;
    }
}
