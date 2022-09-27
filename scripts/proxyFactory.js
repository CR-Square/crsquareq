const {ethers, upgrades} = require("hardhat");

async function setup(){
    console.log("This setup deploys two contracts please check the deployed wallet address");
    const baseC = await ethers.getContractFactory("contracts/Factory.sol:Factory");
    const deployC = await upgrades.deployProxy(baseC);
    await deployC.deployed();
    console.log("The Factory contract has been deployed and this is proxy contract address",deployC.address);
}

setup().catch((err)=>{
    console.log("The contract has failed to deploy", err);
})