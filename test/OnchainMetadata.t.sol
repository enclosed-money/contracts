// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'src/OnchainMetadata.sol';
import 'forge-std/Test.sol';
import '../src/Bill.sol';

contract OnchainMetadataTest is Test {
    OnchainMetadata meta;

    function setUp() public {
        meta = new OnchainMetadata(new Bill());
    }

    function testRender() public {
        string memory uri = meta.uri(0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce000000000000000000000001);

        string[] memory inputs = new string[](3);
        inputs[0] = 'node';
        inputs[1] = 'test/utils/extract.js';
        inputs[2] = uri;

        vm.ffi(inputs);
    }
}
