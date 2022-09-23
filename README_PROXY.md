Proxy Contract Setup: UUPS Proxy:

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
contract is initialized only once
• _authorizeUpgrade() : This method is required to safeguard from unauthorized
upgrades because in the UUPS pattern the upgrade is done from the
implementation contract, whereas in the transparent proxy pattern, the upgrade
is done via the proxy contract
