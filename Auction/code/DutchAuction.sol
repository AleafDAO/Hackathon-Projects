// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DutchAuction is Ownable {
    struct Auction {
        address payable seller;
        address nftContract;
        uint256 tokenId;
        uint256 startPrice;
        uint256 reservePrice;
        uint256 startTime;
        uint256 endTime;
        uint256 deposit;
        bool isActive;
    }

    uint256 public constant FEE_PERCENTAGE = 4;
    uint256 public constant DEPOSIT_PERCENTAGE = 10;
    uint256 public constant PRICE_DECAY_INTERVAL = 3 minutes;
    uint256 public constant PRICE_DECAY_PERCENTAGE = 5;
    uint256 public constant RESERVE_DURATION = 5 minutes;

    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCount;

    event AuctionStarted(uint256 indexed auctionId, address indexed seller, uint256 tokenId, uint256 startPrice, uint256 reservePrice, uint256 startTime);
    event AuctionEnded(uint256 indexed auctionId, address indexed buyer, uint256 finalPrice);
    event AuctionFailed(uint256 indexed auctionId);

    // 构造函数，设置初始所有者
    constructor() Ownable(msg.sender) {}

    // 开始拍卖的方法
    function startAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 reservePrice,
        uint256 startTime
    ) external payable {
        require(startPrice > reservePrice, "Start price must be greater than reserve price");
        uint256 deposit = (startPrice * DEPOSIT_PERCENTAGE) / 100;
        require(msg.value == deposit, "Incorrect deposit amount");

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        auctionCount++;
        auctions[auctionCount] = Auction({
            seller: payable(msg.sender),
            nftContract: nftContract,
            tokenId: tokenId,
            startPrice: startPrice,
            reservePrice: reservePrice,
            startTime: startTime,
            endTime: startTime + ((startPrice - reservePrice) / ((startPrice * PRICE_DECAY_PERCENTAGE) / 100)) * PRICE_DECAY_INTERVAL + RESERVE_DURATION,
            deposit: deposit,
            isActive: true
        });

        emit AuctionStarted(auctionCount, msg.sender, tokenId, startPrice, reservePrice, startTime);
    }

    // 获取当前价格的方法
    function getCurrentPrice(uint256 auctionId) public view returns (uint256) {
        Auction memory auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");

        if (block.timestamp >= auction.endTime - RESERVE_DURATION) {
            return auction.reservePrice;
        }

        uint256 elapsedTime = block.timestamp - auction.startTime;
        uint256 decaySteps = elapsedTime / PRICE_DECAY_INTERVAL;
        uint256 decayAmount = (auction.startPrice * PRICE_DECAY_PERCENTAGE * decaySteps) / 100;
        return auction.startPrice > decayAmount ? auction.startPrice - decayAmount : auction.reservePrice;
    }

    // 竞拍的方法
    function bid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        uint256 currentPrice = getCurrentPrice(auctionId);
        require(msg.value >= currentPrice, "Bid amount is too low");

        uint256 fee = (currentPrice * FEE_PERCENTAGE) / 100;
        uint256 sellerProceeds = currentPrice - fee;

        auction.isActive = false;
        payable(owner()).transfer(fee); // 平台收取手续费
        auction.seller.transfer(sellerProceeds); // 卖家收到拍卖款项
        auction.seller.transfer(auction.deposit); // 退还押金
        if (msg.value > currentPrice) {
            payable(msg.sender).transfer(msg.value - currentPrice); // 退还多余的ETH
        }
        
        IERC721(auction.nftContract).transferFrom(address(this), msg.sender, auction.tokenId);

        emit AuctionEnded(auctionId, msg.sender, currentPrice);
    }

    // 流拍处理的方法
    function finalizeAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(auction.isActive, "Auction is not active");
        require(block.timestamp > auction.endTime, "Auction has not ended yet");

        auction.isActive = false;
        IERC721(auction.nftContract).transferFrom(address(this), auction.seller, auction.tokenId);
        
        uint256 penalty = (auction.deposit * 10) / 100;
        payable(owner()).transfer(penalty); // 平台没收10%押金
        auction.seller.transfer(auction.deposit - penalty); // 退还剩余的押金

        emit AuctionFailed(auctionId);
    }

    // 仅管理员可以调用的提取押金的方法
    function withdrawDeposit(uint256 auctionId) external onlyOwner {
        Auction storage auction = auctions[auctionId];
        require(!auction.isActive, "Auction is still active");

        uint256 penalty = (auction.deposit * 10) / 100;
        payable(owner()).transfer(penalty); // 平台没收10%押金
        auction.seller.transfer(auction.deposit - penalty); // 退还剩余的押金
    }
}
