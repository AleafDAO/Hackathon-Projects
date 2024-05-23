// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "src/Donate/Main.sol";
import "src/Donate/DonateMain.sol";
import "src/uitls/DonationTool.sol";
import "src/vote/DAO.sol";

contract front is DonationT{

    address private main;
    address payable private donateMain;
    address private DaoA;




    constructor(address _main,address payable _donateMain,address _Dao) {
        main = _main;
        donateMain = _donateMain;
        DaoA = _Dao;
    }

    function register() external {
        Main(main).register();
    }

    function donate(uint donationCampaignId,uint amount) external payable {
        DonateMain(donateMain).donate(donationCampaignId, amount);
        // (bool sent,) = donateMain.call{value:amount}(abi.encodeWithSignature("donate(uint,uint)", donationCampaignId,amount));
        // require(sent,"front::front:Fallback");
    }

    function isAdmin(address _address) external view returns(bool) {
        return Dao(DaoA).isAdmin(_address);
    }

    function castVote(uint proposalId,uint8 support) external {
        DonateMain(donateMain).castVote(proposalId, support);
    }


}