// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ICO {
    address admin;
    ERC20 public tokenContract;
    uint public tokenPrice;
    uint public tokenSold;

    uint public preSaleStartTime;
    uint public preSaleEndTime;
    uint public preSaleTokenAmount;
    uint public preSaleTokensSold;
    mapping(address => bool) public preSaleWhitelist;
    mapping(address => mapping (address => uint256)) allowed;

    event Sell(address buyer, uint amount);

    constructor(
        address _tokenContractAddress, 
        uint _tokenPrice, 
        uint _preSaleDuration, 
        uint _preSaleTokenAmount
    ) {
        admin = msg.sender;
        tokenContract = ERC20(_tokenContractAddress); 
        tokenPrice = _tokenPrice; 
        preSaleStartTime = block.timestamp;
        preSaleEndTime = block.timestamp + _preSaleDuration;
        preSaleTokenAmount = _preSaleTokenAmount;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyWhilePreSaleOpen() {
        require(block.timestamp >= preSaleStartTime && block.timestamp <= preSaleEndTime, "Pre-sale is not open");
        _;
    }

    modifier onlyWhileICOOpen() {
        require(block.timestamp > preSaleEndTime, "ICO is not open");
        _;
    }

    function addToPreSaleWhitelist(address _address) public onlyAdmin {
        preSaleWhitelist[_address] = true;
    }

    function removeFromPreSaleWhitelist(address _address) public onlyAdmin {
        preSaleWhitelist[_address] = false;
    }

    function buyTokensPreSale(uint numberOfTokens_) public payable onlyWhilePreSaleOpen {

        require(preSaleWhitelist[msg.sender], "Address not whitelisted for pre-sale");
        uint requiredValue = (numberOfTokens_ * tokenPrice)/ 1 ether;
        require(msg.value >= requiredValue, "Incorrect Ether value sent");
        require(preSaleTokensSold + numberOfTokens_ <= preSaleTokenAmount, "Not enough tokens available in pre-sale");
        require(tokenContract.balanceOf(address(this)) >= numberOfTokens_, "Not enough tokens in contract");

        preSaleTokensSold += numberOfTokens_;
        tokenSold += numberOfTokens_;

        require(tokenContract.transferFrom(msg.sender, address(this), numberOfTokens_), "Token transfer failed");

        emit Sell(msg.sender, numberOfTokens_);
    }

    function buyTokens(uint numberOfTokens_) public payable onlyWhileICOOpen {
        uint requiredValue = (numberOfTokens_ * tokenPrice)/ 1 ether;
        require(msg.value >= requiredValue, "Incorrect Ether value sent");
        //require(tokenContract.balanceOf(address(this)) >= numberOfTokens_, "Not enough tokens in contract");

        tokenSold += numberOfTokens_;

        require(tokenContract.transferFrom(admin, msg.sender,numberOfTokens_), "Token transfer failed");

        emit Sell(msg.sender, numberOfTokens_);
    }

    function approve(address spender, uint256 amount) public onlyAdmin returns (bool) {
        return tokenContract.approve(spender, amount);
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return tokenContract.allowance(owner, spender);
    }

    function balanceOf(address _address) public view returns (uint256) {
        return tokenContract.balanceOf(_address);
    }

    function endSale() public onlyAdmin {
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))), "Token transfer to admin failed");

        payable(admin).transfer(address(this).balance);
    }
}
