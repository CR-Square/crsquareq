// SPDX-License-Identifier: MIT
pragma abicoder v2;
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Founder.sol";


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Vesting is Initializable, UUPSUpgradeable, OwnableUpgradeable{

    mapping(bytes32 => address) private whitelistedTokens;

    function initialize() private initializer onlyProxy{
      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

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

    mapping(address => vestingSchedule) vs;       // vestid -> investor -> installments[date: , fund]
    mapping(uint =>mapping(address => installment)) vestingDues;    // vestId => investorAd => installment
    mapping(uint => mapping(address => uint)) installmentCount; // vestId => investorAd => installmentCount
    mapping(uint => mapping(address => uint)) private investorWithdrawBalance;

    struct founderSetup{
        address founder;
        address founderSMAddress;
        address founderCoinAddress;
    }

// Method: LINEAR
    function depositFounderLinearTokens(uint _tgeFund, founderSetup memory _f, bytes32 _symbol, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _vestingStartDate, uint _vestingMonths, uint _vestingMode) external {
        require(msg.sender == _f.founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_f.founderSMAddress);   // Instance from the founder smart contract. 
        uint _founderDeposit;
        whitelistedTokens[_symbol] = _f.founderCoinAddress;
        if(_vestingMonths == 0){
            _vestingMonths = 1;
        }
        if(f.verifyFounder(_f.founder) == true){
            vs[_f.founder].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[_f.founder].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[_f.founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[_f.founder].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            vs[_f.founder].vestingStartDate[_vestId][_investor] = _vestingStartDate; // 4 unix
            vs[_f.founder].vestingMonths[_vestId][_investor] = _vestingMonths; // 5 plain
            vs[_f.founder].tgeFund[_vestId][_investor] = _tgeFund;
            vs[_f.founder].remainingFundForInstallments[_vestId][_investor] = _amount - vs[_f.founder].tgeFund[_vestId][_investor];
            vs[_f.founder].installmentAmount[_vestId][_investor] = vs[_f.founder].remainingFundForInstallments[_vestId][_investor] / _vestingMonths;
            for(uint i = 0; i < _vestingMonths; i++){
                vestingDues[_vestId][_investor]._date[i+1] = _vestingStartDate + (i * _vestingMode * 1 days);
                vestingDues[_vestId][_investor]._status[i+1] = false;
                vestingDues[_vestId][_investor]._fund[i+1] =  vs[_f.founder].installmentAmount[_vestId][_investor];
            }
            installmentCount[_vestId][_investor] = _vestingMonths;
            require(ERC20(whitelistedTokens[_symbol]).transferFrom(_f.founder, address(this), _amount) == true, "transaction failed or reverted");
        }else{
            revert("The founder is not registered yet");
        }
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

    
    // use the mapping to get the data of investor based on vestid and index number subject to the struct array;
    // getting struct value in array and using investors array so using double array in the smart contract
    function depositFounderLinearTokensToInvestors(forFounder memory _f, bytes32 _symbol, uint _vestId, uint _tgeDate, uint _vestingStartDate, uint _vestingMonths, investors[] memory _investors, uint _vestingMode) external {
        require(msg.sender == _f._founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_f._founSM);   // Instance from the founder smart contract. 
        require(f.verifyFounder(_f._founder) == true,"The founder is not registered yet");
        uint totalTokens = 0;
        whitelistedTokens[_symbol] = _f._founderCoinAddress;
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
            require(ERC20(whitelistedTokens[_symbol]).transferFrom(msg.sender, _investors[i]._investor, (_investors[i]._tokens * (10**18))/10000) == true, "transaction failed or reverted");
            for(uint j = 0; j < _vestingMonths; j++){
                vestingDues[_vestId][_investor]._date[j+1] = _vestingStartDate + (j * _vestingMode * 1 days);
                vestingDues[_vestId][_investor]._status[j+1] = false;
                vestingDues[_vestId][_investor]._fund[j+1] =  vs[msg.sender].installmentAmount[_vestId][_investor];
            }
            installmentCount[_vestId][_investor] = _vestingMonths;
        }
    }

    function withdrawTGEFund(address _investor,address _founder, uint _vestId, bytes32 _symbol) external {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        if(block.timestamp >= vs[_founder].tgeDate[_vestId][_investor]){
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= vs[_founder].tgeFund[_vestId][_investor];
            investorWithdrawBalance[_vestId][_investor] += vs[_founder].tgeFund[_vestId][_investor];
            vs[_founder].tgeFund[_vestId][_investor] = 0; 
            require(ERC20(whitelistedTokens[_symbol]).transfer(msg.sender, vs[_founder].tgeFund[_vestId][_investor]) == true, "transaction failed or reverted");
        }else{
            revert("The transaction has failed because the TGE time has not reached yet");
        }
    }

    // Based on months the installment amount is calculated, once the withdrawn is done deduct.

    function withdrawInstallmentAmount(address _investor,address _founder, uint _vestId, uint _index, bytes32 _symbol) external {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        uint amt;
        if(block.timestamp >= vestingDues[_vestId][_investor]._date[_index]){
            if(vestingDues[_vestId][_investor]._status[_index] != true){
                amt = vestingDues[_vestId][_investor]._fund[_index];
                vs[_founder].remainingFundForInstallments[_vestId][_investor] -= amt;
                vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= amt;
                investorWithdrawBalance[_vestId][_investor] += amt;
                vestingDues[_vestId][_investor]._status[_index] = true;
                require(ERC20(whitelistedTokens[_symbol]).transfer(_investor, amt) == true, "transaction failed or executed");   // update this line
            }else{
                revert("Already Withdrawn");
            }
        }else{
            revert("Installment is not unlocked yet");  
        }
    }

    function withdrawBatch(address _founder, address _investor, uint _vestId, bytes32 _symbol) external {
        require(msg.sender == _investor,"The connected wallet is not investor wallet, please check the address");
        if(installmentCount[_vestId][_investor] != 0){
            uint unlockedAmount = 0;
            for(uint i = 1; i <= installmentCount[_vestId][_investor]; i++){
                if(vestingDues[_vestId][_investor]._date[i] <= block.timestamp && vestingDues[_vestId][_investor]._status[i] != true){
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
            require(ERC20(whitelistedTokens[_symbol]).transfer(msg.sender, unlockedAmount) == true, "transaction failed or executed");
        }
    }

    // READ FUNCTIONS:

    // 1. This shows static amount deposited by the founder for the investor.
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
            if(vestingDues[_vestId][_investor]._date[i] <= block.timestamp && vestingDues[_vestId][_investor]._status[i] != true){
                unlockedAmount += vestingDues[_vestId][_investor]._fund[i];
            }
        }
        return unlockedAmount;
    }

    /*
    Method: NON-LINEAR:
    */
   
    struct due{
        uint256 _dateDue;
        uint256 _fundDue;
    }

    // create an seperate array for date and fund [][]                                                                                                   // due[] memory _dues
    function setNonLinearInstallments(address _founder, address _founderSmartContractAd, uint _vestId, address _investor,due[] memory _dues) external {
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract. 
        if(f.verifyFounder(_founder)){
            uint duesAmount;
            for(uint i = 0; i < _dues.length; i++){     // error with for loop status: resolved.
                vestingDues[_vestId][_investor]._date[i+1] = _dues[i]._dateDue;  //_dues[i]._dateDue;
                vestingDues[_vestId][_investor]._status[i+1] = false;
                vestingDues[_vestId][_investor]._fund[i+1] = (_dues[i]._fundDue * (10**18))/10000;  // added the 10 ** 18 condition here.
                duesAmount += vestingDues[_vestId][_investor]._fund[i+1];
            }
            installmentCount[_vestId][_investor] = _dues.length;
        }else{
            revert("The founder is not registered yet");
        }
    }

    function depositFounderNonLinearTokens(address _founder, address _founderCoinAddress, address _founderSmartContractAd, bytes32 _symbol, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _tgeFund) external{
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract. 
        uint _founderDeposit;
        whitelistedTokens[_symbol] = _founderCoinAddress;
        if(f.verifyFounder(_founder)){
            vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[_founder].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            vs[_founder].tgeFund[_vestId][_investor] = _tgeFund;
            vs[_founder].remainingFundForInstallments[_vestId][_investor] = _amount - vs[_founder].tgeFund[_vestId][_investor];
            require(ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), _amount) == true, "transaction failes or reverted");
        }else{
            revert("The founder is not registered yet");
        }
    }
}