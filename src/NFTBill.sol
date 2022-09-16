// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-contracts/contracts/utils/cryptography/draft-EIP712.sol';
import 'openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/extensions/draft-IERC20Permit.sol';

import {IMetadata} from './interfaces/IMetadata.sol';

error ValueTooSmall();
error ValueTooLarge();
error DeadlineExceeded();
error SignerNotOwner();

contract NFTBill is ERC1155, EIP712 {
    event Approval(address indexed owner, address indexed spender, uint256 id, uint256 amount);

    IMetadata public metadata;

    // Mapping from tokenID -> owner -> spender -> value
    mapping (uint256 => mapping(address => mapping(address => uint256))) public allowances;
    mapping(address => uint256) public nonces;

    constructor(IMetadata _metadata) ERC1155('') EIP712("NFTBill", "1") {
        metadata = _metadata;
    }

    function deposit() external payable {
        uint256 value = msg.value;
        if (value <= 0) revert ValueTooSmall();
        if (value >= type(uint96).max) revert ValueTooLarge();

        _mint(msg.sender, value, 1, '');
    }

    function deposit(address erc20, uint96 value) external {
        if (value <= 0) revert ValueTooSmall();

        // The caller is expected to have `approve()`d this contract
        // for the amount being deposited
        ERC20(erc20).transferFrom(msg.sender, address(this), value);
        // TODO: What if we get less tokens than we asked for?
        uint256 id;
        assembly {
            id := or(value, shl(96, erc20))
        }

        _mint(msg.sender, id, 1, '');
    }

    function getDomainSeparator() external view returns(bytes32) {
        return _domainSeparatorV4();
    }

    function permit(
        uint256 id,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (deadline > block.timestamp) revert DeadlineExceeded();

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 structHash = keccak256(
                abi.encode(
                    keccak256(
                        "Permit(uint256 id,address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                    ),
                    id,
                    owner,
                    spender,
                    value,
                    nonces[owner]++,
                    deadline
                )
            );

            bytes32 hash = _hashTypedDataV4(structHash);
            address recoveredAddress = ECDSA.recover(hash, v, r, s);

            if (recoveredAddress != owner) revert SignerNotOwner();

            allowances[id][recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, id, value);
    }

    function withdraw(uint256 id) external {
        _burn(msg.sender, id, 1);
        address erc20 = address(uint160(id >> 96));
        uint96 value = uint96(id);

        if (erc20 == address(0)) {
            (bool ok, bytes memory data) = msg.sender.call{value: value}('');
            require(ok, string(data));
        } else {
            ERC20(erc20).transfer(msg.sender, value);
        }
    }

    function uri(uint256 id) public view override returns (string memory) {
        return metadata.uri(id);
    }
}
