const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
// require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

const {FOUNDER} = process.env

describe("$$ Testing Founder Smart Contract $$", function(){
    let contract; 

    before(async function(){
        const address = FOUNDER;
        const setup = await ethers.getContractFactory("contracts/Founder.sol:Founder");
        const deployC = await setup.deploy();
        contract = await deployC.attach(address)
    })

    it("* Adding founder to the factory smart contract", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
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

