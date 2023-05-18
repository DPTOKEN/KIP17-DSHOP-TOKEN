import * as dotenv from "dotenv";
import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    dev: {
      url: "http://localhost:8545",
      accounts: [
        "0x78cc9813aa135f44dcba76b1a751271591640473cf039a0efb60d27491dab144",
        "0x84fa91cc7df9476856ae603edc3e84e3b57782f9eea37c6e2400a0c4124f8005",
        "0xa4da287dc643a1f5732137fc5900ffe2edf09a37b3c5d281f3610a2b2c7019a1",
        "0xc04aac3b8bf75548e52bd437546524649da52dc9ec0897041fa3f07630ad87d0",
        "0x0608b4d7bc929e4a4f444764ca904b1942df2b198f7604f88e57697e5e76baa7",
        "0xbfc2e7155d0b287081992e0b41bda7560e901920d8f72cd39446364bd9ed0bcf",
        "0xfbf0fef2691d3b822daf11e2190fa506cd4eba929dcc904af39eb54b30bff59e",
        "0x5381c52fe5a80b2bdfc831bb129ed211b131c4ec4f488756f62c64704b082ca0",
        "0xe317b2db45f3c334c969345c25032a9ef50b04b42f87b8c53e255cd7cba01d7f",
        "0xfe3ad5e53cfca3d36bbd11984c25f5db8a118252735ad59370f13322271f0011",
      ],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
