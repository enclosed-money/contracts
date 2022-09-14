// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error AlreadyAdded();

/// @title  Registry contract :: Adding popular token's data :: DAO Owned 
/// @notice This contract can be called by our main contract for fetching tokenData

contract Registry {

    ///  Address of the DAO
    address immutable owner_DAO;

    /// This struct contains necessary info about an ERC20 token
    /// What more params could be added?
    struct Token{
        string name;
        string symbol;
        uint8 UID;
    }
    
    /// Registry mapping ERC20 token address to its metadata
    mapping(address=>Token) tokenData;
    mapping(address=>bool)  isLegit;

    /// All functions to be called only by the DAO
    modifier isOwner() {
        require(msg.sender==owner_DAO);
        _;
    }
  
    /// msg.sender should be a DAO controlled address
    constructor(){
        owner_DAO = msg.sender;  
    }
    

    ///  DAO can update the token registry by adding new Token Details
    ///  Reverts if token already exists
    ///  @param  tokenAddress Address of the ERC20 token to be added
    ///  @param  tokenParams Token details in the struct format defined above
    ///  Returns true if successfully added

    function addData( address tokenAddress, Token memory tokenParams) isOwner external returns(bool){
        if( isLegit[tokenAddress] == true ){
            revert AlreadyAdded();
        }
        tokenData[tokenAddress] = tokenParams;
        isLegit[tokenAddress] = true;
        return true;
    }
    
}
