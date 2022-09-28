const {ethers, upgrades} = require("hardhat");

// This contract can be used when there is an upgradation feature needs to be implemented for projectAndProposal
// contract.

const proxyContractAddress = "0x77C03dd34b49552A54c920a0276891F2C44533ed";

async function setup(){
    console.log("This setup deploys two contracts please check the wallet address");

    const baseC = await ethers.getContractFactory("ProjectAndProposalV1");
    await upgrades.upgradeProxy(proxyContractAddress,baseC);
}

setup().catch((err)=>{
    console.log("The contract has failed to deploy", err);
})