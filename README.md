**Contract working structure**
1. Factory Smart Contract : (For adding validators to the smart contract)

    a. connect you respective wallet using .connect() and add you wallet address to this smart contract.

    b. Numerous validators can use this smart contract to register their address to the smart contract.

    c. Whether validator or not status can be checked in this smart contract.

2. Founder Smart Contract: (For founders to the smart contract)

    a. To register as founder, the respective founder needs to connect wallet to the smart contract and register.

    b. using "verifyFounder" whether connected wallet is registered or not.

    c. using "getAllFounderAddress" All registered founder details can be checked.

3. InvestorLogin Smart Contract: (For founders to the smart contract) - PrivateRound

    a. To register as Investor, the respective Investor needs to connect wallet to the smart contract and register.

    b. using "verifyInvestor" whether connected wallet is registered or not.

    c. using "getAllInvestorAddress" All registered founder details can be checked.

4. projectAndProposal Smart Contract: 

    a. using "setFounderAndCycleForTheProject" - The founder should connect wallet and set the respective details.

    b. using "setInitialId" - The funds in the smart contract are secured by confidential id's, founder has access to this function.

    c. using "depositStableTokens" - The investors are advised prior to approve tokens for the smart contract to hold and then deposit tokens to the smart contract.

    d. using "Withdraw10PercentOfStableCoin" - Once the tokens are deposited by the investors, 10% of the tokens are available for the founder to withdraw from the smart contract.

    e. using "setSubsequentId" - The founder can initiate the subsequent id for the project, based on investors setup.

    f. using "Validation" - Once the setup is finished, registerd validators can connect their wallet and either approve or reject the project.

    g. using "withdrawSubsequentStableCoins" - Once maximum validation is completed the founder can withdraw tokens based on the subsequent setup.

    h. using "withdrawTokensByInvestor" - If more than 3 subsequence proposal has been rejected by the validators then the funds are available back for the investors to collect.

5. Vesting Smart Contract:

    a. using "depositFounderLinearTokens" - The founder deposits FTK tokens to the investor.

    b. using "depositFounderLinearTokensToInvestors" - The founder deposits FTK tokens to batch of investors, vesting mode and vesting months are required here.

    c. using "withdrawTGEFund" - The investors can withdraw their TGE fund once the TGE timelocked date is passed.

    d. using "withdrawInstallmentAmount" - The investors can withdraw the FTK tokens based on installments.

    e. using "withdrawBatch" - Pending or missed installment can be collected in one action by the investor.

    f. using "depositFounderNonLinearTokens" - The founder sets this action, for the non-linear setup.

    g. using "setNonLinearInstallments" - Once "depositFounderNonLinearTokens" is done, this action is needs to be done by the founder, where the installment setup for the non-linear mode is fixed for the investor.

6. PrivateRound Smart Contract: (Founder -> Investor and Investor -> Founder)

    a. createPrivateRound - Investor creates.

    b. allowance - set allowance for the deposting tokens.

    c. depositTokens - Investor deposits tokens.

    d. withdrawInitialPercentage - Founder withdraws the initial release tokens.

    e. milestoneValidationRequest - The founder requests for milestone validation.

    f. validateMilestone - The investor validates the requested milestones.

    g. withdrawIndividualMilestoneByFounder - The founder withdraws the tokens after successful validation of milestones.

    h. batchWithdrawByInvestors - The investor withdraws the token if the project is canceled.

    i. withdrawIndividualMilestoneByInvestor - The investor withdraws for individual milestones.

    j. withdrawTaxTokens - The founder withdraws the taxed tokens.

**Proxy Contract Setup - UUPS Proxy:**

1. When should we use UUPS?

   OpenZeppelin suggests using the UUPS pattern as it is more gas efficient. But the
   decision of when to use UUPS is really based on several factors like the business
   requirements of the projects, and so on.
   The original motivation for UUPS was for deploying many smart contract wallets on the
   mainnet/testnet. The logic could be deployed once. The proxy could be deployed hundreds of
   times for each new wallet, without spending much gas.
   As the upgrade method resides in the logic contract, the developer can choose UUPS if
   the protocol wants to remove upgradeability completely in the future.

2. scripts:

   The address displayed in the console is the address of the proxy contract. If you visit
   Etherscan and search the deployer address, you’ll see two new contracts created via two
   transactions. The first one is the actual ProjectAndProposal contract (the implementation contract),
   and the second one is the ProjectAndProposal proxy contract.

3. proxy:

   Once verified, your Etherscan transactions will look like this:
   If you check the Pizza contract in Etherscan, the values like owner , slices , etc. will
   not be set or initialized because in the proxy pattern, everything is stored and executed
   in the context of the proxy contract.
   So in order to interact with the Pizza contract, you should do it via the proxy contract.
   To do that, first we need to inform Etherscan that the deployed contract is actually a
   proxy.

4. setup:

   • initialize() : Upgradable contracts should have an initialize method in
   place of constructors, and also the initializer keyword makes sure that the
   contract is initialized only once.

   • _authorizeUpgrade() : This method is required to safeguard from unauthorized
   upgrades because in the UUPS pattern the upgrade is done from the
   implementation contract, whereas in the transparent proxy pattern, the upgrade
   is done via the proxy contract
