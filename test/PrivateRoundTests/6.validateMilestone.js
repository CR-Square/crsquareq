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

    it("Write Function 7: (Investor connects wallet and validates the milestone: milestone no 1)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const milestoneId = 10;
        const roundId = 100;
        const status = true;
        const setup = await contract.connect(inv_1).validateMilestone(
            INVESTORLOGIN, milestoneId, roundId, status
        )
    })

    it("Write Function 8: (Investor connects wallet and validates the milestone: milestone no 1)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const milestoneId = 20;
        const roundId = 100;
        const status = true;
        const setup = await contract.connect(inv_1).validateMilestone(
            INVESTORLOGIN, milestoneId, roundId, status
        )
    })

    it("Write Function 9: (Investor connects wallet and validates the milestone: milestone no 1)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const milestoneId = 30;
        const roundId = 100;
        const status = true;
        const setup = await contract.connect(inv_1).validateMilestone(
            INVESTORLOGIN, milestoneId, roundId, status
        )
    })
})