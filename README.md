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

## P2 - Remittance


In this situation, we presume there are three people: Alice, Bob & Carol:

- Alice wants to send funds to Bob, but she only has ether & Bob wants to be paid in local currency.
- Luckily, Carol runs an exchange shop that converts ether to local currency.
- Therefore, to get the funds to Bob, Alice will allow the funds to be transferred through Carol's Exchange Shop.
- Carol will convert the ether from Alice into local currency for Bob (possibly minus commission).
- To successfully withdraw the ether from Alice, Carol needs to submit two passwords to Alice's Remittance contract:
	- One password that Alice gave to Carol in an email
	- Another password that Alice sent to Bob over SMS.

Since they each have only half of the puzzle, Bob & Carol need to meet in person so they can supply both passwords to the contract. This is a security measure. It may help to understand this use-case as similar to a 2-factor authentication.

Once Carol & Bob meet and Bob gives Carol his password from Alice, Carol can submit both passwords to Alice's remittance contract. If the passwords are correct, the contract will release the ether to Carol who will then convert it into local funds and give those to Bob (again, possibly minus commission).

Of course, for safety, no one should send their passwords to the blockchain in the clear.
