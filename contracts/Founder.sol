// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Founder is Initializable, UUPSUpgradeable, OwnableUpgradeable{
    
    mapping(address => bool) private isFounder;
    address[] private pushFounders;

    function initialize() public initializer {
      ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
       __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function addFounder(address _ad) external{
        require(msg.sender == _ad,"Connect same wallet to add founder address");
        isFounder[_ad] = true;
        pushFounders.push(_ad);
    }

    function verifyFounder(address _ad) external view returns(bool condition){
        if(isFounder[_ad]){
            return true;
        }else{
            return false;
        }
    }

    function getAllFounderAddress() external view returns(address[] memory){
        return pushFounders;
    }    
}