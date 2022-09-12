// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Metadata.sol';

contract OnchainMetadata is MetadataURI {
    function uri(uint256) public view virtual override returns (string memory) {
        return '<svg>';
    }
}
