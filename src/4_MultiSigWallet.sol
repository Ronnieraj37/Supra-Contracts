// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

contract MultiSigWallet {
    mapping(address => bool) public isOwner;
    uint public requiredApprovals;

    struct Transaction {
        uint value;
        uint approvals;
        address to;
        bool executed;
    }

    mapping(uint => mapping(address => bool)) isConfirmed;
    Transaction[] public transactions;

    event TransactionSubmitted(
        uint transactionId,
        address sender,
        address receiver,
        uint amount
    );
    event TransactionConfirmed(uint transactionId, address sender);
    event TransactionCanceled(uint transactionId, address sender);
    event TransactionExecuted(uint transactionId);

    constructor(address[] memory _owners, uint _requiredApprovals) {
        require(_owners.length > 1, "Cannot have a sing owner");
        require(
            _requiredApprovals > 1 && requiredApprovals <= _owners.length,
            "Wrong input of requiredApprovals"
        );

        for (uint i = 0; i < _owners.length; ) {
            require(_owners[i] != address(0), "Invalid Owner");
            isOwner[_owners[i]] = true;
            unchecked {
                i++;
            }
        }
        requiredApprovals = _requiredApprovals;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Only Owner Function");
        _;
    }

    function submitTransaction(address _to) public payable onlyOwner {
        require(_to != address(0), "Invalid Receiver's Address");
        require(msg.value > 0, "Transfer Amount Must Be Greater Than 0");

        uint transactionId = transactions.length;
        isConfirmed[transactionId][msg.sender] = true;
        transactions.push(Transaction(msg.value, 1, _to, false));
        emit TransactionSubmitted(transactionId, msg.sender, _to, msg.value);
    }

    function confirmTransaction(uint _transactionId) public onlyOwner {
        require(_transactionId < transactions.length, "Invalid Transaction Id");
        require(
            !transactions[_transactionId].executed,
            "Transaction Already Executed"
        );
        require(
            !isConfirmed[_transactionId][msg.sender],
            "Transaction Already Approved"
        );

        isConfirmed[_transactionId][msg.sender] = true;
        transactions[_transactionId].approvals++;

        emit TransactionConfirmed(_transactionId, msg.sender);
        if (transactions[_transactionId].approvals >= requiredApprovals) {
            (bool success, ) = transactions[_transactionId].to.call{
                value: transactions[_transactionId].value
            }("");
            require(success, "Transaction Execution Failed");

            transactions[_transactionId].executed = true;
            emit TransactionExecuted(_transactionId);
        }
    }

    function cancelTransaction(uint _transactionId) public onlyOwner {
        require(_transactionId < transactions.length, "Invalid Transaction Id");
        require(
            !transactions[_transactionId].executed,
            "Transaction Already Executed"
        );
        require(
            isConfirmed[_transactionId][msg.sender],
            "Transaction Already not Approved"
        );

        isConfirmed[_transactionId][msg.sender] = false;
        transactions[_transactionId].approvals--;

        emit TransactionCanceled(_transactionId, msg.sender);
    }

    function getTransaction(uint _id) public view returns (Transaction memory) {
        return transactions[_id];
    }
}
