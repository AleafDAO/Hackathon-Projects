// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Tools/IsAdmin.sol";

contract NFT is ERC721 {

    IsAdmin private isAdmin;
    IERC20 private USDT;

    address private owner;
    address private admin;

    string public baseTokenURI;

    struct NFTMessage {
        uint8 number;
        uint256 price;
        uint256 awardUSDT;
        uint256 awardToken;
        bool isRenting;
        bool isSelling;
        uint8 totalNumber;
        address mainOwner;
        
    }

    // mapping (uint => uint8) public totalNumber;
    mapping (uint => NFTMessage) public getNFT;
    mapping (uint8 => mapping (uint8 => uint)) public seat;
    mapping (uint8 => uint8) public seatsOfRoom;
    mapping (address => uint) public totalAllowance;

    constructor(string memory _name,string memory _symbol,address _IsAdmin,address _USDT) ERC721(_name,_symbol){
        isAdmin = IsAdmin(_IsAdmin);
        USDT = IERC20(_USDT);
        owner = msg.sender;

    }


    // uint public Max = 10000;

    modifier adminOnly {
        require(isAdmin.isAdmin(msg.sender),"contract:::NFTDemo::NFTDemo:Admin Only.");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setAdmin(address _Admin) external adminOnly{
        require(msg.sender == owner,"src:::NFT::setAdmin: Owner Only.");
        admin = _Admin;
    }

    function mint(uint tokenId,string memory _baseTokenURI,uint8 _room,uint8 _seat,uint8 _number,uint256 _price,uint256 _awardUSDT,uint256 _awardToken) external adminOnly{
        // require(tokenId>0 && tokenId<Max,"contract:::NFTDemo::NFTDemo:tokenId out of range");
        totalAllowance[msg.sender] += _awardUSDT*_number;
        require(USDT.allowance(msg.sender,admin) > totalAllowance[msg.sender],"src:::NFT::mint: USDT Allowance Not Enough.");
        baseTokenURI = _baseTokenURI;
        _mint(msg.sender, tokenId);
        seat[_room][_seat] = tokenId;
        NFTs.push(NFTMessage(0, 0, 0, 0, true, false, 0, msg.sender));
        setNFT(tokenId, _price, _number, _awardUSDT, _awardToken, false, false, _number, msg.sender);
        
    }

    // function getOwner(uint256 tokenId) public view returns (address) {
    //     return ownerOf(tokenId);
    // }

    function adminTransferFrom(address to,uint tokenId) adminOnly external {
        _adminUpdate(to, tokenId);
    }

    function setNFT(uint _tokenId,uint256 _price,uint8 _number,uint256 _awardUSDT,uint256 _awardToken,bool _isRenting,bool _isSelling,uint8 _totalNumber,address _mainOwner) adminOnly public {
        getNFT[_tokenId].price = _price;
        getNFT[_tokenId].number = _number;
        getNFT[_tokenId].awardUSDT = _awardUSDT;
        getNFT[_tokenId].awardToken = _awardToken;
        getNFT[_tokenId].isRenting = _isRenting;
        getNFT[_tokenId].isSelling = _isSelling;
        getNFT[_tokenId].totalNumber = _totalNumber;
        getNFT[_tokenId].mainOwner = _mainOwner;
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