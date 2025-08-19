const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Loyalty Contract", function () {
  let Loyalty;
  let loyalty;
  let owner;
  let user1;
  let user2;
  let user3;

  beforeEach(async function () {
    // Get signers
    [owner, user1, user2, user3] = await ethers.getSigners();

    // Deploy contract
    Loyalty = await ethers.getContractFactory("Loyalty");
    loyalty = await Loyalty.deploy();
    await loyalty.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await loyalty.owner()).to.equal(owner.address);
    });

    it("Should start with 0 points for all users", async function () {
      expect(await loyalty.checkPoints(user1.address)).to.equal(0);
      expect(await loyalty.checkPoints(user2.address)).to.equal(0);
      expect(await loyalty.checkPoints(user3.address)).to.equal(0);
    });
  });

  describe("Award Points", function () {
    it("Should allow owner to award points", async function () {
      await loyalty.awardPoints(user1.address, 100);
      expect(await loyalty.checkPoints(user1.address)).to.equal(100);
    });

    it("Should accumulate points correctly", async function () {
      await loyalty.awardPoints(user1.address, 50);
      await loyalty.awardPoints(user1.address, 75);
      expect(await loyalty.checkPoints(user1.address)).to.equal(125);
    });

    it("Should emit PointsAwarded event", async function () {
      await expect(loyalty.awardPoints(user1.address, 100))
        .to.emit(loyalty, "PointsAwarded")
        .withArgs(user1.address, 100);
    });

    it("Should not allow non-owner to award points", async function () {
      await expect(
        loyalty.connect(user1).awardPoints(user2.address, 100)
      ).to.be.revertedWith("Not owner");
    });

    it("Should allow awarding 0 points", async function () {
      await loyalty.awardPoints(user1.address, 0);
      expect(await loyalty.checkPoints(user1.address)).to.equal(0);
    });
  });

  describe("Check Points", function () {
    it("Should return correct points for user", async function () {
      await loyalty.awardPoints(user1.address, 150);
      expect(await loyalty.checkPoints(user1.address)).to.equal(150);
    });

    it("Should return 0 for user with no points", async function () {
      expect(await loyalty.checkPoints(user1.address)).to.equal(0);
    });

    it("Should allow anyone to check points", async function () {
      await loyalty.awardPoints(user1.address, 200);
      expect(await loyalty.connect(user2).checkPoints(user1.address)).to.equal(200);
    });
  });

  describe("Redeem Points", function () {
    beforeEach(async function () {
      await loyalty.awardPoints(user1.address, 100);
    });

    it("Should allow user to redeem their points", async function () {
      await loyalty.connect(user1).redeemPoints();
      expect(await loyalty.checkPoints(user1.address)).to.equal(0);
    });

    it("Should return barcode when redeeming points", async function () {
      const tx = await loyalty.connect(user1).redeemPoints();
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      expect(event).to.not.be.undefined;
      expect(event.args[2]).to.be.a("string");
      expect(event.args[2]).to.include("BAR-");
    });

    it("Should emit PointsRedeemed event", async function () {
      await expect(loyalty.connect(user1).redeemPoints())
        .to.emit(loyalty, "PointsRedeemed");
    });

    it("Should not allow redeeming 0 points", async function () {
      await expect(
        loyalty.connect(user2).redeemPoints()
      ).to.be.revertedWith("No points to redeem");
    });

    it("Should reset points to 0 after redemption", async function () {
      await loyalty.connect(user1).redeemPoints();
      expect(await loyalty.checkPoints(user1.address)).to.equal(0);
    });
  });

  describe("Barcode Generation", function () {
    it("Should generate barcode with correct format", async function () {
      await loyalty.awardPoints(user1.address, 500);
      const tx = await loyalty.connect(user1).redeemPoints();
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode = event.args[2];
      
      // Check format: BAR-{address}-{amount}
      expect(barcode).to.match(/^BAR-[0-9a-f]{40}-\d+$/);
      expect(barcode).to.include("500");
    });

    it("Should generate unique barcodes for different users", async function () {
      await loyalty.awardPoints(user1.address, 100);
      await loyalty.awardPoints(user2.address, 100);
      
      const barcode1 = await loyalty.connect(user1).redeemPoints();
      const barcode2 = await loyalty.connect(user2).redeemPoints();
      
      expect(barcode1).to.not.equal(barcode2);
    });

    it("Should handle large point amounts", async function () {
      await loyalty.awardPoints(user1.address, 999999);
      const tx = await loyalty.connect(user1).redeemPoints();
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode = event.args[2];
      expect(barcode).to.include("999999");
    });
  });

  describe("Edge Cases", function () {
    it("Should handle multiple award and redeem cycles", async function () {
      // First cycle
      await loyalty.awardPoints(user1.address, 100);
      await loyalty.connect(user1).redeemPoints();
      expect(await loyalty.checkPoints(user1.address)).to.equal(0);

      // Second cycle
      await loyalty.awardPoints(user1.address, 200);
      await loyalty.connect(user1).redeemPoints();
      expect(await loyalty.checkPoints(user1.address)).to.equal(0);
    });

    it("Should handle multiple users independently", async function () {
      await loyalty.awardPoints(user1.address, 100);
      await loyalty.awardPoints(user2.address, 200);
      
      expect(await loyalty.checkPoints(user1.address)).to.equal(100);
      expect(await loyalty.checkPoints(user2.address)).to.equal(200);
      
      await loyalty.connect(user1).redeemPoints();
      expect(await loyalty.checkPoints(user1.address)).to.equal(0);
      expect(await loyalty.checkPoints(user2.address)).to.equal(200);
    });

    it("Should handle very large point amounts", async function () {
      const largeAmount = ethers.parseEther("1000000"); // 1 million ETH worth of points
      await loyalty.awardPoints(user1.address, largeAmount);
      expect(await loyalty.checkPoints(user1.address)).to.equal(largeAmount);
      
      const tx = await loyalty.connect(user1).redeemPoints();
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode = event.args[2];
      expect(barcode).to.include(largeAmount.toString());
    });
  });
}); 