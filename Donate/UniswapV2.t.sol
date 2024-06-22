// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/UniswapV2ERC20.sol";
import "src/UniswapV2Pair.sol";
import "src/UniswapV2Factory.sol";
import "src/interfaces/IUniswapV2Pair.sol";
import "src/interfaces/IUniswapV2Factory.sol";
import "src/interfaces/IUniswapV2ERC20.sol";

contract UniswapV2Test is Test {
    
    IUniswapV2Factory factory;
    IUniswapV2Pair pair;
    UniswapV2ERC20 token0;
    UniswapV2ERC20 token1;

    address token0Address = address(0x1);
    address token1Address = address(0x2);
    
    function setUp() public {
        factory = new UniswapV2Factory(address(this));
        factory.createPair(token0Address,token1Address);
        address pairAddress = factory.getPair(token0Address,token1Address);
        pair = IUniswapV2Pair(pairAddress);
        token0 = UniswapV2ERC20(token0Address);
        token1 = UniswapV2ERC20(token1Address);
    }

    function testAddLiquidity() public {
        uint96 amount0 = 10 ether;
        uint96 amount1 = 10 ether;

        token0.transfer(address(pair),amount0);
        token1.transfer(address(pair),amount1);
        uint liquidity = pair.balanceOf(address(this));
        require(liquidity > 0,"Liquidity not added");
    }

    function testSwap() public {
        uint96 amount0In = 1 ether;

        token0.transfer(address(pair), amount0In);

        pair.swap(0, amount0In, address(this), new bytes(0));

        uint balance1 = token1.balanceOf(address(this));
        require(balance1 > 0,"Swap failed");

    }

    function testRemoveLiquidity() public {
        uint liquidity = pair.balanceOf(address(this));

        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));

        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));
        require(balance0 > 0,"Remove liquidity failed for token0");
        require(balance1 > 0,"Remove liquidity failed for token1");

    }
}