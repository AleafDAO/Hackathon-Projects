* # 富于激励竞拍者的英式拍卖： 

1. **合约结构设计**：
   - 设计合约结构，包括拍卖状态、拍卖物品信息、竞拍者信息等。
   - ***拍卖状态（AuctionState）***：使用枚举类型表示拍卖的不同状态，如创建中、进行中、已结束等。 
   - ***拍卖物品信息（AuctionItem）***：使用结构体存储每个拍卖物品的详细信息，包括拍卖者地址、物品名称、起拍价、当前最高出价、当前最高出价者、拍卖结束时间等。
   - ***竞拍者信息（Bidder）***：使用结构体存储每个竞拍者的信息，包括竞拍者地址、出价金额等。
   - ***拍卖物品映射（mapping）***：使用映射存储拍卖物品的编号和对应的拍卖信息。
   - ***竞拍者出价记录映射（mapping）***：使用映射存储每个拍卖物品的编号和对应的竞拍者出价记录。
   ### 在 Solidity 中，映射（mapping）是一种用于存储键值对的数据结构，类似于其他编程语言中的字典或关联数组。映射由键和值组成，其中键是唯一的，并且可以是任意可哈希的数据类型，而值可以是任意类型的数据。
   在拍卖合约中，可以使用映射来存储拍卖物品的编号和对应的拍卖信息，以及存储每个拍卖物品的编号和对应的竞拍者出价记录。

   - 示例代码如下所示：

   ```solidity
   contract EnglishAuction {
    struct AuctionItem {
        address seller;
        uint256 startingPrice;
        // other fields
    }
    
    mapping(uint256 => AuctionItem) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;
    uint256 public nextAuctionId;
    
    function createAuction(uint256 _startingPrice) public {
        nextAuctionId++;
        auctions[nextAuctionId] = AuctionItem({
            seller: msg.sender,
            startingPrice: _startingPrice
        });
    }
    
    function placeBid(uint256 _auctionId, uint256 _amount) public {
        bids[_auctionId][msg.sender] = _amount;
    }


   - 在这个示例中，` auctions `是一个映射，用于存储拍卖物品的编号和对应的拍卖信息。而 ` bids ` 是一个双重映射，用于存储每个拍卖物品的编号和对应的竞拍者出价记录。其中，外部映射的键是拍卖物品的编号，内部映射的键是竞拍者的地址，值是竞拍者的出价金额。

2. **初始化**：
   - 设置合约的起拍价、拍卖者信息等。
   - 定义一个结构体用于存储拍卖物品的信息，包括拍卖者地址、起拍价等。
   - 定义一个 mapping 用于存储拍卖物品的编号和对应的拍卖信息。
   - 编写一个函数用于创建拍卖，该函数将拍卖物品信息存储到 mapping 中，并设置起拍价和拍卖者信息。
   *示例：*
   ```solidity
   contract EnglishAuction {
    struct AuctionItem {
        address seller;
        uint256 startingPrice;
        // other fields
    }

    mapping(uint256 => AuctionItem) public auctions;
    uint256 public nextAuctionId;
    
    function createAuction(uint256 _startingPrice) public {
        nextAuctionId++;
        auctions[nextAuctionId] = AuctionItem({
            seller: msg.sender,
            startingPrice: _startingPrice
        });
    }
   } 
   ```
   在这个示例中，`createAuction` 函数用于创建拍卖，并接收一个参数 `_startingPrice`，即起拍价。在函数内部，将 `msg.sender`（即调用该函数的账户地址）作为卖家地址，并将 `_startingPrice` 存储为起拍价。创建完成后，可以通过 `auctions[auctionId]` 来查看对应拍卖的起拍价和卖家地址。

3. **发起拍卖**：
   - 卖家发起拍卖，质押起拍价的20%。
     在合约中实现发起拍卖并质押起拍价的20%可以按照以下步骤进行： 
   - 1. 定义一个结构体用于存储拍卖物品的信息，包括卖家地址、起拍价、质押比例等。
   - 2. 定义一个 mapping 用于存储拍卖物品的编号和对应的拍卖信息。
   - 3. 编写一个函数用于创建拍卖，该函数将拍卖物品信息存储到 mapping 中，并要求卖家质押起拍价的20%。
   - 4. 使用 msg.value 来获取卖家发送的以太币，确保发送的金额符合要求。
*Example:*
```solidity
contract EnglishAuction {
    struct AuctionItem {
        address seller;
        uint256 startingPrice;
        uint256 depositPercentage;
        bool exists;
    }

    mapping(uint256 => AuctionItem) public auctions;
    uint256 public nextAuctionId;

    function createAuction(uint256 _startingPrice, uint256 _depositPercentage) public payable {
        require(_depositPercentage > 0 && _depositPercentage <= 100, "Invalid deposit percentage");
        require(msg.value >= (_startingPrice * _depositPercentage / 100), "Insufficient deposit");

        nextAuctionId++;
        auctions[nextAuctionId] = AuctionItem({
            seller: msg.sender,
            startingPrice: _startingPrice,
            depositPercentage: _depositPercentage,
            exists: true
        });
    }
}
    - 在这个示例中，createAuction 函数用于创建拍卖，要求卖家发送的以太币必须大于或等于起拍价乘以质押比例的20%。如果发送的金额不足，则会触发 `require` 异常。

