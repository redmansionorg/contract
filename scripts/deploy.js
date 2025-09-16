const { ethers } = require("hardhat");

async function main() {
  console.log("开始部署 RedArt 智能合约...");

  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
  console.log("部署账户:", deployer.address);
  console.log("账户余额:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");

  // 1. 部署版权注册中心
  console.log("\n1. 部署 CopyrightRegistry...");
  const CopyrightRegistry = await ethers.getContractFactory("CopyrightRegistry");
  const copyrightRegistry = await CopyrightRegistry.deploy();
  await copyrightRegistry.waitForDeployment();
  console.log("CopyrightRegistry 地址:", await copyrightRegistry.getAddress());

  // 2. 部署版权图谱
  console.log("\n2. 部署 CopyrightGraph...");
  const CopyrightGraph = await ethers.getContractFactory("CopyrightGraph");
  const copyrightGraph = await CopyrightGraph.deploy(await copyrightRegistry.getAddress());
  await copyrightGraph.waitForDeployment();
  console.log("CopyrightGraph 地址:", await copyrightGraph.getAddress());

  // 3. 部署版税管理器
  console.log("\n3. 部署 RoyaltyManager...");
  const RoyaltyManager = await ethers.getContractFactory("RoyaltyManager");
  const royaltyManager = await RoyaltyManager.deploy();
  await royaltyManager.waitForDeployment();
  console.log("RoyaltyManager 地址:", await royaltyManager.getAddress());

  // 4. 部署消息注册中心
  console.log("\n4. 部署 RMRegistry...");
  const RMRegistry = await ethers.getContractFactory("RMRegistry");
  const rmRegistry = await RMRegistry.deploy();
  await rmRegistry.waitForDeployment();
  console.log("RMRegistry 地址:", await rmRegistry.getAddress());

  // 5. 部署作品工厂
  console.log("\n5. 部署 OpusFactory...");
  const OpusFactory = await ethers.getContractFactory("OpusFactory");
  const opusFactory = await OpusFactory.deploy();
  await opusFactory.waitForDeployment();
  console.log("OpusFactory 地址:", await opusFactory.getAddress());

  // 6. 部署示例文学作品
  console.log("\n6. 部署示例文学作品...");
  const LiteratureOpus = await ethers.getContractFactory("LiteratureOpus");
  
  const novelTitle = "红楼梦数字版";
  const synopsisCid = "QmExampleSynopsisHash";
  const logoCid = "QmExampleLogoHash";
  const pseudonym = "曹雪芹";
  const puid = ethers.keccak256(ethers.toUtf8Bytes("caoxueqin_identity"));
  const terms = "All Rights Reserved";
  const royalty = 3000; // 30%

  const literatureOpus = await LiteratureOpus.deploy(
    novelTitle,
    synopsisCid,
    logoCid,
    pseudonym,
    puid,
    terms,
    royalty,
    await opusFactory.getAddress()
  );
  await literatureOpus.waitForDeployment();
  console.log("LiteratureOpus 地址:", await literatureOpus.getAddress());

  // 7. 部署示例艺术品合集
  console.log("\n7. 部署示例艺术品合集...");
  const ArtworkOpus = await ethers.getContractFactory("ArtworkOpus");
  
  const artName = "红楼梦插画集";
  const artSymbol = "HLMART";
  const metadataCid = "QmExampleArtMetadataHash";
  const artLogoCid = "QmExampleArtLogoHash";
  const artPseudonym = "现代插画师";
  const artPuid = ethers.keccak256(ethers.toUtf8Bytes("modern_artist_identity"));
  const royaltyFeeBps = 500; // 5%

  const artworkOpus = await ArtworkOpus.deploy(
    artName,
    artSymbol,
    metadataCid,
    artLogoCid,
    artPseudonym,
    artPuid,
    royaltyFeeBps,
    await literatureOpus.getAddress(),
    await opusFactory.getAddress()
  );
  await artworkOpus.waitForDeployment();
  console.log("ArtworkOpus 地址:", await artworkOpus.getAddress());

  // 输出部署摘要
  console.log("\n=== 部署摘要 ===");
  console.log("CopyrightRegistry:", await copyrightRegistry.getAddress());
  console.log("CopyrightGraph:", await copyrightGraph.getAddress());
  console.log("RoyaltyManager:", await royaltyManager.getAddress());
  console.log("RMRegistry:", await rmRegistry.getAddress());
  console.log("OpusFactory:", await opusFactory.getAddress());
  console.log("LiteratureOpus:", await literatureOpus.getAddress());
  console.log("ArtworkOpus:", await artworkOpus.getAddress());

  // 保存部署信息到文件
  const deploymentInfo = {
    network: "hardhat",
    timestamp: new Date().toISOString(),
    deployer: deployer.address,
    contracts: {
      CopyrightRegistry: await copyrightRegistry.getAddress(),
      CopyrightGraph: await copyrightGraph.getAddress(),
      RoyaltyManager: await royaltyManager.getAddress(),
      RMRegistry: await rmRegistry.getAddress(),
      OpusFactory: await opusFactory.getAddress(),
      LiteratureOpus: await literatureOpus.getAddress(),
      ArtworkOpus: await artworkOpus.getAddress(),
    }
  };

  const fs = require('fs');
  fs.writeFileSync('deployments.json', JSON.stringify(deploymentInfo, null, 2));
  console.log("\n部署信息已保存到 deployments.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
