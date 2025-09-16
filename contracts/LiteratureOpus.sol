// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./OpusFactory.sol";

/**
 * @title LiteratureOpus
 * @dev Original literature with chapters as ERC1155 NFTs (non-transferable)
 */
contract LiteratureOpus is ERC1155, Ownable {

    //作者笔名
    //身份hash
    //小说hash：title & description
    //章节hash：title & content
    //版权hash
    //新的问题是，签名那么多，用户需要多次是很麻烦的，所以是不是不用签名或者只签一个名

    /*
     * 身份信息
     */
    struct PersonIdentity {
        string pseudonym;   // 作者笔名/网名，方便链上判断名称是否重复。
        // 如果笔名重复，可通过邮箱或者手机协助判断，当然puid也是不一样的
        //string masked; // 脱敏邮箱地址或者手机号码，仅用于显示，该部分数据会存储，但是不会参与哈希及签名
        // pid_do data_object: name & id | words （其中words是为了不要让别人那么容易就找出哈希对应的真实用户是谁）
        bytes32 puid;       // 可用来跟原创内容一起hash确权。puid=keccak256(JSON.stringify(pid_do, Object.keys(pid_do).sort()));
        //bytes32 signature;  // 确保puid没有被篡改。ECDSA.Sign(puid)，确权钱包的签名，可以ecrecover()对签名进行验证，可确认地址；

        address ownerAddr;
    }

    /*
     * 确权版权信息
     *
     * require(_timestamp <= block.timestamp, "Future timestamp not allowed");
     * 你也可以添加一个字段 confirmedAt 自动设置为当前 block.timestamp，而 timestamp 则为作者填写字段，这样两者分工清晰。
     *
     */
    struct Copyright {
        bytes32[] wuid;     // work作品的哈希，如果是一本书[buid]，如果是某个章节可以是[buid,cuid]
        bytes32 puid;       // 身份信息哈希
        //
        // 深思熟虑后，觉得还是改一下名字，否字不好记，改成ruid = right of author 也是合理的 ruid
        bytes32 ruid;  // 版权哈希，keccak256(wuid+puid); Founder's Copyright
        //bytes32 signature;  // 确保buid没有被篡改。ECDSA.Sign(buid)，确权钱包的签名，可以ecrecover()对签名进行验证，可确认地址；
        uint256 timestamp;

    }

    /*
    * 1. All Rights Reserved
    * 2. Public Domain
    * 3. Creative Commons (CC) Attribution
    * 4. (CC) Attrib. NonCommercial
    * 5. (CC) Attrib. NonComm. NoDerivs
    * 6. (CC) Attrib. NonComm. ShareAlike
    * 7. (CC) Attribution-ShareAlike
    * 8. (CC) Attribution-NoDerivs
    */
    struct License {
        string terms;     //许可协议方式名称
        uint256 royalty;    //版税占额度 30%
        bytes32 ruid;       //版权哈希

        bytes32 luid;       // 许可证哈希 keccak256(terms + royalty + ruid)
        //bytes32 signature;  // 确保buid没有被篡改。ECDSA.Sign(buid)，确权钱包的签名，可以ecrecover()对签名进行验证，可确认地址；
    }

    /*
     * 作品信息
     * 
     */
    struct Book {
        string title;       // 方便链上判断名称是否重复
        string synopsisCid;     // ipfs地址，synopsis故事梗概纯文本格式，可能包括换行符等。
        string logoCid;     // 
        //
        bytes32 buid;       // keccak256(title小说名称+synopsisCid(故事梗概))
        //bytes32 signature;  // 确保buid没有被篡改。ECDSA.Sign(buid)，确权钱包的签名，可以ecrecover()对签名进行验证，可确认地址；
        //
        //Copyright copyright;
    }

    /*
     * 章节内容
     * 
     */
    struct Chapter {
        string title;
        string contentCid;  // content identify - ipfs地址，小说内容content纯文本格式，包括换行符等，两行表示分段。
        uint256 price;
        bool exists;        // 帮助数组快速判断是否存在
        //
        bytes32 cuid;       // keccak256(小说章节标题+小说内容) = hash ( content or chapter )
        //bytes32 signature;  // 确保buid没有被篡改。ECDSA.Sign(buid)，确权钱包的签名，可以ecrecover()对签名进行验证，可确认地址；
        //
        Copyright copyright;
    }

    PersonIdentity public author;
    Book public novel;
    Copyright public copyright; // copyright novel book
    License public license; //许可证

    mapping(uint256 => Chapter) public chapters;
    uint256 public totalChapters;

    event BookOpened(bytes32 buid, string _title, string cid);
    event ChapterAdded(uint256 chapterNumber, string _title, uint256 price);
    event ChapterPurchased(address indexed reader, uint256 chapterId);
    event PaymentToAuthor(address indexed reader, uint256 amount);
    //后面再完善，建议集中注册版权，由OTS共识机制方便采集与处理
    event CopyrightClaimed(bytes32 indexed ruid, bytes32 buid, bytes32 puid, string opusType);    // "book", "chapter", "collection", "artwork"




    /**
     * baseUri 应为 "ipfs://" 或支持路径拼接格式。
     * baseURI 示例：ipfs:// 或 https://ipfs.io/ipfs/
     * 章节内容 URI 拼接：baseURI + chapters[chapterId].cid
     */
    constructor(
        string memory _title,
        string memory _synopsisCid,
        string memory _logoCid,
        string memory pseudonym,
        bytes32 puid, //persional identiry 身份信息哈希
        string memory terms,
        uint256 royalty,
        address registry
        ) ERC1155("https://ipfs.io/ipfs/") Ownable() {

            _transferOwnership(msg.sender);
            bytes32 _buid = keccak256(abi.encodePacked(_title, _synopsisCid));

            novel = Book({
                title: _title,
                synopsisCid: _synopsisCid,
                logoCid: _logoCid,
                buid: _buid
            });

            author = PersonIdentity({
                pseudonym: pseudonym,
                puid: puid,
                ownerAddr: msg.sender
            });
            
            bytes32[] memory _wuid = new bytes32[](1);
            _wuid[0] = _buid;
            copyright = Copyright({
                ruid: keccak256(abi.encodePacked(puid, _buid)),
                wuid: _wuid,
                puid: puid,
                timestamp: block.timestamp
            });

            license = License({
                terms: terms,
                royalty: royalty,
                ruid: copyright.ruid,
                luid: keccak256(abi.encodePacked(copyright.ruid, terms, royalty))
            });
            
            //author = _author;
            //novel = _book;
            //copyright = _copyright;
            //license = _license;

            // 自我注册到注册器
            if(registry != address(0))
            OpusFactory(registry).registerFromParam(
                address(this),
                msg.sender,
                _title,
                _synopsisCid,
                _logoCid,
                pseudonym
            );
        }

    function writer() external view returns (string memory){
        return author.pseudonym;
    }

    function title() external view returns (string memory){
        return novel.title;
    }

    function synopsisCid() external view returns (string memory){
        return novel.synopsisCid;
    }

    function logoCid() external view returns (string memory){
        return novel.logoCid;
    }

    function addChapter(
        uint256 chapterNumber,
        string calldata _title,
        string calldata contentCid,
        uint256 price
    ) external onlyOwner {
        require(chapters[chapterNumber].exists == false, "Chapter already exists");
        require(chapterNumber == totalChapters+1, "Chapter number must be the next chapter");

            bytes32 _cuid = keccak256(abi.encodePacked(_title, contentCid));
            Copyright memory _copyright = Copyright({
                wuid: new bytes32[](2),
                ruid: keccak256(abi.encodePacked(author.puid, _cuid)),
                puid: author.puid,
                timestamp: block.timestamp
            });
            _copyright.wuid[0] = novel.buid;
            _copyright.wuid[1] = _cuid;

        chapters[chapterNumber] = Chapter(_title, contentCid, price, true, _cuid, _copyright);
        emit ChapterAdded(chapterNumber, _title, price);
        totalChapters++;
    }

    function purchaseChapter(uint256 chapterId) external payable {
        Chapter memory chapter = chapters[chapterId];
        require(chapter.exists, "Chapter not exist");
        require(msg.value == chapter.price, "Incorrect payment");
        require(balanceOf(msg.sender, chapterId) == 0, "Already purchased");

        _mint(msg.sender, chapterId, 1, "");
        payable(owner()).transfer(msg.value);
        emit ChapterPurchased(msg.sender, chapterId);
    }

    // 禁止转让章节NFT
    function setApprovalForAll(address, bool) public pure override {
        revert("Non-transferable");
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert("Non-transferable");
    }

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert("Non-transferable");
    }

    function uri(uint256 chapterId)
        public
        view
        override
        returns (string memory)
    {
        require(chapters[chapterId].exists, "Chapter not found");
        return
            string(
                abi.encodePacked(super.uri(chapterId), chapters[chapterId].contentCid)
            );
    }
}
