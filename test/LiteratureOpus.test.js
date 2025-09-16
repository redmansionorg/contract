const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LiteratureOpus", function () {
  let literatureOpus, opusFactory;
  let owner, reader1, reader2;

  beforeEach(async function () {
    [owner, reader1, reader2] = await ethers.getSigners();
    
    // 部署 OpusFactory
    const OpusFactory = await ethers.getContractFactory("OpusFactory");
    opusFactory = await OpusFactory.deploy();
    await opusFactory.waitForDeployment();

    // 部署 LiteratureOpus
    const LiteratureOpus = await ethers.getContractFactory("LiteratureOpus");
    literatureOpus = await LiteratureOpus.deploy(
      "测试小说",
      "QmSynopsisHash",
      "QmLogoHash",
      "测试作者",
      ethers.keccak256(ethers.toUtf8Bytes("test_author_identity")),
      "All Rights Reserved",
      3000, // 30%
      await opusFactory.getAddress()
    );
    await literatureOpus.waitForDeployment();
  });

  describe("初始化", function () {
    it("应该正确设置基本信息", async function () {
      expect(await literatureOpus.title()).to.equal("测试小说");
      expect(await literatureOpus.writer()).to.equal("测试作者");
      expect(await literatureOpus.synopsisCid()).to.equal("QmSynopsisHash");
      expect(await literatureOpus.logoCid()).to.equal("QmLogoHash");
    });

    it("应该正确设置所有者", async function () {
      expect(await literatureOpus.owner()).to.equal(owner.address);
    });
  });

  describe("章节管理", function () {
    it("应该能够添加章节", async function () {
      await expect(literatureOpus.addChapter(
        1,
        "第一章",
        "QmChapter1Content",
        100 // 0.0001 ETH
      )).to.emit(literatureOpus, "ChapterAdded")
        .withArgs(1, "第一章", 100);

      expect(await literatureOpus.totalChapters()).to.equal(1);
    });

    it("不应该允许添加重复章节", async function () {
      await literatureOpus.addChapter(1, "第一章", "QmChapter1Content", 100);
      
      await expect(literatureOpus.addChapter(
        1,
        "第一章重复",
        "QmChapter1ContentDuplicate",
        200
      )).to.be.revertedWith("Chapter already exists");
    });

    it("应该按顺序添加章节", async function () {
      await literatureOpus.addChapter(1, "第一章", "QmChapter1Content", 100);
      
      await expect(literatureOpus.addChapter(
        3, // 跳过第二章
        "第三章",
        "QmChapter3Content",
        300
      )).to.be.revertedWith("Chapter number must be the next chapter");
    });

    it("只有所有者能添加章节", async function () {
      await expect(literatureOpus.connect(reader1).addChapter(
        1,
        "第一章",
        "QmChapter1Content",
        100
      )).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("章节购买", function () {
    beforeEach(async function () {
      await literatureOpus.addChapter(1, "第一章", "QmChapter1Content", 100);
    });

    it("应该能够购买章节", async function () {
      const chapterPrice = 100; // 100 wei
      
      await expect(literatureOpus.connect(reader1).purchaseChapter(1, {
        value: chapterPrice
      })).to.emit(literatureOpus, "ChapterPurchased")
        .withArgs(reader1.address, 1);

      expect(await literatureOpus.balanceOf(reader1.address, 1)).to.equal(1);
    });

    it("应该拒绝错误的支付金额", async function () {
      const wrongPrice = 200; // 200 wei
      
      await expect(literatureOpus.connect(reader1).purchaseChapter(1, {
        value: wrongPrice
      })).to.be.revertedWith("Incorrect payment");
    });

    it("不应该允许重复购买", async function () {
      const chapterPrice = 100;
      
      await literatureOpus.connect(reader1).purchaseChapter(1, { value: chapterPrice });
      
      await expect(literatureOpus.connect(reader1).purchaseChapter(1, {
        value: chapterPrice
      })).to.be.revertedWith("Already purchased");
    });

    it("应该拒绝购买不存在的章节", async function () {
      const chapterPrice = 100;
      
      await expect(literatureOpus.connect(reader1).purchaseChapter(999, {
        value: chapterPrice
      })).to.be.revertedWith("Chapter not exist");
    });
  });

  describe("NFT 转让限制", function () {
    beforeEach(async function () {
      await literatureOpus.addChapter(1, "第一章", "QmChapter1Content", 100);
      const chapterPrice = 100;
      await literatureOpus.connect(reader1).purchaseChapter(1, { value: chapterPrice });
    });

    it("应该禁止转让NFT", async function () {
      await expect(literatureOpus.connect(reader1).setApprovalForAll(reader2.address, true))
        .to.be.revertedWith("Non-transferable");

      await expect(literatureOpus.connect(reader1).safeTransferFrom(
        reader1.address,
        reader2.address,
        1,
        1,
        "0x"
      )).to.be.revertedWith("Non-transferable");
    });
  });

  describe("URI 生成", function () {
    beforeEach(async function () {
      await literatureOpus.addChapter(1, "第一章", "QmChapter1Content", 100);
    });

    it("应该正确生成章节URI", async function () {
      const uri = await literatureOpus.uri(1);
      expect(uri).to.equal("https://ipfs.io/ipfs/QmChapter1Content");
    });

    it("应该拒绝查询不存在章节的URI", async function () {
      await expect(literatureOpus.uri(999)).to.be.revertedWith("Chapter not found");
    });
  });
});
