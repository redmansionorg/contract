// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//import "./LiteratureOpus.sol"; // 确保此合约路径正确（标准小说合约）
import "./ILiteratureOpus.sol";
import "./ArtworkOpus.sol";

contract OpusFactory {

    // Novel部署事件（用于链下索引或前端展示）
    event NovelRegistered(
        address indexed author,
        address indexed novel,
        string title,
        string synopsisCid,
        string logoCid
    );
    event ArtRegistered(
        address indexed author,
        address indexed art,
        string title,
        string symbol,
        string logoCid
    );

    /// 小说信息结构体，可以作为缓存的一些信息
    struct NovelInfo {
        address author;
        address novel;
        string title;
        string synopsisCid; 
        string logoCid;
        string pseudonym;
    }

    /// 艺术品合集，信息结构体，可以作为缓存的一些信息
    struct ArtInfo {
        address author;
        address artwork;
        string name;
        string symbol;
        string metadataCid; 
        string logoCid;
        string pseudonym;
     }

    // 记录所有小说合约
    address[] public allNovels;
    /// novel合约地址 => 作品信息 检索用 其实在小说合约里面做一个方法统一把全部信息调用返回也是可以的
    mapping(address => NovelInfo) public novelInfos;
    // 作者 => 其部署的小说数组
    mapping(address => address[]) public novelsByAuthor;


    // 艺术品合集
    address[] public allArts;
    mapping(address => ArtInfo) public artInfos;
    mapping(address => address[]) public artsByAuthor;

    // 小说与艺术合集的关系
    mapping(address => address[]) public artsByBook;

    /// 登记一个 Novel 从一个已经部署的小说合约地址。
    // 放在registArt中实现
    // function registerArtToBook(address artAddr, address bookAddr) external {
    //     require(artInfos[artAddr].author == address(0), "Already registered");
    // 	artsOfBook[bookAddr].push(artAddr);
    // }
    
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

        // 小说对象自己记录日志跟这里不一样，这里是注册记录，小说是创建小说
        emit NovelRegistered(msg.sender, novelAddress, _title, synopsisCid, logoCid);
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

        // 
        emit NovelRegistered(msg.sender, novelAddress, _title, _synopsisCid, _logoCid);
    }


    // 获取所有小说数量
    function totalNovels() external view returns (uint256) {
        return allNovels.length;
    }

    // 获取作者的所有小说
    function getNovelsByAuthor(address _author) external view returns (address[] memory) {
        return novelsByAuthor[_author];
    }

    // 获取小说的衍生作品
    function getArtsByBook(address bookAddr) external view returns (address[] memory) {
        return artsByBook[bookAddr];
    }

    /// 登记一个 Novel 从一个已经部署的艺术品合约地址。
    function registerArt(address artAddress) external {

        require(artInfos[artAddress].author == address(0), "Already registered");

        // 调用小说合约判断是否为作者本人
        //address novelAuthor = ILiteratureOpus(artAddress).author();
        //require(novelAuthor == msg.sender, "Not the novel author");

        // 存储
        allArts.push(artAddress);
        artsByAuthor[msg.sender].push(artAddress);

        ArtworkOpus.OriginMetadata memory originInfo = ArtworkOpus(artAddress).getOriginMetadata();
        artsByBook[originInfo.bookAddr].push(artAddress);

        ArtworkOpus.ArtMetadata memory artInfo = ArtworkOpus(artAddress).getArtMetadata();
        // 写入注册表
        artInfos[artAddress] = ArtInfo({
            author: artInfo.author,
            artwork: artAddress,
            name: artInfo.name,
            symbol: artInfo.symbol,
            metadataCid: artInfo.metadataCid,
            logoCid: artInfo.logoCid,
            pseudonym: artInfo.pseudonym
        });

        // 小说对象自己会记录日志，这里记录的话重复了
        emit ArtRegistered(msg.sender, artAddress, artInfo.name, artInfo.symbol, artInfo.logoCid);
    }

    /*
     * 艺术品操作
     */
    function registerArtFromParam(
        address bookAddr,
        address _art,
        address _author,
        string memory _name,
        string memory _symbol,
        string memory _metadataCid,
        string memory _logoCid,
        string memory _pseudonym
    ) external {

        require(artInfos[_art].author == address(0), "Already registered");

        artInfos[_art] = ArtInfo({
            author: _author,
            artwork: _art,
            name: _name,
            symbol: _symbol,
            metadataCid: _metadataCid,
            logoCid: _logoCid,
            pseudonym: _pseudonym
        });

        allArts.push(_art);
        artsByAuthor[_author].push(_art);

        artsByBook[bookAddr].push(_art);

        // 小说对象自己会记录日志，这里记录的话重复了
        emit ArtRegistered(msg.sender, _art, _name, _symbol, _logoCid);
    }

    // 获取所有艺术专辑的数量
    function totalArts() external view returns (uint256) {
        return allArts.length;
    }
    // 获取作者创作的所有小说
    function getArtsByAuthor(address _author) external view returns (address[] memory) {
        return artsByAuthor[_author];
    }

}
