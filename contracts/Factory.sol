// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Factory is Initializable, UUPSUpgradeable, OwnableUpgradeable{

    function initialize() private initializer {
      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

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