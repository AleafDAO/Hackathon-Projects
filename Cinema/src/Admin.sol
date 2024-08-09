// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "./Token.sol";
import "./NFT.sol";
import "./Tools/IsAdmin.sol";

contract Admin {

    // address private NFTAddress;
    // address private tokenAddress;
    NFT private NFTA;
    Token private TokenA;
    IsAdmin private IsAdminA;
    address private admin;

    constructor(address _NFTAddress,address payable _tokenAddress,address _IsAdminAddress) {
        // NFTAddress = _NFTAddress;
        // tokenAddress = _tokenAddress;
        NFTA = NFT(_NFTAddress);
        TokenA = Token(_tokenAddress);
        IsAdminA = IsAdmin(_IsAdminAddress);
        admin = address(this);
    }

    modifier adminOnly {
        require(IsAdminA.isAdmin(msg.sender),"src::Admin:Admin Only.");
        _;
    }

    function rent(uint _tokenId,uint8 _number) external {
        
        address _sender = msg.sender;

        (uint256 price,,bool isRenting,) = NFTA.getNFT(_tokenId);
        require(!isRenting,"src:::Admin::rent: The seat has been rent.");
        uint256 value = price*_number;

        require(TokenA.balanceOf(_sender) > value,"src:::Admin::rent: BALANCE NOT ENOUGH.");
        TokenA.burn(_sender,price);
        NFTA.adminTransferFrom(_sender,_tokenId);
        NFTA.setNFT(_tokenId,price,_number,true,false);

    }

    function award(uint _tokenId) public adminOnly {
        
        (uint256 price,uint8 number,bool isRenting,bool isSelling) = NFTA.getNFT(_tokenId);
        require(isRenting,"src:::Admin::award: NFT Wrong.");
        require(!isSelling,"src:::Admin::award: Seat Selled");

        address NFTOwner = NFTA.ownerOf(_tokenId); 

        TokenA.mint(NFTOwner,2*price);

        if (number == 1) {
            NFTA.setNFT(_tokenId, price, 0, false,false);
            NFTA.adminTransferFrom(admin, _tokenId);
        } else {
            NFTA.setNFT(_tokenId, price, number-1, isRenting, false);
        }
    }

    function buy(uint _tokenId) external adminOnly {

        (uint256 price,uint8 number,bool isRenting,bool isSelling) = NFTA.getNFT(_tokenId);

        require(!isSelling,"src:::Admin::buy: Seat Selled");

        NFTA.setNFT(_tokenId, price, number, isRenting, true);

    }

    function film(uint8 _room) external adminOnly {

        for(uint8 i = 0;i < NFTA.seatsOfRoom(_room);i++){

            uint tokenId = NFTA.getTokenId(_room, i);

            (uint256 price,uint8 number,bool isRenting,bool isSelling) = NFTA.getNFT(tokenId);

            if (isRenting) {
                if (isSelling) {
                    NFTA.setNFT(tokenId, price, number, isRenting, false);
                } else {
                    award(tokenId);
                }
            } else {
                if (isSelling) {
                    NFTA.setNFT(tokenId, price, number, isRenting, false);
                } else {

                }
            }

        }
        
    }


}