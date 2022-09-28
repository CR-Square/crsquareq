// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FounderLogin{
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    function addFounder(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add 'Founder address' ");
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

contract InvestorLogin{
    mapping(address => bool) private isInvestor;
    address[] private pushInvestors;

    function addInvestor(address _ad) public{
        require(msg.sender == _ad,"Connect same wallet to add 'Investor address' ");
        isInvestor[_ad] = true;
        pushInvestors.push(_ad);
    }

    function verifyInvestor(address _ad) public view returns(bool condition){
        if(isInvestor[_ad] == true){
            return true;
        }else{
            return false;
        }
    }

    function getAllInvestorAddress() public view returns(address[] memory){
        return pushInvestors;
    }
}

contract PrivateRound{

    mapping(address => mapping(uint => MilestoneSetup[])) private _milestone;
    // sets investor address to mileStones created by the founder.
    mapping(address => mapping(uint => address)) private addressIdToAddress;    
    // founder => roundId => investor
    mapping(uint => mapping(address => uint)) public fundsRequested;   
    // round id => funds => investor
    mapping(uint => mapping(address => uint)) public initialPercentage;
    // round id => investor => initialPercentage
    mapping(uint => mapping(address => address)) public tokenExpected;
    // roundid => investor => tokenaddress.
    mapping(uint => mapping(address => address)) public seperateContractLink;
    // round id => founder => uinstance contract address.
    mapping(uint => bool) private roundIdControll;

    struct MilestoneSetup {
        uint256 _num;
        uint256 _date;
        uint256 _percent;
    }

    address public contractOwner = msg.sender;
    address public tokenContract;
    /*
        * This dynamically changes everytime token address is submitted.
        * Either by Investor or Founder.
    */    

    modifier onlyOwner(){
        require(msg.sender == contractOwner,"Sender is not the owner of this contract");
        _;
    }

    /*
        * WRITE FUNCTIONS:
    */

    mapping(address => MilestoneSetup) public dates;

    function createPrivateRound(address _founder, uint _roundId, address _tokenContract, 
    address _investorSM, uint _fundRequested, uint _initialPercentage, 
    MilestoneSetup[] memory _mile) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        // FounderLogin founder = FounderLogin(_founderSM);
        InvestorLogin investor = InvestorLogin(_investorSM);
        // require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'FounderLogin' contract");
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
        if(roundIdControll[_roundId] == true){
            revert("round Id is already taken");
        }
        for(uint i = 0; i < _mile.length; ++i){
            _milestone[msg.sender][_roundId].push(_mile[i]);
            milestoneApprovalStatus[_roundId][_mile[i]._num] = 0;
            milestoneWithdrawalStatus[_roundId][_mile[i]._num] = false;
        }
        roundIdControll[_roundId] = true;
        addressIdToAddress[_founder][_roundId] = msg.sender;
        fundsRequested[_roundId][msg.sender] = _fundRequested;
        initialPercentage[_roundId][msg.sender] = _initialPercentage;
        tokenExpected[_roundId][msg.sender] = _tokenContract;
    }

    // initial90
    // initial10
    // escrowBalance

    mapping(uint => mapping(address => uint)) public remainingTokensOfInvestor;
    // round id => investor => tokens
    mapping(uint => mapping(address => uint)) public totalTokensOfInvestor;
    mapping(uint => mapping(address => uint)) public initialTokensForFounder;
    // round id => investor => tokens
    uint public escrowBalance;
    // round id => investor => tokens
    mapping(uint => mapping(address => bool)) private initialWithdrawalStatus;
    mapping(uint => address) private contractAddress;


    function depositTokens(address _tokenContract, address _investorSM, address _founder, uint _tokens, uint _roundId) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
        tokenContract = _tokenContract;
        FundLock fl = new FundLock(msg.sender, _roundId, _tokens, address(this));
        seperateContractLink[_roundId][_founder] = address(fl);
        contractAddress[_roundId] = address(fl);
        ERC20(_tokenContract).transferFrom(msg.sender, seperateContractLink[_roundId][_founder], _tokens);
        remainingTokensOfInvestor[_roundId][msg.sender] = _tokens;
        totalTokensOfInvestor[_roundId][msg.sender] = _tokens;
        uint tax = _tokens * initialPercentage[_roundId][msg.sender] / 100;
        initialTokensForFounder[_roundId][_founder] += tax;
        remainingTokensOfInvestor[_roundId][msg.sender] -= initialTokensForFounder[_roundId][_founder];
        escrowBalance += remainingTokensOfInvestor[_roundId][msg.sender];
    }

    mapping(address => uint) public taxedTokens;
    mapping(uint => uint) private withdrawalFee;
    // 2% tax should be levied on the each transaction
    function withdrawInitialPercentage(address _tokenContract, address _founderSM, uint _roundId) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        FounderLogin founder = FounderLogin(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'FounderLogin' contract");
        if(initialWithdrawalStatus[_roundId][msg.sender] == true){
            revert("Initial withdrawal is already done");
        }
        FundLock fl = FundLock(seperateContractLink[_roundId][msg.sender]);
        uint tax = 2 * (initialTokensForFounder[_roundId][msg.sender] / 100);
        taxedTokens[_tokenContract] += tax;
        initialTokensForFounder[_roundId][msg.sender] -= tax;
        withdrawalFee[_roundId] += tax;
        ERC20(_tokenContract).transferFrom(address(fl), msg.sender, initialTokensForFounder[_roundId][msg.sender]);
        initialWithdrawalStatus[_roundId][msg.sender] = true;
    }

    mapping(uint => mapping(uint => uint)) private rejectedByInvestor;
    mapping(uint => bool) private projectCancel;
    // milestone id => founder address => uint
    mapping(uint => mapping(uint => address)) private requestForValidation;
    // round id => founder address => milestone id.
    mapping(uint => mapping(uint => int)) private milestoneApprovalStatus; // 0 - means default null, 1 - means approves, -1 means rejected.
    mapping(uint => mapping(uint => bool)) private milestoneWithdrawalStatus;

    function milestoneValidationRequest(address _founderSM, uint _milestoneId, uint _roundId) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        FounderLogin founder = FounderLogin(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'FounderLogin' contract");
        requestForValidation[_roundId][_milestoneId] = msg.sender;
    }

    function validateMilestone(address _investorSM, uint _milestoneId, uint _roundId, bool _status) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
        // whether the milestone id => investor address and milestone mapping, it is already validated or not.
        if(milestoneApprovalStatus[_roundId][_milestoneId] == 1){
            revert("The milestone is already approved");
        }
        if(_status == true){
            milestoneApprovalStatus[_roundId][_milestoneId] = 1;
        }else if(_status == false){
            rejectedByInvestor[_roundId][_milestoneId] += 1;
            milestoneApprovalStatus[_roundId][_milestoneId] = -1;
        }
        if(rejectedByInvestor[_roundId][_milestoneId] >= 3){
            projectCancel[_roundId] = true;
        }
    }

    bool private defaultedByFounder;
    mapping(uint => mapping(uint => bool)) private milestoneStatus;
    mapping(uint => mapping(address => uint)) private unlockedRead;
    mapping(uint => mapping(address => uint)) private lockedRead;
    mapping(uint => mapping(address => uint)) private withdrawnByFounder;

    function batchWithdrawMilestoneTokens(address _founderSM, address _investor, uint _roundId, address _tokenContract) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        FounderLogin founder = FounderLogin(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'FounderLogin' contract");
        uint unlockedAmount = 0;
        if(initialWithdrawalStatus[_roundId][msg.sender] != true){
            unlockedAmount = initialTokensForFounder[_roundId][msg.sender];
        }
        for(uint i = 0; i < _milestone[_investor][_roundId].length; i++){   
            uint id = _milestone[_investor][_roundId][i]._num;
            if(milestoneApprovalStatus[_roundId][id] == 1 && milestoneWithdrawalStatus[_roundId][id] == false){
                unlockedAmount += (totalTokensOfInvestor[_roundId][_investor] * _milestone[_investor][_roundId][i]._percent)/ 100;
                milestoneWithdrawalStatus[_roundId][_milestone[_investor][_roundId][i]._num] = true;
                remainingTokensOfInvestor[_roundId][_investor] -= unlockedAmount;
            }
        }
        if(unlockedAmount > 0){
            uint tax = (2 * unlockedAmount) / 100;
            taxedTokens[_tokenContract] += tax;
            escrowBalance -= unlockedAmount;
            unlockedAmount -= tax;
            withdrawalFee[_roundId] += tax;
            FundLock fl = FundLock(seperateContractLink[_roundId][msg.sender]);
            ERC20(_tokenContract).transferFrom(address(fl), msg.sender, unlockedAmount);
            withdrawnByFounder[_roundId][msg.sender] += unlockedAmount;
        }else{
            revert("No unlocked tokens to withdraw");
        } 
    }

    function withdrawIndividualMilestoneByFounder(address _founderSM, address _investor, uint _roundId, uint _milestoneId, uint _percentage, address _tokenContract) public {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        FounderLogin founder = FounderLogin(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'FounderLogin' contract");
        uint unlockedAmount = 0;
        if(milestoneApprovalStatus[_roundId][_milestoneId] == 1 && milestoneWithdrawalStatus[_roundId][_milestoneId] == false){
            unlockedAmount = (totalTokensOfInvestor[_roundId][_investor] * _percentage)/ 100;
            milestoneWithdrawalStatus[_roundId][_milestoneId] = true;
            remainingTokensOfInvestor[_roundId][_investor] -= unlockedAmount;
        }
        if(unlockedAmount > 0){
            uint tax = (2 * unlockedAmount) / 100;
            taxedTokens[_tokenContract] += tax;
            escrowBalance -= unlockedAmount;
            unlockedAmount -= tax;
            withdrawalFee[_roundId] += tax;
            FundLock fl = FundLock(seperateContractLink[_roundId][msg.sender]);
            ERC20(_tokenContract).transferFrom(address(fl), msg.sender, unlockedAmount);
            withdrawnByFounder[_roundId][msg.sender] += unlockedAmount;
        }else{
            revert("No unlocked tokens to withdraw");
        } 
    }

    function withdrawIndividualMilestoneByInvestor(address _investorSM, uint _roundId, address _founder, uint _milestoneId, uint _percentage, address _tokenContract) public{
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
        uint count = 0;
        for(uint i = 0; i < _milestone[msg.sender][_roundId].length; i++){
            if(block.timestamp > _milestone[msg.sender][_roundId][i]._date && requestForValidation[_roundId][_milestone[msg.sender][_roundId][i]._num] != _founder){
                count += 1;
            }
        }
        if(projectCancel[_roundId] == true || count >= 2){
            defaultedByFounder = true;
        }
        if(defaultedByFounder == true){
            uint lockedAmount = 0;
            if(milestoneApprovalStatus[_roundId][_milestoneId] != 1){
                lockedAmount += (totalTokensOfInvestor[_roundId][msg.sender] * _percentage) / 100;
                remainingTokensOfInvestor[_roundId][msg.sender] -= lockedAmount;
            }
            if(lockedAmount > 0){
                FundLock fl = FundLock(seperateContractLink[_roundId][_founder]);
                escrowBalance -= lockedAmount;
                uint tax = (2 * lockedAmount)/ 100;
                taxedTokens[_tokenContract] += tax;
                withdrawalFee[_roundId] += tax;
                lockedAmount -= tax;
                ERC20(_tokenContract).transferFrom(address(fl), msg.sender, lockedAmount); 
            }
        }
    }

    mapping(address => mapping(uint => uint)) private investorWithdrawnTokens;
    // investor add => roundid => withdrawn token

    function batchWithdrawByInvestors(address _investorSM, uint _roundId, address _founder, address _tokenContract) public{
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
        uint count = 0;
        for(uint i = 0; i < _milestone[msg.sender][_roundId].length; i++){
            if(block.timestamp > _milestone[msg.sender][_roundId][i]._date && requestForValidation[_roundId][_milestone[msg.sender][_roundId][i]._num] != _founder){
                count += 1;
            }
        }
        if(projectCancel[_roundId] == true || count >= 2){
            defaultedByFounder = true;
        }
        uint lockedAmount = 0;
        if(defaultedByFounder == true){
            for(uint i = 0; i < _milestone[msg.sender][_roundId].length; i++){
                if(milestoneApprovalStatus[_roundId][_milestone[msg.sender][_roundId][i]._num] != 1){
                    lockedAmount += (totalTokensOfInvestor[_roundId][msg.sender] * _milestone[msg.sender][_roundId][i]._percent) / 100;
                    remainingTokensOfInvestor[_roundId][msg.sender] -= lockedAmount;
                }
            }
            if(lockedAmount > 0){
                FundLock fl = FundLock(seperateContractLink[_roundId][_founder]);
                escrowBalance -= lockedAmount;
                uint tax = (2 * lockedAmount)/ 100;
                taxedTokens[_tokenContract] += tax;
                withdrawalFee[_roundId] += tax;
                lockedAmount -= tax;
                investorWithdrawnTokens[msg.sender][_roundId] = lockedAmount;
                ERC20(_tokenContract).transferFrom(address(fl), msg.sender, lockedAmount); 
            }
        }
    }

    function changeAdminAddress(address _newAdmin) public onlyOwner{
        contractOwner = _newAdmin;
    }

    // All the taxed tokens are there in the contract itself. no instance is created
    function withdrawTaxTokens(address _tokenContract) public onlyOwner {
        require(msg.sender != address(0), "Invalid address");
        ERC20(_tokenContract).transfer(msg.sender,  taxedTokens[_tokenContract]);
        taxedTokens[_tokenContract] = 0;
    }   

    /*
        * READ FUNCTIONS:
    */

    function milestoneStatusChk(uint roundId, uint milestoneId) public view returns(int){
        return milestoneApprovalStatus[roundId][milestoneId];
    }

    function milestoneDetails(address _investor, uint _roundId) public view returns(MilestoneSetup[] memory){
        return _milestone[_investor][_roundId];
    }

    function getMilestonesDetails(address _investor, uint _roundId) public view returns(MilestoneSetup[] memory){
        return _milestone[_investor][_roundId];
    }

    function getContractAddress(uint _roundId) public view returns(address smartContractAddress){
        return contractAddress[_roundId];
    }

    function projectStatus(uint _roundId) public view returns(bool projectLiveOrNot){
        return projectCancel[_roundId];
    }

    function tokenStatus(uint _roundId, address _founder, address _investor) public view returns(uint unlockedAmount, uint lockedAmount, uint withdrawnTokensByFounder){
        uint unlockedTokens = 0;
        uint lockedTokens = 0;
        uint withdrawnTokens = 0;
        if(initialWithdrawalStatus[_roundId][_founder] != true){
            unlockedTokens = initialTokensForFounder[_roundId][_founder];
        }else{
            withdrawnTokens = initialTokensForFounder[_roundId][_founder];
        }
        for(uint i = 0; i < _milestone[_investor][_roundId].length; i++){   
            uint id = _milestone[_investor][_roundId][i]._num;
            if(milestoneApprovalStatus[_roundId][id] == 1 && milestoneWithdrawalStatus[_roundId][id] == false){
                unlockedTokens += (totalTokensOfInvestor[_roundId][_investor] * _milestone[_investor][_roundId][i]._percent)/ 100;
            } else if(milestoneApprovalStatus[_roundId][id] == 1 && milestoneWithdrawalStatus[_roundId][_milestone[_investor][_roundId][i]._num] == true){
                uint beforeTax = (totalTokensOfInvestor[_roundId][_investor] * _milestone[_investor][_roundId][i]._percent) / 100;
                uint tax = (2 * beforeTax)/ 100;
                withdrawnTokens += beforeTax - tax;
            // } else if(milestoneApprovalStatus[_roundId][id] != 1){
            //     lockedTokens += (totalTokensOfInvestor[_roundId][_investor] * _milestone[_investor][_roundId][i]._percent) / 100;
            }
        }
        // lockedTokens -= investorWithdrawnTokens[_investor][_roundId];
        lockedTokens = totalTokensOfInvestor[_roundId][_investor] - investorWithdrawnTokens[_investor][_roundId] - withdrawnTokens - withdrawalFee[_roundId] - unlockedTokens;
        return(
            unlockedTokens,
            lockedTokens,
            withdrawnTokens
        );
    }

    function investorWithdrawnToken(address _investor, uint _roundId) public view returns(uint investorWithdrawnTokenNumber){
        uint investorWithdrawTok = investorWithdrawnTokens[_investor][_roundId];
        return investorWithdrawTok;
    }

    function readTaxFee(uint _roundId) public view returns(uint transactionFee){
        uint txFee = withdrawalFee[_roundId];
        return txFee;
    }

    function milestoneWithdrawStatus(uint _roundId, uint _milestoneId) public view returns(bool){
        return milestoneWithdrawalStatus[_roundId][_milestoneId];
    }

    function initialWithdrawStatus(uint _roundId, address _founder) public view returns(bool initialWithdraw){
        return initialWithdrawalStatus[_roundId][_founder];
    }

    function availableTaxTokens(address _tokenContract) public view returns(uint taxTokens){
        return taxedTokens[_tokenContract];
    }

    function contractBalance() public view returns(uint escrowBal){
        return escrowBalance;
    }

    function defaultedToWithdrawMilestoneTokens() public view returns(bool){
        return defaultedByFounder;
    }

    function returnsCurrentBalanceOfInvestor(uint _roundId, address _investor) public view returns(uint investorBalance){
        return remainingTokensOfInvestor[_roundId][_investor];
    }
}

contract FundLock{
    address public _contractOwner;
    mapping(uint => mapping(address => uint)) public _amount;

    constructor (address investor, uint roundId, uint amount, address privateRoundContractAd) {
        _contractOwner = msg.sender;
        _amount[roundId][investor] = amount;
        ERC20(PrivateRound(privateRoundContractAd).tokenContract()).approve(privateRoundContractAd,amount);
    }
}
