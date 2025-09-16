// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./CopyrightRegistry.sol";

contract CopyrightGraph {

    enum EdgeType {
        DerivedFrom,    // 衍生
        TranslatedFrom, // 翻译
        RemixedFrom,    // 改编或混合
        ReferencedFrom  // 引用或致敬
    }

    struct Edge {
        bytes32 fromRuid;
        bytes32 toRuid;
        EdgeType edgeType;
        uint64 createdAt;
        address createdBy;
    }

    /// 所有边的数组（可枚举）
    Edge[] public allEdges;

    /// fromRuid => outbound edge indices
    mapping(bytes32 => uint256[]) public outEdges;

    /// toRuid => inbound edge indices
    mapping(bytes32 => uint256[]) public inEdges;

    /// fromRuid => toRuid => exists?
    mapping(bytes32 => mapping(bytes32 => bool)) public edgeExists;

    event GraphEdgeAdded(
        bytes32 indexed fromRuid,
        bytes32 indexed toRuid,
        EdgeType edgeType,
        address createdBy,
        uint64 createdAt
    );

    CopyrightRegistry public registry;

    constructor(address registryAddr) {
        registry = CopyrightRegistry(registryAddr);
    }

    /**
     * @notice 添加一条版权图谱边：A 衍生 → B
     * @param fromRuid 原始作品 RUID（节点起点）
     * @param toRuid 衍生作品 RUID（节点终点）
     * @param edgeType 衍生关系类型
     */
    function addEdge(
        bytes32 fromRuid,
        bytes32 toRuid,
        EdgeType edgeType
    ) external {
        require(fromRuid != toRuid, "Cannot point to self");
        require(!edgeExists[fromRuid][toRuid], "Edge already exists");

        _assertRegistered(fromRuid);
        _assertRegistered(toRuid);

        // 可选：只允许原作注册人建立衍生链
        (, , , , address registeredByFrom) = registry.getRegistration(fromRuid);
        require(msg.sender == registeredByFrom, "Only original author can declare");

        // 写入边数据
        edgeExists[fromRuid][toRuid] = true;
        allEdges.push(Edge(fromRuid, toRuid, edgeType, uint64(block.timestamp), msg.sender));
        uint256 edgeIndex = allEdges.length - 1;

        outEdges[fromRuid].push(edgeIndex);
        inEdges[toRuid].push(edgeIndex);

        emit GraphEdgeAdded(fromRuid, toRuid, edgeType, msg.sender, uint64(block.timestamp));
    }

    /**
     * @notice 获取某个节点的出边（我衍生了谁）
     */
    function getOutEdges(bytes32 fromRuid) external view returns (Edge[] memory) {
        uint256[] memory indices = outEdges[fromRuid];
        Edge[] memory result = new Edge[](indices.length);
        for (uint i = 0; i < indices.length; i++) {
            result[i] = allEdges[indices[i]];
        }
        return result;
    }

    /**
     * @notice 获取某个节点的入边（谁衍生了我）
     */
    function getInEdges(bytes32 toRuid) external view returns (Edge[] memory) {
        uint256[] memory indices = inEdges[toRuid];
        Edge[] memory result = new Edge[](indices.length);
        for (uint i = 0; i < indices.length; i++) {
            result[i] = allEdges[indices[i]];
        }
        return result;
    }

    /**
     * @notice 获取全图中的边（可分页）
     */
    function getAllEdges(uint256 offset, uint256 limit) external view returns (Edge[] memory) {
        uint256 total = allEdges.length;
        if (offset >= total) return new Edge[](0) ;
        uint256 end = offset + limit > total ? total : offset + limit;
        Edge[] memory result = new Edge[](end - offset);
        for (uint i = offset; i < end; i++) {
            result[i - offset] = allEdges[i];
        }
        return result;
    }

    /**
     * @notice 内部检查 RUID 是否已注册
     */
    function _assertRegistered(bytes32 ruid) internal view {
        (, , , uint64 ts, ) = registry.getRegistration(ruid);
        require(ts > 0, "RUID not registered");
    }
}
