# RedArt - 版权管理和数字作品交易平台

RedArt 是一个基于以太坊的智能合约系统，用于管理数字文学作品的版权、交易和衍生作品关系。该系统支持文学作品章节付费阅读、艺术品NFT交易、版权关系图谱和版税分配等功能。

## 项目特性

### 核心功能
- **文学作品管理**: 支持小说章节的付费阅读和版权管理
- **艺术品交易**: 基于ERC721的艺术品NFT交易，支持版税分配
- **版权注册**: 去中心化的版权声明和注册系统
- **版权图谱**: 追踪作品之间的衍生关系
- **版税管理**: 多级版税分配机制
- **消息注册**: 支持OTS（Open Timestamps）证明的消息注册

### 技术架构
- **Solidity 0.8.18**: 智能合约开发语言
- **OpenZeppelin**: 安全的标准合约库
- **ERC721**: 艺术品NFT标准
- **ERC1155**: 文学作品章节标准
- **EIP-2981**: 版税标准支持

## 合约说明

### 主要合约

1. **LiteratureOpus** - 文学作品合约
   - 基于ERC1155实现章节付费阅读
   - 支持作者身份验证和版权声明
   - 章节内容通过IPFS存储

2. **ArtworkOpus** - 艺术品合约
   - 基于ERC721的艺术品NFT
   - 支持EIP-2981版税标准
   - 与文学作品关联的衍生作品

3. **CopyrightRegistry** - 版权注册中心
   - 注册所有作品的版权声明
   - 提供版权查询和验证功能

4. **CopyrightGraph** - 版权关系图谱
   - 追踪作品间的衍生关系
   - 支持多种关系类型（衍生、翻译、改编、引用）

5. **RoyaltyManager** - 版税管理器
   - 管理多级版税分配
   - 支持复杂的版税链条

6. **OpusFactory** - 作品工厂
   - 统一管理所有作品合约
   - 提供作品注册和查询功能

## 快速开始

### 环境要求
- Node.js >= 16.0.0
- npm 或 yarn

### 安装依赖
```bash
npm install
```

### 编译合约
```bash
npm run compile
```

### 运行测试
```bash
npm test
```

### 运行覆盖率测试
```bash
npm run test:coverage
```

### 部署合约

#### 本地网络
```bash
# 启动本地节点
npm run node

# 在另一个终端部署
npm run deploy:local
```

#### 测试网络
```bash
# 配置环境变量
cp env.example .env
# 编辑 .env 文件，填入你的私钥和RPC URL

# 部署到 Sepolia 测试网
npm run deploy:sepolia
```

### 验证合约
```bash
npx hardhat verify --network sepolia <合约地址>
```

## 使用示例

### 创建文学作品
```javascript
const LiteratureOpus = await ethers.getContractFactory("LiteratureOpus");
const novel = await LiteratureOpus.deploy(
  "小说标题",
  "QmSynopsisHash", // IPFS 故事梗概哈希
  "QmLogoHash",     // IPFS 封面哈希
  "作者笔名",
  authorPuid,       // 作者身份哈希
  "All Rights Reserved",
  3000,             // 30% 版税
  opusFactoryAddress
);
```

### 添加章节
```javascript
await novel.addChapter(
  1,                    // 章节号
  "第一章",             // 章节标题
  "QmChapter1Content",  // IPFS 内容哈希
  ethers.parseEther("0.01") // 章节价格
);
```

### 购买章节
```javascript
await novel.purchaseChapter(1, {
  value: ethers.parseEther("0.01")
});
```

### 创建艺术品合集
```javascript
const ArtworkOpus = await ethers.getContractFactory("ArtworkOpus");
const artwork = await ArtworkOpus.deploy(
  "艺术品合集名称",
  "ARTSYMBOL",
  "QmArtMetadataHash",
  "QmArtLogoHash",
  "艺术家笔名",
  artistPuid,
  500,                 // 5% 版税
  novelAddress,        // 关联的文学作品
  opusFactoryAddress
);
```

### 铸造艺术品
```javascript
const puid = ethers.keccak256(ethers.toUtf8Bytes("artist_identity"));
const awid = ethers.keccak256(ethers.toUtf8Bytes("artwork_content"));
const ruid = ethers.keccak256(ethers.concat([puid, awid]));

await artwork.mintArt(
  "QmTokenMetadataHash", // 代币元数据
  ruid,
  puid,
  awid
);
```

## 测试

项目包含完整的测试套件，覆盖所有主要功能：

- **CopyrightRegistry.test.js** - 版权注册测试
- **LiteratureOpus.test.js** - 文学作品合约测试
- **ArtworkOpus.test.js** - 艺术品合约测试
- **RoyaltyManager.test.js** - 版税管理测试

运行测试：
```bash
npm test
```

## 部署信息

部署完成后，合约地址会保存在 `deployments.json` 文件中。

## 安全考虑

- 所有合约都经过OpenZeppelin安全库保护
- 使用最新的Solidity版本和最佳实践
- 包含完整的访问控制机制
- 支持暂停和升级功能（如需要）

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request来改进项目。

## 联系方式

如有问题，请通过GitHub Issues联系我们，谢谢。
