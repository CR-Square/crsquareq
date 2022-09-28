//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./founder.sol";
import "./factory.sol";
import "./ERC20.sol";

contract ProjectAndProposal{

    uint private totalValueForProject;               // initial
    uint private totalDepositedStableCoinsInThePot;  // sub
    uint private TenPercentBalanceOfStableCoin;      // initial
    
    address[] private validatorWhoApproved;
    address[] private validatorWhoRejected;
    address[] private allValidators;

    bool private proposalCancelledRevertWithdrawlToInvestors;
  
// MAPPINGS: LINKING ID TO INITIAL AND SUBSEQUENT:
    mapping(bytes32 => address) private whitelistedTokens;
    // mapping(address => uint) public getInvestorsId;
    mapping(uint => address[]) private arrApprovedValidator;
    mapping(uint => address[]) private arrRejectedValidator;

// MAPPINGS: GETTING THE BALANCE DATA:
    mapping(address => mapping(uint => uint)) public subsequentBalanceOfFounder;
    mapping(address => mapping(uint => uint)) public subsequentBalanceOfInvestor;
    mapping(uint => mapping(address => uint)) public initialTenPercentOfInvestor;
    mapping(address => mapping(uint => uint)) public initialBalanceOfFounder;


// MAPPINGS: LINKING ID'S TO FOUNDER AND SUBSEQUENT PROPOSALS:
    mapping(uint => mapping(address => address)) public initialfounderId;
    mapping(uint => mapping(address => address)) public subsfounderId;
    mapping(uint => mapping(address => address)) public initialInvestorId;
    mapping(uint => mapping(address => address)) public subsInvestorId;

    mapping(uint => mapping(address => address)) public founderAndInvestorConnection;
    mapping(address => mapping(uint => uint)) public totalValueExpectedRespectiveToFounder;

    function returnFounderAndInvestorConnection(uint _initialId, address _founder, address _investor) public view returns(bool){
        bool status;
        if(founderAndInvestorConnection[_initialId][_founder] == _investor){
            status = true;
            return status;
        }else{
            revert("The connection is mismatch");
        }
    }

// MATCHING FOUNDER AND TOTAL VALUE FOR PROJECT:

/*
    mapping(address => uint) public 
*/

    struct founderLink{
        uint projectId;
        uint cycles;
        // uint projectExpectedValue;
    }  

    mapping(uint => founderLink) projectCycle;

    mapping(address => uint) public projectIdAndFounder; // This outputs project id, when correct address is passed.
    // mapping(uint => uint) public balanceOfEscrowBasedOnId;   // This records the balance according to projectid.
    mapping(uint => mapping(address => uint)) private es; // This records total balance that the escrow uses.

    function escrowBalanceOfStableCoins(uint _projectId, address _investor) public view returns(uint Balance){
        return es[_projectId][_investor];
    }

    function setFounderAndCycleForTheProject(address _founderSmartContractAd, address _founderAd, uint _projectId, uint _cycles) public{
        require(msg.sender == _founderAd,"The connected wallet and the founder is mismatching");    // Security level 1
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract.
        if(f.verifyFounder(_founderAd) == true){    // Verifying whether the founder is already registered in founder smart contract.
            projectIdAndFounder[_founderAd] = _projectId;   // Regular mapping
            projectCycle[_projectId].cycles = _cycles;  // dynamic
            getProjectCycles[_projectId] = _cycles; // static
            getProjectCurrentCycle[_projectId] =  projectCycle[_projectId].cycles;
            getProjectStatus[_projectId] = "On going";
        }else{
            revert("The address is not registered in the founders contract");
        }
    }

    // function returnFounderAndCycle(uint _projectId) public view returns(uint){
    //     return(projectCycle[_projectId].cycles);
    // }

    mapping(address => uint) private founderAndInitialId;
    mapping(address => uint) private founderAndSubsequentId;
   

    function returnFounderAndInitialId(address _ad, uint _initialId) public view returns(uint){
        require(founderAndInitialId[_ad] == _initialId, "The id is a mismatch");
        return founderAndInitialId[_ad];
    }

/* -------------------------------x
 FOUNDER ACTION: INITIAL ID SETUP:

 require(subs1[_projectId][_subsId]._investorSetup == _investor
   -------------------------------x
*/

    struct founderSettingInvestorToTheProposal{
        uint _initialId;    // founder + projectid must == initialid
        uint _amountForProposal;    // founder + _ initialid must == totalValue For project 
        address _investor;      // founder + initialid must == investor
        uint _initial10PercentOfInvestor;
    }

    struct initialAndInvestor{
        uint _initialId;
        address _investor;
    }

    mapping(address => mapping(uint => founderSettingInvestorToTheProposal)) founderLinkInvestorInitialProposal;
    mapping(uint => mapping(uint => founderSettingInvestorToTheProposal)) initialAndProjLinkInvestor;
    mapping(uint => mapping(address => initialAndInvestor[])) justInvestor;
    uint[] private ids;


    function setInitialId(address _founder,address _investor, uint _initialId, uint _projectId, uint _totalValProposal) public {
        require(msg.sender == _founder,"The connected wallet is not a founder wallet");
        require(projectIdAndFounder[_founder] == _projectId,"The founder address is not matched with project id");
        ids.push(_initialId);
        uint i;
        for(i = 0; i < ids.length-1; i++){
            if(ids[i] == _initialId){
                revert("The id is already taken, please use different id");
            }
        }

        initialAndInvestor memory iI;
        iI = initialAndInvestor(_initialId, _investor);
        justInvestor[_projectId][_founder].push(iI);

        founderLinkInvestorInitialProposal[_investor][_projectId]._initialId = _initialId;
        founderLinkInvestorInitialProposal[_investor][_initialId]._amountForProposal = _totalValProposal;  
        founderLinkInvestorInitialProposal[_founder][_initialId]._investor = _investor;   
     
        initialAndProjLinkInvestor[_initialId][_projectId]._investor = _investor;
        founderAndInitialId[_founder] = _initialId;
        getInitialProposalRequestedFund[_projectId][_initialId] = _totalValProposal;
    }

    function returnFounderInitialAndInvestor(address _founder,address _investor, uint _initialId, uint _projectId) public view returns(
        uint initialId, uint proposalValueForInvestor, address investorAddress, uint initial10PercentOfInvestor){
        return(
            founderLinkInvestorInitialProposal[_investor][_projectId]._initialId,
            founderLinkInvestorInitialProposal[_investor][_initialId]._amountForProposal,
            founderLinkInvestorInitialProposal[_founder][_initialId]._investor,
            founderLinkInvestorInitialProposal[_investor][_initialId]._initial10PercentOfInvestor
        );
    }

    function initial_prop_info(uint _projectId, uint initial_id, address _founder) public view returns (initialAndInvestor memory) {
        initialAndInvestor memory iI;
        if (justInvestor[_projectId][_founder].length > 0) {
            for (uint i = 0; i < justInvestor[_projectId][_founder].length; i++) {
                if (justInvestor[_projectId][_founder][i]._initialId == initial_id) {
                    iI = justInvestor[_projectId][_founder][i];
                }
            }
            return iI;
        } else {
            revert("there is no initial proposal");
        }
    }

/* -----------------------------------x
   FOUNDER ACTION: SUBSEQUENT ID SETUP:
   -----------------------------------x
*/
    uint[] private idsSub;

    struct getSubsequentData{
        uint subsequentId;
        uint subsequentBalance;
        address[] investors;
    }

    mapping (uint => mapping(address => getSubsequentData[])) SUBS; // struct used array
    address[] private Subinvestors;
    mapping(uint => mapping(uint => uint)) private subsCycleBalance;

    function setSubsequentId(address _founder, uint _subsId, uint _projectId) public {
        require(msg.sender == _founder,"you are not founder");
        idsSub.push(_subsId);
        uint i;
        for(i = 0; i < idsSub.length-1; i++){
            if(idsSub[i] == _subsId){
                revert("The id is already taken, please use different id");
            }
        }
        subsCycleBalance[_projectId][_subsId] = es[_projectId][_founder] / projectCycle[_projectId].cycles;
        Subinvestors = AI[_projectId].allInvestors;

        getSubsequentData memory s;
        s = getSubsequentData(_subsId, subsCycleBalance[_projectId][_subsId], Subinvestors);
        SUBS[_projectId][_founder].push(s);
        isSubsequentCreatedOrNot[_projectId][_subsId] = true;
        getSubsequentProposalFund[_projectId][_subsId] = subsCycleBalance[_projectId][_subsId];
    }

    function subsequent_prop_info(uint proj_id, uint subs_id, address founder) public view returns (getSubsequentData memory) {
        getSubsequentData memory s;
        if (SUBS[proj_id][founder].length > 0) {
            for (uint i = 0; i < SUBS[proj_id][founder].length; i++) {
                if (SUBS[proj_id][founder][i].subsequentId == subs_id) {
                    s = SUBS[proj_id][founder][i];
                }
            }
            return s;
        } else {
            revert("there is no initial proposal");
        }
    }

/*
-----------------------x
Validation Function:
-----------------------x
1. Validation can be done in bulk understanding the addresses in the array and then making the setup.
*/
    mapping(uint => mapping(uint => address[])) public approvals;
    mapping(uint => mapping(uint => address[])) public rejections;
    mapping(uint => mapping(uint => string)) private subStatus;
    mapping(uint => mapping(uint => bool)) isSubsequentCreatedOrNot;


    mapping(uint => mapping(uint => uint)) private withdrawlSetup;
    bool public projectRejectionStatus;


    function Validate(bool _choice, address _validator, address _contractad, uint _subsId, uint _projectId) public returns (bool voted){
    Factory f = Factory(_contractad);
    require(f.checkValidatorIsRegistered(_validator) == true,"The address is not registered as validators");
    require(msg.sender == _validator,"The connected wallet is not a validator address");
    require(isSubsequentCreatedOrNot[_projectId][_subsId] == true,"The subsequent is not yet created");
    if(_choice == true){
        approvals[_projectId][_subsId].push(_validator);
    } else if(_choice == false){
        rejections[_projectId][_subsId].push(_validator);
    }
    if(approvals[_projectId][_subsId].length >= 3){
        subStatus[_projectId][_subsId] = "Approved";
    } else if (rejections[_projectId][_subsId].length >= 3){
        subStatus[_projectId][_subsId] = "Rejected";
        if(rejections[_projectId][_subsId].length == 3) {
            getRejectedSubsequentProposalsCounts[_projectId] += 1;
        }
    }
    if(getRejectedSubsequentProposalsCounts[_projectId] >= 3){
        // withdrawlSetup[_projectId][_subsId] = 3;
        getProjectStatus[_projectId] = "Rejected";
    }
    return true;
}


    function getSubsequentStatusAfterValidation(uint _projectId, uint _subsId) public view returns(string memory statusOfProjectAndSubsequent){
        return subStatus[_projectId][_subsId];  // This can be used in the withdraw function 
    }

    function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
        return whitelistedTokens[token];
    }


    // MAPPINGS-NEW: GETTING THE BALANCE DATA FOR INITIAL DATA:
    mapping(uint => mapping(address => uint)) public initialNinentyInvestor;
    mapping(address => mapping(uint => uint)) public initialNinentyFounder;


    struct allInvestorBool{
        address[] allInvestors;
        mapping(address => bool) validator;
        bool _state;
        address _investor;
    }

    mapping(uint => allInvestorBool) AI;
    mapping(bool => allInvestorBool) AIBOOL;
    mapping(uint => mapping(uint => address)) private projectSubsAndInvestor;

    address[] private ALLinvestors;



    // INVESTOR DEPOSIT:
    function depositStableTokens(address _investor, address _founder, uint256 _amount, bytes32 symbol, address tokenAddress, uint _initialId, uint _projectId) external {
        require(msg.sender == _investor,"The connected wallet is not matching");           
        require(_amount == founderLinkInvestorInitialProposal[_investor][_initialId]._amountForProposal,"The amount is a mismatching or id's are mismatching");
        require(initialAndProjLinkInvestor[_initialId][_projectId]._investor == _investor,"The investor is not linked to the founder and initialId");
            
        whitelistedTokens[symbol] = tokenAddress;            
        ERC20(whitelistedTokens[symbol]).transferFrom(_investor, address(this), _amount);
        initialInvestorId[_projectId][_investor] = msg.sender;

        AI[_projectId].allInvestors.push(_investor);
        ALLinvestors.push(_investor);

        initialNinentyInvestor[_projectId][_investor] = _amount;
        getProjectEscrowBalance[_projectId][_founder] += _amount;
        getInvestorInvestedBalance[_projectId][_investor] += _amount;
        getInvestorCurrentBalance[_projectId][_investor] += _amount;

        uint sendOnly10Percent = _amount * 10/100;
        initialTenPercentOfInvestor[_projectId][_investor] += sendOnly10Percent;
        _depositStatusByInvestor[_projectId][_investor] = true;
        initialNinentyInvestor[_projectId][_investor] -= initialTenPercentOfInvestor[_projectId][_investor];
        founderLinkInvestorInitialProposal[_investor][_initialId]._initial10PercentOfInvestor = initialTenPercentOfInvestor[_projectId][_investor]; // This reads 10% of investor
        es[_projectId][_founder] += initialNinentyInvestor[_projectId][_investor]; // This reads total 90% balance of different investors
        getTotalProjectValue[_projectId] = es[_projectId][_founder];
    }

    function returnAllInvestors(uint _projectId) public view returns(address[] memory){
        return(AI[_projectId].allInvestors);
    }

    function TOTALBALANCE(address _founder, uint _projectId) public view returns(uint escrowBalance){
        return es[_projectId][_founder];
    }     


   /*----------------------------x
    WithdrawStableCoin by Founder:
    -----------------------------x
   */

    function withdrawSubsequentStableCoins(uint subs_Id, address _founder, bytes32 symbol, uint _projectId) external returns (bool withdrawStatus){
    
        require(msg.sender == _founder,"The connected wallet is not a founder wallet"); 
        if(getRejectedSubsequentProposalsCounts[_projectId] >= 3){
            revert("The project is closed, due to three subsequence validation failure");
        }
        if(approvals[_projectId][subs_Id].length >= 3){
            uint i;
            for(i = 0; i < justInvestor[_projectId][_founder].length; i++){  
                address investor = justInvestor[_projectId][_founder][i]._investor; 
                uint Investorbalance = initialNinentyInvestor[_projectId][investor];
                uint escrowBalance = es[_projectId][_founder];
                uint share = (Investorbalance * subsCycleBalance[_projectId][subs_Id]) / escrowBalance;
                initialNinentyInvestor[_projectId][investor] -= share;
                getInvestorCurrentBalance[_projectId][investor] -= share;
            }
            es[_projectId][_founder] -= subsCycleBalance[_projectId][subs_Id];
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, subsCycleBalance[_projectId][subs_Id]);
            getTotalReleasedFundsToFounderFromEscrow[_projectId][_founder] += subsCycleBalance[_projectId][subs_Id];
            projectCycle[_projectId].cycles -= 1;   // dynamic
            getProjectCurrentCycle[_projectId] = projectCycle[_projectId].cycles;
            getTotalProjectValue[_projectId] = es[_projectId][_founder];
            if(projectCycle[_projectId].cycles <= 0){
                getProjectStatus[_projectId] = "Completed";
            }
            getTheSubsequentProposalWithdrawalStatus[_projectId][subs_Id] = true;
            return true;
        }else{
            revert("The withdrawl is not possible by the founder");
        }          
    }

    function whoApprovedSubsequentProposalBasedOnId(uint256 subs_id) public view returns (address[] memory) {
        return arrApprovedValidator[subs_id];
    }

    function whoRejectedSubsequentProposalBasedOnId(uint256 subs_id) public view returns (address[] memory) {
        return arrRejectedValidator[subs_id];
    }

    // INVESTOR WITHDRAW TOKENS WHEN 3 SUBSEQUENT PROPOSALS HAVE FAILED
    function withdrawTokensByInvestor(address _founder, address _investor, bytes32 symbol, uint _projectId) external  {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        require(initialInvestorId[_projectId][_investor] == msg.sender,"investor address is mismatch with subsequent id");
        if(getRejectedSubsequentProposalsCounts[_projectId] >= 3){
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, initialNinentyInvestor[_projectId][_investor]);
            es[_projectId][_founder] -= initialNinentyInvestor[_projectId][_investor];
            getTotalProjectValue[_projectId] = es[_projectId][_founder];
            getInvestorCurrentBalance[_projectId][_investor] -= initialNinentyInvestor[_projectId][_investor];
            initialNinentyInvestor[_projectId][_investor] = 0;
            projectRejectionStatus = true;
        }else{
            revert("The project has not ended yet");
        }
    } 

    // FOUNDER WITHDRAW 10% TOKENS:
    function Withdraw10PercentOfStableCoin(address _founderSmartContractAd, address _founder, address _investor, bytes32 symbol, uint _projectId) public  {
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract.
        if(f.verifyFounder(_founder) == true){
            ERC20(whitelistedTokens[symbol]).transfer(msg.sender, initialTenPercentOfInvestor[_projectId][_investor]);
            getInvestorCurrentBalance[_projectId][_investor] -= initialTenPercentOfInvestor[_projectId][_investor];
            getTotalReleasedFundsToFounderFromEscrow[_projectId][_founder] += initialTenPercentOfInvestor[_projectId][_investor];
            getTheTenpercentWithdrawalStatus[_projectId][_investor] = true;
            initialTenPercentOfInvestor[_projectId][_investor] = 0;
        }else{
            revert("The founder address is not registered yet");
        }
    }

