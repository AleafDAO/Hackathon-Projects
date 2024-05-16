// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {GovernorEvent} from "src/uitls/GovernTool.sol";
import "src/DAO.sol";

contract Govern is GovernorEvent {

    address private dao;
    address owner;
    address public implementation;

    event FallbackTriggered(address caller,bytes data);

    constructor(
        address _dao,
        address _timeLock,
        address _token,
        address _implementation,
        uint _votingDelay,
        uint _votingPeriod
    ) {
        dao = _dao;
        owner = msg.sender;

        _delegateTo(_implementation, abi.encodeWithSignature(
            "initialize(address,address,address,uint,uint)",
            _dao,
            _timeLock,
            _token,
            _votingDelay,
            _votingPeriod));
        
    }

    function _delegateTo(address callee,bytes memory data) internal {

        (bool success,bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success,0) {
                revert(add(returnData,0x20),returndatasize())
            }
        }

    }

    modifier adminOnly() {
        require(Dao(dao).isAdmin(msg.sender) || msg.sender == owner,"Govern::adminOnly:You must be ADMIN.");
        _;
    }

    function setImplementation(address _implementation) public adminOnly(){
        require(_implementation != address(0), "Govern::setImplementation:ADDRESS(0)");

        address oldImplementation = implementation;
        implementation = _implementation;

        emit NewImplementation(oldImplementation, _implementation);
    }



    fallback() external {
        (bool success, ) = implementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize())
            }
            default {
                return(free_mem_ptr, returndatasize())
            }
        }
         emit FallbackTriggered(msg.sender, msg.data);
    }
}
