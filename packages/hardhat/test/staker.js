const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

const increaseWorldTimeInSeconds = async (seconds, mine = false) => {
  await ethers.provider.send("evm_increaseTime", [seconds]);
  if (mine) {
    await ethers.provider.send("evm_mine", []);
  }
};

describe("My staker", function () {
  let owner;
  let addr1;
  let addr2;

  let stakerContract;
  let exampleExternalContract;
  let ExampleExternalContractFactory;

  beforeEach(async () => {
    // Deploy ExampleExternalContract
    ExampleExternalContractFactory = await ethers.getContractFactory(
      "ExampleExternalContract"
    );
    exampleExternalContract = await ExampleExternalContractFactory.deploy();

    // Deploy StakerContract
    const StakerContractFactory = await ethers.getContractFactory("Staker");
    stakerContract = await StakerContractFactory.deploy(
      exampleExternalContract.address
    );

    [owner, addr1, addr2] = await ethers.getSigners();
  });

  describe("Test timeLeft method", () => {
    it("timeLeft returns 0 after deadline", async () => {
      await increaseWorldTimeInSeconds(180, true);

      const timeLeft = await stakerContract.timeLeft();
      expect(timeLeft).to.equal(0);
    });

    it("timeLeft returns correct timeleft after 10 seconds", async () => {
      const secondsElapsed = 10;
      const timeLeftBefore = await stakerContract.timeLeft();
      await increaseWorldTimeInSeconds(10, true);

      const timeLeftAfter = await stakerContract.timeLeft();
      expect(timeLeftAfter).to.equal(timeLeftBefore.sub(secondsElapsed));
    });
  });

  describe("Test stake method", () => {
    it("Stake event is emitted", async () => {
      const stakedAmount = await ethers.utils.parseEther("0.5");

      await expect(stakerContract.connect(addr1).stake({ value: stakedAmount }))
        .to.emit(stakerContract, "Stake")
        .withArgs(addr1.address, stakedAmount);

      // Check contract has correct balance after staking
      const contractBalance = await ethers.provider.getBalance(
        stakerContract.address
      );
      expect(contractBalance).to.equal(stakedAmount);

      // Check contract has stored our staked amount correctly in balances
      const addr1Balance = await stakerContract.balances(addr1.address);
      expect(addr1Balance).to.equal(stakedAmount);
    });

    it("Stake is reverted after deadline", async () => {
      const stakedAmount = await ethers.utils.parseEther("0.5");

      await increaseWorldTimeInSeconds(180, true);

      await expect(
        stakerContract.connect(addr1).stake({ value: stakedAmount })
      ).to.be.revertedWith("Time reached already");
    });

    it("Stake is reverted if already completed", async () => {
      const fullStake = await ethers.utils.parseEther("1");

      const stakeTx = await stakerContract
        .connect(addr1)
        .stake({ value: fullStake });
      await stakeTx.wait();

      const executeTx = await stakerContract.connect(addr1).execute();
      await executeTx.wait();

      await expect(
        stakerContract.connect(addr1).stake({ value: fullStake })
      ).to.be.revertedWith("Already staked");
    });
  });
});
