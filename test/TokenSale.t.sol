// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/1_TokenSale.sol";

contract TokenSaleTest is Test {
    TokenSale public tokenSale;
    address payable public owner;
    address payable public contributor1;

    function setUp() public {
        owner = payable(msg.sender);
        contributor1 = payable(address(0x123));

        tokenSale = new TokenSale(
            1, // _presaleMinContribution
            10, // _presaleMaxContribution
            5, // _publicSaleMinContribution
            15, // _publicSaleMaxContribution
            100, // _presaleCap
            200 // _publicSaleCap
        );
    }

    function testPresaleWithinLimits() public {
        tokenSale.contributeToPresale{value: 5}();
        assertEq(tokenSale.userBalance(), 5000);
        assertEq(tokenSale.presaleCapLeft(), 95);
    }

    function testPublicSaleWithinLimits() public {
        tokenSale.closePresale();
        tokenSale.contributeToPublicSale{value: 10 wei}();
        assertEq(tokenSale.userBalance(), 8000);
        assertEq(tokenSale.publicSaleCapLeft(), 190);
    }

    function testPresaleExceedsCap() public {
        vm.expectRevert(bytes("Induvidual Contribution exceeded"));
        tokenSale.contributeToPresale{value: 11 wei}();
        assertEq(tokenSale.presaleContributions(msg.sender), 0);
        assertEq(tokenSale.userBalance(), 0);
        assertEq(tokenSale.presaleCapLeft(), 100);
    }

    function testPublicSaleExceedsCap() public {
        tokenSale.closePresale();
        vm.expectRevert(bytes("Induvidual Contribution exceeded"));
        tokenSale.contributeToPublicSale{value: 201 wei}();
        assertEq(tokenSale.publicSaleContributions(msg.sender), 0);
        assertEq(tokenSale.userBalance(), 0);
        assertEq(tokenSale.publicSaleCapLeft(), 200);
    }

    function testDistributeTokens() public {
        tokenSale.distributeTokens(contributor1, 1000);
        assertEq(tokenSale.balanceOf(contributor1), 1000);
    }

    function testClosePresale() public {
        tokenSale.closePresale();
        assert(tokenSale.presaleClosed());
    }

    function testClosePublicSale() public {
        tokenSale.closePublicSale();
        assert(tokenSale.publicSaleClosed());
    }
}
