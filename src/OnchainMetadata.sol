// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Bill.sol';
import './interfaces/IMetadata.sol';
import 'openzeppelin-contracts/contracts/utils/Base64.sol';
import 'openzeppelin-contracts/contracts/utils/Strings.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol';

abstract contract Ether is IERC20Metadata {
    function name() public view virtual override returns (string memory) {
        return 'ETHER';
    }

    function symbol() public view virtual override returns (string memory) {
        return 'ETH';
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}

contract OnchainMetadata is IMetadata {
    using Strings for uint96;

    Bill public bill;

    constructor(Bill _bill) {
        bill = _bill;
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory name;
        uint256 value;
        string memory _renderedMetadata;

        address erc20 = address(uint160(id >> 96));
        string memory displayValue = uint96(id).toString();

        if (erc20 == address(0)) {
            name = 'ETHER';
            value = uint96(id) * 10**18;
            _renderedMetadata = Base64.encode(
                bytes(
                    bill.render(
                        'ETH',
                        name,
                        address(0),
                        uint96(value),
                        18
                    )
                )
            );
        } else {
            IERC20Metadata coin = IERC20Metadata(address(erc20));
            value = uint96(id) * 10**coin.decimals();
            name = coin.name();

            _renderedMetadata = Base64.encode(
                bytes(
                    bill.render(
                        coin.symbol(),
                        coin.name(),
                        erc20,
                        uint96(value),
                        coin.decimals()
                    )
                )
            );
        }

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "',
                    string.concat(displayValue, ' ', name),
                    '", "description": "ENCLOSED.MONEY - Turn Your Magic Internet Money Into an NFT -- Because, Why Not?!", "image": "data:image/svg+xml;base64,',
                    _renderedMetadata,
                    '"}'
                )
            )
        );

        return string.concat('data:application/json;base64,', json);
    }
}
