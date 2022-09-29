pragma solidity 0.8.0;

contract FactoryProject_ProposalDetails{
    address[] public FounderAddress;
    string[] public FounderName;
    string[] public ProposalDetails;
    address private SuperAdmin;

    constructor (address _ad){
        SuperAdmin = _ad;
    }

    modifier onlySuperAdmin(){
        require(SuperAdmin == msg.sender,"You are not the SuperAdmin to add founder proposals");
        _;
    }

    function addFounderAndProposal(address _ad, string memory _name, string memory _proposal) public onlySuperAdmin{
        FounderAddress.push(_ad);
        FounderName.push(_name);
        ProposalDetails.push(_proposal);
    }
}
