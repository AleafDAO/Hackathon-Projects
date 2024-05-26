
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;
contract DonationEvent {
    constructor() {
        
    }

    event CreatDonationCampaign(
        address indexed recipient,
        uint256 DonationCampaignId,
        uint256 targetAmount,
        uint256 startBlock,
        uint256 endBlock
    );

    event Donate(address indexed donater,address indexed recipient,uint256 indexed amount,bool isLast);

}

contract DonationT {

    mapping (uint => DonationCampaign) DonationCampaigns;

    //通过该投票活动id，查找队列中下一个投票活动（指针next）
    mapping (uint => DonationCampaign) next;
    //通过该投票活动id，查找队列中下一个投票活动（指针last）
    mapping (uint => DonationCampaign) prev;

    mapping (uint => Donater) Donaters;

    mapping (address => uint) DonaterId;

    uint256 public fee;

    uint public DonationCount;

    uint public DonationQueueCount;

    uint public DonaterCount;

    struct  DonationCampaign {
        // string name;
        uint256 DonationCampaignId;
        uint256 targetAmount;
        uint256 raisedAmount;
        uint256 endBlock;
        address payable recipient;
        bool Donating;
        bool Ending;

        // bool active;
    }

    struct Donater {

        address account;
        uint256 donaterId;
        uint256 amount;
        uint256 lastTime;
    }

    //队列头节点，初始化时，id设为0
    DonationCampaign public queueHead;
    DonationCampaign public end;


}