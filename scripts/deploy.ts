import { ethers } from "hardhat";

async function main() {
  const ERC721 = await ethers.getContractFactory("DSHOP");
  const erc721 = await ERC721.deploy("DSHOP", "DP", "10000");

  await erc721.deployed();

  console.log(`DSHOP NFT deployed to ${erc721.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
