//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract  Remittance is Ownable { 
    
    uint256 withdrawalTime;
    address[] public userList;
    mapping(address => bytes32) userToPassword;

    modifier isExchanger() {
        require(msg.sender == userList[0]);
        _;
    }

    event WithdrawFunds(address indexed withdrawer, uint256 amountWithdrawn);

    constructor(uint256 seedAmount, address exchangerRole, address recieverRole) payable {
        require(msg.value >= seedAmount, "Not enough seed funding provided");
        userList.push(exchangerRole);
        userList.push(recieverRole);
    }

    // Implement an atomic transaction over here 
    function withdrawFunds(uint256 exchangerPassword, uint256 receiverPassword) isExchanger() external {
        require(msg.sender == userList[0]);
        require(_computePasswordFromNonce(exchangerPassword) == userToPassword[userList[0]]);
        require(_computePasswordFromNonce(receiverPassword) == userToPassword[userList[1]]);       
        
        emit WithdrawFunds(msg.sender, address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    function _computePasswordFromNonce(uint256 nonce) internal returns(bytes32 passwordHash) {
        passwordHash = keccak256(abi.encodePacked(nonce));
        userToPassword[msg.sender] = passwordHash;
    }

}
