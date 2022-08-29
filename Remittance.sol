//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract RemittanceContract { 

struct Remittance {
        address sender;
        address exchanger;
        uint256 value;
        uint256 expiry;
    }

    mapping (bytes32 => Remittance) codeToRemittance; 
    mapping (address => uint256) walletBalance;

    event NewRemittanceRequestCreated(address sender, address exchanger, uint256 transactionValue, uint256 expiry);
    event ReleaseTokensToExchanger(address exchanger, uint256 transactionValue, uint256 timestamp);
    event TransactionConfirmedBySender(address sender, address exchanger, uint256 timestamp);

    function createNewRemittanceRequest(uint256 withholdingInterval, bytes32 remittanceHash) external payable {
        require(msg.value > 0, "Remittance should have non-zero deliverable value");
        require(withholdingInterval >= 1, "Remittance must have more than 1 hour of review");      
        codeToRemittance[remittanceHash] = Remittance(msg.sender, address(0), msg.value, block.timestamp + withholdingInterval * 1 hours);
        emit NewRemittanceRequestCreated(msg.sender, address(0), msg.value, block.timestamp + withholdingInterval * 1 hours);
    }

    function releaseTokensToExchanger(bytes32 exchangerNumberHash, bytes32 recipientNumberHash) external {
        bytes32 uniqueSignatureValue = keccak256(abi.encodePacked(exchangerNumberHash, recipientNumberHash));
        require(codeToRemittance[uniqueSignatureValue].value > 0, "There is no balance against this value");
        require(codeToRemittance[uniqueSignatureValue].expiry > block.timestamp, "This check has now expired");
        codeToRemittance[uniqueSignatureValue].exchanger = msg.sender;
        emit ReleaseTokensToExchanger(msg.sender, walletBalance[msg.sender], block.timestamp);
    }

    function confirmTransaction(bytes32 remittanceHash) external {
        require(msg.sender == codeToRemittance[remittanceHash].sender, "Only the sender can withdraw funds");
        require(codeToRemittance[remittanceHash].exchanger != address(0), "This transactions first needs to be initiated by exchanger"); 
        if (codeToRemittance[remittanceHash].expiry > block.timestamp) {
            walletBalance[codeToRemittance[remittanceHash].exchanger] += codeToRemittance[remittanceHash].value;
        }  else {
            walletBalance[codeToRemittance[remittanceHash].sender] += codeToRemittance[remittanceHash].value;   
        }
        codeToRemittance[remittanceHash].value = 0;
        emit TransactionConfirmedBySender(codeToRemittance[remittanceHash].sender, codeToRemittance[remittanceHash].exchanger, block.timestamp);
    }   

    function withdrawValue(uint256 amount) public {
        require(walletBalance[msg.sender] > 0, "You do not have any money in this account");
        walletBalance[msg.sender] = 0;
        payable(address(msg.sender)).transfer(amount);
    } 
}
