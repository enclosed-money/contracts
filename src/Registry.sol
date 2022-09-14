// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title  Registry contract :: Checking if a token's legit
/// @notice This contract can be called by our main contract for checking if the ERC20 token address is legit

contract Registry is Ownable {
    mapping(address => bool) isLegit;

    event TokenSetTo(address indexed, bool value);

    /// @notice To be called by the DAO, this switches ERC20 address in the isLegit mapping
    /// @param tokenAddress ERC20 token address
    /// @param _bool The value we want to switch to

    function setIsLegit(address tokenAddress, bool _bool) public onlyOwner {
        if (_bool == true) {
            isLegit[tokenAddress] = true;
            emit TokenSetTo(tokenAddress, true);
        } else {
            delete isLegit[tokenAddress];
            emit TokenSetTo(tokenAddress, false);
        }
    }

    /// @notice Struct for calling setIsLegit in a batched format
    /// @param n Length of the Array
    /// @param addressesList List of ERC20token addresses
    /// @param valuesList Their respective value we want to switch to
    struct BatchedData {
        uint8 n;
        address[] addressesList;
        bool[] valueList;
    }

    /// @notice Helps in switching ERC20 Token value in batches
    /// @param _BatchedData See above struct
    
    function setIsLegitBatched(BatchedData memory _BatchedData)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _BatchedData.n; i++) {
            setIsLegit(_BatchedData.addressesList[i], _BatchedData.valueList[i]);
        }
    }
}
