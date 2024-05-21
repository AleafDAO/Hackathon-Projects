// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

contract Dao {
    address public owner;

    mapping(address => bool) public Admin;
    mapping(address => bool) public Whitelisted;

    constructor(address _owner){
        owner = _owner;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner,"DAO::OnlyOwner:Only Owner can do that.");
        _;
    }

    function setAdmin(address _adder) external OnlyOwner {
        Admin[_adder] = true;
    }

    function isAdmin(address _address) public view returns(bool) {
        return Admin[_address];
    }
    
    function setMember(address _adder) external{
        require(Admin[msg.sender] || msg.sender == owner,"DAO::setMember:You must be Admin&Owner.");
        Whitelisted[_adder] = true;
    }

    function isMember(address _address) public view returns(bool) {
        return isMember(_address);
    }


} 




