const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
require("dotenv").config();

const {PRIVATEROUND,FOUNDERLOGIN,INVESTORLOGIN} = process.env
let contract;

describe("Private Round contract testing", function(){
    before(async function(){
        const address = PRIVATEROUND;
        const setup = await ethers.getContractFactory("contracts/PrivateRound.sol:PrivateRound");
        const deployC = await setup.deploy();
        contract = deployC.attach(address)
    })

    it("Write Function 1: (Investor Connects Wallet) => Creates private round for the Founder", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const roundId = 100;
        const tokenAddress = "0x2E8D504E81594cF707Fe842Dc0eb32810DDB219B";  // DAI in Goerli
        const structArray = [[10,1663045153,20],[20,1663046153,30],[30,1663046953,40]];
        const app = await contract.connect(inv_1).createPrivateRound(
            roundId, INVESTORLOGIN, 10, structArray)
    })

    it("Write Function 2: (Investor Deposits Tokens)", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const roundId = 100;
        const tokenAddress = "0x2E8D504E81594cF707Fe842Dc0eb32810DDB219B";  // DAI in Goerli
        const tokens = { value: ethers.utils.parseEther("1000") }
        const setup = await contract.connect(inv_1).depositTokens(
            tokenAddress, INVESTORLOGIN, add.address, tokens.value, roundId
        )
    })
})