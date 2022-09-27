const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
require("dotenv").config();

const {PRIVATEROUND,FOUNDERLOGIN,INVESTORLOGIN} = process.env
let contract;

describe("Founder requests for milestone validation", function(){
    before(async function(){
        const address = PRIVATEROUND;
        const setup = await ethers.getContractFactory("contracts/PrivateRound.sol:PrivateRound");
        const deployC = await setup.deploy();
        contract = deployC.attach(address)
    })

    // Milestone Validation Request as per test case: Request Number 1
    it("Write Function 4: (Founder connects wallet and request for milestone validation 1)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const milestoneId = 10;
        const roundId = 100;
        const setup = await contract.connect(add).milestoneValidationRequest(
            FOUNDERLOGIN, milestoneId, roundId
        )
    })

    // Milestone Validation Request as per test case: Request Number 2
    it("Write Function 5: (Founder connects wallet and request for milestone validation 2)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const milestoneId = 20;
        const roundId = 100;
        const setup = await contract.connect(add).milestoneValidationRequest(
            FOUNDERLOGIN, milestoneId, roundId
        )
    })

    // Milestone Validation Request as per test case: Request Number 3
    it("Write Function 6: (Founder connects wallet and request for milestone validation 3)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const milestoneId = 30;
        const roundId = 100;
        const setup = await contract.connect(add).milestoneValidationRequest(
            FOUNDERLOGIN, milestoneId, roundId
        )
    })
    
})