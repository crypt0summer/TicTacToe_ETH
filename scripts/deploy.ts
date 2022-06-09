// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
import { ethers } from "hardhat";

async function main() {
  const [owner] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account balance:", (await owner.getBalance()).toString());

  // Deploy Vault
  const VaultContract = await hre.ethers.getContractFactory("VaultContract");
  const vault = await VaultContract.deploy();
  await vault.deployed();

  console.log("VaultContract deployed to:", vault.address);

  //Deploy TicTacToe
  const TicTacToe = await hre.ethers.getContractFactory("TicTacToe");
  const ttt = await TicTacToe.deploy();
  await ttt.deployed();
  console.log("TicTacToe deployed to:", ttt.address);

  //Setup
  await ttt.connect(owner).setVault(vault.address);
  await vault.setNewOwner(ttt.address);
  console.log("Set new owner to:", await vault.owner());

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
