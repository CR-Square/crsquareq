const {expect} = require("chai")
const {ethers, provider} = require("hardhat")
require("dotenv").config();

const {VESTING} = process.env;

describe("$$ Vesting Smart Contract", function(){
    let contract; 

    before(async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const address = VESTING;
        const setup = await ethers.getContractFactory("contracts/Vesting.sol:Vesting");
        const deployC = await setup.connect(add).deploy();
        contract = await deployC.attach(address);
    })

    it("* test case 1: depositFounderLinearTokens", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        let tge = { value: ethers.utils.parseEther("100") }
        let amt = { value: ethers.utils.parseEther("1000") }
        const setup = await contract.connect(add).depositFounderLinearTokens( tge.value,
        [add.address, `${process.env.FACTORY_SM_AD}`, `${process.env.FOUNDER_COIN_AD}`],
        `${process.env.FOUNDER_BYTES32}`, 200, amt.value, inv_1.address, 1659635620, 1659635620, 1, 1);
    })

    it("* test case 2: depositFounderLinearTokensToInvestors", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        // [[inv_1.address,amt_1.value,amt_1Tge.value],[inv_2.address,amt_2.value,amt_2Tge.value]]
        const setup = await contract.connect(add).depositFounderLinearTokensToInvestors(
            [add.address,`${process.env.FACTORY_SM_AD}`,`${process.env.FOUNDER_COIN_AD}`],
            `${process.env.FOUNDER_BYTES32}`,200,1659635620,1659635620,1,
            [[inv_1.address,1000,100],[inv_2.address,2000,200]],
            1
        )
    })

    it("* test case 3: withdrawTGEFund", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const setup = await contract.connect(inv_1).withdrawTGEFund(inv_1.address,
            add.address,200,`${process.env.FOUNDER_BYTES32}`)
    })

    it("* test case 4: withdrawInstallmentAmount", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const setup = await contract.connect(inv_1).withdrawInstallmentAmount(inv_1.address,
            add.address,200,1,`${process.env.FOUNDER_BYTES32}`)
    })

    it("* test case 5: withdrawBatch", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        const setup = await contract.connect(inv_1).withdrawBatch(add.address,
            inv_1.address,200,`${process.env.FOUNDER_BYTES32}`)
    })

    it("* test case 6: depositFounderNonLinearTokens", async function(){
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        let amt = { value: ethers.utils.parseEther("1000") }
        let tge = { value: ethers.utils.parseEther("100") }
        const setup = await contract.connect(add).depositFounderNonLinearTokens(add.address,
            `${process.env.FOUNDER_COIN_AD}`, `${process.env.FACTORY_SM_AD}`, `${process.env.FOUNDER_BYTES32}`,
            200,amt.value, inv_1.address,1659635620,tge.value)
    })

    it("* test case 7: setNonLinearInstallments", async function(){
        // [[1659635620,100],[1659635620,200],[1659635620,400]]
        const [add,inv_1,inv_2,val1,val2,val3,val4] = await ethers.getSigners();
        let amt = { value: ethers.utils.parseEther("1000") }
        let tge = { value: ethers.utils.parseEther("100") }
        const setup = await contract.connect(add).setNonLinearInstallments(add.address,
            `${process.env.FACTORY_SM_AD}`,200,inv_1.address,[[1659635620,100],[1659635620,200],[1659635620,400]])
    })
})
