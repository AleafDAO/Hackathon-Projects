# Hackathon-Projects

## AuctionHouse

### *Mentality of designing:*

Initially, the user selects between two auction modes: English auction and Dutch auction (Note: This proposal innovates upon the English auction with some modifications, differing slightly from the traditional approach).

Second, modules need to be added for both auction modes.

Third, this step involves the smart contract portion for both auction modes, with equal priority.

(1) Incentivized Bidding English Auction:
The steps are as follows:
To begin, establish a reserve price. The seller pledges 20% of the reserve price, then initiates the auction.
There are three scenarios:
The first scenario is a successful auction, meaning a deal is made. The 20% pledged is refunded to the seller, and 95% of the transaction amount accrues to the seller, with a 5% deduction. Within this 5%, 3% is distributed among bidding participants based on the size of their bids, and 2% is levied as a platform transaction fee.
The second scenario is an unsuccessful auction, where the seller terminates the auction. In this case, the 20% pledged by the seller cannot be reclaimed. Instead, 40% is awarded to the highest bidder, and 40% of the pledged amount (from the 20%) is proportionally distributed among other bidders, with the remaining 20% going to the platform.
Additionally, there is a third scenario, a stale auction, where the seller's set reserve price is too high, resulting in no bidders willing to bid. In this case, a penalty mechanism is activated, with 10% of the seller's pledged amount forfeited to the platform.
Ultimately, funds flow into the English auction fund pool and the platform address.

(2) Traditional Dutch Auction:
The steps are as follows:
Again, set a reserve price and pledge 10% of it, then initiate the auction.
There are two scenarios:
In the first scenario, the auction is successful, and a deal is made. A 5% fee is charged on the auction amount, with 2% allocated to the platform and 3% entering the fund pool. The amount pledged by the seller is returned.
In the second scenario, if the seller finds the price too low and cannot accept further reductions but no bidders accept the offer, the auction is terminated, resulting in a stale auction. In this case, 66% of the seller's pledged amount enters the fund pool, while the remaining 34% goes to the platform.
Finally, funds flow into the Dutch auction fund pool and the platform address.

Fourth, the auction concludes, and claims can be made.

*`[This smart contract aims to incentivize bidding by implementing a reward mechanism, thereby increasing the auction success rate and fostering trading volume in the NFT market.]`*
