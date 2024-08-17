// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/NFT.sol";
import "src/Token.sol";
import "src/Admin.sol";
import "src/Tools/IsAdmin.sol";

contract AdminTest is Test {
    IsAdmin isAdmin;
    Token token;
    Token USDT;
    NFT nft;
    Admin admin;
    address sender = address(0x1);
    address sender2 = address(0x2);

    function setUp() public {

        isAdmin = new IsAdmin();
        token = new Token("CIN","CIN",address(isAdmin));
        USDT = new Token("USDT","USDT",address(isAdmin));
        nft = new NFT("CIN","CIN",address(isAdmin),address(USDT));

        address payable A = payable(address(token));
        admin = new Admin(address(nft),A,address(isAdmin),address(USDT));

        isAdmin.setAdmin(msg.sender);
        isAdmin.setAdmin(sender);
        isAdmin.setAdmin(address(admin));
        nft.setAdmin(address(admin));

        vm.startPrank(sender);

        USDT.mint(sender,10000000000);
        // console.log(USDT.balanceOf(sender));
        USDT.approve(address(admin),1000000000);
        // console.log(USDT.allowance(sender,address(admin)));

        nft.setSeatsNumber(0,10);
        for (uint8 i = 0; i < 10; i++) {
            nft.mint(i,'',0,i,1,1000,102,101);
            // nft.setNFT(i, 1000, 0,false,false);
        }

        vm.stopPrank();
    }

    // function testBuy() public {
    //     vm.startPrank(sender);

    //     admin.buy(0);
    //     (uint8 _number,uint256 _price,uint256 _awardUSDT,uint256 _awardToken,bool _isRenting,bool _isSelling,uint8 _totalNumber,address _mainOwner) = nft.getNFT(0);
    //     // (,,,bool A) = nft.getNFT(0);
    //     console.log(_isSelling);

    //     vm.stopPrank();
    // }

    function testFilm() public {
        vm.startPrank(sender);

        admin.buy(0);
        admin.buy(1);
        (uint8 _number,uint256 _price,uint256 _awardUSDT,uint256 _awardToken,bool _isRenting,bool _isSelling,uint8 _totalNumber,address _mainOwner) = nft.getNFT(0);
        // (,,,bool A) = nft.getNFT(0);
        console.log(_isSelling);

        USDT.mint(sender2, 100000000000);

        vm.stopPrank();

        vm.startPrank(sender2);
        USDT.approve(address(admin),1000000000);
        admin.rent(1);
        admin.rent(2);
        (,,,,bool _AisRenting,bool _AisSelling,,) = nft.getNFT(1);
        console.log(_AisRenting);
        console.log(_AisSelling);
        vm.stopPrank();

        vm.startPrank(sender);

        console.log(nft.ownerOf(1));

        admin.film(0);
        (uint8 _Bnumber,,,,bool _BisRenting,bool _BisSelling,,) = nft.getNFT(1);
        // (,,,bool B) = nft.getNFT(0);
        console.log(_BisSelling);
        console.log(_BisRenting);
        console.log(_Bnumber);
        console.log(nft.ownerOf(1));
        console.log(admin.getAwardUSDT(sender2,1));
        console.log(admin.getAwardToken(sender2,2));
        

        vm.stopPrank();

        vm.startPrank(sender2);

        console.log(USDT.balanceOf(sender2));
        admin.withdraw(1);
        console.log(USDT.balanceOf(sender2));
        console.log(admin.getAwardUSDT(sender2,1));

        console.log(token.balanceOf(sender2));
        admin.withdraw(2);
        console.log(token.balanceOf(sender2));
        console.log(admin.getAwardUSDT(sender2,2));

        vm.stopPrank();
    }

    // function testRent() public {
    //     vm.startPrank(sender);

    //     admin.rent(1);
    //     (,,,,bool _AisRenting,,,) = nft.getNFT(1);
    //     console.log(_AisRenting);

    //     vm.stopPrank();
    // }
}