// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

interface Itoken {
    function getPriorVotes(address amount,uint blocknumber) external view returns(uint);
}