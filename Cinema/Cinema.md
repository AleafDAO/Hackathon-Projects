# 简介

为影院和消费者提供一个平台用于租赁影院座位，从而帮助影院在淡季提高座位的利用率，在每场电影放映后   
//给予未售出座位的租赁者一定奖励
对售出自己座位的租赁者提供一定奖励。
# 具体功能

1.影院方面

mint接口，给影院方输入参数，从而mint座位对应的NFT

待设置属性：放映厅编号，座位（四位数XX排XX列），每场次基准价格。


2.消费者方面

lease接口，选择影院座位，交易对应NFT

3.主体

film接口，每场电影放映结束触发，发放奖励等等

buy接口，每场电影座位售出后触发。



award，奖励机制



# 具体逻辑

1.mint(uint tokenId,string memory _baseTokenURI,uint8 _room,uint8 _seat,uint8 _number,uint256 _price,uint256 _awardUSDT,uint256 _awardToken),需要如此8个参数（_baseTokenURI可集成到合约中，直接生成），并将对应数据存储在一个NFTMessage struct中，后续使用时调用。判断对应USDT的allowance>totalAllowance[msg.sender]（totalAllowance在每次mint时+=awardUSDT*number）。

2.rent(uint _tokenId)通过tokenId（可转变成room，seat）租赁座位，租赁者需要提前将USDT approve给admin合约，合约中判断allowance>price，接着租赁者将USDT直接转交给当前NFT的owner，将NFT交易给租赁者，更改对应NFTMessage中的isRenting参数。

3.award(uint _tokenId)通过tokenId记录奖励，判断NFTMessage中的isSelling参数，true则记录NFT owner的AwardUSTD增加awardUSTD，false则记录NFT owner的AwardToken增加awardToken（AwardUSTD和AwardToken是个mapping (address => mapping (uint => uint)) AwardUSDT），再判断NFTMessage中的number：若number !== 1，number-=1；若number == 1，将number设置为初始值（记录在NFTMessage中），再将NFT交易回影院的地址（记录在NFTMessage中），同时将isSelling设置为false。

4.film(uint8 _room)通过room，对同一放映室的座位对应NFT循环进行操作：若isRenting，触发award；else，将isSelling设置为false。

5.buy(uint _tokenId)通过tokenId，设置对应NFTMessage的isSelling为true。

6.withdraw(uint _tokenId)通过tokenId，将每个NFT对应获得的award一次性提取出来，USDT从影院交易给租赁者，Token直接mint给租赁者。


