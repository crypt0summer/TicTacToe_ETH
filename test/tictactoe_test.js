const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TicTacToe", function () {
  let account1, account2, account3;
  let TicTacToe, ttt;
  let gameId;

  beforeEach(async () => {
    [account1, account2, account3] = await ethers.getSigners();
    TicTacToe = await ethers.getContractFactory("TicTacToe");
    ttt = await TicTacToe.deploy();
    await ttt.deployed();

    let transaction = await ttt
      .connect(account1)
      .createGame({ value: ethers.utils.parseEther("0.1") });

    const receipt = await transaction.wait();
    for (const event of receipt.events) {
      // console.log(`Event ${event.event} with args ${event.args}`);

      gameId = event.args.gameId;
    }
  });

  describe("Success Plan", function () {
    it("Create and Start game", async function () {
      let tx = await ttt
        .connect(account2)
        .joinAndStartGame(gameId, { value: ethers.utils.parseEther("0.1") });
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

    it("Should fail - tried to play game that wasn't started", async function () {
      await expect(
        ttt.connect(account2).takeTurn(gameId, 1, 1)
      ).to.be.revertedWith("Game is not playing");
    });

    it("Should fail - non player tried to play", async function () {
      await ttt.connect(account2).joinAndStartGame(gameId, {value:ethers.utils.parseEther("0.1") });
      await expect(
        ttt.connect(account3).takeTurn( gameId, 1, 2)
      ).to.be.revertedWith("Not a valid player");
    });

    it("Should fail - tried playing twice", async function () {
      await ttt.connect(account2).joinAndStartGame(gameId, {value:ethers.utils.parseEther("0.1") });
      await ttt.connect(account2).takeTurn(gameId, 1, 1);
      await expect(
        ttt.connect(account2).takeTurn( gameId, 1, 2)
      ).to.be.revertedWith("Not your turn");
    });

    it("Should fail - tried wrong spot range", async function () {
      await ttt.connect(account2).joinAndStartGame(gameId, {value:ethers.utils.parseEther("0.1") });
      await expect(
        ttt.connect(account2).takeTurn( gameId, 0, 0)
      ).to.be.revertedWith("Wrong position");
      await expect(
        ttt.connect(account2).takeTurn( gameId, 1, 4)
      ).to.be.revertedWith("Wrong position");
      await expect(
        ttt.connect(account2).takeTurn( gameId, 4, 2)
      ).to.be.revertedWith("Wrong position");
    });

    it("Should fail - tried to get spot already taken", async function () {
      await ttt.connect(account2).joinAndStartGame(gameId, {value:ethers.utils.parseEther("0.1") });
      await ttt.connect(account2).takeTurn(gameId, 1, 1);
      await expect(
        ttt.connect(account1).takeTurn( gameId, 1, 1)
      ).to.be.revertedWith("Already taken");
    });
  });
});