4. **竞拍**：
   - 允许竞拍者进行出价。
```solidity
contract EnglishAuction {
    // 定义拍卖物品结构体
    struct AuctionItem {
        address seller;                 // 卖家地址
        uint256 startingPrice;          // 起拍价
        uint256 currentHighestBid;      // 当前最高出价
        address currentHighestBidder;  // 当前最高出价者
    }
    
    // 存储拍卖物品的编号和对应的拍卖信息
    mapping(uint256 => AuctionItem) public auctions;
    
    // 竞拍函数
    function bid(uint256 _itemId, uint256 _bidAmount) public {
        // 确保出价高于当前最高出价
        require(_bidAmount > auctions[_itemId].currentHighestBid, "Bid amount must be higher than current highest bid");
        
        // 如果有之前的最高出价者，则将资金退回给之前的最高出价者
        if (auctions[_itemId].currentHighestBidder != address(0)) {
            auctions[_itemId].currentHighestBidder.transfer(auctions[_itemId].currentHighestBid);
        }
        
        // 更新拍卖物品的当前最高出价和当前最高出价者为新的竞拍者
        auctions[_itemId].currentHighestBid = _bidAmount;
        auctions[_itemId].currentHighestBidder = msg.sender;
    }
}
    - 这个合约包含了一个 `AuctionItem` 结构体，用于存储拍卖物品的信息，包括卖家地址、起拍价、当前最高出价和当前最高出价者。通过 bid 函数，竞拍者可以对拍卖物品进行竞拍，要求竞拍金额高于当前最高出价，否则会失败。如果有新的最高出价，之前的最高出价者将收到退回的出价金额，并且更新当前最高出价和最高出价者为新的竞拍者。

5. **拍卖成功处理**：
   - 成交后，归还卖家质押的20%。
   - 抽取成交额的5%作为平台手续费，其中3%分给参与叫价的竞拍者，2%归平台。
   *示例：*
   ```solidity
   contract EnglishAuction {
    struct AuctionItem {
        address seller;
        uint256 startingPrice;
        uint256 currentHighestBid;
        address currentHighestBidder;
        bool ended;
    }
    
    mapping(uint256 => AuctionItem) public auctions;
    mapping(address => uint256) public pendingReturns;
    
    function finalizeAuction(uint256 _itemId) public {
        AuctionItem storage item = auctions[_itemId];
        require(item.ended, "Auction not ended yet");

        // 计算总金额
        uint256 totalAmount = item.currentHighestBid;
        // 计算平台手续费
        uint256 platformFee = totalAmount * 5 / 100;
        // 计算卖家应获得的金额（起拍价的20%）
        uint256 sellerRefund = item.startingPrice * 20 / 100;
        // 计算卖家最终应获得的金额（扣除平台手续费和起拍价的20%）
        uint256 sellerAmount = totalAmount - platformFee - sellerRefund;
        // 计算竞拍者最终应支付的金额（扣除平台手续费）
        uint256 winnerAmount = totalAmount - platformFee;

        // 将卖家起拍价的20%退还给卖家
        item.seller.transfer(sellerRefund);
        // 将剩余金额转给卖家
        item.seller.transfer(sellerAmount);
        // 将竞拍者应支付的金额记录到待退款列表中
        pendingReturns[item.currentHighestBidder] += winnerAmount;

        // 将平台手续费按照3%分给竞拍者，2%归平台
        uint256 bidderFee = totalAmount * 3 / 100;
        uint256 platformFee = totalAmount * 2 / 100;
        // 按出价比例分配手续费
        uint256 bidAmount = item.currentHighestBid;
        uint256 bidderReward = (bidAmount * bidderFee) / totalAmount;
        uint256 platformReward = bidderFee - bidderReward;
        pendingReturns[item.currentHighestBidder] += bidderReward;
        // 将2%的手续费转给平台地址
        address platformAddress = /* platform address */;
        platformAddress.transfer(platformReward);
    }
}
    ```
    * ### ps：`platform address` 为平台地址! *
    - 按比例分配的逻辑是：
    1.`bidAmount` 变量存储了当前拍卖物品的最高出价金额，即竞拍者当前出价的金额。
    2.`bidderReward `变量计算了竞拍者应获得的手续费奖励。计算方法是竞拍者出价金额 `bidAmount` 乘以竞拍者手续费比例 `bidderFee`,然后除以总金额 3.`totalAmount`。这样计算可以保证竞拍者获得的奖励与其出价的比例成正比。
    4.`platformReward` 变量计算了平台应获得的手续费奖励。计算方法是总手续费 bidderFee 减去竞拍者应获得的奖励 bidderReward，即剩余的手续费归平台所有。
最后，竞拍者的手续费奖励 `bidderReward` 被累加到 `pendingReturns` 映射中，以便后续竞拍者可以取回奖励。平台手续费奖励 `platformReward` 则直接转账给平台地址。

6. **拍卖不成功处理**：
   - 卖家终止拍卖，质押的起拍价的20%不能被要回来。
   - 抽取质押额的40%奖励给最大的出价者。
   - 抽取质押的20%中的40%按比例分给其他叫价的竞拍者。
   - 剩下的20%归平台。

```Solidity
contract EnglishAuction {
    struct AuctionItem {
        address seller;
        uint256 startingPrice;
        uint256 currentHighestBid;
        address currentHighestBidder;
        bool ended;
        address[] bidders; // 存储竞拍者地址
        mapping(address => uint256) bidAmounts; // 存储竞拍者出价金额
    }
    
    mapping(uint256 => AuctionItem) public auctions;
    mapping(address => uint256) public pendingReturns;
    
    function cancelAuction(uint256 _itemId) public {
        AuctionItem storage item = auctions[_itemId];
        require(msg.sender == item.seller, "Only seller can cancel the auction");
        require(!item.ended, "Auction already ended");
        
        uint256 totalAmount = item.startingPrice;
        uint256 maxBid = item.currentHighestBid;
        uint256 maxBidderReward = totalAmount * 40 / 100; // 最大出价者奖励40%
        uint256 remainingAmount = totalAmount - maxBid;
        uint256 remainingBidderRewardPool = (totalAmount * 20 / 100) * 40 / 100; // 剩余出价者奖励40%
        uint256 platformReward = (totalAmount * 20 / 100) * 20 / 100; // 平台奖励20%

        // 将最大出价者奖励40%存入待退款映射中
        pendingReturns[item.currentHighestBidder] += maxBidderReward;

        // 遍历剩余出价者，按质押额比例分配40%的奖励
        for (uint i = 0; i < item.bidders.length; i++) {
            if (item.bidders[i] != item.currentHighestBidder) {
                uint256 bidAmount = item.bidAmounts[item.bidders[i]];
                uint256 bidderReward = (bidAmount * remainingBidderRewardPool) / totalAmount;
                pendingReturns[item.bidders[i]] += bidderReward;
            }
        }

        // 将平台奖励20%转账给平台地址
        address platformAddress = /* platform address */;
        platformAddress.transfer(platformReward);

        // 标记拍卖已结束
        item.ended = true;
    }
}
```
`cancelAuction` 函数用于处理拍卖不成功的情况。卖家调用该函数取消拍卖，然后按照规则处理剩余的资金：
最大出价者奖励40%的逻辑在 `pendingReturns[item.currentHighestBidder] += maxBidderReward;` 实现。剩余出价者按比例分配40%的奖励的逻辑在循环中实现，平台奖励20%直接转账给平台地址。
7. **流拍处理**：
   - 拍卖流拍，直接罚没卖家质押金额的10%归平台。
```Solidity
 function cancelAuction(uint256 _itemId) public {
        AuctionItem storage item = auctions[_itemId];
        require(msg.sender == item.seller, "Only seller can cancel the auction");
        require(!item.ended, "Auction already ended");
        
        // 计算罚没的金额
        uint256 penaltyAmount = （item.startingPrice * 20 / 100）* 10 / 100;
        uint256 platformReward = penaltyAmount; // 罚没的金额归平台

        // 将罚没的金额转账给平台地址
        address platformAddress = /* platform address */;
        platformAddress.transfer(platformReward);

        // 标记拍卖已结束
        item.ended = true;
```
    - 这部分逻辑很简单。
8. **资金流入处理**：
   - 最终资金流入英式拍卖资金池与平台地址。
   ```Solidity
    contract EnglishAuction {
    address payable public platformAddress; // 平台地址
    address payable public fundPoolAddress; // 资金池地址

    constructor(address _platformAddress, address _fundPoolAddress) public {
        platformAddress = payable(_platformAddress);
        fundPoolAddress = payable(_fundPoolAddress);
    }

    function endAuction(uint256 _itemId) public {
        // 拍卖结束时处理资金
        // 假设有一些逻辑用于计算资金分配，这里省略
        uint256 totalAmount = /* 计算出的总金额 */;
        uint256 sellerProceeds = /* 计算出的卖家获得的金额 */;
        uint256 platformFee = /* 计算出的平台手续费 */;
        uint256 bidderRewards = /* 计算出的竞拍者奖励金额 */;

        // 转账给卖家
        pendingReturns[seller] += sellerProceeds;

        // 转账给平台
        platformAddress.transfer(platformFee);

        // 转账给竞拍者
        pendingReturns[highestBidder] += bidderRewards;
    }
}```
   - `platformAddress` 和 `fundPoolAddress` 是在合约初始化时设置的平台和资金池地址。在拍卖结束时，根据计算的结果，将资金分配到相应的地址。
9. **测试*：
   - 编写测试用例，测试合约的各项功能是否正常。

    contract EnglishAuctionTest {
    // 合约实例
    EnglishAuction auction;
    // 卖家、竞拍者1、竞拍者2的地址
    address public seller;
    address public bidder1;
    address public bidder2;
    
    // 拍卖ID
    uint256 public auctionId;
    
    // 竞拍者1、竞拍者2的奖励金额
    uint256 public bidder1Reward;
    uint256 public bidder2Reward;

    // 在所有测试用例执行之前执行，初始化合约和拍卖
    function beforeAll() public {
        // 分配地址
        seller = address(0x1);
        bidder1 = address(0x2);
        bidder2 = address(0x3);

        // 创建一个新的拍卖合约
        auction = new EnglishAuction(address(0x4), address(0x5));

        // 创建一个拍卖并获取拍卖ID
        auctionId = auction.createAuction(seller, 100);
    }

    // 测试竞拍功能
    function testBid() public {
        // 竞拍者1出价110
        auction.bid(auctionId, {from: bidder1, value: 110});
        // 竞拍者2出价120
        auction.bid(auctionId, {from: bidder2, value: 120});

        // 检查最高出价者和最高出价金额是否正确
        assert(auction.highestBidder(auctionId) == bidder2);
        assert(auction.highestBid(auctionId) == 120);
    }

    // 测试结束拍卖功能
    function testEndAuction() public {
        // 结束拍卖
        auction.endAuction(auctionId);

        // 检查拍卖是否已结束
        assert(auction.ended(auctionId) == true);

        // 获取竞拍者1的奖励金额
        bidder1Reward = auction.pendingReturns(bidder1);
        // 获取竞拍者2的奖励金额
        bidder2Reward = auction.pendingReturns(bidder2);
    }

    // 测试取消拍卖功能
    function testCancelAuction() public {
        // 取消拍卖
        auction.cancelAuction(auctionId);

        // 检查拍卖是否已结束
        assert(auction.ended(auctionId) == true);
    }
  测试时可以检查正常拍卖功能，还可以显示出如果存在的参与竞拍者的奖励金额。
 ps:（在想有没有可能在竞拍者试图参与竞拍的时候就显示可能获得的奖励金额呢？这样会不会更激励参与竞拍？）
10. 部署：
    - 部署合约到以太坊或其他支持Solidity的区块链上。
- 1. 使用 Remix 等 Solidity IDE 编译合约代码，生成合约的 `ABI（Application Binary Interface）`和字节码。
- 2. 在 MetaMask 或其他以太坊钱包中创建或导入一个账户，并确保账户有足够的 `ETH`用于支付 `gas` 费用。
- 3. 使用 Remix 或其他方式将合约部署到以太坊网络中，需要填入合约的 `ABI` 和字节码，并选择合适的 `gas` 费用和 `gas` 上限。
- 4. 等待部署完成，合约部署成功后会返回一个合约地址，该地址可以在区块链浏览器上查看合约的交易和状态。
- 5. 我们应该使用测试网部署。
##总结： 
目前尚未解决的：
 - 1.各个函数的整合，让它成为一个完整的可用的合约项目代码。
 - 2.方案是否还有瑕疵？还有什么地方没有完善？
 - 3.核心的比如奖励竞拍者的代码逻辑我都基本看过改过了，应该没有什么大问题，但是难免有纰漏，各位在使用的时候还要再看一遍，以防有错误。
 - 4.前端页面尚未解决。
 - 5.合约调用怎么写也是勠需解决的问题之一。
