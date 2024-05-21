// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationContract {

    address public owner;
    address public admin;
    
    // 募捐活动结构体
    struct DonationCampaign {
        string name;
        uint256 targetAmount;
        uint256 raisedAmount;
        uint256 duration;
        address recipient;
        bool active;
    }
    
    // 募捐活动列表
    DonationCampaign[] public campaigns;
    
    // 捐助记录
    mapping(address => mapping(uint256 => uint256)) public donations; // 用户地址 => 活动索引 => 捐款金额
    
    // 事件通知
    event DonationMade(address indexed donater, uint256 indexed campaignIndex, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }

    function setAdmin(address _admin) public {
        require(msg.sender == owner, "Only owner can create campaigns");
        admin = _admin;
    }

    modifier adminOnly() {
        require(msg.sender == admin, "Program::adminOnly:You must be ADMIN.");
        _;
    }
    
    // 发起募捐活动
    function createCampaign(
        string memory _name,
        uint256 _targetAmount,
        uint256 _duration,
        address _recipient
        ) external adminOnly() {

        campaigns.push(DonationCampaign({
            name: _name,
            targetAmount: _targetAmount,
            raisedAmount: 0,
            duration: _duration,
            recipient: _recipient,
            active: true
        }));
    }
    
    // 捐款
    function donate(uint256 _campaignIndex) external payable {
        require(_campaignIndex < campaigns.length, "Invalid campaign index");
        require(campaigns[_campaignIndex].active, "Campaign is not active");
        require(block.timestamp < campaigns[_campaignIndex].duration, "Campaign is over");
        require(msg.value > 0, "Donation amount must be greater than 0");
        
        campaigns[_campaignIndex].raisedAmount += msg.value;
        donations[msg.sender][_campaignIndex] += msg.value;
        
        emit DonationMade(msg.sender, _campaignIndex, msg.value);
    }
    
    // 获取特定募捐活动信息
    function getCampaign(uint256 _campaignIndex) external view returns (
        string memory name,
        uint256 targetAmount,
        uint256 raisedAmount,
        uint256 duration,
        address recipient,
        bool active
    ) {
        require(_campaignIndex < campaigns.length, "Invalid campaign index");
        DonationCampaign storage campaign = campaigns[_campaignIndex];
        return (
            campaign.name,
            campaign.targetAmount,
            campaign.raisedAmount,
            campaign.duration,
            campaign.recipient,
            campaign.active
        );
    }
}