// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './DecimalStrings.sol';

contract Bill {
    function render(
        string memory symbol,
        string memory name,
        address erc20,
        uint96 value,
        uint8 decimals
    ) public pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:#000;font-family:Courier New">',
                '<text x="50%" y="50%" text-anchor="middle" fill="#fff" font-size="80" font-weight="bold">',
                DecimalStrings.decimalString(uint256(value), decimals, false),
                '</text>',
                '<text x="50%" y="64%" text-anchor="middle" fill="#fff" font-size="40">',
                symbol,
                '</text>',
                '<text x="20" y="310" fill="#999" font-size="16">',
                name,
                '</text>',
                '<text x="20" y="330" fill="#999" font-size="12">0x',
                addressToAsciiString(erc20),
                '</text>',
                '</svg>'
            );
    }

    function addressToAsciiString(address x)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
