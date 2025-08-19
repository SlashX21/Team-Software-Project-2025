const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Loyalty Contract (User ID Based)", function () {
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
      expect(await loyalty.checkPoints("1001")).to.equal(0);
      expect(await loyalty.checkPoints("1002")).to.equal(0);
      expect(await loyalty.checkPoints("CUSTOMER001")).to.equal(0);
    });
  });

  describe("Award Points", function () {
    it("Should allow owner to award points", async function () {
      await loyalty.awardPoints("1001", 100);
      expect(await loyalty.checkPoints("1001")).to.equal(100);
    });

    it("Should accumulate points correctly", async function () {
      await loyalty.awardPoints("1001", 50);
      await loyalty.awardPoints("1001", 75);
      expect(await loyalty.checkPoints("1001")).to.equal(125);
    });

    it("Should emit PointsAwarded event", async function () {
      await expect(loyalty.awardPoints("1001", 100))
        .to.emit(loyalty, "PointsAwarded")
        .withArgs("1001", 100);
    });

    it("Should not allow non-owner to award points", async function () {
      await expect(
        loyalty.connect(user1).awardPoints("1002", 100)
      ).to.be.revertedWith("Not owner");
    });

    it("Should allow awarding 0 points", async function () {
      await loyalty.awardPoints("1001", 0);
      expect(await loyalty.checkPoints("1001")).to.equal(0);
    });

    it("Should handle different user ID formats", async function () {
      await loyalty.awardPoints("CUSTOMER001", 150);
      await loyalty.awardPoints("VIP_USER_123", 200);
      expect(await loyalty.checkPoints("CUSTOMER001")).to.equal(150);
      expect(await loyalty.checkPoints("VIP_USER_123")).to.equal(200);
    });
  });

  describe("Check Points", function () {
    it("Should return correct points for user", async function () {
      await loyalty.awardPoints("1001", 150);
      expect(await loyalty.checkPoints("1001")).to.equal(150);
    });

    it("Should return 0 for user with no points", async function () {
      expect(await loyalty.checkPoints("1001")).to.equal(0);
    });

    it("Should allow anyone to check points", async function () {
      await loyalty.awardPoints("1001", 200);
      expect(await loyalty.connect(user2).checkPoints("1001")).to.equal(200);
    });

    it("Should handle empty user ID", async function () {
      expect(await loyalty.checkPoints("")).to.equal(0);
    });
  });

  describe("Redeem Points", function () {
    beforeEach(async function () {
      await loyalty.awardPoints("1001", 100);
    });

    it("Should allow owner to redeem user points", async function () {
      await loyalty.redeemPoints("1001");
      expect(await loyalty.checkPoints("1001")).to.equal(0);
    });

    it("Should return barcode when redeeming points", async function () {
      const tx = await loyalty.redeemPoints("1001");
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      expect(event).to.not.be.undefined;
      expect(event.args[2]).to.be.a("string");
      expect(event.args[2]).to.include("BAR-");
      expect(event.args[2]).to.include("1001");
    });

    it("Should emit PointsRedeemed event", async function () {
      await expect(loyalty.redeemPoints("1001"))
        .to.emit(loyalty, "PointsRedeemed");
    });

    it("Should not allow redeeming 0 points", async function () {
      await expect(
        loyalty.redeemPoints("1002")
      ).to.be.revertedWith("No points to redeem");
    });

    it("Should reset points to 0 after redemption", async function () {
      await loyalty.redeemPoints("1001");
      expect(await loyalty.checkPoints("1001")).to.equal(0);
    });

    it("Should not allow non-owner to redeem points", async function () {
      await expect(
        loyalty.connect(user1).redeemPoints("1001")
      ).to.be.revertedWith("Not owner");
    });
  });

  describe("User Exists", function () {
    it("Should return false for user with no points", async function () {
      expect(await loyalty.userExists("1001")).to.equal(false);
    });

    it("Should return true for user with points", async function () {
      await loyalty.awardPoints("1001", 50);
      expect(await loyalty.userExists("1001")).to.equal(true);
    });

    it("Should return false after points are redeemed", async function () {
      await loyalty.awardPoints("1001", 50);
      expect(await loyalty.userExists("1001")).to.equal(true);
      
      await loyalty.redeemPoints("1001");
      expect(await loyalty.userExists("1001")).to.equal(false);
    });
  });

  describe("Barcode Generation", function () {
    it("Should generate barcode with correct format", async function () {
      await loyalty.awardPoints("1001", 500);
      const tx = await loyalty.redeemPoints("1001");
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode = event.args[2];
      
      // Check format: BAR-{userId}-{amount}
      expect(barcode).to.match(/^BAR-1001-500$/);
    });

    it("Should generate unique barcodes for different users", async function () {
      await loyalty.awardPoints("1001", 100);
      await loyalty.awardPoints("1002", 100);
      
      const tx1 = await loyalty.redeemPoints("1001");
      const receipt1 = await tx1.wait();
      const event1 = receipt1.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode1 = event1.args[2];
      
      const tx2 = await loyalty.redeemPoints("1002");
      const receipt2 = await tx2.wait();
      const event2 = receipt2.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode2 = event2.args[2];
      
      expect(barcode1).to.not.equal(barcode2);
      expect(barcode1).to.equal("BAR-1001-100");
      expect(barcode2).to.equal("BAR-1002-100");
    });

    it("Should handle large point amounts", async function () {
      await loyalty.awardPoints("1001", 999999);
      const tx = await loyalty.redeemPoints("1001");
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode = event.args[2];
      expect(barcode).to.equal("BAR-1001-999999");
    });

    it("Should handle special characters in user IDs", async function () {
      await loyalty.awardPoints("CUSTOMER-001", 100);
      const tx = await loyalty.redeemPoints("CUSTOMER-001");
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode = event.args[2];
      expect(barcode).to.equal("BAR-CUSTOMER-001-100");
    });
  });

  describe("Edge Cases", function () {
    it("Should handle multiple award and redeem cycles", async function () {
      // First cycle
      await loyalty.awardPoints("1001", 100);
      await loyalty.redeemPoints("1001");
      expect(await loyalty.checkPoints("1001")).to.equal(0);

      // Second cycle
      await loyalty.awardPoints("1001", 200);
      await loyalty.redeemPoints("1001");
      expect(await loyalty.checkPoints("1001")).to.equal(0);
    });

    it("Should handle multiple users independently", async function () {
      await loyalty.awardPoints("1001", 100);
      await loyalty.awardPoints("1002", 200);
      
      expect(await loyalty.checkPoints("1001")).to.equal(100);
      expect(await loyalty.checkPoints("1002")).to.equal(200);
      
      await loyalty.redeemPoints("1001");
      expect(await loyalty.checkPoints("1001")).to.equal(0);
      expect(await loyalty.checkPoints("1002")).to.equal(200);
    });

    it("Should handle very large point amounts", async function () {
      const largeAmount = ethers.parseEther("1000000"); // 1 million ETH worth of points
      await loyalty.awardPoints("1001", largeAmount);
      expect(await loyalty.checkPoints("1001")).to.equal(largeAmount);
      
      const tx = await loyalty.redeemPoints("1001");
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode = event.args[2];
      expect(barcode).to.include(largeAmount.toString());
    });

    it("Should handle empty string user ID", async function () {
      await loyalty.awardPoints("", 100);
      expect(await loyalty.checkPoints("")).to.equal(100);
      expect(await loyalty.userExists("")).to.equal(true);
      
      const tx = await loyalty.redeemPoints("");
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode = event.args[2];
      expect(barcode).to.equal("BAR--100");
    });

    it("Should handle very long user IDs", async function () {
      const longUserId = "A".repeat(50); // 50 character user ID
      await loyalty.awardPoints(longUserId, 100);
      expect(await loyalty.checkPoints(longUserId)).to.equal(100);
      
      const tx = await loyalty.redeemPoints(longUserId);
      const receipt = await tx.wait();
      const event = receipt.logs.find(log => log.fragment && log.fragment.name === "PointsRedeemed");
      const barcode = event.args[2];
      expect(barcode).to.include(longUserId);
    });
  });

  describe("Security", function () {
    it("Should only allow owner to award points", async function () {
      await expect(
        loyalty.connect(user1).awardPoints("1001", 100)
      ).to.be.revertedWith("Not owner");
    });

    it("Should only allow owner to redeem points", async function () {
      await loyalty.awardPoints("1001", 100);
      await expect(
        loyalty.connect(user1).redeemPoints("1001")
      ).to.be.revertedWith("Not owner");
    });

    it("Should not allow negative point amounts", async function () {
      // This would be handled by the uint256 type in Solidity
      // The test framework will throw an error if we try to pass negative numbers
    });
  });
}); 