const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("My vendor", function () {
  let owner;
  let addr1;

  let yourTokenContract;
  let vendorContract;

  beforeEach(async () => {
    const YourTokenContractFactory = await ethers.getContractFactory(
      "YourToken"
    );
    yourTokenContract = await YourTokenContractFactory.deploy();

    const VendorContractFactory = await ethers.getContractFactory("Vendor");
    vendorContract = await VendorContractFactory.deploy(
      yourTokenContract.address
    );

    [owner, addr1] = await ethers.getSigners();

    await vendorContract.transferOwnership(owner.address);

    await yourTokenContract.transfer(
      vendorContract.address,
      await ethers.utils.parseEther("1000")
    );
  });

  describe("Test withdraw method", function () {
    it("Non-owner shouldn't be able to withdraw", async function () {
      await expect(vendorContract.connect(addr1).withdraw()).to.be.revertedWith(
        "Ownable: caller is not the owner"
      );
    });

    it("Owner should be able to withdraw", async () => {
      await vendorContract
        .connect(addr1)
        .buyTokens({ value: await ethers.utils.parseEther("1") });

      await vendorContract.connect(owner).withdraw();
    });
  });

  describe("Test sellTokens method", () => {
    it("Shouldn't be able to sell more tokens than possessed", async () => {
      await vendorContract
        .connect(addr1)
        .buyTokens({ value: await ethers.utils.parseEther("1") });

      await expect(
        vendorContract
          .connect(addr1)
          .sellTokens(await ethers.utils.parseEther("101"))
      ).to.be.revertedWith("User doesn't have enough tokens to sell");
    });

    it("Should be able to sell tokens before seller approves", async () => {
      await vendorContract
        .connect(addr1)
        .buyTokens({ value: await ethers.utils.parseEther("1") });

      await expect(
        vendorContract
          .connect(addr1)
          .sellTokens(await ethers.utils.parseEther("100"))
      ).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
    });

    it("Successful sellTokens", async () => {
      // Buy 1 ETH of tokens
      await vendorContract
        .connect(addr1)
        .buyTokens({ value: await ethers.utils.parseEther("1") });

      // Approve selling 1 ETH of tokens
      const tokensToSell = await ethers.utils.parseEther("100");
      await yourTokenContract
        .connect(addr1)
        .approve(vendorContract.address, tokensToSell);

      // Sell 1 ETH of tokens
      await vendorContract.connect(addr1).sellTokens(tokensToSell);

      // Confirm vendor has 1000 tokens again
      expect(
        await yourTokenContract.balanceOf(vendorContract.address)
      ).to.equal(await ethers.utils.parseEther("1000"));

      // Confirm seller has 0 tokens
      expect(await yourTokenContract.balanceOf(addr1.address)).to.equal(0);
    });
  });
});
