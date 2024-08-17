// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/Tools/IsAdmin.sol";
import "src/NFT.sol";
import "src/Token.sol";

contract Mint is Script {
    function run() external {
        vm.startBroadcast();

        address isAdminAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        address nftAddress = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;
        address admin = 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9;
        address payable USDTAddress = payable(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);

        IsAdmin isAdmin = IsAdmin(isAdminAddress);
        NFT nft = NFT(nftAddress);
        Token USDT = Token(USDTAddress);


        isAdmin.setAdmin(msg.sender);
        isAdmin.setAdmin(admin);
        isAdmin.setAdmin(nftAddress);

        nft.setAdmin(admin);        
        
        USDT.mint(msg.sender,10000000000000000000);
        USDT.mint(0x70997970C51812dc3A010C7d01b50e0d17dc79C8,10000000000);

        USDT.approve(admin,1000000000000000);

        nft.setSeatsNumber(0,10);
        for (uint8 i = 0; i < 10; i++) {
            nft.mint(i,'',0,i,10,10000,1001,1002);
            // nft.setNFT(i, 1000, 0,false,false);
        }

        vm.stopBroadcast();

    }
}