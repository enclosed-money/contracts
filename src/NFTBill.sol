// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

import {IMetadata} from './interfaces/IMetadata.sol';

error ValueTooSmall();
error ValueTooLarge();

contract NFTBill is ERC1155 {
    IMetadata public metadata;

    constructor(IMetadata _metadata) ERC1155('') {
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
