// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract DSHOP is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl, ERC721Burnable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public owner;

    string private metadataUri;
    string private metadataSuffix = "";
    uint256 public maxSupply;
    uint256 public tokenId;
    struct Refs {
        address[] addr;
        string[] refName;
        string[] buyName;
        string[] contact;
        string[] email;
        uint8[] amount;
        uint256[] timestamp;
        uint256[] klay;
    }
    address[] public referer;
    uint256 public refCounter;

    mapping(address => Refs) refs;

    struct SaleInfo {
        uint256 amount;
        uint256 price;
        uint64 startTime;
        uint64 endTime;
        bool whitelist;
        uint256 perTx;
        uint256 perWallet;
        uint256 maxLimit;
        uint256 minted;
    }
    mapping(uint16 => SaleInfo) public saleInfos;
    mapping(uint16 => mapping(address => uint256)) public mintLogs;
    mapping(address => mapping(uint16 => bool)) public hasWhitelist;

    uint16 public saleInfoNum = 0;
    bool private isRevealed = false;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _maxSupply
    ) ERC721(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        tokenId = 1;
        maxSupply = _maxSupply;
        refCounter = 0;
        owner = msg.sender;
    }

    // =============================================================
    //                        INTERNAL METHODS
    // =============================================================

    function _addRef(address _ref, uint8 _amount, string calldata refName, string calldata buyName, string calldata contact, string calldata email) private {
        if(refs[_ref].amount.length == 0) {
            referer.push(_ref);
            refCounter++;
        }
        refs[_ref].addr.push(msg.sender);
        refs[_ref].amount.push(_amount);
        refs[_ref].timestamp.push(block.timestamp);
        refs[_ref].refName.push(refName);
        refs[_ref].buyName.push(buyName);
        refs[_ref].contact.push(contact);
        refs[_ref].email.push(email);
        refs[_ref].klay.push(msg.value);
    }

    function _logMint(address addr, uint16 step, uint256 quantity)
    private 
    {
        mintLogs[step][addr] += quantity;
        saleInfos[step].minted += quantity;
    }
    function _checkIsMintable(address addr, uint16 step, uint256 quantity) 
    internal 
    returns (bool) 
    {
        if (step >= saleInfoNum) revert("Not exist mint step");
        SaleInfo memory saleInfo = saleInfos[step];
        if (block.timestamp < saleInfo.startTime) revert("Minting hasn't started yet");
        if (block.timestamp > saleInfo.endTime) revert("Minting has ended");
        if (saleInfo.amount < saleInfo.minted + quantity) revert("Sold out in this step");
        if (tokenId + quantity - 1 > maxSupply) revert("Sold out for total supply");
        if (saleInfo.whitelist && !hasWhitelist[addr][step]) revert("You don't have access role");
        if (saleInfo.maxLimit != 0 && tokenId + quantity - 1 > saleInfo.maxLimit) revert("Sold out for max limit");
        if (saleInfo.perTx != 0 && saleInfo.perTx < quantity)
            revert("Exceeds the maximum number of mints per transaction");
        if (saleInfo.perWallet != 0 && saleInfo.perWallet < mintLogs[step][addr] + quantity)
            revert("Exceeds the maximum number of mints per wallet");
        if (quantity == 0) revert("Invalid quantity");
        if (msg.sender == addr && msg.value != saleInfo.price * quantity) revert("Invalid value");
        return true;
    }
    function _beforeTokenTransfer(address from, address to, uint256 _tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, _tokenId, batchSize);
    }
    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) 
    {
        super._burn(_tokenId);
    }

    function pause() public onlyRole(PAUSER_ROLE)
    {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE)
    {
        _unpause();
    }

    // =============================================================
    //                        MINT METHODS
    // =============================================================
    function transferOwnership(address newOwner) 
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        owner = newOwner;
    }
    function airdrop(address to, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
    {
        if(tokenId + amount - 1 > maxSupply) revert("Sold out for max supply");
        for(uint256 i = 0; i < amount; i++) {
        _safeMint(to, tokenId);
        tokenId++;
        }
    }

    function getRefs(address _addr)
    public
    view
    returns(address[] memory addresses, uint8[] memory amounts, uint256[] memory timestamps)
    {
        return (refs[_addr].addr, refs[_addr].amount, refs[_addr].timestamp);
    }
    function getRefsDetail(address _addr)
    public
    view
    returns(string[] memory refNames, string[] memory buyNames, string[] memory contacts, string[] memory emails, uint256[] memory klays)
    {
        return (refs[_addr].refName, refs[_addr].buyName, refs[_addr].contact, refs[_addr].email, refs[_addr].klay);
    }
    function mint(
        uint16 step,
        uint8 amount,
        address addr,
        string calldata refName,
        string calldata buyName,
        string calldata contact,
        string calldata email
    ) external payable {
        _checkIsMintable(msg.sender, step, amount);
        _logMint(msg.sender, step, amount);
        for(uint256 i = 0; i < amount; i++) {
        _safeMint(msg.sender, tokenId);
        tokenId++;
        }
        _addRef(addr, amount, refName, buyName, contact, email);
    }
    
    function setSaleInfoList(
        uint256[] memory amounts,
        uint256[] memory prices,
        uint64[] memory startTimes,
        uint64[] memory endTimes,
        bool[] memory whitelists,
        uint256[] memory perTxs,
        uint256[] memory perWallets,
        uint256[] memory maxLimits,
        uint16 startIdx
    ) external onlyRole(MINTER_ROLE) {
        require(startIdx <= saleInfoNum, "startIdx is out of range");
        for (uint16 i = 0; i < amounts.length; i++)
            saleInfos[i + startIdx] = SaleInfo(
                amounts[i],
                prices[i],
                startTimes[i],
                endTimes[i],
                whitelists[i],
                perTxs[i],
                perWallets[i],
                maxLimits[i],
                saleInfos[i + startIdx].minted
            );
        if (startIdx + amounts.length > saleInfoNum) saleInfoNum = startIdx + uint16(amounts.length);
    }
    function setWhitelist(address[] calldata _addr, uint16 _step, bool _accessRole)
    public
    onlyRole(MINTER_ROLE)
    {
        for(uint256 i = 0; i < _addr.length; i++) {
            hasWhitelist[_addr[i]][_step] = _accessRole;
        }
    }
    function withdraw(uint256 amount)
    public
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
    payable(msg.sender).transfer(amount);
    }
    function currentTime()
    public 
    view
    returns(uint256)
    {
        return block.timestamp;
    }

    // =============================================================
    //                        TOKEN METHODS
    // =============================================================

    function setMaxSupply(uint256 _amount)
    public
    onlyRole(MINTER_ROLE)
    {
        maxSupply = _amount;
    }
    function tokenURI(uint256 _tokenId) public view virtual override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (!isRevealed) return string(abi.encodePacked(metadataUri, "prereveal", metadataSuffix));
        return string(abi.encodePacked(metadataUri, Strings.toString(_tokenId), metadataSuffix));
    }

    function tokensOfOwner(address owner_)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(owner_);
        uint256[] memory result = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            result[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return result;
    }
    function contractURI()
    public
    view
    returns (string memory)
    {
        return string(abi.encodePacked(metadataUri, "contract", metadataSuffix));
    }
    function setMetadata(string calldata _metadataUri, string calldata _metadataSuffix, bool _isReveal)
    external
    onlyRole(MINTER_ROLE)
    {
        metadataUri = _metadataUri;
        metadataSuffix = _metadataSuffix;
        isRevealed = _isReveal;
    }
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
