// SPDX-License-Identifier: MIT

pragma abicoder v2;
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Factory {

    address[] private allValidatorsArray;
    mapping(address => bool) private validatorBoolean;
    
    function addValidators(address _ad) public {
        require(msg.sender == _ad,"please use the address of connected wallet");
        allValidatorsArray.push(_ad);
        validatorBoolean[_ad] = true;
    }

    function returnArray() public view returns(address[] memory){ 
        return allValidatorsArray;
    }

    function checkValidatorIsRegistered(address _ad) public view returns(bool condition){
        if(validatorBoolean[_ad] == true){
            return true;
        }else{
            return false;
        }
    }
}

contract Founder{
    
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    function addFounder(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add founder address");
        isFounder[_ad] = true;
        pushFounders.push(_ad);
    }

    function verifyFounder(address _ad) public view returns(bool condition){
        if(isFounder[_ad] == true){
            return true;
        }else{
            return false;
        }
    }

    function getAllFounderAddress() public view returns(address[] memory){
        return pushFounders;
    }    
}


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ProjectAndProposal is Initializable, UUPSUpgradeable, OwnableUpgradeable{

    function initialize() private initializer {
      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    mapping(bytes32 => address) private whitelistedTokens;
    mapping(uint => mapping(address => uint)) public initialTenPercentOfInvestor;
    mapping(uint => mapping(address => address)) public initialInvestorId;

    struct founderLink{
        uint projectId;
        uint cycles;
    }  

    mapping(uint => founderLink) projectCycle;
    mapping(address => uint) public projectIdAndFounder; // This outputs project id, when correct address is passed.
    mapping(uint => mapping(address => uint)) private es; // This records total balance that the escrow uses.

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

 // FOUNDER ACTION: INITIAL ID SETUP:

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
        getInitialProposalRequestedFund[_projectId][_initialId] = _totalValProposal;
    }

  // FOUNDER ACTION: SUBSEQUENT ID SETUP:
 
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

/*
-----------------------x
Validation Function:
-----------------------x
*/
    mapping(uint => mapping(uint => address[])) public approvals;
    mapping(uint => mapping(uint => address[])) public rejections;
    mapping(uint => mapping(uint => string)) private subStatus;
    mapping(uint => mapping(uint => bool)) isSubsequentCreatedOrNot;
    mapping(uint => mapping(uint => uint)) private withdrawlSetup;
    bool public projectRejectionStatus;

    // Validating 
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
        getProjectStatus[_projectId] = "Rejected";
    }
    return true;
    }     

    function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
        return whitelistedTokens[token];
    }

    // MAPPINGS-NEW: GETTING THE BALANCE DATA FOR INITIAL DATA:
    mapping(uint => mapping(address => uint)) public initialNinentyInvestor;

    struct allInvestorBool{
        address[] allInvestors;
        mapping(address => bool) validator;
        bool _state;
        address _investor;
    }

    mapping(uint => allInvestorBool) AI;
    address[] private ALLinvestors;

    address public tokenContract;
    mapping(uint => mapping(address => address)) public seperateContractLink;

    // INVESTOR DEPOSIT:
    function depositStableTokens(address _investor, address _founder, uint256 _amount, bytes32 symbol, address tokenAddress, uint _initialId, uint _projectId) external {
        require(msg.sender == _investor,"The connected wallet is not matching");           
        require(_amount == founderLinkInvestorInitialProposal[_investor][_initialId]._amountForProposal,"The amount is a mismatching or id's are mismatching");
        require(initialAndProjLinkInvestor[_initialId][_projectId]._investor == _investor,"The investor is not linked to the founder and initialId");
        tokenContract = tokenAddress;
        pp_lock pp = new pp_lock(_investor, _projectId, _amount, address(this));
        whitelistedTokens[symbol] = tokenAddress;
        seperateContractLink[_projectId][_investor] = address(pp);
        ERC20(whitelistedTokens[symbol]).transferFrom(_investor, seperateContractLink[_projectId][_investor], _amount);
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
    
   /*----------------------------x
    WithdrawStableCoin by Founder:
    -----------------------------x
   */

    mapping(address => mapping(uint => bool)) private subsequentIdStatus;


    function withdrawSubsequentStableCoins(uint subs_Id, address _founder, bytes32 symbol, uint _projectId) external returns (bool withdrawStatus){
    
        require(msg.sender == _founder,"The connected wallet is not a founder wallet"); 
        if(getRejectedSubsequentProposalsCounts[_projectId] >= 3){
            revert("The project is closed, due to three subsequence validation failure");
        }
        if(approvals[_projectId][subs_Id].length >= 3 && subsequentIdStatus[_founder][subs_Id] == false){
            uint i;
            for(i = 0; i < justInvestor[_projectId][_founder].length; i++){  
                address investor = justInvestor[_projectId][_founder][i]._investor; 
                uint Investorbalance = initialNinentyInvestor[_projectId][investor];
                uint escrowBalance = es[_projectId][_founder];
                uint share = (Investorbalance * subsCycleBalance[_projectId][subs_Id]) / escrowBalance; // single investor balance
                pp_lock pp = pp_lock(seperateContractLink[_projectId][investor]);
                uint localAmt = Investorbalance / getProjectCurrentCycle[_projectId];
                ERC20(whitelistedTokens[symbol]).transferFrom(address(pp), _founder, localAmt);
                initialNinentyInvestor[_projectId][investor] -= share;
                getInvestorCurrentBalance[_projectId][investor] -= share;
            }
            subsequentIdStatus[_founder][subs_Id] = true;
            es[_projectId][_founder] -= subsCycleBalance[_projectId][subs_Id];
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

    // INVESTOR WITHDRAW TOKENS WHEN 3 SUBSEQUENT PROPOSALS HAVE FAILED
    function withdrawTokensByInvestor(address _founder, address _investor, bytes32 symbol, uint _projectId) external  {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        require(initialInvestorId[_projectId][_investor] == msg.sender,"investor address is mismatch with subsequent id");
        if(getRejectedSubsequentProposalsCounts[_projectId] >= 3){
            pp_lock pp = pp_lock(seperateContractLink[_projectId][_investor]);
            ERC20(whitelistedTokens[symbol]).transferFrom(address(pp), _investor, initialNinentyInvestor[_projectId][_investor]);
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
            pp_lock pp = pp_lock(seperateContractLink[_projectId][_investor]);
            ERC20(whitelistedTokens[symbol]).transferFrom(address(pp), _founder, initialTenPercentOfInvestor[_projectId][_investor]);
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

    // 3. getInvestorCurrentBalance - project_id, founder     // Individual investor balance (dynamic) // used in Deposit stable, 10% withdraw and 90% withdraw. 
    mapping(uint => mapping(address => uint)) public getInvestorCurrentBalance;
    function _getInvestorCurrentBalance(uint _projectId, address _investor) public view returns(uint){
        return getInvestorCurrentBalance[_projectId][_investor];
    }

    // 4. getTotalReleasedFundsToFounderFromEscrow - project_id, founder      // fund taken by founder from investors- static  // used in 10% withdraw and 90% withdraw. 
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

    // 12. getWhoValidatedTheSubsequentProposal - project_id, subsequent_prop_id   // validators list - approved   // mapping name approvals;
    function _approvedValidators(uint _projectId, uint _subsId) public view returns(address[] memory){
        return  approvals[_projectId][_subsId];
    }

    // 13. getWhoRejectedSubsequentProposal - project_id, subsequent_prop_id       // validators list - rejected    // mapping name rejections;
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

contract pp_lock{
    address public _contractOwner;
    mapping(uint => mapping(address => uint)) public _amount;

    constructor (address investor, uint projId, uint amount, address ppContractAd) {
        _contractOwner = msg.sender;
        _amount[projId][investor] = amount;

        ERC20(ProjectAndProposal(ppContractAd).tokenContract()).approve(ppContractAd,amount);
    }
}