/*-----------------------------x
    Expected all read functions:
  -----------------------------x  
*/

    // 1. getProjectEscrowBalance - project_id, founder  .Total Balance of escrow (static)

    mapping(uint => mapping(address => uint)) public getProjectEscrowBalance;   // all balance of investor deposits in project, both 10% and 90% combined.

    function _getProjectEscrowBalance(uint _projectId, address _founder) public view returns(uint){
        return getProjectEscrowBalance[_projectId][_founder];
    }

    // 2. getInvestorInvestedBalance - project_id, founder    // Same Total Investors investment static in the project.

    mapping(uint => mapping(address => uint)) public getInvestorInvestedBalance;

    function _getInvestorInvestedBalance(uint _projectId, address _investor) public view returns(uint){
        return getInvestorInvestedBalance[_projectId][_investor];
    }

    // 3. getInvestorCurrentBalance - project_id, founder     // Individual investor balance (dynamic)
    // used in Deposit stable, 10% withdraw and 90% withdraw. 

    mapping(uint => mapping(address => uint)) public getInvestorCurrentBalance;

    function _getInvestorCurrentBalance(uint _projectId, address _investor) public view returns(uint){
        return getInvestorCurrentBalance[_projectId][_investor];
    }

    // 4. getTotalReleasedFundsToFounderFromEscrow - project_id, founder      // fund taken by founder from investors- static
    // used in 10% withdraw and 90% withdraw. 
    mapping(uint => mapping(address => uint)) public getTotalReleasedFundsToFounderFromEscrow;

    function _getTotalReleasedFundsToFounderFromEscrow(uint _projectId, address _founder) public view returns(uint){
        return getTotalReleasedFundsToFounderFromEscrow[_projectId][_founder];
    }

    // 5. getInitialProposalRequestedFund - project_id, initial_prop_id      // how much founder is requested while intial prop

    mapping(uint => mapping(uint => uint)) public getInitialProposalRequestedFund;

    function _getInitialProposalRequestedFund(uint _projectId, uint _initialId) public view returns(uint){
        return getInitialProposalRequestedFund[_projectId][_initialId];
    }


    // 6. getSubsequentProposalFund - project_id, subsequent_prop_id          // subsequent balance

    mapping(uint => mapping(uint => uint)) public getSubsequentProposalFund;

    function _getSubsequentProposalFund(uint _projectId, uint _subsId) public view returns(uint){
        return getSubsequentProposalFund[_projectId][_subsId];
    }

    // 7. getProjectCycles - project_id             // no of cycle (static)

    mapping(uint => uint) public getProjectCycles;

    function _getProjectCycles(uint _projectId) public view returns(uint){
        return getProjectCycles[_projectId];
    }

    // 8. getProjectCurrentCycle - project_id       // no of cycle (dynamic)
    mapping(uint => uint) public getProjectCurrentCycle;

    function _getProjectCurrentCycle(uint _projectId) public view returns(uint){
        return getProjectCurrentCycle[_projectId];
    }

    // 9. getSubsequentProposalStatus - project_id, subsequent_prop_id        // subsequentProposal Live or not 

    mapping(uint => mapping(uint => string)) public getSubsequentProposalStatus;

    function _getSubsequentProposalStatus(uint _projectId, uint _subsId) public view returns(string memory){
            return subStatus[_projectId][_subsId];
    }

    // 10. getRejectedSubsequentProposalsCount - project_id         // how many times a subsequent have been rejected proj

    mapping(uint => uint) public getRejectedSubsequentProposalsCounts;

    function _getRejectedSubsequentProposalsCount(uint _projectId) public view returns(uint){
        return getRejectedSubsequentProposalsCounts[_projectId];
    }

    // 11. getProjectStatus - project_id                            // project live or not
    mapping(uint => string) public getProjectStatus;

    function _getProjectStatus(uint _projectId) public view returns(string memory){
        return getProjectStatus[_projectId];
    }

    // 12. getWhoValidatedTheSubsequentProposal - project_id, subsequent_prop_id   // validators list - approved
    // mapping name approvals;

    function _approvedValidators(uint _projectId, uint _subsId) public view returns(address[] memory){
        return  approvals[_projectId][_subsId];
    }

    // 13. getWhoRejectedSubsequentProposal - project_id, subsequent_prop_id       // validators list - rejected
    // mapping name rejections;

    function _rejectedValidators(uint _projectId, uint _subsId) public view returns(address[] memory){
        return  rejections[_projectId][_subsId];
    }

    // 14. getTotalProjectValue - project_id                                       // Total Balance of escrow (dynamic)
    mapping(uint => uint) public getTotalProjectValue;

    function _getProjectCurrentEscrowBalance(uint _projectId) public view returns(uint){
        return getTotalProjectValue[_projectId];
    }

    // 15. getTheTenpercentWithdrawalStatus - project_id, initial_prop_id // stable tokens: whether withdrawn or not.
    mapping(uint => mapping(address => bool)) public getTheTenpercentWithdrawalStatus;

    function _getTheTenpercentWithdrawalStatus(uint _projectId, address _investor) public view returns(bool){
        return getTheTenpercentWithdrawalStatus[_projectId][_investor];
    }

    // 16. getTheSubsequentProposalWithdrawalStatus - project_id, subsequent_prop_id // statble tokens: whether withdrawn or not. If withdrawn, how much (edited) 
    mapping(uint => mapping(uint => bool)) public getTheSubsequentProposalWithdrawalStatus;

    function _getTheSubsequentProposalWithdrawalStatus(uint _projectId, uint _subsId) public view returns(bool){
        return getTheSubsequentProposalWithdrawalStatus[_projectId][_subsId];
    }

    function _checkTenPecentOfStableToken(uint _projectId, address _investor) public view returns(uint){
        return initialTenPercentOfInvestor[_projectId][_investor];
    }

    /*
    This function outputs bool if the investor has already invested to the initial setup.
    */  

    mapping(uint => mapping(address => bool)) private _depositStatusByInvestor;

    function  _depositStatus(uint _projectId, address _investor) public view returns(bool){
        return _depositStatusByInvestor[_projectId][_investor];
    }

}