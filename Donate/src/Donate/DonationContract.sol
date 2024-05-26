// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationContract {
    
    struct User {
        string email;
        string username;
        string password;
    }

    struct DonationProject {
        string name;
        uint targetAmount;
        uint currentAmount;
        bool isActive;
        address[] donors;
    }
    
    DonationProject[] public donationProjects;
    mapping(address => uint) public totalDonations;
    mapping(string => User) public users;

    // 登录
    function login(string memory _email, string memory _password) public view returns (string memory) {
        require(keccak256(abi.encodePacked(users[_email].password)) == keccak256(abi.encodePacked(_password)), "Invalid email or password");
        return users[_email].username;
    }

    // 注册
    function register(string memory _email, string memory _username, string memory _password) public {
        require(bytes(users[_email].email).length == 0, "Email already exists");
        users[_email] = User(_email, _username, _password);
    }

    // 捐助
    function donate(uint _projectId) public payable {
        // Implement donation logic
    }

    // 获取排行榜数据
    function getLeaderboard() public view returns (string[] memory) {
        // Implement leaderboard logic
    }

    // 获取最后一个捐助者
    function getLastDonator() public view returns (string memory) {
        // Implement last donator logic
    }

    // 获取NFT数量
    function getNFTs() public view returns (uint) {
        // Implement NFT logic
    }
    
    // 发放NFT奖励
    function issueNFTRewards() public {
        // Implement NFT reward logic
    }
}