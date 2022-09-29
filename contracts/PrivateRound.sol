// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Founder.sol";

contract InvestorLogin{
    
    mapping(address => bool) private isInvestor;
    address[] private pushInvestors;

    function addInvestor(address _ad) external{
        require(msg.sender == _ad,"Connect same wallet to add 'Investor address' ");
        isInvestor[_ad] = true;
        pushInvestors.push(_ad);
    }

    function verifyInvestor(address _ad) external view returns(bool condition){
        if(isInvestor[_ad] == true){
            return true;
        }else{
            return false;
        }
    }

    function getAllInvestorAddress() external view returns(address[] memory){
        return pushInvestors;
    }
}


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PrivateRound is Initializable, UUPSUpgradeable, OwnableUpgradeable{

    mapping(address => mapping(uint => MilestoneSetup[])) private _milestone; // sets investor address to mileStones created by the founder.
    mapping(uint => mapping(address => uint)) public initialPercentage;  // round id => investor => initialPercentage   
    mapping(uint => mapping(address => address)) public seperateContractLink;  // round id => founder => uinstance contract address.   
    mapping(uint => bool) private roundIdControll;
    address public contractOwner;

    function initialize() private initializer {
      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
       contractOwner = msg.sender;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    struct MilestoneSetup {
        uint256 _num;
        uint256 _date;
        uint256 _percent;
    }

    address public tokenContract;
    /*
        * This dynamically changes everytime token address is submitted.
        * Either by Investor or Founder.
    */    

    modifier onlyAdmin(){
        require(msg.sender == contractOwner,"Sender is not the owner of this contract");
        _;
    }

    /*
        * WRITE FUNCTIONS:
    */

    function createPrivateRound(uint _roundId, address _investorSM, uint _initialPercentage, MilestoneSetup[] memory _mile) external {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
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
        initialPercentage[_roundId][msg.sender] = _initialPercentage;
    }

    mapping(uint => mapping(address => uint)) public remainingTokensOfInvestor;  // round id => investor => tokens   
    mapping(uint => mapping(address => uint)) public totalTokensOfInvestor;    // round id => investor => tokens 
    mapping(uint => mapping(address => uint)) public initialTokensForFounder;  // round id => founder => tokens
    mapping(uint => mapping(address => bool)) private initialWithdrawalStatus;
    mapping(uint => address) private contractAddress;

    function depositTokens(address _tokenContract, address _investorSM, address _founder, uint _tokens, uint _roundId) external {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
        tokenContract = _tokenContract;
        FundLock fl = new FundLock(msg.sender, _roundId, _tokens, address(this));
        seperateContractLink[_roundId][_founder] = address(fl);
        contractAddress[_roundId] = address(fl);
        remainingTokensOfInvestor[_roundId][msg.sender] = _tokens;
        totalTokensOfInvestor[_roundId][msg.sender] = _tokens;
        uint tax = _tokens * initialPercentage[_roundId][msg.sender] / 100;
        initialTokensForFounder[_roundId][_founder] += tax;
        remainingTokensOfInvestor[_roundId][msg.sender] -= initialTokensForFounder[_roundId][_founder];
        require(ERC20(_tokenContract).transferFrom(msg.sender, seperateContractLink[_roundId][_founder], _tokens) == true, "transaction failed or reverted");
    }

    mapping(address => uint) public taxedTokens;
    mapping(uint => uint) private withdrawalFee;
    
    function withdrawInitialPercentage(address _tokenContract, address _founderSM, uint _roundId) external { // 2% tax should be levied on the each transaction
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        Founder founder = Founder(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'Founder' contract");
        if(initialWithdrawalStatus[_roundId][msg.sender] == true){
            revert("Initial withdrawal is already done");
        }
        FundLock fl = FundLock(seperateContractLink[_roundId][msg.sender]);
        uint tax = 2 * (initialTokensForFounder[_roundId][msg.sender] / 100);
        taxedTokens[_tokenContract] += tax;
        initialTokensForFounder[_roundId][msg.sender] -= tax;
        withdrawalFee[_roundId] += tax;
        initialWithdrawalStatus[_roundId][msg.sender] = true;
        require(ERC20(_tokenContract).transferFrom(address(fl), msg.sender, initialTokensForFounder[_roundId][msg.sender]) == true, "transaction failed or reverted");
    }

    mapping(uint => mapping(uint => uint)) private rejectedByInvestor;
    mapping(uint => bool) private projectCancel;
    mapping(uint => mapping(uint => address)) private requestForValidation;
    mapping(uint => mapping(uint => int)) private milestoneApprovalStatus; // 0 - means default null, 1 - means approves, -1 means rejected.
    mapping(uint => mapping(uint => bool)) private milestoneWithdrawalStatus;

    function milestoneValidationRequest(address _founderSM, uint _milestoneId, uint _roundId) external {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        Founder founder = Founder(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'Founder' contract");
        requestForValidation[_roundId][_milestoneId] = msg.sender;
    }

    function validateMilestone(address _investorSM, uint _milestoneId, uint _roundId, bool _status) external {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        InvestorLogin investor = InvestorLogin(_investorSM);
        require(investor.verifyInvestor(msg.sender) == true, "The address is not registered in the 'InvestorLogin' contract");
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

    function withdrawIndividualMilestoneByFounder(address _founderSM, address _investor, uint _roundId, uint _milestoneId, uint _percentage, address _tokenContract) external {
        require(msg.sender != address(0), "The address is not valid or the address is 0");
        Founder founder = Founder(_founderSM);
        require(founder.verifyFounder(msg.sender) == true, "The address is not registered in the 'Founder' contract");
        uint unlockedAmount = 0;
        if(milestoneApprovalStatus[_roundId][_milestoneId] == 1 && milestoneWithdrawalStatus[_roundId][_milestoneId] == false){
            unlockedAmount = (totalTokensOfInvestor[_roundId][_investor] * _percentage)/ 100;
            milestoneWithdrawalStatus[_roundId][_milestoneId] = true;
            remainingTokensOfInvestor[_roundId][_investor] -= unlockedAmount;
        }
        if(unlockedAmount > 0){
            uint tax = (2 * unlockedAmount) / 100;
            taxedTokens[_tokenContract] += tax;
            unlockedAmount -= tax;
            withdrawalFee[_roundId] += tax;
            FundLock fl = FundLock(seperateContractLink[_roundId][msg.sender]);
            require(ERC20(_tokenContract).transferFrom(address(fl), msg.sender, unlockedAmount) == true, "transaction failed or reverted");
        }else{
            revert("No unlocked tokens to withdraw");
        } 
    }

    function withdrawIndividualMilestoneByInvestor(address _investorSM, uint _roundId, address _founder, uint _milestoneId, uint _percentage, address _tokenContract) external{
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
                uint tax = (2 * lockedAmount)/ 100;
                taxedTokens[_tokenContract] += tax;
                withdrawalFee[_roundId] += tax;
                lockedAmount -= tax;
                investorWithdrawnTokens[msg.sender][_roundId] = lockedAmount;
                require(ERC20(_tokenContract).transferFrom(address(fl), msg.sender, lockedAmount) == true, "transaction failed or reverted"); 
            }
        }
    }

    mapping(address => mapping(uint => uint)) private investorWithdrawnTokens;  // investor add => roundid => withdrawn token

    function batchWithdrawByInvestors(address _investorSM, uint _roundId, address _founder, address _tokenContract) external{
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
                uint tax = (2 * lockedAmount)/ 100;
                taxedTokens[_tokenContract] += tax;
                withdrawalFee[_roundId] += tax;
                lockedAmount -= tax;
                investorWithdrawnTokens[msg.sender][_roundId] = lockedAmount;
                require(ERC20(_tokenContract).transferFrom(address(fl), msg.sender, lockedAmount) == true, "transaction failed or reverted"); 
            }
        }
    }

    function changeAdminAddress(address _newAdmin) external onlyAdmin{
        require(msg.sender != address(0), "Invalid address");
        contractOwner = _newAdmin;
    }

    function withdrawTaxTokens(address _tokenContract) external onlyAdmin { // All the taxed tokens are there in the contract itself. no instance is created
        require(msg.sender != address(0), "Invalid address");
        taxedTokens[_tokenContract] = 0;
        require(ERC20(_tokenContract).transfer(msg.sender, taxedTokens[_tokenContract]) == true, "execution failed or reverted");
    }   

    /*
        * READ FUNCTIONS:
    */

    function milestoneStatusChk(uint roundId, uint milestoneId) external view returns(int){
        return milestoneApprovalStatus[roundId][milestoneId];
    }

    function getContractAddress(uint _roundId) external view returns(address smartContractAddress){
        return contractAddress[_roundId];
    }

    function projectStatus(uint _roundId) external view returns(bool projectLiveOrNot){
        return projectCancel[_roundId];
    }

    function tokenStatus(uint _roundId, address _founder, address _investor) external view returns(uint unlockedAmount, uint lockedAmount, uint withdrawnTokensByFounder){
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
            }
        }
        lockedTokens = totalTokensOfInvestor[_roundId][_investor] - investorWithdrawnTokens[_investor][_roundId] - withdrawnTokens - withdrawalFee[_roundId] - unlockedTokens;
        return(
            unlockedTokens,
            lockedTokens,
            withdrawnTokens
        );
    }

    function investorWithdrawnToken(address _investor, uint _roundId) external view returns(uint investorWithdrawnTokenNumber){
        return investorWithdrawnTokens[_investor][_roundId];
    }

    function readTaxFee(uint _roundId) external view returns(uint transactionFee){
        return withdrawalFee[_roundId];
    }

    function milestoneWithdrawStatus(uint _roundId, uint _milestoneId) external view returns(bool){
        return milestoneWithdrawalStatus[_roundId][_milestoneId];
    }

    function initialWithdrawStatus(uint _roundId, address _founder) external view returns(bool initialWithdraw){
        return initialWithdrawalStatus[_roundId][_founder];
    }

    function availableTaxTokens(address _tokenContract) external view returns(uint taxTokens){
        return taxedTokens[_tokenContract];
    }
}

contract FundLock{
    address public _contractOwner;
    mapping(uint => mapping(address => uint)) public _amount;

    constructor (address investor, uint roundId, uint amount, address privateRoundContractAd) {
        _contractOwner = msg.sender;
        _amount[roundId][investor] = amount;
        require(ERC20(PrivateRound(privateRoundContractAd).tokenContract()).approve(privateRoundContractAd,amount) == true, "execution failed or reverted");
    }
}
