// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Opus 接口标准，要求支持 author()、title()
interface ILiteratureOpus {
    function writer() external view returns (string memory);

    function title() external view returns (string memory);

    function synopsisCid() external view returns (string memory);

    function logoCid() external view returns (string memory);
}

