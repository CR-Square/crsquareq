const {ethers, upgrades} = require("hardhat");

//contract deployment:

async function setup(){
    console.log("This setup deploys two contracts please check the wallet address");
    const baseC = await ethers.getContractFactory("ProjectAndProposal");
    const deployC = await upgrades.deployProxy(baseC);
    await deployC.deployed();
    console.log("The contract has been deployed and this is proxy contract address ",deployC.address);
}

setup().catch((err)=>{
    console.log("The contract has failed to deploy", err);
})