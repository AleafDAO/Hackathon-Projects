
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

library SafeMath {
    using Math for uint256;

    function sub(uint256 a,uint256 b) public returns (uint256) {
        (bool d,uint256 c) = a.trySub(b);
        require(d,"uitls:::SafeMath::sub:NO SAFE");
        return c;
    }

    function add(uint256 a,uint256 b) public returns (uint256) {
        (bool d,uint256 c) = a.tryAdd(b);
        require(d,"uitls:::SafeMath::add:NO SAFE");
        return c;
    }
}