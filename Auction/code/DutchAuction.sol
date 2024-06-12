// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/chainlink-brownie-contracts/contracts/src/v0.8//AutomationCompatible.sol";

contract DutchAuction is Ownable, AutomationCompatibleInterface{

    struct Auction {
        address payable seller;
        address nftAddress;
        uint256 tokenId;
        uint256 startPrice;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        uint256 price_decay_interval;
        uint256 price_decay_amount;
        uint256 reserve_duration;
        bool isActive;
    }

    mapping(address nftAddress => mapping(uint256 tokenId => uint256)) public auctionIdQuery;
    mapping(address nftAddress => mapping(uint256 tokenId => bool)) public isOnAuction;
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCount;
    uint256 public constant FEE_PERCENTAGE = 3;   //手续费设置千分之三

    event AuctionStarted(uint256 indexed auctionId, address indexed seller, uint256 tokenId, uint256 startPrice, uint256 reservePrice, uint256 startTime, address nftAddress, uint256 endTime);
    event AuctionEnded(uint256 indexed auctionId, address indexed buyer, uint256 finalPrice);
    event AuctionFailed(uint256 indexed auctionId);
    
    constructor() Ownable(msg.sender) {}

    /**
    * 用户创建拍卖
    */
    function startAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 startPrice,
        uint256 reservePrice,
        uint256 startTime,
        uint256 price_decay_interval,
        uint256 price_decay_amount,
        uint256 reserve_duration
    ) external payable {
        require(startPrice > reservePrice, "Start price must be greater than reserve price");
        require(startTime >= block.timestamp, "Start time must be in the future");
        auctionCount++;
        uint256 endTime = startTime + ((startPrice - reservePrice) / price_decay_amount) * price_decay_interval + reserve_duration;
        auctions[auctionCount] = Auction({
            seller: payable(msg.sender),
            nftAddress: nftAddress,
            tokenId: tokenId,
            startPrice: startPrice,
            reservePrice: reservePrice,
            startTime: startTime,
            endTime: endTime,
            isActive: true,
            price_decay_amount: price_decay_amount,
            price_decay_interval: price_decay_interval,
            reserve_duration: reserve_duration
        }); 
        auctionIdQuery[nftAddress][tokenId] = auctionCount;
        isOnAuction[nftAddress][tokenId] = true;
        emit AuctionStarted(auctionCount, msg.sender, tokenId, startPrice, reservePrice, startTime, nftAddress, endTime);
    }

    /**
    * 计算当前拍品的价格
    */
    function getCurrentPrice(uint256 auctionId) public view returns (uint256) {
        Auction memory auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        if (block.timestamp >= auction.endTime - auction.reserve_duration) {
            return auction.reservePrice;
        }
        uint256 elapsedTime = block.timestamp - auction.startTime;
        uint256 decaySteps = elapsedTime / auction.price_decay_interval;
        uint256 decayAmount = decaySteps * auction.price_decay_amount;
        uint256 currentPrice = auction.startPrice - decayAmount;
        return currentPrice;
    }
    
    /**
    * 用户对指定NFT进行竞拍
    */
    function bid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        uint256 currentPrice = getCurrentPrice(auctionId);
        require(msg.value >= currentPrice, "Bid amount is too low");

        uint256 fee = (currentPrice * FEE_PERCENTAGE) / 1000;
        uint256 sellerProceeds = currentPrice - fee;

        auction.isActive = false;
        payable(owner()).transfer(fee); // 平台收取手续费
        auction.seller.transfer(sellerProceeds); // 卖家收到拍卖款项
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice); // 退还多余的ETH
        }
        
        IERC721(auction.nftAddress).transferFrom(auction.seller, msg.sender, auction.tokenId);
        emit AuctionEnded(auctionId, msg.sender, currentPrice);
    }

    /**
    * 用户取消拍卖
    */
    function finalizeAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        auction.isActive = false;
        isOnAuction[auction.nftAddress][auction.tokenId] = false;
        emit AuctionFailed(auctionId);
    }

    /**
    * 拍卖时间截止自动结束拍卖
    */
    function withdrawDeposit(uint256 auctionId) internal {
        Auction storage auction = auctions[auctionId];
        auction.isActive = false;
        isOnAuction[auction.nftAddress][auction.tokenId] = false;
    }

    /**
    * chainlink自动化合约接口,检查是否有拍卖需要结束
    */
    function checkUpkeep(bytes calldata /*checkData*/) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        uint256 auctionId;

        for (uint256 i = 0; i < auctionCount; i++) {
            Auction storage auction = auctions[i];

            if (block.timestamp > auction.endTime && auction.isActive) {
                upkeepNeeded = true;
                performData = abi.encode(auctionId);
                break;
            }
        }
    }

    /**
    * chainlink自动化合约接口,执行结束拍卖
    */
    function performUpkeep(bytes calldata performData) external { 
        uint256 auctionId = abi.decode(performData, (uint256));
        withdrawDeposit(auctionId);
    }
}
