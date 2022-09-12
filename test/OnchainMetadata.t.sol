// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'src/OnchainMetadata.sol';
import 'forge-std/Test.sol';

contract OnchainMetadataTest is Test {
    OnchainMetadata meta;

    function setUp() public {
        meta = new OnchainMetadata();
    }

    function testRender() public {
        string memory uri = meta.uri(1);

        string[] memory inputs = new string[](3);
        inputs[0] = 'node';
        inputs[1] = 'test/utils/extract.js';
        inputs[2] = uri;

        vm.ffi(inputs);
    }
}
