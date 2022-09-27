const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
require("dotenv").config();

const {PRIVATEROUND,FOUNDERLOGIN,INVESTORLOGIN} = process.env
let contract;

describe("All Read Functions", function(){
    before(async function(){
        const address = PRIVATEROUND;
        const setup = await ethers.getContractFactory("contracts/PrivateRound.sol:PrivateRound");
        const deployC = await setup.deploy();
        contract = deployC.attach(address)
    })

    it("Read Function 1: gets the created private round array for the founder", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const getDetails = await contract.connect(add).getMilestonesDetails(
            inv_1.address, 101
        );
        console.log(getDetails);
    })

    it("Read Function 2: token status", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const roundId = 101;
        const setup = await contract.connect(add).tokenStatus(
            roundId, add.address, inv_1.address
        );
        console.log(setup);
    })
})