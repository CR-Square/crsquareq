const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
require("dotenv").config();

const {PRIVATEROUND,FOUNDERLOGIN,INVESTORLOGIN} = process.env
let contract;

describe("Founder Withdraws the initial percentage tokens from the contract", function(){
    before(async function(){
        const address = PRIVATEROUND;
        const setup = await ethers.getContractFactory("contracts/PrivateRound.sol:PrivateRound");
        const deployC = await setup.deploy();
        contract = deployC.attach(address)
    })

    it("Write Function 3: (Founder withdraws tokens unlocked according to the roundId )", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const tokenAddress = "0x2E8D504E81594cF707Fe842Dc0eb32810DDB219B";  // DAI in Goerli
        const roundId = 100;
        const setup = await contract.connect(add).withdrawInitialPercentage(
            tokenAddress, FOUNDERLOGIN, roundId
        )
    })
})