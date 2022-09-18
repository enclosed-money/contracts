// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title  Registry contract :: Checking if a token is verified
/// @notice This contract can be called by our main contract for checking if the ERC20 token address is verified by the DAO

contract Registry is Ownable {
    mapping(address => bool) public verified;

    event ChangedVerificationStatus(address indexed erc20, bool value);

    /// @notice Sets verification status of the ERC20 address in the above mapping 
    /// @param tokenAddress ERC20 token address
    /// @param _verified The boolean value to switch to

    function setERC20Status(address tokenAddress, bool _verified)
        public
        onlyOwner
    {
        verified[tokenAddress] = _verified;
        emit ChangedVerificationStatus(tokenAddress, _verified);
    }

    function setERC20StatusBatched(
        address[] memory tokenAdrList,
        bool[] memory values
    )
        public
        onlyOwner
    {
        for (uint256 i = 0; i < tokenAdrList.length; i++) {
            setERC20Status(tokenAdrList[i], values[i]);
        }
    }
}


