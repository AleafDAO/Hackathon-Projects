// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

interface ITimeLock {

    function delay() external view returns (uint);

    function GRACE_PERIOD() external view returns (uint); 

    function queuedTransactions(bytes32 hash) external view  returns (bool);

    function queuedTransaction(address target,uint value,string calldata signature,bytes calldata data,uint eta) external returns (bytes32);

    function cancelTransaction(address target,uint value,string calldata signature,bytes calldata data,uint eta) external;

    function executeTransaction(address target,uint value,string calldata signature,bytes calldata data,uint eta) external payable returns (bytes memory);

}