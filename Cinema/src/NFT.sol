// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./Tools/IsAdmin.sol";

contract NFT is ERC721 {

    IsAdmin private isAdmin;

    string public baseTokenURI;

    struct NFTMessage {
        uint256 price;
        uint8 number;
        bool isRenting;
        bool isSelling;
    }

    mapping (uint => NFTMessage) public getNFT;
    mapping (uint8 => mapping (uint8 => uint)) public seat;
    mapping (uint8 => uint8) public seatsOfRoom;

    constructor(string memory _name,string memory _symbol,address _IsAdmin) ERC721(_name,_symbol){
        isAdmin = IsAdmin(_IsAdmin);
    }


    // uint public Max = 10000;

    modifier adminOnly {
        require(isAdmin.isAdmin(msg.sender),"contract:::NFTDemo::NFTDemo:Admin Only.");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function mint(uint tokenId,string memory _baseTokenURI,uint8 _room,uint8 _seat) external {
        // require(tokenId>0 && tokenId<Max,"contract:::NFTDemo::NFTDemo:tokenId out of range");
        baseTokenURI = _baseTokenURI;
        _mint(msg.sender, tokenId);
        seat[_room][_seat] = tokenId;
        NFTs.push(NFTMessage(10, 0, true,false));
        setNFT(tokenId, 10, 0, true, false);
    }

    function getOwner(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId);
    }

    function adminTransferFrom(address to,uint tokenId) adminOnly external {
        _adminUpdate(to, tokenId);
    }

    function setNFT(uint _tokenId,uint256 _price,uint8 _number,bool _isRenting,bool _isSelling) adminOnly public {
        getNFT[_tokenId].price = _price;
        getNFT[_tokenId].number = _number;
        getNFT[_tokenId].isRenting = _isRenting;
        getNFT[_tokenId].isSelling = _isSelling;
        NFTs[_tokenId] = getNFT[_tokenId];
    }

    function setSeatsNumber(uint8 _room,uint8 _seats) external {
        seatsOfRoom[_room] = _seats;
    }

    function getTokenId(uint8 _room,uint8 _seat) public view returns (uint256) {
        return seat[_room][_seat];
    }





    NFTMessage[] public NFTs;

    function getAllNFT() external view returns (NFTMessage[] memory) {
        return NFTs;
    }


}