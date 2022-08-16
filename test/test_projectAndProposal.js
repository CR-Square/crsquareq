const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
const {web3} = require("web3");
require("dotenv").config();

const {PROJECTANDPROPOSAL} = process.env

describe("$$ Testing ProjectAndProposal Smart Contract $$", function(){
    let contract; 
    before(async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        // This is the proxy address, the UUPS proxy pattern is needed to followed to achieve the proxy.
        const address = PROJECTANDPROPOSAL;
        const setup = await ethers.getContractFactory("contracts/ProjectAndProposal.sol:ProjectAndProposal");
        const deployC = await setup.connect(add).deploy();
        contract = await deployC.attach(address);
        /*
            projectId - 100
            initialId - 1
            subsequentId - 15
        */
    })

    it("* test case 1: setFounderAndCycleForTheProject", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const f_sm = `${process.env.FOUNDER_SM_AD}`
        const setup = await contract.connect(add).setFounderAndCycleForTheProject(f_sm,add.address,100,5);
    })

    it("* test case 2: setInitialId", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        let values = { value: ethers.utils.parseEther("1000") }
        // console.log(inv_1.address);
        const setup = await contract.connect(add).setInitialId(add.address,inv_1.address,1,100,values.value)
    })

    it("* test case 3: depositStableTokens", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const stable_byt32 = `${process.env.STABLE_BYTES32}`;
        const stable_contractAd = `${process.env.STABLE_CONTRACT}`   
        let values = { value: ethers.utils.parseEther("1000") }   
        // console.log(values.value);
        const setup = await contract.connect(inv_1).depositStableTokens(inv_1.address,add.address,values.value,stable_byt32,stable_contractAd,1,100)
        // console.log(setup);
    })

    it("* test case 4: Withdraw10PercentOfStableCoin", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const f_sm = `${process.env.FOUNDER_SM_AD}`
        const stable_byt32 = `${process.env.STABLE_BYTES32}`
        const contract_stable = `${process.env.STABLE_CONTRACT}`
        const setup = await contract.connect(add).Withdraw10PercentOfStableCoin(f_sm, add.address, inv_1.address, stable_byt32,100);
    })

    it("* test case 5: setSubsequentId", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const setup = await contract.connect(add).setSubsequentId(add.address,15,100);
    })

    it("* test case 5.1: Validate - Validation process 1", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const boolean = true;
        const factory_contract = `${process.env.FACTORY_SM_AD}`;
        const setup = await contract.connect(val1).Validate(boolean,val1.address,factory_contract,15,100);
    })

    it("* test case 5.2: Validate - Validation process 1", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const boolean = true;
        const factory_contract = `${process.env.FACTORY_SM_AD}`;
        const setup = await contract.connect(val2).Validate(boolean,val2.address,factory_contract,15,100);
    })

    it("* test case 5.3: Validate - Validation process 1", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const boolean = true;
        const factory_contract = `${process.env.FACTORY_SM_AD}`;
        const setup = await contract.connect(val3).Validate(boolean,val3.address,factory_contract,15,100);
    })

    it("* test case 5.4: Validate - Validation process 1", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const boolean = true;
        const factory_contract = `${process.env.FACTORY_SM_AD}`;
        const setup = await contract.connect(val4).Validate(boolean,val4.address,factory_contract,15,100);
    })

    /*
        once validation is succesfull, the founder is allowed to withdraw the tokens
    */

    it("* test case 6: withdrawSubsequentStableCoins", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const stable_byt32 = `${process.env.STABLE_BYTES32}`
        const setup = await contract.connect(add).withdrawSubsequentStableCoins(15,add.address,stable_byt32,100);
    })

    /*
        once the project is rejected by validation, comment other test cases and run.
    */

    it("* test case 7: withdrawTokensByInvestor", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const stable_byt32 = `${process.env.STABLE_BYTES32}`
        const setup = await contract.connect(inv_1).withdrawSubsequentStableCoins(add.address,inv_1.address,stable_byt32,100);
    })
})