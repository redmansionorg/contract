const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RoyaltyManager", function () {
  let royaltyManager;
  let owner, author1, author2, author3;

  beforeEach(async function () {
    [owner, author1, author2, author3] = await ethers.getSigners();
    
    const RoyaltyManager = await ethers.getContractFactory("RoyaltyManager");
    royaltyManager = await RoyaltyManager.deploy();
    await royaltyManager.waitForDeployment();
  });

  describe("版税注册", function () {
    it("应该能够注册版税链", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const royaltyItems = [
        {
          receiver: author1.address,
          bps: 3000, // 30%
          sourceRuid: ethers.ZeroHash
        },
        {
          receiver: author2.address,
          bps: 2000, // 20%
          sourceRuid: ruid
        }
      ];

      await expect(royaltyManager.registerRoyaltyList(ruid, royaltyItems))
        .to.emit(royaltyManager, "RoyaltyRegistered")
        .withArgs(ruid, owner.address);

      expect(await royaltyManager.isRegistered(ruid)).to.be.true;
    });

    it("不应该允许重复注册", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const royaltyItems = [
        {
          receiver: author1.address,
          bps: 5000,
          sourceRuid: ethers.ZeroHash
        }
      ];

      await royaltyManager.registerRoyaltyList(ruid, royaltyItems);
      
      await expect(royaltyManager.registerRoyaltyList(ruid, royaltyItems))
        .to.be.revertedWithCustomError(royaltyManager, "AlreadyRegistered");
    });

    it("不应该允许空版税列表", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const royaltyItems = [];

      await expect(royaltyManager.registerRoyaltyList(ruid, royaltyItems))
        .to.be.revertedWithCustomError(royaltyManager, "EmptyRoyaltyList");
    });

    it("不应该允许版税总额超过100%", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const royaltyItems = [
        {
          receiver: author1.address,
          bps: 6000, // 60%
          sourceRuid: ethers.ZeroHash
        },
        {
          receiver: author2.address,
          bps: 5000, // 50%
          sourceRuid: ruid
        }
      ];

      await expect(royaltyManager.registerRoyaltyList(ruid, royaltyItems))
        .to.be.revertedWithCustomError(royaltyManager, "InvalidRoyaltyTotal");
    });
  });

  describe("版税查询", function () {
    let ruid, royaltyItems;

    beforeEach(async function () {
      ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      royaltyItems = [
        {
          receiver: author1.address,
          bps: 3000, // 30%
          sourceRuid: ethers.ZeroHash
        },
        {
          receiver: author2.address,
          bps: 2000, // 20%
          sourceRuid: ruid
        },
        {
          receiver: author3.address,
          bps: 1000, // 10%
          sourceRuid: ruid
        }
      ];

      await royaltyManager.registerRoyaltyList(ruid, royaltyItems);
    });

    it("应该能够获取版税列表", async function () {
      const royaltyList = await royaltyManager.getRoyaltyList(ruid);
      
      expect(royaltyList.length).to.equal(3);
      expect(royaltyList[0].receiver).to.equal(author1.address);
      expect(royaltyList[0].bps).to.equal(3000);
      expect(royaltyList[1].receiver).to.equal(author2.address);
      expect(royaltyList[1].bps).to.equal(2000);
      expect(royaltyList[2].receiver).to.equal(author3.address);
      expect(royaltyList[2].bps).to.equal(1000);
    });

    it("应该能够获取版税接收者", async function () {
      const [receivers, bps] = await royaltyManager.getRoyaltyReceivers(ruid);
      
      expect(receivers.length).to.equal(3);
      expect(receivers[0]).to.equal(author1.address);
      expect(receivers[1]).to.equal(author2.address);
      expect(receivers[2]).to.equal(author3.address);
      
      expect(bps.length).to.equal(3);
      expect(bps[0]).to.equal(3000);
      expect(bps[1]).to.equal(2000);
      expect(bps[2]).to.equal(1000);
    });

    it("应该正确计算版税总额", async function () {
      const salePrice = ethers.parseEther("1.0"); // 1 ETH
      const totalAmount = await royaltyManager.getTotalRoyaltyAmount(ruid, salePrice);
      
      // 30% + 20% + 10% = 60% of 1 ETH = 0.6 ETH
      expect(totalAmount).to.equal(ethers.parseEther("0.6"));
    });

    it("应该处理零销售价格", async function () {
      const totalAmount = await royaltyManager.getTotalRoyaltyAmount(ruid, 0);
      expect(totalAmount).to.equal(0);
    });
  });

  describe("边界情况", function () {
    it("应该允许100%版税", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const royaltyItems = [
        {
          receiver: author1.address,
          bps: 10000, // 100%
          sourceRuid: ethers.ZeroHash
        }
      ];

      await expect(royaltyManager.registerRoyaltyList(ruid, royaltyItems))
        .to.emit(royaltyManager, "RoyaltyRegistered");
    });

    it("应该允许单个接收者", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const royaltyItems = [
        {
          receiver: author1.address,
          bps: 5000, // 50%
          sourceRuid: ethers.ZeroHash
        }
      ];

      await royaltyManager.registerRoyaltyList(ruid, royaltyItems);
      
      const [receivers, bps] = await royaltyManager.getRoyaltyReceivers(ruid);
      expect(receivers.length).to.equal(1);
      expect(receivers[0]).to.equal(author1.address);
      expect(bps[0]).to.equal(5000);
    });
  });
});
