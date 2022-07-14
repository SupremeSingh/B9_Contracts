//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract Splitter is Ownable { 

    using SafeERC20 for IERC20;
    IERC20 immutable tokenToBeSplit;

    mapping (address => uint256) userAccountDetails;

    uint256 public totalValueDeposited;
    uint256 public currentShareValue;
    uint256 public totalSharesIssued;

    event NewParticipantAdded(address indexed newParticipant);
    event DepositTokens(address contributor, uint256 amountAdded);
    event WithdrawTokens(address indexed withdrawer, uint256 amountWithdrawn);
    
    constructor(address _tokenAddress, address[] memory initialUserList, uint256 baseShares) {
      require(baseShares % 1000000000 > 0, "Base shares must be at least 9 decimals");
      require(IERC20(_tokenAddress).totalSupply() >= 0, "This is not a valid ERC20 Token");
      
      tokenToBeSplit = IERC20(_tokenAddress);  
      for (uint256 i = 0; i < initialUserList.length; ++i ) {
          _addNewUser(initialUserList[i], baseShares);
      }
      totalSharesIssued += baseShares * initialUserList.length;
    }

    function depositTokens(uint256 amount) external onlyOwner() {
        currentShareValue = amount / totalSharesIssued;
        totalValueDeposited += amount;
        emit DepositTokens(msg.sender, amount);
        tokenToBeSplit.safeTransferFrom(msg.sender,address(this), amount);
    }

    function addNewUser(address newUserAddress, uint256 baseShares) external onlyOwner() {
        totalSharesIssued += baseShares;
        currentShareValue = totalValueDeposited / totalSharesIssued;
        _addNewUser(newUserAddress, baseShares);
    }

    function withdrawDust() external onlyOwner() {
        uint256 dustAmount = tokenToBeSplit.balanceOf(address(this)) - totalValueDeposited;
        require(dustAmount > 0, "Not enough dust");
        tokenToBeSplit.safeTransfer(msg.sender, dustAmount);
        emit WithdrawTokens(msg.sender, dustAmount);
    }

    function withdrawTokens(uint256 amountToBeWithdrawn) external {
        require(userAccountDetails[msg.sender] * currentShareValue >= amountToBeWithdrawn, "Insufficient balance in account");
        userAccountDetails[msg.sender] -= amountToBeWithdrawn / currentShareValue;
        totalSharesIssued -= amountToBeWithdrawn / currentShareValue;
        totalValueDeposited -= amountToBeWithdrawn;
        emit WithdrawTokens(msg.sender, amountToBeWithdrawn);
        tokenToBeSplit.safeTransfer(msg.sender, amountToBeWithdrawn);
    }

    function _addNewUser(address newUserAddress, uint256 shares) private {
        require(shares > 0, "Share value cannot be 0");
        require(userAccountDetails[newUserAddress] == 0, "This address has been registered");
        require(shares % 1000000000 > 0, "Base shares must be at least 9 decimals");
        require(newUserAddress != address(0), "0x - This address is not a valid input");
        
        userAccountDetails[newUserAddress] = shares;
        emit NewParticipantAdded(newUserAddress); 
    }

}
