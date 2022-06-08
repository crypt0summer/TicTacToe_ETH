const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TicTacToe", function () {
  let account1, account2;
  let TicTacToe, ttt;
  let gameId;

  beforeEach(async () => {
    [account1, account2] = await ethers.getSigners();
    TicTacToe = await ethers.getContractFactory("TicTacToe");
    ttt = await TicTacToe.deploy();
    await ttt.deployed();

    let transaction = await ttt
      .connect(account1)
      .createGame({ value: ethers.utils.parseEther("0.1") });

    const receipt = await transaction.wait();
    for (const event of receipt.events) {
      // console.log(`Event ${event.event} with args ${event.args}`);
      if (event.event == "LogGameId") {
        gameId = event.args.gameId;
      }
    }
  });

  describe("Success Plan", function () {
    it("Create and Start game", async function () {
      let tx = await ttt.connect(account2).joinAndStartGame(gameId, {value:ethers.utils.parseEther("0.1") });
      expect(tx).to.not.be.undefined;
      
    });
    // it("Should User 1 Win", async function () {
    //   expect(1).to.equal(1);
    // });
    // it("Should User 2 Win", async function () {
    //   expect(1).to.equal(1);
    // });
    // it("Should draw and restart the game", async function () {
    //   expect(1).to.equal(1);
    // });
  });

  describe("Error Plan", function () {
    it("Should fail - player 1 & 2 ETH didn't match", async function () {
      await expect(
        ttt.connect(account2).joinAndStartGame(gameId)
      ).to.be.revertedWith("Invalid ETH");
    });

    // it("Should fail - tried playing twice", async function () {
    //   expect(1).to.equal(1);
    // });

    // it("Should fail - tried taken spot", async function () {
    //   expect(1).to.equal(1);
    // });
  });
});
