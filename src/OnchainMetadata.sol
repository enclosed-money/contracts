// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Bill.sol';
import './interfaces/IMetadata.sol';
import 'openzeppelin-contracts/contracts/utils/Base64.sol';
import 'openzeppelin-contracts/contracts/utils/Strings.sol';

import 'forge-std/console.sol';

contract OnchainMetadata is IMetadata {
    using Strings for uint256;
    
    struct Metadata {
        string symbol;
        string name;
        address erc20;
        uint96 value;
        uint8 decimals;
    }

    Bill public bill;

    constructor(Bill _bill) {
        bill = _bill;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        address erc20 = address(uint160(id >> 96));
        // TODO: refactor hardcoded value
        uint96 value = uint96(id)*10**18; 

        // TODO: check registry and return proper stuff
        // just hardcoded for now
        Metadata memory _metadata = Metadata({
            symbol: 'USDC',
            name: 'USD Coin',
            erc20: erc20,
            value: value,
            decimals: 18
        });

        string memory _renderedMetadata = Base64.encode(bytes(bill.render(_metadata.symbol, _metadata.name, _metadata.erc20, _metadata.value, _metadata.decimals)));

        string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"name": "ENCLOSED.MONEY - #',
                    id.toString(),
                    '", "description": "Turn Your Magic Internet Money Into an NFT -- Because, Why Not?!", "image": "data:image/svg+xml;base64,',
                    _renderedMetadata,
                    '"}'
                )
            )
        )
        );

        // TODO: remove
        console.log(string(
            abi.encodePacked("data:application/json;base64,", json)
        ));

        return string(
            abi.encodePacked("data:application/json;base64,", json)
        );
    }
}
