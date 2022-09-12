// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Bill.sol';

contract BillExample is Bill {
    function example1() public pure returns (string memory) {
        return
            render(
                'USDC',
                'USD Coin',
                0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
                0.00000005 ether,
                9
            );
    }

    function example() public pure returns (string memory) {
        return
            render(
                'USDT',
                'Tether USD',
                0xdAC17F958D2ee523a2206206994597C13D831ec7,
                0.00000000000431 ether,
                6
            );
    }
}
