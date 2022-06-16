//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Splitter is Ownable{ 

    IERC20 tokenToBeSplit;

    struct UserAccounts {
        uint256 balances;
        bool hasBeenRegistered;
    }
    address[] public allAddressesRegistered; 
    mapping (address => UserAccounts) userAccountDetails;
    uint256 private carry;

    event NewParticipantAdded(address indexed newParticipant, address registrar);
    event NewTokensAdded(address contributor, uint256 amountAdded);

    modifier notForOwner(address _addressToBeUsed) {
        require(_addressToBeUsed != owner(), "The owner cannot benefit from this function");
        _;
    }

    constructor(address _tokenAddress) {
      tokenToBeSplit = IERC20(_tokenAddress);  
    }

    function depositTokens(uint256 _amount) external onlyOwner() {
        require(tokenToBeSplit.allowance(msg.sender, address(this)) >= _amount,"Insuficient Allowance");
        require(tokenToBeSplit.transferFrom(msg.sender,address(this), _amount),"Transfer Failed");
    
        updateUserBalances(_amount);
        
        emit NewTokensAdded(msg.sender, _amount);
    }

    function withdrawTokens(uint256 _amountToBeWithdrawn) external notForOwner(msg.sender) returns(bool didGoThrough){
        require(userAccountDetails[msg.sender].balances > _amountToBeWithdrawn, "Insufficient balance in account");
        userAccountDetails[msg.sender].balances -= _amountToBeWithdrawn;
        tokenToBeSplit.transfer(msg.sender, _amountToBeWithdrawn);
        didGoThrough = true;
    }

    function addParticipants(address _newUserAddress) external onlyOwner notForOwner(_newUserAddress){
        require(_newUserAddress != address(0), "0x is not a valid input");
        require(!userAccountDetails[_newUserAddress].hasBeenRegistered, "This address has been registered");
        allAddressesRegistered.push(_newUserAddress);
        userAccountDetails[_newUserAddress] = UserAccounts(0, true);
        emit NewParticipantAdded(_newUserAddress, msg.sender);
    }

    function getContractBalance() public view returns(uint256 value){
        value = tokenToBeSplit.balanceOf(address(this));
    }

    // Does not have decimals so far 
    function updateUserBalances(uint256 _amount) internal returns(bool output) {
        uint256 intVal = (_amount + carry) / allAddressesRegistered.length;
        for (uint256 i = 0; i < allAddressesRegistered.length; ++i ) {
            userAccountDetails[allAddressesRegistered[i]].balances += intVal;
        }
        carry = (_amount + carry) % allAddressesRegistered.length;
        output = true;
    }

}
