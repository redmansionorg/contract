const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CopyrightRegistry", function () {
  let copyrightRegistry;
  let owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    
    const CopyrightRegistry = await ethers.getContractFactory("CopyrightRegistry");
    copyrightRegistry = await CopyrightRegistry.deploy();
    await copyrightRegistry.waitForDeployment();
  });

  describe("版权注册", function () {
    it("应该能够注册版权", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_puid"));
      const wuid = [ethers.keccak256(ethers.toUtf8Bytes("test_wuid"))];
      const opusType = "literature";

      await expect(copyrightRegistry.connect(addr1).registerCopyright(
        ruid,
        puid,
        wuid,
        opusType
      )).to.emit(copyrightRegistry, "CopyrightClaimed");

      const registration = await copyrightRegistry.getRegistration(ruid);
      expect(registration.puid).to.equal(puid);
      expect(registration.wuid[0]).to.equal(wuid[0]);
      expect(registration.opusType).to.equal(opusType);
      expect(registration.registeredBy).to.equal(addr1.address);
    });

    it("不应该允许重复注册相同的RUID", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_puid"));
      const wuid = [ethers.keccak256(ethers.toUtf8Bytes("test_wuid"))];
      const opusType = "literature";

      await copyrightRegistry.connect(addr1).registerCopyright(ruid, puid, wuid, opusType);
      
      await expect(copyrightRegistry.connect(addr2).registerCopyright(
        ruid,
        puid,
        wuid,
        opusType
      )).to.be.revertedWith("Already registered");
    });

    it("不应该允许注册空的RUID", async function () {
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_puid"));
      const wuid = [ethers.keccak256(ethers.toUtf8Bytes("test_wuid"))];
      const opusType = "literature";

      await expect(copyrightRegistry.connect(addr1).registerCopyright(
        ethers.ZeroHash,
        puid,
        wuid,
        opusType
      )).to.be.revertedWith("Invalid ruid");
    });
  });

  describe("查询功能", function () {
    it("应该能够检查RUID是否已注册", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_puid"));
      const wuid = [ethers.keccak256(ethers.toUtf8Bytes("test_wuid"))];
      const opusType = "literature";

      expect(await copyrightRegistry.isRegistered(ruid)).to.be.false;

      await copyrightRegistry.connect(addr1).registerCopyright(ruid, puid, wuid, opusType);

      expect(await copyrightRegistry.isRegistered(ruid)).to.be.true;
    });

    it("应该能够获取注册信息", async function () {
      const ruid = ethers.keccak256(ethers.toUtf8Bytes("test_ruid"));
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_puid"));
      const wuid = [ethers.keccak256(ethers.toUtf8Bytes("test_wuid"))];
      const opusType = "literature";

      await copyrightRegistry.connect(addr1).registerCopyright(ruid, puid, wuid, opusType);

      const registration = await copyrightRegistry.getRegistration(ruid);
      expect(registration.puid).to.equal(puid);
      expect(registration.wuid[0]).to.equal(wuid[0]);
      expect(registration.opusType).to.equal(opusType);
      expect(registration.registeredBy).to.equal(addr1.address);
      expect(registration.registeredAt).to.be.greaterThan(0);
    });
  });
});
