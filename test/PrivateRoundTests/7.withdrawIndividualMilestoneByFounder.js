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

    it("Write Function 9: (Founder withdraws the first approved milestone token)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const milestoneId = 10;
        const roundId = 100;
        const percentage = 20;
        const tokenAddress = "0x2E8D504E81594cF707Fe842Dc0eb32810DDB219B";  // DAI in Goerli
        const setup = await contract.connect(add).withdrawIndividualMilestoneByFounder(
            FOUNDERLOGIN, inv_1.address, roundId, milestoneId, percentage, tokenAddress
        )
    })

    it("Write Function 10: (Founder withdraws the first approved milestone token)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const milestoneId = 20;
        const roundId = 100;
        const percentage = 30;
        const tokenAddress = "0x2E8D504E81594cF707Fe842Dc0eb32810DDB219B";  // DAI in Goerli
        const setup = await contract.connect(add).withdrawIndividualMilestoneByFounder(
            FOUNDERLOGIN, inv_1.address, roundId, milestoneId, percentage, tokenAddress
        )
    })

    it("Write Function 11: (Founder withdraws the first approved milestone token)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const milestoneId = 30;
        const roundId = 100;
        const percentage = 40;
        const tokenAddress = "0x2E8D504E81594cF707Fe842Dc0eb32810DDB219B";  // DAI in Goerli
        const setup = await contract.connect(add).withdrawIndividualMilestoneByFounder(
            FOUNDERLOGIN, inv_1.address, roundId, milestoneId, percentage, tokenAddress
        )
    })
})

