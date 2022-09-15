// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import 'src/OnchainMetadata.sol';
import 'forge-std/Test.sol';
import '../src/Bill.sol';

import 'forge-std/console.sol';

contract MockERC20 is IERC20Metadata, ERC20 {
    constructor() ERC20('SHIBA INU', 'SHIB') {}
}

contract OnchainMetadataTest is Test {
    OnchainMetadata meta;
    MockERC20 coin;

    function setUp() public {
        meta = new OnchainMetadata(new Bill());
        coin = new MockERC20();
    }

    function testRender() public {
        console.log('>>> MockERC20 address >>> ', address(coin)); // 0xEFc56627233b02eA95bAE7e19F648d7DcD5Bb132
        string memory uri = meta.uri(0xEFc56627233b02eA95bAE7e19F648d7DcD5Bb132000000000000000000000001);

        string[] memory inputs = new string[](3);
        inputs[0] = 'node';
        inputs[1] = 'test/utils/extract.js';
        inputs[2] = uri;

        console.log('>>> base64 encoded svg >>>', uri);

        vm.ffi(inputs);
    }

    function testEthRender() public {
        // console.log(address(0)); // 0x0000000000000000000000000000000000000000
        string memory uri = meta.uri(0x0000000000000000000000000000000000000000000000000000000000000001);

        string[] memory inputs = new string[](3);
        inputs[0] = 'node';
        inputs[1] = 'test/utils/extract.js';
        inputs[2] = uri;

        console.log('>>> base64 encoded svg >>>', uri);

        vm.ffi(inputs);
    }
}
