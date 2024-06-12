// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/chainlink-brownie-contracts/contracts/src/v0.8//AutomationCompatible.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BritishAuction is AutomationCompatibleInterface{

    struct AuctionItem {
        address seller ; // 卖家地址
        address nftAddress; // NFT合约地址
        uint256 nftTokenId; // NFT Token ID
        uint256 startingPrice; // 起拍价
        uint256 currentHighestBid; // 当前最高出价
        address currentHighestBidder; // 当前最高出价者地址
        bool ended; // 拍卖是否结束
        uint256 totalBidAmount; // 总出价金额
        mapping(address => uint256) bidAmounts; // 每个竞拍者的出价金额
        address[] bidders; // 竞拍者列表
        uint256 startTime; // 拍卖开始时间
        uint256 endTime; // 拍卖结束时间    
        uint256 interval; // 拍卖间隔
    }
    
    mapping(address nftAddress => mapping(uint256 tokenId => uint256)) public auctionIdQuery;
    mapping(address nftAddress => mapping(uint256 tokenId => bool)) public isOnAuction;
    mapping(uint256 => AuctionItem) public auctions; // 拍卖ID与拍卖物品的映射
    mapping(address => uint256) public pendingReturns; // 竞拍者待领取的金额
    uint256 public nextAuctionId; // 下一个拍卖ID
    address payable public platformAddress; // 平台地址
    mapping(address => uint256) public balances; // 竞拍者个人中心余额

    event AuctionCreated(uint256 auctionId, address seller, uint256 startingPrice, uint256 _startTime, address nftAddress, uint256 tokenId); // 拍卖创建事件
    event HighestBidIncreased(uint256 auctionId, address bidder, uint256 amount); // 最高出价增加事件
    event AuctionEnded(uint256 auctionId, address winner, uint256 amount); // 拍卖结束事件
    event AuctionCancelled(uint256 auctionId); // 拍卖取消事件
    event RewardDistributed(uint256 auctionId, address bidder, uint256 reward); // 奖励分发事件
    event ReserveAdded(address indexed user, uint256 amount); // 添加余额事件

    constructor(address payable _platformAddress) {
        platformAddress = _platformAddress; // 设置平台地址
    }


    /**
     * 用户创建拍卖
     */
    function createAuction(uint256 _startingPrice, uint256 _startTime,  address nftAddress, uint256 nftTokenId, uint256 interval) public payable {
        require(_startTime >= block.timestamp, "Start time must be in the future");
        nextAuctionId++;
        auctionIdQuery[nftAddress][nftTokenId] = nextAuctionId;
        AuctionItem storage newItem = auctions[nextAuctionId];
        newItem.seller = msg.sender;
        newItem.startingPrice = _startingPrice;
        newItem.ended = false;
        newItem.startTime = _startTime;
        newItem.nftAddress = nftAddress;
        newItem.nftTokenId = nftTokenId;
        newItem.interval = interval;
        isOnAuction[nftAddress][nftTokenId] = true;
        emit AuctionCreated(nextAuctionId, msg.sender, _startingPrice, _startTime, nftAddress, nftTokenId); // 触发拍卖创建事件
    }

    /**
    * 用户对指定NFT进行出价竞拍
    */
    function bid(uint256 _itemId, uint256 bitAmount) public payable {
        // 进行竞拍
        AuctionItem storage item = auctions[_itemId];
        require(block.timestamp >= item.startTime, "Auction has not started yet"); // 确认拍卖已开始
        require(!item.ended, "Auction already ended"); // 确认拍卖未结束
        require(bitAmount < msg.value + balances[msg.sender], "Insufficient balance"); // 确认余额足够
        require(bitAmount > item.currentHighestBid, "There already is a higher bid"); // 确认出价高于当前最高出价
        
        balances[msg.sender] += msg.value; // 将用户余额增加
        uint256 previousBid = item.bidAmounts[msg.sender]; // 之前的出价金额

        uint256 additionalBid = bitAmount - previousBid; // 额外出价金额
        if (previousBid > 0) {
            item.totalBidAmount += additionalBid; // 更新总出价金额
        } else {
            item.totalBidAmount += additionalBid; // 更新总出价金额
            item.bidders.push(msg.sender); // 将新的竞拍者添加到竞拍者列表中
        }

        item.bidAmounts[msg.sender] = bitAmount; // 更新竞拍者的出价金额
        item.currentHighestBid = bitAmount; // 更新当前最高出价
        item.currentHighestBidder = msg.sender; // 更新当前最高出价者

        balances[msg.sender] -= additionalBid; // 更新用户余额，未使用的部分会在竞拍结束时返还
        item.endTime = block.timestamp + item.interval; // 更新拍卖结束时间
        emit HighestBidIncreased(_itemId, msg.sender, bitAmount); // 触发最高出价增加事件
    }

    /**
    * 用户取消拍卖
    */
    function cancelAuction(uint256 _itemId) public {
        AuctionItem storage item = auctions[_itemId];
        require(msg.sender == item.seller, "Only seller can cancel the auction");
        require(!item.ended, "Auction already ended"); 
        item.ended = true;
        isOnAuction[item.nftAddress][item.nftTokenId] = false;
        for (uint256 i = 0; i < item.bidders.length; i++) {
            address bidder = item.bidders[i];
            uint256 bidAmount = item.bidAmounts[bidder];
            if (bidAmount > 0) {
                item.bidAmounts[bidder] = 0;
                balances[bidder] += bidAmount;
            }
        }
        emit AuctionCancelled(_itemId); 
    }

    /**
    * 用户结束拍卖
    */
    function endAuction(uint256 _itemId) internal {
        // 结束拍卖
        AuctionItem storage item = auctions[_itemId];
        require(!item.ended, "Auction already ended"); // 确认拍卖未结束

        uint256 totalAmount = item.currentHighestBid; // 总成交金额
        uint256 platformFee = totalAmount * 3 / 1000; // 平台手续费0.3%
        uint256 sellerAmount = totalAmount * 967 / 1000; // 卖家所得金额96.7%
        uint256 pre_bidderReward = totalAmount * 30 / 1000; // 竞拍者奖励金额3%
        address highestBidder;
        // 从竞拍者列表中移除当前最高出价者（最后的成交者）
        for (uint i = 0; i < item.bidders.length; i++) {
            if (item.bidders[i] == item.currentHighestBidder) {
                highestBidder = item.bidders[i];
                item.bidders[i] = item.bidders[item.bidders.length - 1];
                item.bidders.pop();
                break;
            }
        }

        // 分配奖励
        for (uint i = 0; i < item.bidders.length; i++) {
            address bidder = item.bidders[i];
            uint256 bidderReward = item.bidAmounts[bidder] + (item.bidAmounts[bidder] * pre_bidderReward) / item.totalBidAmount; // 按比例分配
            pendingReturns[bidder] = bidderReward;
            withdrawPendingReturns(bidder);
            emit RewardDistributed(_itemId, bidder, bidderReward); // 触发奖励分发事件
        }
        payable(platformAddress).transfer(platformFee); 
        payable(item.seller).transfer(sellerAmount);
        IERC721(item.nftAddress).transferFrom(item.seller, highestBidder, item.nftTokenId);
        item.ended = true;
        isOnAuction[item.nftAddress][item.nftTokenId] = false;
        emit AuctionEnded(_itemId, item.currentHighestBidder, totalAmount); // 触发拍卖结束事件
    }


    /**
    * 用户提取个人中心余额
    */
    function withdrawBalance(uint256 amount) public {
        require (amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] = balances[msg.sender] - amount;
        payable(msg.sender).transfer(amount); 
    }

    /**
    * 用户提取竞拍者待领取金额
    */
    function withdrawPendingReturns(address bidder) internal {
        uint256 amount = pendingReturns[msg.sender];
        pendingReturns[bidder] = 0;
        payable(bidder).transfer(amount); 
    }

    /**
    * 用户向个人中心余额中添加ETH
    */
    function reserve() public payable {
        require(msg.value > 0, "Must send ETH to add to reserve");
        balances[msg.sender] += msg.value;
        emit ReserveAdded(msg.sender, msg.value); // 触发添加余额事件
    }

    receive() external payable {
        // 处理接收的ETH
        balances[msg.sender] += msg.value;
        emit ReserveAdded(msg.sender, msg.value); // 触发添加余额事件
    }


   /**
   * chainlink自动化合约接口,检查是否有拍卖需要结束
   */
   function checkUpkeep(bytes calldata /*checkData*/) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = false;
        uint256 auctionId;

        // 遍历拍卖ID列表，检查是否有拍卖需要结束
        for (uint256 i = 0; i < nextAuctionId; i++) {
            AuctionItem storage item = auctions[i];

            if (block.timestamp > item.endTime && !item.ended) {
                upkeepNeeded = true;
                performData = abi.encode(auctionId);
                break;
            }
        }
    }

   /**
   * chainlink自动化合约接口,结束拍卖
   */
    function performUpkeep(bytes calldata performData) external { 
        uint256 auctionId = abi.decode(performData, (uint256));
        endAuction(auctionId);
    }
}
