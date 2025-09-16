// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./LiteratureOpus.sol"; // 确保此合约路径正确（标准小说合约）
import "./ILiteratureOpus.sol";

contract NovelFactory {

    // Novel部署事件（用于链下索引或前端展示）
    event NewNovelDeployed(
        address indexed author,
        address indexed novel,
        string title,
        string synopsisCid,
        string logoCid
    );

    /// 小说信息结构体
    struct NovelInfo {
        address author;
        address novel;
        string title;
        string synopsisCid; 
        string logoCid;
        string pseudonym;
    }

    /// novel合约地址 => 作品信息
    mapping(address => NovelInfo) public novelInfos;

    // 记录所有小说合约
    address[] public allNovels;
    //uint256 public totalNovels;

    // 作者 => 其部署的小说
    mapping(address => address[]) public novelsByAuthor;

    function createNovel(
        string memory title,
        string memory synopsisCid,
        string memory logoCid,
        string memory pseudonym,
        bytes32 puid, //persional identiry 身份信息哈希
        string memory terms,
        uint256 royalty
    ) external returns (address novelAddress) {

        // 创建新的小说合约，所有者为 msg.sender 后续再添加
        LiteratureOpus novel = new LiteratureOpus(
            title,
            synopsisCid,
            logoCid,
            pseudonym,
            puid,
            terms,
            royalty,
            address(0)
        );

        novelAddress = address(novel);

        // 存储
        allNovels.push(novelAddress);
        novelsByAuthor[msg.sender].push(novelAddress);

        // 触发事件，供前端和子图使用
        emit NewNovelDeployed(msg.sender, novelAddress, title, synopsisCid, logoCid);


        // 写入注册表
        novelInfos[novelAddress] = NovelInfo({
            author: msg.sender,
            novel: novelAddress,
            title: title,
            synopsisCid: synopsisCid,
            logoCid: logoCid,
            pseudonym: pseudonym
        });

    }

    /// 登记一个 Novel 从一个已经部署的小说合约地址。
    function register(address novelAddress) external {

        require(novelInfos[novelAddress].author == address(0), "Already registered");

        // 调用小说合约判断是否为作者本人
        //address novelAuthor = ILiteratureOpus(novelAddress).author();
        //require(novelAuthor == msg.sender, "Not the novel author");

        // 存储
        allNovels.push(novelAddress);
        novelsByAuthor[msg.sender].push(novelAddress);

        string memory _title = ILiteratureOpus(novelAddress).title();
        string memory synopsisCid = ILiteratureOpus(novelAddress).synopsisCid();
        string memory logoCid = ILiteratureOpus(novelAddress).logoCid();
        string memory pseudonym = ILiteratureOpus(novelAddress).writer();

        // 写入注册表
        novelInfos[novelAddress] = NovelInfo({
            author: msg.sender,
            novel: novelAddress,
            title: _title,
            synopsisCid: synopsisCid,
            logoCid: logoCid,
            pseudonym: pseudonym
        });

        emit NewNovelDeployed(msg.sender, novelAddress, _title, synopsisCid, logoCid);
    }

    function registerFromParam(
        address novelAddress,
        address _author,
        string memory _title,
        string memory _synopsisCid,
        string memory _logoCid,
        string memory _pseudonym
    ) external {

        require(novelInfos[novelAddress].author == address(0), "Already registered");

        novelInfos[novelAddress] = NovelInfo({
            author: _author,
            novel: novelAddress,
            title: _title,
            synopsisCid: _synopsisCid,
            logoCid: _logoCid,
            pseudonym: _pseudonym
        });

        allNovels.push(novelAddress);
        novelsByAuthor[_author].push(novelAddress);

        emit NewNovelDeployed(msg.sender, novelAddress, _title, _synopsisCid, _logoCid);
    }


    // 获取所有小说数量
    function totalNovels() external view returns (uint256) {
        return allNovels.length;
    }

    // 获取作者的所有小说
    function getNovelsByAuthor(address _author) external view returns (address[] memory) {
        return novelsByAuthor[_author];
    }
}
