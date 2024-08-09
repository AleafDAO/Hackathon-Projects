// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.10;

contract IsAdmin {

    address internal owner;
    mapping (address => bool) public isAdmin;

    constructor() {
        owner = msg.sender;
    }

    function setAdmin(address _address) external {
        require(owner == msg.sender||isAdmin[msg.sender],"src::::Tools:::IsAdmin::setAdmin: Owner or Admin Only.");
        require(!isAdmin[_address],"src::::Tools:::IsAdmin::setAdmin: ADMIN");
        isAdmin[_address] = true;
    }

}