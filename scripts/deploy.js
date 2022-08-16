const hre = require("hardhat");

let contract_1;
let contract_2;
// let contract_3;
let contract_4;

async function deployFactory(){
    const setup_1 = await hre.ethers.getContractFactory("contracts/Factory.sol:Factory");
    const deployC_1 = await setup_1.deploy();
    contract_1 = await deployC_1.deployed();
    console.log("Factory contract address -->", deployC_1.address);
}

async function deployFounder(){
    const setup_2 = await hre.ethers.getContractFactory("contracts/Founder.sol:Founder");
    const deployC_2 = await setup_2.deploy();
    contract_2 = await deployC_2.deployed();
    console.log("Founder contract address -->", deployC_2.address);
}

// async function deployProjectAndProposal(){
//     const setup_3 = await hre.ethers.getContractFactory("contracts/ProjectAndProposal.sol:ProjectAndProposal");
//     const deployC_3 = await setup_3.deploy();
//     contract_3 = await deployC_3.deployed();
//     console.log("ProjectAndProposal contract address -->", deployC_3.address);
// }

async function deployVesting(){
    const setup_4 = await hre.ethers.getContractFactory("contracts/Vesting.sol:Vesting");
    const deployC_4 = await setup_4.deploy();
    contract_4 = await deployC_4.deployed();
    console.log("Vesting contract address -->", deployC_4.address);
}

async function batchCall(){
    await deployFactory().catch((err) =>{
        console.log(err);
    })
    
    await deployFounder().catch((err) =>{
        console.log(err);
    })
    
    // await deployProjectAndProposal().catch((err) =>{
    //     console.log(err);
    // })
    
    await deployVesting().catch((err) =>{
        console.log(err);
    })
}

batchCall()

