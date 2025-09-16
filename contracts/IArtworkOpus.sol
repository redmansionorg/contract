// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Opus 接口标准，要求支持 getMetadata
interface IArtworkOpus {


    function getOriginMetadata()
        external
        view
        returns (bytes memory);

    function getArtMetadata()
        external
        view
        returns (bytes memory);

    
}
