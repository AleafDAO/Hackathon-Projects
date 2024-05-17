// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract EnglishAuction {
    struct AuctionItem {
        address seller; // 卖家地址
        uint256 startingPrice; // 起拍价
        uint256 currentHighestBid; // 当前最高出价
        address currentHighestBidder; // 当前最高出价者地址
        bool ended; // 拍卖是否结束
        uint256 totalBidAmount; // 总出价金额
        mapping(address => uint256) bidAmounts; // 每个竞拍者的出价金额
        address[] bidders; // 竞拍者列表
        uint256 startTime; // 拍卖开始时间
    }

    mapping(uint256 => AuctionItem) public auctions; // 拍卖ID与拍卖物品的映射
    mapping(address => uint256) public pendingReturns; // 竞拍者待领取的金额
    uint256 public nextAuctionId; // 下一个拍卖ID
    address payable public platformAddress; // 平台地址
    mapping(address => uint256) public balances; // 竞拍者个人中心余额

    event AuctionCreated(uint256 auctionId, address seller, uint256 startingPrice, uint256 _startTime); // 拍卖创建事件
    event HighestBidIncreased(uint256 auctionId, address bidder, uint256 amount); // 最高出价增加事件
    event AuctionEnded(uint256 auctionId, address winner, uint256 amount); // 拍卖结束事件
    event AuctionCancelled(uint256 auctionId); // 拍卖取消事件
    event RewardDistributed(uint256 auctionId, address bidder, uint256 reward); // 奖励分发事件
    event ReserveAdded(address indexed user, uint256 amount); // 添加余额事件

    constructor(address payable _platformAddress) {
        platformAddress = _platformAddress; // 设置平台地址
    }

    function createAuction(uint256 _startingPrice, uint256 _startTime) public payable {
        // 创建拍卖，要求卖家质押起拍价的20%
        require(msg.value >= (_startingPrice * 20 / 100), "Deposit must be at least 20% of starting price");
        require(_startTime > block.timestamp, "Start time must be in the future");

        nextAuctionId++;
        AuctionItem storage newItem = auctions[nextAuctionId];
        newItem.seller = msg.sender;
        newItem.startingPrice = _startingPrice;
        newItem.ended = false;
        newItem.startTime = _startTime;
        emit AuctionCreated(nextAuctionId, msg.sender, _startingPrice, _startTime); // 触发拍卖创建事件
    }

    function bid(uint256 _itemId) public payable {
        // 进行竞拍
        AuctionItem storage item = auctions[_itemId];
        require(block.timestamp >= item.startTime, "Auction has not started yet"); // 确认拍卖已开始
        require(!item.ended, "Auction already ended"); // 确认拍卖未结束
        require(msg.value + balances[msg.sender] > item.currentHighestBid, "There already is a higher bid"); // 确认出价高于当前最高出价

        uint256 totalBidAmount = msg.value + balances[msg.sender]; // 总出价金额
        uint256 previousBid = item.bidAmounts[msg.sender]; // 之前的出价金额

        if (previousBid > 0) {
            uint256 additionalBid = totalBidAmount - previousBid; // 额外出价金额
            item.totalBidAmount += additionalBid; // 更新总出价金额
        } else {
            item.bidders.push(msg.sender); // 将新的竞拍者添加到竞拍者列表中
        }

        item.bidAmounts[msg.sender] = totalBidAmount; // 更新竞拍者的出价金额
        item.currentHighestBid = totalBidAmount; // 更新当前最高出价
        item.currentHighestBidder = msg.sender; // 更新当前最高出价者

        balances[msg.sender] = 0; // 清空用户余额，未使用的部分会在竞拍结束时返还

        emit HighestBidIncreased(_itemId, msg.sender, totalBidAmount); // 触发最高出价增加事件
    }


    function cancelAuction(uint256 _itemId) public {
        // 取消拍卖
        AuctionItem storage item = auctions[_itemId];
        require(msg.sender == item.seller, "Only seller can cancel the auction"); // 确认只有卖家可以取消拍卖
        require(!item.ended, "Auction already ended"); // 确认拍卖未结束

        // 罚金为起拍价的20%的10%
        uint256 penaltyAmount = (item.startingPrice * 20 / 100) * 10 / 100;
        platformAddress.transfer(penaltyAmount); // 将罚金转入平台地址

        item.ended = true;
        emit AuctionCancelled(_itemId); // 触发拍卖取消事件
    }

    function endAuction(uint256 _itemId) public {
        // 结束拍卖
        AuctionItem storage item = auctions[_itemId];
        require(msg.sender == item.seller, "Only seller can end the auction"); // 确认只有卖家可以结束拍卖
        require(!item.ended, "Auction already ended"); // 确认拍卖未结束

        uint256 totalAmount = item.currentHighestBid; // 总成交金额
        uint256 platformFee = totalAmount * 2 / 100; // 平台手续费2%
        uint256 sellerAmount = totalAmount * 95 / 100; // 卖家所得金额95%
        uint256 pre_bidderReward = totalAmount * 3 / 100; // 竞拍者奖励金额3%

     // 从竞拍者列表中移除当前最高出价者（最后的成交者）
    for (uint i = 0; i < item.bidders.length; i++) {
        if (item.bidders[i] == item.currentHighestBidder) {
            item.bidders[i] = item.bidders[item.bidders.length - 1];
            item.bidders.pop();
            break;
        }
    }

    // 分配奖励
    for (uint i = 0; i < item.bidders.length; i++) {
        address bidder = item.bidders[i];
        uint256 bidderReward = (item.bidAmounts[bidder] * pre_bidderReward) / item.totalBidAmount; // 按比例分配
        pendingReturns[bidder] += bidderReward;
        emit RewardDistributed(_itemId, bidder, bidderReward); // 触发奖励分发事件
    }
        platformAddress.transfer(platformFee); // 转移平台手续费
        payable(item.seller).transfer(sellerAmount); // 转移卖家所得金额

        item.ended = true;
        emit AuctionEnded(_itemId, item.currentHighestBidder, totalAmount); // 触发拍卖结束事件
    }

    function withdraw() public {
    // 提现待领取的金额和个人中心余额
    uint256 amount = pendingReturns[msg.sender];
    uint256 balanceAmount = balances[msg.sender];
    uint256 totalAmount = amount + balanceAmount; // 计算总提现金额

    require(totalAmount > 0, "No pending returns or balance"); // 确认有待领取金额或个人中心余额

    pendingReturns[msg.sender] = 0;
    balances[msg.sender] = 0;

    payable(msg.sender).transfer(totalAmount); // 转移待领取金额和个人中心余额到竞拍者地址
    }
    
    function reserve() public payable {
        // 增加余额
        require(msg.value > 0, "Must send ETH to add to reserve");
        balances[msg.sender] += msg.value;
        emit ReserveAdded(msg.sender, msg.value); // 触发添加余额事件
    }

    function getBalance() public view returns (uint256) {
        // 获取个人中心余额
        return balances[msg.sender];
    }
}
