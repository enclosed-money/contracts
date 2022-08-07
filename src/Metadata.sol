// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface MetadataURI {
    function uri(uint256 id) external view returns (string memory);
}
