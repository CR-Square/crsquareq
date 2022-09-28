require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require("@openzeppelin/hardhat-upgrades");
// require("hardhat-contract-sizer");
require("dotenv").config();

const {FOUNDER_PVT_KEY,INVESTOR2_PVT_KEY,V1_PVT_KEY,V2_PVT_KEY,V3_PVT_KEY,
  V4_PVT_KEY,ES_API,ES_API_POLYSCAN,INVESTOR1_PVT_KEY,P_MAINNET,P_MUMBAI,GOERLI} = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks:{
    polygon_mainnet: {
      url:P_MAINNET,  
      accounts: [FOUNDER_PVT_KEY,INVESTOR1_PVT_KEY,INVESTOR2_PVT_KEY,V1_PVT_KEY,V2_PVT_KEY,V3_PVT_KEY,
        V4_PVT_KEY]
    },
    polygon_mumbai: {
      url:P_MUMBAI,   
      accounts: [FOUNDER_PVT_KEY,INVESTOR1_PVT_KEY,INVESTOR2_PVT_KEY,V1_PVT_KEY,V2_PVT_KEY,V3_PVT_KEY,
        V4_PVT_KEY],
      gas: 2100000,
      gasPrice: 8000000000
    },
    goerli: {
      url:GOERLI,  
      accounts: [FOUNDER_PVT_KEY,INVESTOR1_PVT_KEY,INVESTOR2_PVT_KEY,V1_PVT_KEY,V2_PVT_KEY,V3_PVT_KEY,
        V4_PVT_KEY],
      gas: 2100000,
      gasPrice: 8000000000
    }
  },
  etherscan : {
    apiKey : {
      goerli:ES_API
    }
  },
  mocha: {
    timeout: 160000
  }
};