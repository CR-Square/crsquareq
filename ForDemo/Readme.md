 
-----------x
PSEUDOCODE: Escrow Smart Contract
-----------x

A. Metamask wallet setup:
-------------------------x

1. Create multiple metamask wallets filled with test ethers choose any test network.
2. Founder wallet address and SuperAdmin wallet address is must, fill it up with test ethers and stable coins.
3. In order to make the Escrow smart contract accept ERC20 token, go to etherscan address of the specified stablecoin and then go to write function and connect your metamask wallet and then 
-> approve function:
   address: "the smart contract address"
   uint: specify amount in wei, the set maximum allowance that the smart contract can use with users stable coin or ether.

--------------------------------------------------------------------x
B. Smart Contract Work Flow: (step by step function to invoke first)
--------------------------------------------------------------------x

Constructor Function :

a. _ballotOfficialName: Enter the Name of the Founder (will be registered in the blockchain)
b. _proposal: Enter the proposal laid by the founder (will be registered in the blockchain)
c. valueAllocated: The maximum value the smart contract can collect from the investors.
d. _setFounder: Founders metamask wallet address.
e.  _superAdmin: SuperAdmins metamask wallet address.

----------x
Functions:
----------x

1.  function "whitelistToken": Pass in values as bytes32 of symbol of token (eg: USDC - 0x32000....0)
address: contract verified and deployed address of the ERC20-USDC smart contract in the etherscan.

2. function "depositTokens": pass in values in uint(wei format) and bytes32 value of the token symbol that you want to deposit.

3. function "DirectDepositTokens": Investors who wants to take the risk and direclty want to  invest tokens to the contract can invest directly.

4. function "withdrawAllTokenFromThePool": Only founder can access this function and once all the conditions are cleared founder can withdraw funds from the smart contract.
amount: enter value in wei.
symbol: enter token symbol.

5. function "withdrawTokens": The state of this function is available for the investors to withdraw their fund once validators have failed to approve the transaction, pass in value and symbol to withdraw the funds.

6. function "accountBalances" : This will get the balance deposited by a single address to the smart contract.

7. function "Withdraw10PercentOfSingleTokenDeposit" : Special condition where, if a single investor has invested more than 80% of the pool max limit, 10% of the tokens are available for the founder to withdraw immediately.

8. function "addValidators": This function is restricted to onlySuperAdmin whereas he can only add validators and name them, once validators are added they can select their wallet address and vote for the proposal.

9. function "Validate": This function lets us validators to validate either "true" for approve and "false" for reject.

10. function "SuperAdminReviewValidatorRequest": This function will make the admin to change the decision of validators to false, or true and the condition within withdraw of tokens will change according to that.

11. function type - address [] array: 

a.) "validatorsWhoApproved" - Pass in uint values to get the wallet address who have approved for the smart contract.

b.) "validatorsWhoRejected" - Pass in uint values to get the wallet address who have rejected for the smart contract.

12. function uint: "totalDepositedStableCoinsInThePot" - Outputs the total tokens deposited in the smart contract. 

 
