const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
require("dotenv").config();

const {INVESTORLOGIN} = process.env

describe("$$ Testing Investor Login Smart Contract  $$", function(){
    let contract; 

    before(async function(){
        const address = INVESTORLOGIN;
        const setup = await ethers.getContractFactory("contracts/PrivateRound.sol:InvestorLogin");
        const deployC = await setup.deploy();
        contract = deployC.attach(address)
    })

    it("* Adding Investor to the 'InvestorLogin Smart Contract'", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        // console.log(inv_1.address);
        // To check whether the passing investor address is correct or not.
        const app = await contract.connect(inv_1).addInvestor(inv_1.address);
    })

    it("* Verifying whether the Investor has access to the smart contract", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const app = await contract.connect(inv_1).verifyInvestor(inv_1.address);
    })

    it("* Gets all the Investor addresses in the smart contract", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const app = await contract.connect(inv_1).getAllInvestorAddress();
    })
})