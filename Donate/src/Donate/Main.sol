// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "src/uitls/DonationTool.sol";



contract Main is DonationT{

    address owner;

    event Register(address donater,uint donaterId);

    constructor(uint256 _fee) {

        fee = _fee;
        DonationCount = 0;
        DonaterCount = 0;
        DonationQueueCount = 0;
        owner = msg.sender;

    }

    function register() public {
        _registerInternal(msg.sender);
    }

    // function getOwner() public {
    //     print(owner);
    // }

    function _registerInternal(address _donater) internal {

        Donater storage donater = Donaters[DonaterCount];
        donater.donaterId = DonaterCount;
        donater.account = _donater;
        donater.lastTime = 0;
        DonaterId[_donater] = donater.donaterId;
        emit Register(_donater,donater.donaterId);
       
    }

    

}