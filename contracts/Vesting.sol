// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity ^0.8.9;
import "./Founder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Vesting is Initializable, UUPSUpgradeable, OwnableUpgradeable{

    error zeroAddress();
    error tokenAlreadyExist();
    error tokenNotSupported();
    error vestIdAlreadyLinkedToFounder();
    error founderNotRegistered();
    error addressNotMatched();
    error tgeDateNotReached();
    error alreadyWithdrawn();
    error installmentNotUnlocked(); 

    // STATE VARIABLES:
    address public contractOwner;
    address private FounderContract;
    address[] private tokenContractAddress;

    // EVENTS

    // MODIFIERS:
    modifier onlyAdmin(){
        require(msg.sender == contractOwner,"Sender is not the owner of this contract");
        _;
    }

    // STRUCTS
    struct vestingSchedule{
        mapping(uint => mapping(address => uint)) depositsOfFounderTokensToInvestor;   // 1 vestingId, address(Investor) = amount (total by founder)
        mapping(uint => mapping(address => uint)) depositsOfFounderCurrentTokensToInvestor;
        mapping(uint => mapping(address => uint)) tgeDate;                          // vestId, investor = date
        mapping(uint => mapping(address => uint)) tgePercentage;                       // vestingId, investor, storeDate (unix)
        mapping(uint => mapping(address => uint)) vestingStartDate;                 // vestingId, investor, vestingStarDate (unix)
        mapping(uint => mapping(address => uint)) vestingMonths;                    // vestingId, investor, vestingMonths (plain days)
        mapping(uint => mapping(address => uint)) tgeFund;                          // vestId, investor - tge percentage amt
        mapping(uint => mapping(address => uint)) remainingFundForInstallments;     // vestId, investor = remaining of tge
        mapping(uint => mapping(address => uint)) installmentAmount;                // vestId, investor = 800/24 =  
    }

    struct installment{
        mapping(uint => uint) _date; // index => date 
        mapping(uint => bool) _status; 
        mapping(uint => uint) _fund;
    }

    struct investors{
        address _investor;
        uint _tokens;
        uint _tgeFund;
    }

    struct forFounder{
        address _founder;
        address _founSM;
        address _founderCoinAddress;
    }

    struct I{
        address _investor;
        uint _fund;
    }

    struct due{
        uint256 _dateDue;
        uint256 _fundDue;
    }

    // MAPPINGS
    mapping(address => bool) private addressExist;
    mapping(address => vestingSchedule) vs;       // vestid -> investor -> installments[date: , fund]
    mapping(uint =>mapping(address => installment)) vestingDues;    // vestId => investorAd => installment
    mapping(uint => mapping(address => uint)) installmentCount; // vestId => investorAd => installmentCount
    mapping(uint => mapping(address => uint)) private investorWithdrawBalance;
    mapping(address => mapping(uint => bool)) private isVestIdForFounder;
    mapping(uint256 => bool) private vestIdExist;

    /**
        * initialize().
        * This method is for UUPS upgrade. 
    */

    function initialize() external initializer{
      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
       contractOwner = msg.sender;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /**
        * Whitelist contract this is necessary for Founder:
        * @param _contractAddressFounder This sets the FounderContract Address.
    */
    function whitelistFounderContract(address _contractAddressFounder) external onlyAdmin{
        if(_contractAddressFounder == address(0)){ revert zeroAddress();}
        FounderContract = _contractAddressFounder;
    }

    /**
        * whitelistToken.  eg: FTK
        * Whitelist the token address, so that only tokensfrom the whitelist works.
        * @param _tokenContract Enter the token contract address to be logged to the smart contract.
    */
    function whitelistToken(address _tokenContract) external onlyAdmin{
        if(_tokenContract == address(0)){ revert zeroAddress();}
        if(addressExist[_tokenContract] == true){ revert tokenAlreadyExist();}
        addressExist[_tokenContract] = true;
        tokenContractAddress.push(_tokenContract);
    }

    // Method: LINEAR:
    /**
        * depositFounderLinearTokens
        * @param _tgeFund 1
        * @param _coinContractAd 2
        * @param _vestId 3
        * @param _amount 4
        * @param _investor 5
        * @param _tgeDate 6 
        * @param _vestingStartDate 7 
        * @param _vestingMonths 8 
        * @param _vestingMode 9
    */
    function depositFounderLinearTokens(uint _tgeFund, address _coinContractAd, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _vestingStartDate, uint _vestingMonths, uint _vestingMode) external {
        if(addressExist[_coinContractAd] != true){ revert tokenNotSupported();}
        Founder founder = Founder(FounderContract);
        if(isVestIdForFounder[msg.sender][_vestId] == true){ revert vestIdAlreadyLinkedToFounder();}
        isVestIdForFounder[msg.sender][_vestId] = true;
        uint _founderDeposit;
        if(_vestingMonths == 0){
            _vestingMonths = 1;
        }
        if(founder.verifyFounder(msg.sender)){
            vs[msg.sender].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[msg.sender].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[msg.sender].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[msg.sender].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            vs[msg.sender].vestingStartDate[_vestId][_investor] = _vestingStartDate; // 4 unix
            vs[msg.sender].vestingMonths[_vestId][_investor] = _vestingMonths; // 5 plain
            vs[msg.sender].tgeFund[_vestId][_investor] = _tgeFund;
            vs[msg.sender].remainingFundForInstallments[_vestId][_investor] = _amount - vs[msg.sender].tgeFund[_vestId][_investor];
            vs[msg.sender].installmentAmount[_vestId][_investor] = vs[msg.sender].remainingFundForInstallments[_vestId][_investor] / _vestingMonths;
            for(uint i = 0; i < _vestingMonths; i++){
                vestingDues[_vestId][_investor]._date[i+1] = _vestingStartDate + (i * _vestingMode * 1 days);
                vestingDues[_vestId][_investor]._status[i+1] = false;
                vestingDues[_vestId][_investor]._fund[i+1] =  vs[msg.sender].installmentAmount[_vestId][_investor];
            }
            installmentCount[_vestId][_investor] = _vestingMonths;
            require(ERC20(_coinContractAd).transferFrom(msg.sender, address(this), _amount), "transaction failed or reverted");
        }else{
            revert founderNotRegistered();
        }
    }

    

    /**
        * depositFounderLinearTokensToInvestors
        * use the mapping to get the data of investor based on vestid and index number subject to the struct array
        * getting struct value in array and using investors array so using double array in the smart contract
        * @param _coinContractAd 1
        * @param _vestId 2
        * @param _tgeDate 3
        * @param _vestingStartDate 4
        * @param _vestingMonths 5
        * @param _investors 6
        * @param _vestingMode 7 
    */
    function depositFounderLinearTokensToInvestors(address _coinContractAd, uint _vestId, uint _tgeDate, uint _vestingStartDate, uint _vestingMonths, investors[] memory _investors, uint _vestingMode) external {
        if(addressExist[_coinContractAd] != true){ revert tokenNotSupported();}
        Founder founder = Founder(FounderContract);
        require(founder.verifyFounder(msg.sender), "The address is not registered in the 'Founder' contract");
        if(isVestIdForFounder[msg.sender][_vestId] == true){ revert vestIdAlreadyLinkedToFounder();}
        isVestIdForFounder[msg.sender][_vestId] = true;
        uint totalTokens = 0;
        if(_vestingMonths == 0){
            _vestingMonths = 1;
        }
        for(uint i = 0; i < _investors.length; i++){
            address _investor = _investors[i]._investor;
            uint _amount = (_investors[i]._tokens * (10**18))/10000;
            totalTokens += _amount;
            vs[msg.sender].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            vs[msg.sender].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[msg.sender].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            vs[msg.sender].vestingStartDate[_vestId][_investor] = _vestingStartDate; // 4 unix
            vs[msg.sender].vestingMonths[_vestId][_investor] = _vestingMonths; // 5 plain
            vs[msg.sender].tgeFund[_vestId][_investor] = (_investors[i]._tgeFund * (10**18))/10000;
            vs[msg.sender].remainingFundForInstallments[_vestId][_investor] = _amount - vs[msg.sender].tgeFund[_vestId][_investor];
            vs[msg.sender].installmentAmount[_vestId][_investor] = vs[msg.sender].remainingFundForInstallments[_vestId][_investor] / _vestingMonths;
            require(ERC20(_coinContractAd).transferFrom(msg.sender, _investors[i]._investor, (_investors[i]._tokens * (10**18))/10000), "transaction failed or reverted");
            for(uint j = 0; j < _vestingMonths; j++){
                vestingDues[_vestId][_investor]._date[j+1] = _vestingStartDate + (j * _vestingMode * 1 days);
                vestingDues[_vestId][_investor]._status[j+1] = false;
                vestingDues[_vestId][_investor]._fund[j+1] =  vs[msg.sender].installmentAmount[_vestId][_investor];
            }
            installmentCount[_vestId][_investor] = _vestingMonths;
        }
    }

    /**
        * withdrawTGEFund
        * @param _investor 1
        * @param _founder 2
        * @param _vestId 3
        * @param _coinContractAd 4
    */
    function withdrawTGEFund(address _investor,address _founder, uint _vestId, address _coinContractAd) external {
        if(addressExist[_coinContractAd] != true){ revert tokenNotSupported();}
        if(msg.sender != _investor){ revert addressNotMatched();}
        if(block.timestamp >= vs[_founder].tgeDate[_vestId][_investor]){
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= vs[_founder].tgeFund[_vestId][_investor];
            investorWithdrawBalance[_vestId][_investor] += vs[_founder].tgeFund[_vestId][_investor];
            require(ERC20(_coinContractAd).transfer(msg.sender, vs[_founder].tgeFund[_vestId][_investor]), "transaction failed or reverted");
            vs[_founder].tgeFund[_vestId][_investor] = 0; 
        }else{
            revert tgeDateNotReached();
        }
    }

    /**
        * withdrawInstallmentAmount
        * Based on months the installment amount is calculated, once the withdrawn is done deduct.
        * @param _investor 1
        * @param _founder 2
        * @param _vestId 3
        * @param _index 4
        * @param _coinContractAd 5
    */
    function withdrawInstallmentAmount(address _investor,address _founder, uint _vestId, uint _index, address _coinContractAd) external {
        if(addressExist[_coinContractAd] != true){ revert tokenNotSupported();}
        if(msg.sender != _investor){ revert addressNotMatched();}
        uint amt;
        if(block.timestamp >= vestingDues[_vestId][_investor]._date[_index]){
            if(!vestingDues[_vestId][_investor]._status[_index]){
                amt = vestingDues[_vestId][_investor]._fund[_index];
                vs[_founder].remainingFundForInstallments[_vestId][_investor] -= amt;
                vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= amt;
                investorWithdrawBalance[_vestId][_investor] += amt;
                vestingDues[_vestId][_investor]._status[_index] = true;
                require(ERC20(_coinContractAd).transfer(_investor, amt), "transaction failed or executed");   // update this line
            }else{
                revert alreadyWithdrawn();
            }
        }else{
            revert installmentNotUnlocked(); 
        }
    }

    /**
        * withdrawBatch 
        * @param _founder 1
        * @param _investor 2 
        * @param _vestId 3
        * @param _coinContractAd 4
    */
    function withdrawBatch(address _founder, address _investor, uint _vestId, address _coinContractAd) external {
        if(msg.sender != _investor){ revert addressNotMatched();}
        if(installmentCount[_vestId][_investor] != 0){
            uint unlockedAmount = 0;
            for(uint i = 1; i <= installmentCount[_vestId][_investor]; i++){
                if(vestingDues[_vestId][_investor]._date[i] <= block.timestamp && !vestingDues[_vestId][_investor]._status[i]){
                    unlockedAmount += vestingDues[_vestId][_investor]._fund[i];
                    vestingDues[_vestId][_investor]._status[i] = true;
                }
            }
            vs[_founder].remainingFundForInstallments[_vestId][_investor] -= unlockedAmount;
            if(block.timestamp >= vs[_founder].tgeDate[_vestId][_investor]){
                unlockedAmount += vs[_founder].tgeFund[_vestId][_investor];
                vs[_founder].tgeFund[_vestId][_investor] = 0; 
            }
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= unlockedAmount;
            investorWithdrawBalance[_vestId][_investor] += unlockedAmount;
            require(ERC20(_coinContractAd).transfer(msg.sender, unlockedAmount), "transaction failed or executed");
        }
    }

    
    // Method: NON-LINEAR:
    /**
        * setNonLinearInstallments
        * create an seperate array for date and fund [][]
        * @param _founder 1
        * @param _vestId 2
        * @param _investor 3
        * @param _dues 4
    */                                                                                             
    function setNonLinearInstallments(address _founder, uint _vestId, address _investor,due[] memory _dues) external {
        if(msg.sender != _founder){ revert addressNotMatched();}
        Founder founder = Founder(FounderContract);
        if(founder.verifyFounder(_founder)){
            uint duesAmount;
            for(uint i = 0; i < _dues.length; i++){     // error with for loop status: resolved.
                vestingDues[_vestId][_investor]._date[i+1] = _dues[i]._dateDue;  //_dues[i]._dateDue;
                vestingDues[_vestId][_investor]._status[i+1] = false;
                vestingDues[_vestId][_investor]._fund[i+1] = (_dues[i]._fundDue * (10**18))/10000;  // added the 10 ** 18 condition here.
                duesAmount += vestingDues[_vestId][_investor]._fund[i+1];
            }
            installmentCount[_vestId][_investor] = _dues.length;
        }else{
            revert founderNotRegistered();
        }
    }

    /**
        * depositFounderNonLinearTokens
        * @param _founder 1
        * @param _coinContractAd 2
        * @param _vestId 3
        * @param _amount 4
        * @param _investor 5
        * @param _tgeDate 6
        * @param _tgeFund 7
    */
    function depositFounderNonLinearTokens(address _founder, address _coinContractAd, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _tgeFund) external{
        if(msg.sender != _founder){ revert addressNotMatched();}
        Founder founder = Founder(FounderContract);
        if(isVestIdForFounder[msg.sender][_vestId] == true){ revert vestIdAlreadyLinkedToFounder();}
        isVestIdForFounder[msg.sender][_vestId] = true;
        uint _founderDeposit;
        if(founder.verifyFounder(_founder)){
            vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[_founder].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            vs[_founder].tgeFund[_vestId][_investor] = _tgeFund;
            vs[_founder].remainingFundForInstallments[_vestId][_investor] = _amount - vs[_founder].tgeFund[_vestId][_investor];
            require(ERC20(_coinContractAd).transferFrom(_founder, address(this), _amount), "transaction failed or reverted");
        }else{
            revert founderNotRegistered();
        }
    }

    // READ FUNCTIONS:
    function currentEscrowBalanceOfInvestor(address _founder, uint _vestId, address _investor) external view returns(uint){
        return vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor];
    }

    function investorTGEFund(address _founder, uint _vestId, address _investor) external view returns(uint){
        return vs[_founder].tgeFund[_vestId][_investor];
    }

    function investorInstallmentFund(uint _vestId, uint _index, address _investor) external view returns(uint,uint){
        return (vestingDues[_vestId][_investor]._fund[_index],
                vestingDues[_vestId][_investor]._date[_index]
        );
    }

    function investorWithdrawnFund(address _investor, uint _vestId) external view returns(uint){
        return investorWithdrawBalance[_vestId][_investor];
    }

    function returnRemainingFundExcludingTGE(address _founder, address _investor, uint _vestId) external view returns(uint){
        return vs[_founder].remainingFundForInstallments[_vestId][_investor];
    }

    function investorUnlockedFund(address _founder, address _investor, uint _vestId) external view returns(uint){
        uint unlockedAmount = 0;
        if(block.timestamp >= vs[_founder].tgeDate[_vestId][_investor]){
            unlockedAmount += vs[_founder].tgeFund[_vestId][_investor];
        }
        for(uint i = 1; i <= installmentCount[_vestId][_investor]; i++){
            if(vestingDues[_vestId][_investor]._date[i] <= block.timestamp && !vestingDues[_vestId][_investor]._status[i]){
                unlockedAmount += vestingDues[_vestId][_investor]._fund[i];
            }
        }
        return unlockedAmount;
    }
}