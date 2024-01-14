// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import "../src/3_TokenSwap.sol";

contract TokenSwapTest is Test {
    TokenSwap public tokenSwap;
    address public owner;
    address public user1;
    ERC20 public tokenA;
    ERC20 public tokenB;

    function setUp() public {
        owner = payable(msg.sender);
        user1 = payable(address(0x123));
        tokenSwap = new TokenSwap(address(tokenA), address(tokenB), 2); // 1 TokenA = 2 TokenB
    }

    function testSwapAToB() public {
        tokenA.transfer(address(tokenSwap), 10);

        tokenSwap.swapAToB(5);

        assertEq(
            tokenA.balanceOf(address(tokenSwap)),
            5,
            "TokenA balance in swap contract is incorrect"
        );
        assertEq(
            tokenB.balanceOf(address(tokenSwap)),
            10,
            "TokenB balance in swap contract is incorrect"
        );
        assertEq(
            tokenB.balanceOf(msg.sender),
            5,
            "TokenB balance for user is incorrect"
        );
    }

    function testSwapBToA() public {
        tokenB.transfer(address(tokenSwap), 10);

        tokenSwap.swapBToA(5);

        assertEq(
            tokenA.balanceOf(address(tokenSwap)),
            5,
            "TokenA balance in swap contract is incorrect"
        );
        assertEq(
            tokenB.balanceOf(address(tokenSwap)),
            5,
            "TokenB balance in swap contract is incorrect"
        );
        assertEq(
            tokenA.balanceOf(msg.sender),
            2,
            "TokenA balance for user is incorrect"
        );
    }

    function testSetExchangeRate() public {
        tokenSwap.setExchangeRate(3); // 1 TokenA = 3 TokenB now

        assertEq(
            tokenSwap.exchangeRate(),
            3,
            "Exchange rate not set correctly"
        );
    }

    function testSetExchangeRateNonOwner() public {
        vm.prank(user1);
        vm.expectRevert("Owner Rights Needed");
        tokenSwap.setExchangeRate(4);
    }
}
