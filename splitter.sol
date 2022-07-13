//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract SplitterFactory {

    mapping(address => mapping(address => bool)) userAccountDetails;
    
    event NewSplitterCreated(address indexed creator, address splitter);

    function deploy(address tokenAddress) external {
        require(userAccountDetails[msg.sender][tokenAddress] == false, "You have a splitter for this token");
        Splitter newSplitterInstance = new Splitter(tokenAddress);
        userAccountDetails[msg.sender][tokenAddress] = true;
        emit NewSplitterCreated(msg.sender, address(newSplitterInstance));

        newSplitterInstance.transferOwnership(msg.sender);
    }
}

contract Splitter is Ownable { 

    IERC20 tokenToBeSplit;

    struct UserAccounts {
        uint256 balances;
        bool hasBeenRegistered;
    }

    address[] public allAddressesRegistered; 
    mapping (address => UserAccounts) userAccountDetails;

    event NewParticipantAdded(address indexed newParticipant);
    event DepositTokens(address contributor, uint256 amountAdded);
    event WithdrawTokens(address indexed withdrawer, uint256 amountWithdrawn);

    constructor(address _tokenAddress) {
      require(IERC20(_tokenAddress).totalSupply() >= 0, "This is not a valid ERC20 Token");
      tokenToBeSplit = IERC20(_tokenAddress);  
    }

    function depositTokens(uint256 _amount) external onlyOwner() {
        tokenToBeSplit.transferFrom(msg.sender,address(this), _amount);
        emit DepositTokens(msg.sender, _amount);
        updateUserBalances(_amount);
    }

    function withdrawTokens(uint256 _amountToBeWithdrawn) external {
        require(msg.sender != owner(), "Owner cannot withdraw funds from the contract");
        require(userAccountDetails[msg.sender].balances >= _amountToBeWithdrawn, "Insufficient balance in account");
        userAccountDetails[msg.sender].balances -= _amountToBeWithdrawn;
        emit WithdrawTokens(msg.sender, _amountToBeWithdrawn);
        tokenToBeSplit.transfer(msg.sender, _amountToBeWithdrawn);
    }


    function addParticipants(address _newUserAddress) external onlyOwner {
        require(_newUserAddress != address(0) && _newUserAddress != owner(), "This address is not a valid input");
        require(!userAccountDetails[_newUserAddress].hasBeenRegistered, "This address has been registered");
        allAddressesRegistered.push(_newUserAddress);
        userAccountDetails[_newUserAddress] = UserAccounts(0, true);
        emit NewParticipantAdded(_newUserAddress);
    }

    function getContractBalance() public view returns(uint256 value){
        value = tokenToBeSplit.balanceOf(address(this));
    }

    function updateUserBalances(uint256 _amount) internal returns(bool success) {
        uint256 intVal = _amount / allAddressesRegistered.length;
        uint256 carry = _amount % allAddressesRegistered.length;
        for (uint256 i = 0; i < allAddressesRegistered.length; ++i ) {
            userAccountDetails[allAddressesRegistered[i]].balances += intVal;
        }
        tokenToBeSplit.transfer(owner(), carry);
        success = true;
    }

}
