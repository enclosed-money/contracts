// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './Metadata.sol';
import 'openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol';
import 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';

contract NFTBill is ERC1155 {
    MetadataURI public metadata;

    constructor(MetadataURI _metadata) ERC1155('') {
        metadata = _metadata;
    }

    function deposit() external payable {
        require(msg.value > 0, 'Send at least 1 wei');
        require(msg.value <= type(uint96).max, 'Too much ETH');

        uint256 id = msg.value;
        _mint(msg.sender, id, 1, '');
    }

    function deposit(address erc20, uint96 value) external {
        require(value > 0, 'Send at least some coins');

        // The caller is expected to have `approve()`d this contract
        // for the amount being deposited
        ERC20(erc20).transferFrom(msg.sender, address(this), value);
        // TODO: What if we get less tokens than we asked for?
        uint256 id = (uint256(uint160(erc20)) << 96) | value;
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
