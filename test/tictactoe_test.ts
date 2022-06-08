import { BigNumber, Contract, Signer } from "ethers";

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe.skip("TicTacToe", function () {
  let account1: Signer;
  let account2: Signer;
  let account3: Signer;
  let ttt: Contract;
  let gameId: BigNumber;

  enum GameState {
    READY,
    PLAYING,
    FINISHED,
  }
  beforeEach(async () => {
    [account1, account2, account3] = await ethers.getSigners();
    const TicTacToe = await ethers.getContractFactory("TicTacToe");
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

    it("Should User 1 Win - row", async function () {
      let tx = await ttt
        .connect(account2)
        .joinAndStartGame(gameId, { value: ethers.utils.parseEther("0.1") });
      expect(tx).to.not.be.undefined;

      await ttt.connect(account1).takeTurn(gameId, 1, 1);
      await ttt.connect(account2).takeTurn(gameId, 2, 2);

      await ttt.connect(account1).takeTurn(gameId, 1, 2);
      await ttt.connect(account2).takeTurn(gameId, 2, 3);

      await ttt.connect(account1).takeTurn(gameId, 1, 3);

      const gameInfo = await ttt.getGameInfo(gameId);
      expect(gameInfo.winner).to.equal(await account1.getAddress());
      expect(gameInfo.status).to.equal(GameState.FINISHED);
    });

    it("Should User 2 Win - column", async function () {
      let tx = await ttt
        .connect(account2)
        .joinAndStartGame(gameId, { value: ethers.utils.parseEther("0.1") });
      expect(tx).to.not.be.undefined;

      await ttt.connect(account2).takeTurn(gameId, 1, 1);
      await ttt.connect(account1).takeTurn(gameId, 2, 2);

      await ttt.connect(account2).takeTurn(gameId, 2, 1);
      await ttt.connect(account1).takeTurn(gameId, 3, 3);

      await ttt.connect(account2).takeTurn(gameId, 3, 1);

      const gameInfo = await ttt.getGameInfo(gameId);
      expect(gameInfo.winner).to.equal(await account2.getAddress());
      expect(gameInfo.status).to.equal(GameState.FINISHED);
    });

    it("Should draw and restart the game", async function () {
      let tx = await ttt
        .connect(account2)
        .joinAndStartGame(gameId, { value: ethers.utils.parseEther("0.1") });
      expect(tx).to.not.be.undefined;

      await ttt.connect(account2).takeTurn(gameId, 3, 2);
      await ttt.connect(account1).takeTurn(gameId, 3, 1);

      await ttt.connect(account2).takeTurn(gameId, 2, 2);
      await ttt.connect(account1).takeTurn(gameId, 1, 2);

      await ttt.connect(account2).takeTurn(gameId, 2, 1);
      await ttt.connect(account1).takeTurn(gameId, 2, 3);

      await ttt.connect(account2).takeTurn(gameId, 1, 3);
      await ttt.connect(account1).takeTurn(gameId, 3, 3);

      await ttt.connect(account2).takeTurn(gameId, 1, 1);

      const gameInfo = await ttt.getGameInfo(gameId);
      //Check reset
      expect(gameInfo.status).to.equal(GameState.PLAYING);
      expect(gameInfo.turnsTaken).to.equal(0);
      expect(gameInfo.winner).to.equal("0x0000000000000000000000000000000000000000");

      await ttt.connect(account1).takeTurn(gameId, 3, 2);

    });
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
      await ttt
        .connect(account2)
        .joinAndStartGame(gameId, { value: ethers.utils.parseEther("0.1") });
      await expect(
        ttt.connect(account3).takeTurn(gameId, 1, 2)
      ).to.be.revertedWith("Not a valid player");
    });

    it("Should fail - tried playing twice", async function () {
      await ttt
        .connect(account2)
        .joinAndStartGame(gameId, { value: ethers.utils.parseEther("0.1") });
      await ttt.connect(account2).takeTurn(gameId, 1, 1);
      await expect(
        ttt.connect(account2).takeTurn(gameId, 1, 2)
      ).to.be.revertedWith("Not your turn");
    });

    it("Should fail - tried wrong spot range", async function () {
      await ttt
        .connect(account2)
        .joinAndStartGame(gameId, { value: ethers.utils.parseEther("0.1") });
      await expect(
        ttt.connect(account2).takeTurn(gameId, 0, 0)
      ).to.be.revertedWith("Wrong position");
      await expect(
        ttt.connect(account2).takeTurn(gameId, 1, 4)
      ).to.be.revertedWith("Wrong position");
      await expect(
        ttt.connect(account2).takeTurn(gameId, 4, 2)
      ).to.be.revertedWith("Wrong position");
    });

    it("Should fail - tried to get spot already taken", async function () {
      await ttt
        .connect(account2)
        .joinAndStartGame(gameId, { value: ethers.utils.parseEther("0.1") });
      await ttt.connect(account2).takeTurn(gameId, 1, 1);
      await expect(
        ttt.connect(account1).takeTurn(gameId, 1, 1)
      ).to.be.revertedWith("Already taken");
    });
  });
});


describe("Vault Plan", function () {
  let account1: Signer; 
  let account2: Signer;
  let vault : Contract;

  beforeEach(async function () {
    [account1, account2] = await ethers.getSigners();
    const VaultContract = await ethers.getContractFactory("VaultContract");
    vault = await VaultContract.deploy();
    await vault.deployed();
  });


  describe("Success Plan", function () {
    it("Should create a vault, put money in it", async function () {
      const gameId = 0;
      const value = "0.1"

      await vault
        .connect(account1)
        .createVault(gameId, { value: ethers.utils.parseEther(value) });
      const vaultInfo = await vault.connect(account1).getVault(0);

      expect(vaultInfo.totalAmount).to.equal(
        ethers.utils.parseEther(value)
      );

      await vault
        .connect(account1)
        .addAmount(gameId, { value: ethers.utils.parseEther(value) });
      
      const vaultInfo2 = await vault.connect(account1).getVault(0);
      expect(vaultInfo2.totalAmount).to.equal(
        ethers.utils.parseEther("0.2")
      );

    });

    // it("Should Withdraw prize", async function () {
    // });
  });

  describe("Failure Plan", function () {
    it("Should fail createing a vault because not an owner", async function () {
      const gameId = 0;
      const value = "0.1"

      await expect(
        vault.connect(account2).createVault(gameId, { value: ethers.utils.parseEther(value) })
      ).to.be.revertedWith("Ownable: caller is not the owner");

    });

    it("Should fail money deposit because not an owner", async function () {
      const gameId = 0;
      const value = "0.1"

      await expect(
        vault.connect(account2).addAmount(gameId, { value: ethers.utils.parseEther(value) })
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    // it("Should fail money witdraw because not an owner", async function () {
    // });
  });


});