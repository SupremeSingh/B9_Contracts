//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Remittance is Ownable { 

    uint256 public totalFundsToSend;
    uint256 public reviewDuration;
    bytes32 public uniqueSignatureValue;
    bool public investigationStatus;

    mapping(address => uint256) agentToEthBalance;

    event ReleaseTokensToExchanger(address exchangerAddress, uint256 timestamp);
    event SubmitFraudProof(address recipientAddress, uint256 timestamp);
    event InvestigationConcluded(address addressPunished, uint256 fundsRetained, uint256 timestamp);

    modifier whileInReview() {
        require(block.timestamp < reviewDuration, "Can only do this in the review period");
        _;
    }

    constructor(uint256 fundsToSend, uint256 withholdingPeriod, bytes32 uniqueSignature) payable {
        require(msg.value >= fundsToSend, "Not enough funding provided");
        require(withholdingPeriod >= 1 hours, "At least 1 hour of waiting is needed");
        reviewDuration = block.timestamp + (withholdingPeriod * 1 hours);
        totalFundsToSend = fundsToSend;
        uniqueSignatureValue = uniqueSignature;
    }   

    function releaseTokensToExchanger(uint256 exchangerNumber, uint256 recipientNumber) external whileInReview {
        require(uniqueSignatureValue == keccak256(abi.encodePacked(exchangerNumber, recipientNumber)), "One of the inputs is invalid");
        agentToEthBalance[msg.sender] += address(this).balance;
        emit ReleaseTokensToExchanger(msg.sender, block.timestamp);
    }

    function submitFraudProof() external payable whileInReview {
        require(msg.value >= totalFundsToSend, "Inadequate stake for the fraud proof");
        agentToEthBalance[msg.sender] += msg.value;
        investigationStatus = true;
        emit SubmitFraudProof(msg.sender, block.timestamp);
    }

    function conductInvestigation(address agentToPunish) external onlyOwner whileInReview {
        require(investigationStatus, "No complaint filed by recipient");
        agentToEthBalance[msg.sender] += agentToEthBalance[agentToPunish];
        emit InvestigationConcluded(agentToPunish, agentToEthBalance[agentToPunish], block.timestamp);
        agentToEthBalance[agentToPunish] = 0;
        investigationStatus = false;
    }

    function withdrawValue(uint256 amount) public {
        require(block.timestamp > reviewDuration, "Can only withdraw funds after review duration");
        require(!investigationStatus, "Cannot withdraw during on-going investigation");
        require(agentToEthBalance[msg.sender] >= amount, "Insufficient balance in account");
        agentToEthBalance[msg.sender] -= amount;
        payable(address(msg.sender)).transfer(amount);
    } 
}
