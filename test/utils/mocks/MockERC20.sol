// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
    string public constant tokenName = 'Mock Token';
    string public constant tokenSymbol = 'MTKN';

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public nonces;

    constructor() ERC20(tokenName, tokenSymbol) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
                ),
                keccak256(bytes(tokenName)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            'UniswapV2: INVALID_SIGNATURE'
        );
        _approve(owner, spender, value);
    }
}
