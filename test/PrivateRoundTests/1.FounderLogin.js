const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
require("dotenv").config();

const {FOUNDERLOGIN} = process.env

describe("$$ Testing Founder Login Smart Contract  $$", function(){
    let contract; 

    before(async function(){
        const address = FOUNDERLOGIN;
        const setup = await ethers.getContractFactory("contracts/PrivateRound.sol:FounderLogin");
        const deployC = await setup.deploy();
        contract = deployC.attach(address)
    })

    it("* Adding founder to the 'FounderLogin Smart Contract'", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        // console.log(add.address);
        // To check whether the passing founder address is correct or not.
        const app = await contract.connect(add).addFounder(add.address);
    })

    it("* Verifying whether the founder has access to the smart contract", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const app = await contract.connect(add).verifyFounder(add.address);
    })

    it("* Gets all the founder addresses in the smart contract", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const app = await contract.connect(val1).getAllFounderAddress();
    })
})