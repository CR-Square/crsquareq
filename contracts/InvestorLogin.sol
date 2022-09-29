// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract InvestorLogin is Initializable, UUPSUpgradeable, OwnableUpgradeable{
    
    mapping(address => bool) private isInvestor;
    address[] private pushInvestors;

    function initialize() private initializer {
      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

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