const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ArtworkOpus", function () {
  let artworkOpus, literatureOpus, opusFactory;
  let owner, buyer1, buyer2;

  beforeEach(async function () {
    [owner, buyer1, buyer2] = await ethers.getSigners();
    
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
      3000,
      await opusFactory.getAddress()
    );
    await literatureOpus.waitForDeployment();

    // 部署 ArtworkOpus
    const ArtworkOpus = await ethers.getContractFactory("ArtworkOpus");
    artworkOpus = await ArtworkOpus.deploy(
      "测试艺术品合集",
      "TESTART",
      "QmArtMetadataHash",
      "QmArtLogoHash",
      "测试艺术家",
      ethers.keccak256(ethers.toUtf8Bytes("test_artist_identity")),
      500, // 5%
      await literatureOpus.getAddress(),
      await opusFactory.getAddress()
    );
    await artworkOpus.waitForDeployment();
  });

  describe("初始化", function () {
    it("应该正确设置艺术品信息", async function () {
      const artMetadata = await artworkOpus.getArtMetadata();
      expect(artMetadata.name).to.equal("测试艺术品合集");
      expect(artMetadata.symbol).to.equal("TESTART");
      expect(artMetadata.metadataCid).to.equal("QmArtMetadataHash");
      expect(artMetadata.logoCid).to.equal("QmArtLogoHash");
      expect(artMetadata.pseudonym).to.equal("测试艺术家");
      expect(artMetadata.royaltyFeeBps).to.equal(500);
    });

    it("应该正确设置原始作品信息", async function () {
      const originMetadata = await artworkOpus.getOriginMetadata();
      expect(originMetadata.bookAddr).to.equal(await literatureOpus.getAddress());
      expect(originMetadata.authorAddr).to.equal(owner.address);
      expect(originMetadata.royalty).to.equal(500);
    });

    it("应该正确设置ERC721基本信息", async function () {
      expect(await artworkOpus.name()).to.equal("测试艺术品合集");
      expect(await artworkOpus.symbol()).to.equal("TESTART");
    });
  });

  describe("艺术品铸造", function () {
    it("应该能够铸造艺术品", async function () {
      const tokenURI = "QmTokenMetadataHash";
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_artist_identity"));
      const awid = ethers.keccak256(ethers.toUtf8Bytes("artwork_content_hash"));
      const ruid = ethers.keccak256(ethers.concat([puid, awid]));

      await expect(artworkOpus.mintArt(tokenURI, ruid, puid, awid))
        .to.emit(artworkOpus, "ArtMinted")
        .withArgs(owner.address, 1, tokenURI);

      expect(await artworkOpus.totalSupply()).to.equal(1);
      expect(await artworkOpus.ownerOf(1)).to.equal(owner.address);
      expect(await artworkOpus.tokenURI(1)).to.equal(tokenURI);
    });

    it("应该验证版权信息", async function () {
      const tokenURI = "QmTokenMetadataHash";
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_artist_identity"));
      const awid = ethers.keccak256(ethers.toUtf8Bytes("artwork_content_hash"));
      const wrongRuid = ethers.keccak256(ethers.toUtf8Bytes("wrong_ruid"));

      await expect(artworkOpus.mintArt(tokenURI, wrongRuid, puid, awid))
        .to.be.revertedWith("Copyright verification failed, RUID is not equal.");
    });

    it("只有所有者能铸造", async function () {
      const tokenURI = "QmTokenMetadataHash";
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_artist_identity"));
      const awid = ethers.keccak256(ethers.toUtf8Bytes("artwork_content_hash"));
      const ruid = ethers.keccak256(ethers.concat([puid, awid]));

      await expect(artworkOpus.connect(buyer1).mintArt(tokenURI, ruid, puid, awid))
        .to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("版税信息", function () {
    it("应该正确计算版税", async function () {
      const salePrice = ethers.parseEther("1.0"); // 1 ETH
      const [receiver, royaltyAmount] = await artworkOpus.royaltyInfo(1, salePrice);
      
      expect(receiver).to.equal(owner.address);
      expect(royaltyAmount).to.equal(ethers.parseEther("0.05")); // 5% of 1 ETH
    });

    it("应该支持EIP-2981接口", async function () {
      expect(await artworkOpus.supportsInterface("0x2a55205a")).to.be.true; // IERC2981
    });
  });

  describe("RUID 管理", function () {
    beforeEach(async function () {
      const tokenURI = "QmTokenMetadataHash";
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_artist_identity"));
      const awid = ethers.keccak256(ethers.toUtf8Bytes("artwork_content_hash"));
      const ruid = ethers.keccak256(ethers.concat([puid, awid]));
      
      await artworkOpus.mintArt(tokenURI, ruid, puid, awid);
    });

    it("应该能够获取代币RUID", async function () {
      const puid = ethers.keccak256(ethers.toUtf8Bytes("test_artist_identity"));
      const awid = ethers.keccak256(ethers.toUtf8Bytes("artwork_content_hash"));
      const expectedRuid = ethers.keccak256(ethers.concat([puid, awid]));
      
      expect(await artworkOpus.tokenRUID(1)).to.equal(expectedRuid);
    });

    it("应该拒绝查询不存在代币的RUID", async function () {
      await expect(artworkOpus.tokenRUID(999)).to.be.revertedWith("ERC721: invalid token ID");
    });
  });

  describe("元数据URI", function () {
    it("应该正确生成元数据URI", async function () {
      const metadataURI = await artworkOpus.metadataURI();
      expect(metadataURI).to.equal("ipfs://QmArtMetadataHash");
    });
  });
});
