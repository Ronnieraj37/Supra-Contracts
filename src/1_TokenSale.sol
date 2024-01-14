// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenSale is ERC20 {

    uint256 public presaleCap;
    uint256 public publicSaleCap;

    uint256 public presaleCapLeft;
    uint256 public publicSaleCapLeft;

    uint256 public presaleMinContribution;
    uint256 public presaleMaxContribution;

    uint256 public publicSaleMinContribution;
    uint256 public publicSaleMaxContribution;

    mapping(address => uint256) public presaleContributions;
    mapping(address => uint256) public publicSaleContributions;

    bool public presaleClosed = false;
    bool public publicSaleClosed = false;

    event TokensPurchased(address indexed buyer, uint256 amount, bool isPresale);
    event RefundClaimed(address indexed contributor, uint256 amount, bool isPresale);
    event TokenDistribution(address indexed recipient, uint256 amount);
    event PresaleClosed();
    event PublicSaleClosed();

    address public owner;

    constructor(uint256 _presaleMinContribution,uint256 _presaleMaxContribution,uint256 _publicSaleMinContribution,uint256 _publicSaleMaxContribution, uint _presaleCap , uint _publicSaleCap) ERC20("Token", "TKN") {
        owner = msg.sender;
        presaleMinContribution = _presaleMinContribution;
        presaleMaxContribution =  _presaleMaxContribution;
        publicSaleMinContribution= _publicSaleMinContribution;
        publicSaleMaxContribution=  _publicSaleMaxContribution;
        presaleCap = _presaleCap;
        presaleCapLeft = _presaleCap;
        publicSaleCapLeft = _publicSaleCap;
        publicSaleCap = _publicSaleCap;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Owner Rights Needed");
        _;
    }

    modifier onlyWhenOpen() {
        require(
            (!presaleClosed)||(!publicSaleClosed),
            "Token sale is closed"
        );
        _;
    }

    modifier onlyPresale() {
        require(!presaleClosed, "Presale is closed");
        _;
    }

    modifier onlyPublicSale() {
        require( presaleClosed && !publicSaleClosed, "Public sale is closed");
        _;
    }

    function contributeToPresale() external payable onlyWhenOpen onlyPresale {
        require(msg.value >= presaleMinContribution , "Invalid contribution amount");
        require(presaleContributions[msg.sender]+(msg.value) <= presaleMaxContribution, "Induvidual Contribution exceeded");
        require(msg.value <= presaleCapLeft, "Exceeds presale cap");
        presaleContributions[msg.sender] = presaleContributions[msg.sender]+(msg.value);
        _mint(msg.sender, getTokenAmount(msg.value, true));
        presaleCapLeft -= msg.value;
        emit TokensPurchased(msg.sender, msg.value, true);
    }

    function contributeToPublicSale() external payable onlyWhenOpen onlyPublicSale {
        require(msg.value >= publicSaleMinContribution, "Invalid contribution amount");
        require(publicSaleContributions[msg.sender]+(msg.value) <= publicSaleMaxContribution , "Induvidual Contribution exceeded");
        require(msg.value <= publicSaleCapLeft, "Exceeds public sale cap");
        publicSaleCapLeft -= msg.value;
        publicSaleContributions[msg.sender] = publicSaleContributions[msg.sender]+(msg.value);
        _mint(msg.sender, getTokenAmount(msg.value, false));
        emit TokensPurchased(msg.sender, msg.value, false);
    }

    function distributeTokens(address recipient, uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid token amount");
        _mint(recipient, amount);
        emit TokenDistribution(recipient, amount);
    }

    function userBalance() external view returns (uint){
        return balanceOf(msg.sender);
    }

    function claimRefund() external onlyWhenOpen {
        require(
            ( !presaleClosed && presaleContributions[msg.sender] > 0) && presaleCapLeft > 0||
            ( !publicSaleClosed && publicSaleContributions[msg.sender] > 0 && publicSaleCapLeft >0 ),
            "No refund available"
        );

        uint256 refundAmount = 0;
        if ( !presaleClosed) {
            refundAmount = presaleContributions[msg.sender];
            presaleContributions[msg.sender] = 0;
            transfer(address(this), getTokenAmount(refundAmount,true));
            payable(msg.sender).transfer(refundAmount);
            emit RefundClaimed(msg.sender, refundAmount, !presaleClosed);
        } else if ( !publicSaleClosed) {
            refundAmount = publicSaleContributions[msg.sender];
            publicSaleContributions[msg.sender] = 0;
            transfer(address(this), getTokenAmount(refundAmount,false));
            payable(msg.sender).transfer(refundAmount);
            emit RefundClaimed(msg.sender, refundAmount, !presaleClosed);
        }
    }

    function closePresale() external onlyOwner {
        require(!presaleClosed, "Presale already closed");
        presaleClosed = true;
        emit PresaleClosed();
    }

    function closePublicSale() external onlyOwner {
        require(!publicSaleClosed, "Public sale already closed");
        publicSaleClosed = true;
        emit PublicSaleClosed();
    }

    function getTokenAmount(uint256 weiAmount, bool isPresale) internal pure returns (uint256) {
        uint256 rate = isPresale ? 1000 : 800; // 1 Ether = 1000 tokens during presale, 1 Ether = 800 tokens during public sale
        return weiAmount * (rate);
    }
}
