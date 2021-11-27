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
  let rest;

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

    [owner, addr1, addr2, ...rest] = await ethers.getSigners();
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
});
