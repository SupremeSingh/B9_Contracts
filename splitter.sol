//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SplitterV2 is Ownable { 

    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    EnumerableSet.AddressSet private tokenSet;
    mapping(address => mapping(address => uint256)) public UserToTokenToBalance;

    event AddNewDeposit(address indexed contributor, address tokenAddress, uint256 tokenAmount);
    event WithdrawToken(address indexed withdrawer, address tokenAddress, uint256 tokenAmount);

    function withdrawToken(address tokenAddress, uint256 tokenAmount) public {
        require(UserToTokenToBalance[msg.sender][tokenAddress] >= tokenAmount, "Insufficient balance in account");
        
        IERC20 tokenToBeSplit = IERC20(tokenAddress);  
        UserToTokenToBalance[msg.sender][tokenAddress] -= tokenAmount;
        emit WithdrawToken(msg.sender, tokenAddress, tokenAmount);

        tokenToBeSplit.safeTransfer(msg.sender, tokenAmount);
    } 

    function addNewDeposit(address tokenAddress, uint256 tokenAmount,  address[] memory initialUserList) external {     
        IERC20 tokenToBeSplit = IERC20(tokenAddress);  
        require(tokenAddress != address(0), "This is not a valid address");
        require(tokenToBeSplit.totalSupply() >= 0, "This is not a valid ERC20 Token");

        tokenSet.add(tokenAddress);

        uint256 individualTokenAmount = tokenAmount / initialUserList.length;
        uint256 dust = tokenAmount % initialUserList.length;
        for (uint256 i = 0; i < initialUserList.length; ++i ) {
            UserToTokenToBalance[initialUserList[i]][tokenAddress] += individualTokenAmount;
        }
        
        UserToTokenToBalance[owner()][tokenAddress] += dust;
        emit AddNewDeposit(msg.sender, tokenAddress, tokenAmount);

        tokenToBeSplit.safeTransferFrom(msg.sender,address(this), tokenAmount);
    }

    function withdrawAll() external {
        address[] memory knownTokenList = EnumerableSet.values(tokenSet);
        for (uint256 i = 0; i < knownTokenList.length; ++i ) {
            withdrawToken(knownTokenList[i], UserToTokenToBalance[msg.sender][knownTokenList[i]]);
        }
    }   
}
