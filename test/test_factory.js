const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
require("dotenv").config();

const {FACTORY} = process.env

describe("$$ Testing Factory Smart Contract $$", function(){
    let contract; 

    before(async function(){
        const address = FACTORY;
        const setup = await ethers.getContractFactory("contracts/Factory.sol:Factory");
        const deployC = await setup.deploy();
        contract = await deployC.attach(address);
    })

    it("* Adding validator1 to the factory smart contract", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const app = await contract.connect(val1).addValidators(val1.address);
    })

    it("* Adding validator2 to the factory smart contract", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const app = await contract.connect(val2).addValidators(val2.address);
    })

    it("* Adding validator3 to the factory smart contract", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const app = await contract.connect(val3).addValidators(val3.address);
    })

    it("* Adding validator4 to the factory smart contract", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const app = await contract.connect(val4).addValidators(val4.address);
    })

    it("* Gets all the validator addresses in the smart contract", async function(){
        let localSetup = true;
        const app = await contract.returnArray();
        if(app.length >= 4){
            console.log("There are enough validators in the smart contract to validate");
        }else{
            localSetup = false;
            return localSetup;
        }
    })
})