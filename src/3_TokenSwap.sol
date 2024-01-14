// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenSwap {
    address public owner;
    ERC20 public tokenA;
    ERC20 public tokenB;
    uint256 public exchangeRate;

    event Swap(address indexed user, uint256 amountA, uint256 amountB);

    constructor(address _tokenA, address _tokenB, uint256 _exchangeRate) {
        require(
            _tokenA != address(0) && _tokenB != address(0),
            "Token address cannot be zero"
        );
        require(_exchangeRate > 0, "Exchange rate must be greater than zero");

        tokenA = ERC20(_tokenA);
        tokenB = ERC20(_tokenB);
        exchangeRate = _exchangeRate;
        owner = msg.sender;
    }

    function swapAToB(uint256 amountA) external {
        require(amountA > 0, "Amount must be greater than zero");

        uint256 amountB = (amountA * exchangeRate) / (10 ** tokenA.decimals());

        require(
            tokenA.balanceOf(msg.sender) >= amountA,
            "Insufficient balance of Token A"
        );
        require(
            tokenB.balanceOf(address(this)) >= amountB,
            "Insufficient balance of Token B"
        );

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transfer(msg.sender, amountB);

        emit Swap(msg.sender, amountA, amountB);
    }

    function swapBToA(uint256 amountB) external {
        require(amountB > 0, "Amount must be greater than zero");

        uint256 amountA = (amountB * (10 ** tokenA.decimals())) / exchangeRate;

        require(
            tokenB.balanceOf(msg.sender) >= amountB,
            "Insufficient balance of Token B"
        );
        require(
            tokenA.balanceOf(address(this)) >= amountA,
            "Insufficient balance of Token A"
        );

        tokenB.transferFrom(msg.sender, address(this), amountB);
        tokenA.transfer(msg.sender, amountA);

        emit Swap(msg.sender, amountB, amountA);
    }

    function setExchangeRate(uint256 newExchangeRate) external {
        require(owner == msg.sender, "Owner Rights Needed");
        require(newExchangeRate > 0, "Exchange rate must be greater than zero");
        exchangeRate = newExchangeRate;
    }
}
