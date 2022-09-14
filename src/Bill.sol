// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./utils/DecimalStrings.sol";

contract Bill {
    function render(
        string memory symbol,
        string memory name,
        address erc20,
        uint96 value,
        uint8 decimals
    )
        public
        pure
        returns (string memory)
    {
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="290" height="500" viewbox = "0 0 290 500" style="background:#000;font-family:Courier New ">',
            '<defs> <path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V460 A28 28 0 0 1 250 488 H40 A28 28 0 0 1 12 460 V40 A28 28 0 0 1 40 12 z" /> </defs>',
            '<rect x="16" y="16" width="258" height="468" rx="26" ry="26" fill="rgba(0, 0, 0, 0)" stroke="rgba(255, 255, 255, 0.2)" style="stroke-width:2   ;fill-opacity:0.1;stroke-opacity:0.9" />',
            '<text x="40.5%" y="20%" text-anchor="middle" fill="#fff" font-size="80" font-weight="light">',
            DecimalStrings.decimalString(uint256(value), decimals, false),
            "</text>",
            '<text x="27.5%" y="30%" text-anchor="middle" fill="#fff" font-size="40">',
            symbol,
            "</text>",
            '<text text-rendering="optimizeSpeed">',
            '<textPath startOffset="-100%" fill="white" font-family="Courier New" font-size="10px" xlink:href="#text-path-a">Wrapping tokens into an NFT by Enclosed.money <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>',
            '<textPath startOffset="0%" fill="white" font-family="Courier New" font-size="10px" xlink:href="#text-path-a">Wrapping tokens into an NFT by Enclosed.money <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>',
            '<textPath startOffset="50%" fill="white" font-family="Courier New" font-size="10px" xlink:href="#text-path-a">',
            name,
            " .",
            addressToAsciiString(erc20),
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>',
            '<textPath startOffset="-50%" fill="white" font-family="Courier New" font-size="10px" xlink:href="#text-path-a">',
            name,
            " .",
            addressToAsciiString(erc20),
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>',
            "</text>",
            "</svg>"
        );
    }

    function addressToAsciiString(address x)
        internal
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b =
                bytes1(uint8(uint256(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) {
            return bytes1(uint8(b) + 0x30);
        } else {
            return bytes1(uint8(b) + 0x57);
        }
    }
}
