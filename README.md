# B9 Labs Solutions

This is a series of solutions for the Solidity contract development series by the B9 Labs auditing service. These simple-seeming challenges trip up the developer on a number of vulnerabilities, that are otherwise easy to ignore. There is also a strong focus on architecture, gas efficiency and best coding practices. 

## P1 - Splitter

Here we are creating a smart contract that allows an initializer to split a certain token between a set of recipients in any proportion they so wish. 

Basic specs - 

 - Ensure all transactions are on-chain and easy to track  
 - Return excessive balances from contract to the contributor  
 - Take up an IERC20 Token and a list of people to split it between  
 - Have a clear contributor to the vault, and allow them to add agents

Additionally, we will be adding testing conditions to ensure the contract functions properly.

