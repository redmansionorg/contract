// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./OpusFactory.sol";
import "./LiteratureOpus.sol";
// import "./IArtworkOpus.sol";

/**
 * @title ArtOpus
 * @dev ERC721 artistic works with embedded royalty and license attribution
 */
contract ArtworkOpus is ERC721URIStorage, IERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct OriginMetadata {
        address bookAddr; // 作品地址，具体消息可以直接访问作品合约实例
        address authorAddr;// 作品作者账户（该作品的所有者）。如果没有对应作品的话，是作品的版权所有者(原版小说地址)
        uint96 royalty; // 作品版税设置（衍生品版税累加收取）
    }

    struct ArtMetadata{
            string name;
            string symbol;
            string metadataCid;
            string logoCid;
            address author;
            string pseudonym;
            bytes32 puid;
            bytes32 buid;
            bytes32 ruid;
            uint96 royaltyFeeBps;
            uint256 timestamp;
        }

    OriginMetadata public originInfo;
    ArtMetadata public artInfo;

    // Optional mapping for token RUIDs
    mapping(uint256 => bytes32) private _tokenRUIDs;

    /*为了简化，许可条款只能沿用原创小说的，由于它不涉及到计算，所以就不用重复保存，只需读取小说的就可以*/
    // struct LicenseInfo {
    //     string description;
    //     string licenseURI;
    // }
    //mapping(uint256 => LicenseInfo) public licenseOf;

    event ArtMinted(address indexed to, uint256 tokenId, string tokenURI);
    //后面再完善，建议集中注册版权，由OTS共识机制方便采集与处理，wuid = BUID | CUID | CCCID | AWID (work universal identiry)
    event CopyrightClaimed(bytes32 indexed ruid, bytes32 puid, bytes32 wuid, string opusType);    // "book", "chapter", "collection", "artwork"

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _metadataCid,
        string memory _logoCid,
        string memory _pseudonym,
        bytes32 _puid,
        uint96 _royaltyFeeBps,
        address _bookAddr,
        address registry
    ) ERC721(_name, _symbol) Ownable() {

        _transferOwnership(msg.sender);
        artInfo.name = _name;
        artInfo.symbol = _symbol;
        artInfo.metadataCid=_metadataCid;
        artInfo.logoCid = _logoCid;
        artInfo.author = address(this);
        artInfo.pseudonym = _pseudonym;
        artInfo.puid = _puid;
        artInfo.royaltyFeeBps = _royaltyFeeBps;
        artInfo.timestamp = block.timestamp;

        artInfo.buid = keccak256(abi.encodePacked(_name, _logoCid));
        artInfo.ruid = keccak256(abi.encodePacked( artInfo.puid, artInfo.buid));

        emit CopyrightClaimed(artInfo.ruid, artInfo.puid, artInfo.buid, "collection");


        originInfo.bookAddr = _bookAddr;
        originInfo.authorAddr = msg.sender;
        originInfo.royalty = _royaltyFeeBps;

        //自我注册到注册器
        if(registry != address(0))
       OpusFactory(registry).registerArtFromParam(
            _bookAddr,
            address(this),
            msg.sender,
            name(),
            symbol(),
            _metadataCid,
            _logoCid,
            _pseudonym
        );

    }

    function mintArt(
        string calldata tokenURI,
        bytes32 _ruid,
        bytes32 _puid,
        bytes32 _awid
        )external
        onlyOwner
        returns (uint256)
    {

        bytes32 ver_ruid = keccak256(abi.encodePacked(_puid, _awid));
        require( ver_ruid == _ruid, "Copyright verification failed, RUID is not equal.");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        emit ArtMinted(msg.sender, newItemId, tokenURI);

        _setTokenRUID(newItemId, _ruid);
        emit CopyrightClaimed(_ruid, _awid, _puid, "artwork");

        return newItemId;
    }

    /// @notice EIP-2981 royalty standard support
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = originInfo.authorAddr;
        royaltyAmount = (salePrice * artInfo.royaltyFeeBps) / 10000;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721URIStorage)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenRUID(uint256 tokenId) public view virtual returns (bytes32) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        bytes32 _tokenRUID = _tokenRUIDs[tokenId];
        return _tokenRUID;
    }

    function _setTokenRUID(uint256 tokenId, bytes32 _tokenRUID) internal virtual {
        _tokenRUIDs[tokenId] = _tokenRUID;
    }

    
    function getOriginMetadata()
        external
        view
        returns (OriginMetadata memory){
            return  originInfo;
        }

    /*
     * 为了方便，一次性把基础信息取出，不用多次与智能合约交互。
     */
    function getArtMetadata()
        external
        view
        returns (ArtMetadata memory)
    {
        return artInfo;
    }

    /*
     * NFT 合集的metadata uri
     */
    function metadataURI()
        external
        view
        returns (string memory)
    {
        return string.concat("ipfs://", artInfo.metadataCid);
    }


    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _tokenIds.current();
    }

}
