// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "src/uitls/DonationTool.sol";
import "src/vote/GovernImp.sol";
import "src/vote/DAO.sol";
import "src/Donate/Main.sol";


contract DonateMain is DonationT,DonationEvent,GovernImp{

    address owner;

    address private main;

    event fallbackEvent(address caller,bytes data);

    event receiveEvent(address caller);

    constructor(address _main) {
        owner = msg.sender;
        main = _main;
    }

    modifier adminOnly() {
        require(Dao(dao).isAdmin(msg.sender),"DonateMain::adminOnly:You are not Admin.");
        _;
    }

    function creatDonationCampaign(address payable recipient,uint256 targetAmount,uint256 duration) public {
        
        DonationCampaign storage donationCampaign = DonationCampaigns[DonationCount + 1];
        DonationCount++;
        donationCampaign.DonationCampaignId = DonationCount;
        donationCampaign.targetAmount = targetAmount;
        donationCampaign.raisedAmount = 0;
        donationCampaign.endBlock = block.number + duration;
        donationCampaign.recipient = recipient;
        // donationCampaign.Voting = false;
        donationCampaign.Ending = false;
        donationCampaign.Donating = true;

        if (donationCampaign.DonationCampaignId == 1) {
            prev[1] = queueHead;
            next[0] = donationCampaign;
        }
        next[donationCampaign.DonationCampaignId-1] = donationCampaign;
        prev[donationCampaign.DonationCampaignId] = DonationCampaigns[donationCampaign.DonationCampaignId -1];

        DonationQueueCount++;

        emit CreatDonationCampaign(
            recipient,
            donationCampaign.DonationCampaignId,
            targetAmount,
            block.number,
            donationCampaign.endBlock
        );
    }

    function _changeQueue(uint _donationCampaignId) internal {
        // require(DonationCampaigns[_donationCampaignId].Donating,"DonateMain::changeQueue:Campaign must be Donating.");
        // require(!DonationCampaigns[_donationCampaignId].Voting,"DonateMain::changeQueue:Campaign is Voting.");
        DonationCampaign memory donationCampaign = DonationCampaigns[_donationCampaignId];
        DonationCampaign memory queueFirst = prev[next[0].DonationCampaignId];
        //头
        prev[next[0].DonationCampaignId] = donationCampaign;
        next[0] = donationCampaign;
        //中
        next[prev[_donationCampaignId].DonationCampaignId] = next[_donationCampaignId];
        prev[next[_donationCampaignId].DonationCampaignId] = prev[_donationCampaignId];
        //目标
        next[_donationCampaignId] = queueFirst;
        prev[_donationCampaignId] = queueHead;

    }

    function changeQueueTop(uint _donationCampaignId) public adminOnly() {
        address[] memory _targets;
        string[] memory _signatures;
        bytes[] memory _calldatas;
        uint[] memory _value;
        string memory _description;

        _targets[0] = owner;
        _signatures[0] = "";
        _calldatas[0] = abi.encodeWithSignature("_changeQueueTop(uint)", _donationCampaignId);
        _value[0] = 0;
        _description = "";

        propose(_targets,_signatures,_calldatas,_value,_description);

        // uint id = propose([owner],"",abi.encodeWithSignature("_changeQueueTop(uint)", _donationCampaignId),0,"");
    }

    function donate(uint donationCampaignId,uint amount) public payable{

        require(address(this).balance >= amount, "DonateMain::donate:Counter ETH is not enough.");
        require(DonationCampaigns[donationCampaignId].Donating,"DonateMain::donate:The Campaign is not Donating.");
        
        DonationCampaign memory donationCampaign = DonationCampaigns[donationCampaignId];
        uint256 remain = donationCampaign.targetAmount - donationCampaign.raisedAmount;
        if (remain <= amount) {
            amount = remain;
        }


        (bool sent,) = donationCampaign.recipient.call{value:amount}("");
        // (bool feesent,) = main.call{value:fee}("");
        require(sent ,"DonateMain::donate:Fallback.");

        DonationCampaigns[donationCampaignId].raisedAmount += amount;
        Donaters[DonaterId[msg.sender]].amount += amount;
        if (remain == amount && DonationCampaigns[donationCampaignId].raisedAmount == DonationCampaigns[donationCampaignId].targetAmount) {
            Donaters[DonaterId[msg.sender]].lastTime ++;
            emit Donate(msg.sender,donationCampaign.recipient,amount,true);
            outQueue(donationCampaignId);
        } else {
            emit Donate(msg.sender,donationCampaign.recipient,amount,false);
        }
    }

    function outQueue(uint _donationCampaignId) internal {
        next[prev[_donationCampaignId].DonationCampaignId] = next[_donationCampaignId];
        prev[next[_donationCampaignId].DonationCampaignId] = prev[_donationCampaignId];
        next[_donationCampaignId] = end;
        prev[_donationCampaignId] = end;
        DonationCampaigns[_donationCampaignId].Donating = false;
        DonationCampaigns[_donationCampaignId].Ending = true;
    }

    fallback() external payable{
        emit fallbackEvent(msg.sender, msg.data);
    }

    receive() external payable{
        emit receiveEvent(msg.sender);
    }


}