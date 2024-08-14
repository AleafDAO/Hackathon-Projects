// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "./Token.sol";
import "./NFT.sol";
import "./Tools/IsAdmin.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Admin {

    // address private NFTAddress;
    // address private tokenAddress;
    NFT private NFTA;
    Token private TokenA;
    IsAdmin private IsAdminA;
    IERC20 private USDT;
    address private admin;

    mapping (address => mapping (uint => uint)) AwardUSDT;
    mapping (address => mapping (uint => uint)) AwardToken;

    constructor(address _NFTAddress,address payable _tokenAddress,address _IsAdminAddress,address _USDTAddress) {
        // NFTAddress = _NFTAddress;
        // tokenAddress = _tokenAddress;
        NFTA = NFT(_NFTAddress);
        TokenA = Token(_tokenAddress);
        IsAdminA = IsAdmin(_IsAdminAddress);
        USDT = IERC20(_USDTAddress);
        admin = address(this);
    }

    modifier adminOnly {
        require(IsAdminA.isAdmin(msg.sender),"src::Admin:Admin Only.");
        _;
    }

    function rent(uint _tokenId) external {
        
        address _sender = msg.sender;
        address _owner = NFTA.ownerOf(_tokenId);

        (uint8 _number,uint256 _price,uint256 _awardUSDT,uint256 _awardToken,bool isRenting,,uint8 _totalNumber,address _mainOwner) = NFTA.getNFT(_tokenId);
        require(!isRenting,"src:::Admin::rent: The seat has been rent.");
        require(USDT.allowance(_mainOwner,address(this)) > NFTA.totalAllowance(_mainOwner));
        require(USDT.allowance(_sender,address(this)) > _price,"src:::Admin::rent: USDT Allowance Not Enough.");

        USDT.transferFrom(_sender,_owner,_price);
        NFTA.adminTransferFrom(_sender,_tokenId);
        NFTA.setNFT(_tokenId,_price,_number,_awardUSDT,_awardToken,true,false,_totalNumber,_mainOwner);

    }

    function award(uint _tokenId) public adminOnly {

        address _owner = NFTA.ownerOf(_tokenId);
        
        (uint8 _number,uint256 _price,uint256 _awardUSDT,uint256 _awardToken,bool _isRenting,bool _isSelling,uint8 _totalNumber,address _mainOwner) = NFTA.getNFT(_tokenId);
        require(_isRenting,"src:::Admin::award: NFT Wrong.");

        if (_isSelling) {
            AwardUSDT[_owner][_tokenId] += _awardUSDT;
        } else {
            AwardToken[_owner][_tokenId] += _awardToken;
        }

        
        if (_number == 1) {
            NFTA.setNFT(_tokenId, _price, _totalNumber, _awardUSDT, _awardToken, false, false, _totalNumber, _mainOwner);
            NFTA.adminTransferFrom(_mainOwner, _tokenId);
        } else {
            NFTA.setNFT(_tokenId, _price, _number-1, _awardUSDT, _awardToken, _isRenting, false, _totalNumber, _mainOwner);
        }
    }

    function buy(uint _tokenId) external adminOnly {

        (uint8 _number,uint256 _price,uint256 _awardUSDT,uint256 _awardToken,bool _isRenting,bool _isSelling,uint8 _totalNumber,address _mainOwner) = NFTA.getNFT(_tokenId);

        require(!_isSelling,"src:::Admin::buy: Seat Selled");

        NFTA.setNFT(_tokenId, _price, _number, _awardUSDT, _awardToken, _isRenting, true, _totalNumber, _mainOwner);

    }

    function film(uint8 _room) external adminOnly {

        for(uint8 i = 0;i < NFTA.seatsOfRoom(_room);i++){

            uint tokenId = NFTA.getTokenId(_room, i);

            (uint8 _number,uint256 _price,uint256 _awardUSDT,uint256 _awardToken,bool _isRenting,,uint8 _totalNumber,address _mainOwner) = NFTA.getNFT(tokenId);

            if (_isRenting) {
                award(tokenId);
            } else {
                NFTA.setNFT(tokenId, _price, _number, _awardUSDT, _awardToken, _isRenting, true, _totalNumber, _mainOwner);
            }

        }
        
    }

    function withdraw(uint _tokenId) external {

        address _sender = msg.sender;
        address _owner = NFTA.ownerOf(_tokenId);
        bool success = USDT.transferFrom(_owner,_sender,AwardUSDT[_sender][_tokenId]);
        require(success,"src:::Admin::withdraw: USTD transfer Fail.");
        AwardUSDT[_sender][_tokenId] = 0;

        TokenA.mint(_sender,AwardToken[_sender][_tokenId]);
        AwardToken[_sender][_tokenId] = 0;

    }


}