// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/NFT.sol";
import "src/Token.sol";
import "src/Admin.sol";
import "src/Tools/IsAdmin.sol";

contract Deploy is Script{

    function run() external {

        vm.startBroadcast();

        IsAdmin isAdmin = new IsAdmin();
        Token token = new Token("CIN","CIN",address(isAdmin));
        Token USDT = new Token("USDT","USDT",address(isAdmin));
        NFT nft = new NFT("CIN","CIN",address(isAdmin),address(USDT));

        address payable A = payable(address(token));
        Admin admin = new Admin(address(nft),A,address(isAdmin),address(USDT));

        console.log("IsAdmin deploy at ",address(isAdmin));
        console.log("Token deploy at ",address(token));
        console.log("USDT depoly at ",address(USDT));
        console.log("NFT deploy at ",address(nft));
        console.log("Admin deploy at ",address(admin));

        vm.stopBroadcast();
    }
}

