// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import "../src/4_MultiSigWallet.sol";

interface CheatCodes {
    function addr(uint256) external returns (address);
}

contract MultiSigTest is Test {
    MultiSigWallet public multiSig;
    address public owner1;
    address public owner2;
    address public receiver;

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        owner1 = cheats.addr(1);
        owner2 = cheats.addr(2);
        receiver = cheats.addr(3);
        address[] memory t = new address[](2);
        t[0] = owner1;
        t[1] = owner2;
        multiSig = new MultiSigWallet(t, 2);
    }

    function testSubmitTransaction() public {
        vm.deal(owner1, 10 wei);
        vm.prank(owner1);
        multiSig.submitTransaction{value: 10 wei}(receiver);
        assertFalse(multiSig.getTransaction(0).executed);
    }

    function testSubmitTransactionInvalidReceiver() public {
        vm.prank(owner1);
        vm.deal(owner1, 10 wei);
        vm.expectRevert(bytes("Invalid Receiver's Address"));
        multiSig.submitTransaction{value: 10 wei}(address(0));
    }

    function testSubmitTransactionZeroValue() public {
        vm.prank(owner1);
        vm.deal(owner1, 10 wei);
        vm.expectRevert(bytes("Transfer Amount Must Be Greater Than 0"));
        multiSig.submitTransaction{value: 0 wei}(receiver);
    }

    function testConfirmTransaction() public {
        vm.prank(owner1);
        vm.deal(owner1, 10 wei);
        multiSig.submitTransaction{value: 10 wei}(receiver);
        vm.prank(owner2);
        multiSig.confirmTransaction(0);
        assertTrue(multiSig.getTransaction(0).executed);
    }

    function testConfirmTransactionInvalidId() public {
        vm.prank(owner1);
        vm.expectRevert(bytes("Invalid Transaction Id"));
        multiSig.confirmTransaction(1);
    }

    function testConfirmTransactionAlreadyExecuted() public {
        vm.prank(owner1);
        vm.deal(owner1, 10 wei);
        multiSig.submitTransaction{value: 10 wei}(receiver);
        vm.prank(owner2);
        multiSig.confirmTransaction(0);
        vm.prank(owner1);
        vm.expectRevert(bytes("Transaction Already Executed"));
        multiSig.confirmTransaction(0);
    }

    function testConfirmTransactionAlreadyApproved() public {
        vm.prank(owner1);
        vm.deal(owner1, 10 wei);
        multiSig.submitTransaction{value: 10 wei}(receiver);
        vm.prank(owner1);
        vm.expectRevert(bytes("Transaction Already Approved"));
        multiSig.confirmTransaction(0);
    }

    function testCancelTransaction() public {
        vm.prank(owner1);
        vm.deal(owner1, 10 wei);
        multiSig.submitTransaction{value: 10 wei}(receiver);
        vm.prank(owner1);
        multiSig.cancelTransaction(0);
        assertEq(multiSig.getTransaction(0).approvals, 0);
    }

    function testCancelTransactionInvalidId() public {
        vm.prank(owner1);
        vm.deal(owner1, 10 wei);
        multiSig.submitTransaction{value: 10 wei}(receiver);
        vm.prank(owner1);
        vm.expectRevert(bytes("Invalid Transaction Id"));
        multiSig.cancelTransaction(1);
    }

    function testCancelTransactionAlreadyExecuted() public {
        vm.prank(owner1);
        vm.deal(owner1, 10 wei);
        multiSig.submitTransaction{value: 10 wei}(receiver);
        vm.prank(owner2);
        multiSig.confirmTransaction(0);
        vm.prank(owner1);
        vm.expectRevert(bytes("Transaction Already Executed"));
        multiSig.cancelTransaction(0);
    }

    function testCancelTransactionNotApproved() public {
        vm.prank(owner1);
        vm.deal(owner1, 10 wei);
        multiSig.submitTransaction{value: 10 wei}(receiver);
        vm.prank(owner2);
        vm.expectRevert(bytes("Transaction Already not Approved"));
        multiSig.cancelTransaction(0);
    }
}
