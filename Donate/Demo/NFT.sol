// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DonationNFT is ERC721 {
    constructor() ERC721("DonationNFT", "DNFT") {}

    function mint(address recipient, uint256 tokenId) public {
        _mint(recipient, tokenId);
    }
}

contract DonationTracker {
    // 存储捐赠者地址和捐赠金额
    mapping(address => uint256) public donations;

    // 存储每个赛季的前三名捐赠者
    address[3] public topDonors;

    // 这里需要一个逻辑来更新捐赠者信息和排名

    function getTopDonors() public view returns (address[3] memory) {
        return topDonors;
    }

    // 这里需要一个逻辑来结束赛季并触发NFT铸造
}

// Chainlink Keepers会调用这个合约的特定函数来处理自动化