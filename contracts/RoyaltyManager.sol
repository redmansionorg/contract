// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title RoyaltyManager
/// @dev 管理链上作品的多级分润链条结构，支持每一级创作者设置自己的绝对分润比例，并记录授权来源。
contract RoyaltyManager {
    struct RoyaltyItem {
        address receiver;       // 收款地址
        uint96 bps;             // 分润比例，单位为Basis Points（如3000 = 30%）
        bytes32 sourceRuid;     // 授权来源作品ID（可选）
    }

    // 每个作品唯一标识 ruid => 分润链
    mapping(bytes32 => RoyaltyItem[]) public royaltyLines;
    mapping(bytes32 => bool) public isRegistered;

    uint96 public constant MAX_BPS = 10000;

    event RoyaltyRegistered(bytes32 indexed ruid, address indexed registrant);

    error AlreadyRegistered();
    error InvalidRoyaltyTotal();
    error EmptyRoyaltyList();

    /// @notice 注册作品分润链结构
    /// @param ruid 作品ID（内容buid + 作者puid生成）
    /// @param items 分润接收人列表（可包含祖先作者 + 自身）
    function registerRoyaltyList(bytes32 ruid, RoyaltyItem[] calldata items) external {
        if (isRegistered[ruid]) revert AlreadyRegistered();
        if (items.length == 0) revert EmptyRoyaltyList();

        uint96 totalBps = 0;
        for (uint i = 0; i < items.length; i++) {
            royaltyLines[ruid].push(items[i]);
            totalBps += items[i].bps;
        }

        if (totalBps > MAX_BPS) revert InvalidRoyaltyTotal();
        isRegistered[ruid] = true;
        emit RoyaltyRegistered(ruid, msg.sender);
    }

    /// @notice 查询指定作品的所有分润项
    function getRoyaltyList(bytes32 ruid) external view returns (RoyaltyItem[] memory) {
        return royaltyLines[ruid];
    }

    /// @notice 返回所有接收者与其分润比率
    function getRoyaltyReceivers(bytes32 ruid) external view returns (address[] memory receivers, uint96[] memory bps) {
        RoyaltyItem[] storage items = royaltyLines[ruid];
        receivers = new address[](items.length);
        bps = new uint96[](items.length);

        for (uint i = 0; i < items.length; i++) {
            receivers[i] = items[i].receiver;
            bps[i] = items[i].bps;
        }
    }

    /// @notice 计算总分润金额（用于 EIP-2981）
    function getTotalRoyaltyAmount(bytes32 ruid, uint256 salePrice) external view returns (uint256 totalAmount) {
        RoyaltyItem[] storage items = royaltyLines[ruid];
        for (uint i = 0; i < items.length; i++) {
            totalAmount += (salePrice * items[i].bps) / MAX_BPS;
        }
    }
}
