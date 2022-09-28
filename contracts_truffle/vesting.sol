//SPDX-License-Identifier: MIT

import "./founder.sol";
import "./ERC20.sol";

pragma solidity 0.8.4;

contract Vesting{

/*
    Vesting Smart Contract:
        a. depositFounderTokens(proj_id, vest_id, investor, token_no, tge_date_in_seconds, tge_percent, vesting_start_date, no_of_vesting_months)
        uint projId;
        uint vestingID;
        amount = no of tokens;
        uint tgeDate (keep this record in seconds)
        vesting start data = tgeData + vestingStart Date in seconds
        no of vestingMonths a simple uint.

        1. Founder is linking everything with investor address and vesting id, so make sure this condition check is there at first line

        whitelistedTokens[_symbol] = _tokenAddress;
        ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), _amount);
*/  

    mapping(bytes32 => address) private whitelistedTokens;

    struct vestingSchedule{
        mapping(uint => mapping(address => uint)) depositsOfFounderTokensToInvestor;   // 1 vestingId, address(Investor) = amount (total by founder)
        mapping(uint => mapping(address => uint)) depositsOfFounderCurrentTokensToInvestor;
        mapping(uint => mapping(uint => address)) investorLinkProjectAndVesting;    // projId, vestingId, address(Investor)
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

    // function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
    //     return whitelistedTokens[token];
    // }

    mapping(uint => mapping(address => uint)) private investorWithdrawBalance;

    // function whitelistToken(bytes32 _symbol, address _founderCoinAddress) public returns(address){
    //     return whitelistedTokens[_symbol] = _founderCoinAddress;
    // }

    struct founderSetup{
        address founder;
        address founderSMAddress;
        address founderCoinAddress;
    }

// Method: LINEAR
    function depositFounderLinearTokens(uint _tgeFund, founderSetup memory _f, bytes32 _symbol, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _vestingStartDate, uint _vestingMonths, uint _vestingMode) public {
        require(msg.sender == _f.founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_f.founderSMAddress);   // Instance from the founder smart contract. 
        // uint _tgePercentage;
        uint _founderDeposit;
        if(f.verifyFounder(_f.founder) == true){
            vs[_f.founder].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[_f.founder].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[_f.founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[_f.founder].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            // vs[_founder].tgePercentage[_vestId][_investor] = _tgePercent;
            // _tgePercentage = vs[_founder].tgePercentage[_vestId][_investor];
            vs[_f.founder].vestingStartDate[_vestId][_investor] = _vestingStartDate; // 4 unix
            vs[_f.founder].vestingMonths[_vestId][_investor] = _vestingMonths; // 5 plain
            /* TGEFUND:
            1. This gives use the balance of tge fund available for the investor to withdraw.
            2. makes this available for the investor to withdraw after "_tgeDate".
            */
            vs[_f.founder].tgeFund[_vestId][_investor] = _tgeFund;
            /*REMAININGFUND:
            1. This will divide the fund based on installments.
            */
            vs[_f.founder].remainingFundForInstallments[_vestId][_investor] = _amount - vs[_f.founder].tgeFund[_vestId][_investor];
            vs[_f.founder].installmentAmount[_vestId][_investor] = vs[_f.founder].remainingFundForInstallments[_vestId][_investor] / _vestingMonths;
            // whitelistedTokens[_symbol] = _tokenAddress;
            whitelistedTokens[_symbol] = _f.founderCoinAddress;
            ERC20(whitelistedTokens[_symbol]).transferFrom(_f.founder, address(this), _amount);
            for(uint i = 0; i < _vestingMonths; i++){
                vestingDues[_vestId][_investor]._date[i+1] = _vestingStartDate + (i * _vestingMode * 1 days);
                vestingDues[_vestId][_investor]._status[i+1] = false;
                vestingDues[_vestId][_investor]._fund[i+1] =  vs[_f.founder].installmentAmount[_vestId][_investor];
            }
            installmentCount[_vestId][_investor] = _vestingMonths;
        }else{
            revert("The founder is not registered yet");
        }
    }

    /*---------------------x
    Multi Investors Deposit;
    -----------------------x
    Where array of investor address can be used and desired amount can be deposited for the investors.
    */

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

    // getting struct value in array and using investors array so using double array in the smart contract
    function depositFounderLinearTokensToInvestors(forFounder memory _f, bytes32 _symbol, uint _vestId, uint _tgeDate, uint _vestingStartDate, uint _vestingMonths, investors[] memory _investors, uint _vestingMode) public {
        require(msg.sender == _f._founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_f._founSM);   // Instance from the founder smart contract. 
        require(f.verifyFounder(_f._founder) == true,"The founder is not registered yet");
        uint totalTokens = 0;
        for(uint i = 0; i < _investors.length; i++){
            address _investor = _investors[i]._investor;
            uint _amount = (_investors[i]._tokens * (10**18))/10000;
            totalTokens += _amount;
            vs[msg.sender].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            vs[msg.sender].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[msg.sender].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            // vs[msg.sender].tgePercentage[_vestId][_investor] = _tgePercent;
            vs[msg.sender].vestingStartDate[_vestId][_investor] = _vestingStartDate; // 4 unix
            vs[msg.sender].vestingMonths[_vestId][_investor] = _vestingMonths; // 5 plain
            /* TGEFUND:
            1. This gives use the balance of tge fund available for the investor to withdraw.
            2. makes this available for the investor to withdraw after "_tgeDate".
            */
            vs[msg.sender].tgeFund[_vestId][_investor] = (_investors[i]._tgeFund * (10**18))/10000;
            /*REMAININGFUND:
            1. This will divide the fund based on installments.
            */
            vs[msg.sender].remainingFundForInstallments[_vestId][_investor] = _amount - vs[msg.sender].tgeFund[_vestId][_investor];
            vs[msg.sender].installmentAmount[_vestId][_investor] = vs[msg.sender].remainingFundForInstallments[_vestId][_investor] / _vestingMonths;
            for(uint j = 0; j < _vestingMonths; j++){
                vestingDues[_vestId][_investor]._date[j+1] = _vestingStartDate + (j * _vestingMode * 1 days);
                vestingDues[_vestId][_investor]._status[j+1] = false;
                vestingDues[_vestId][_investor]._fund[j+1] =  vs[msg.sender].installmentAmount[_vestId][_investor];
            }
            installmentCount[_vestId][_investor] = _vestingMonths;
        }
        whitelistedTokens[_symbol] = _f._founderCoinAddress;
        ERC20(whitelistedTokens[_symbol]).transferFrom(msg.sender, address(this), totalTokens);
    }

    function withdrawTGEFund(address _investor,address _founder, uint _vestId, bytes32 _symbol) public {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        if(block.timestamp >= vs[_founder].tgeDate[_vestId][_investor]){
            ERC20(whitelistedTokens[_symbol]).transfer(msg.sender, vs[_founder].tgeFund[_vestId][_investor]);
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= vs[_founder].tgeFund[_vestId][_investor];
            investorWithdrawBalance[_vestId][_investor] += vs[_founder].tgeFund[_vestId][_investor];
            vs[_founder].tgeFund[_vestId][_investor] = 0; 
        }else{
            revert("The transaction has failed because the TGE time has not reached yet");
        }
    }

    // Based on months the installment amount is calculated, once the withdrawn is done deduct.

    function withdrawInstallmentAmount(address _investor,address _founder, uint _vestId, uint _index, bytes32 _symbol) public {
        require(msg.sender == _investor,"The connected wallet is not investor wallet");
        uint amt;
        if(block.timestamp >= vestingDues[_vestId][_investor]._date[_index]){
            if(vestingDues[_vestId][_investor]._status[_index] != true){
                amt = vestingDues[_vestId][_investor]._fund[_index];
                ERC20(whitelistedTokens[_symbol]).transfer(_investor, amt);   // update this line
                vs[_founder].remainingFundForInstallments[_vestId][_investor] -= amt;
                vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= amt;
                investorWithdrawBalance[_vestId][_investor] += amt;
                // vestingDues[_vestId][_investor]._fund[_index] = 0;
                vestingDues[_vestId][_investor]._status[_index] = true;
            }else{
                revert("Already Withdrawn");
            }
        }else{
            revert("Installment is not unlocked yet");  
        }
    }

    /*
    Setup:
    1. The installments grouping setup depends on the unix time (block.timestamp).
    2. loop through this vs[_founder].installmentAmount[_vestId][_investor].
    3. This unlocks based on unix time right so make sure the current time is larger or equivalent to unlock time.
    4. calc the token from array of installments, sum the installments till whc date its unlocked.
    5. The same setup can be used for the tge fund, also if he wished to withdraw tge fund in one go do the same loop, sum
       the tokens and do the process.
    6. For tgeFund and for Installment make it true.
    7. 
    */

    function withdrawBatch(address _founder, address _investor, uint _vestId, bytes32 _symbol) public {
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
            ERC20(whitelistedTokens[_symbol]).transfer(msg.sender, unlockedAmount);
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] -= unlockedAmount;
            investorWithdrawBalance[_vestId][_investor] += unlockedAmount;
        }
    }

    /*
    --------------X
    READ FUNCTIONS:
    --------------X
    */
    // 1. This shows static amount deposited by the founder for the investor.
    function currentEscrowBalanceOfInvestor(address _founder, uint _vestId, address _investor) public view returns(uint){
        return vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor];
    }

    function investorTGEFund(address _founder, uint _vestId, address _investor) public view returns(uint){
        return vs[_founder].tgeFund[_vestId][_investor];
    }

    function investorInstallmentFund(uint _vestId, uint _index, address _investor) public view returns(uint,uint){
        return (vestingDues[_vestId][_investor]._fund[_index],
                vestingDues[_vestId][_investor]._date[_index]
                );
    }

    function investorWithdrawnFund(address _investor, uint _vestId) public view returns(uint){
        return investorWithdrawBalance[_vestId][_investor];
    }

    function returnRemainingFundExcludingTGE(address _founder, address _investor, uint _vestId) public view returns(uint){
        return vs[_founder].remainingFundForInstallments[_vestId][_investor];
    }

    function investorUnlockedFund(address _founder, address _investor, uint _vestId) public view returns(uint){
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

    // create an seperate array for date and fund [][]
                                                                                                          // due[] memory _dues
    function setNonLinearInstallments(address _founder, address _founderSmartContractAd, uint _vestId, address _investor,due[] memory _dues) public {
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract. 
        if(f.verifyFounder(_founder) == true){
            uint duesAmount;
            for(uint i = 0; i < _dues.length; i++){     // error with for loop status: resolved.
                vestingDues[_vestId][_investor]._date[i+1] = _dues[i]._dateDue;  //_dues[i]._dateDue;
                vestingDues[_vestId][_investor]._status[i+1] = false;
                vestingDues[_vestId][_investor]._fund[i+1] = (_dues[i]._fundDue * (10**18))/10000;  // added the 10 ** 18 condition here.
                duesAmount += vestingDues[_vestId][_investor]._fund[i+1];
            }
            installmentCount[_vestId][_investor] = _dues.length;
            // if(vs[_founder].remainingFundForInstallments[_vestId][_investor] != duesAmount){
            //     delete installmentCount[_vestId][_investor];
            //     delete vestingDues[_vestId][_investor];
            //     revert("Dues amount is not matching with actual number of tokens");
            // }
        }else{
            revert("The founder is not registered yet");
        }
    }

    function depositFounderNonLinearTokens(address _founder, address _founderCoinAddress, address _founderSmartContractAd, bytes32 _symbol, uint _vestId, uint _amount, address _investor, uint _tgeDate, uint _tgeFund) public{
        require(msg.sender == _founder,"The connected wallet is not founder wallet");
        Founder f = Founder(_founderSmartContractAd);   // Instance from the founder smart contract. 
        // uint _tgePercentage;
        uint _founderDeposit;
        whitelistedTokens[_symbol] = _founderCoinAddress;
        if(f.verifyFounder(_founder) == true){
            vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor] = _amount; // 1 deposit
            _founderDeposit = vs[_founder].depositsOfFounderTokensToInvestor[_vestId][_investor];
            vs[_founder].depositsOfFounderCurrentTokensToInvestor[_vestId][_investor] = _amount;
            vs[_founder].tgeDate[_vestId][_investor] = _tgeDate; // 3 unix
            // vs[_founder].tgePercentage[_vestId][_investor] = _tgePercent;
            // _tgePercentage = vs[_founder].tgePercentage[_vestId][_investor];
            /* TGEFUND:
            1. This gives use the balance of tge fund available for the investor to withdraw.
            2. makes this available for the investor to withdraw after "_tgeDate".
            */
            vs[_founder].tgeFund[_vestId][_investor] = _tgeFund;
            /*REMAININGFUND:
            1. This will divide the fund based on installments.
            */
            vs[_founder].remainingFundForInstallments[_vestId][_investor] = _amount - vs[_founder].tgeFund[_vestId][_investor];
            ERC20(whitelistedTokens[_symbol]).transferFrom(_founder, address(this), _amount);
        }else{
            revert("The founder is not registered yet");
        }
    }
}