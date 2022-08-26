// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@                                        @@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@                                        @@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@       @@@@@@@      @@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@       @@@@@@@      @@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@
//@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@@@@@@@@                    @@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@
//@@@@@@@             @@@@@@@             @@@@@@@@@@@@@@             @@@@@@@@@@@@@
//@@@@@@@             @@@@@@@             @@@@@@@@@@@@@@             @@@@@@@@@@@@@
//@@@@@@@             @@@@@@@             @@@@@@@@@@@@@@             @@@@@@@@@@@@@
//              @@@@@@       @@@@@@@@@@@@@                                  @@@@@@
//              @@@@@@       @@@@@@@@@@@@@                                  @@@@@@
//              @@@@@@       @@@@@@@@@@@@@                                  @@@@@@
//       @@@@@@@      @@@@@@@       @@@@@@@@@@@@@                    @@@@@@@
//       @@@@@@@      @@@@@@@       @@@@@@@@@@@@@                    @@@@@@@
//       @@@@@@@      @@@@@@@       @@@@@@@@@@@@@                    @@@@@@@
//
// =============================================================================
// Non-Fungible Faces
// Created by Toni Minge
// January 2022
// =============================================================================

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NonFungibleFacesLight is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private supply;

    // =============================================================================
    // Initial Data
    // =============================================================================

    uint256 public whitelist_cost = 0.01 ether;
    uint256 public public_cost = 0.08 ether;
    uint256 public maxSupply = 10000;
    bool public paused = false;
    string private _baseURIextended = "ipfs://";

    // map whitelist user
    mapping(address => uint8) private _allowList;

    // map token uris
    mapping (uint256 => string) private _tokenURIs;


    constructor() ERC721("Non-Fungible Faces Light", "NFFL"){}

    // =============================================================================
    // External Information
    // =============================================================================

    function currentSupply() public view returns (uint256) {
        return supply.current();
    }

    function totalSupply() public view returns (uint256) {
        return maxSupply;
    }

    function hasMintsLeft(address _wallet) public view returns (bool) {
        bool _hasMintsLeft = false;
        if (_allowList[_wallet] > 0) {
            _hasMintsLeft = true;
        }
        return _hasMintsLeft;
    }

    // =============================================================================
    // Mint Functions & JSON Export of Data
    // =============================================================================

    function mintWhitelist(string memory _metadataURI) public payable mintCompliance() {
        require(!paused, "The contract is paused!");
        require(0 <= _allowList[msg.sender], "Exceeded max available to purchase");
        require(msg.value >= whitelist_cost, "Insufficient funds!");

        _allowList[msg.sender] -= 1;

        supply.increment();
        uint256 tokenId = supply.current();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _metadataURI);
    }

    function mint(string memory _metadataURI) public payable mintCompliance() {
        require(!paused, "The contract is paused!");
        require(msg.value >= public_cost, "Insufficient funds!");

        supply.increment();
        uint256 tokenId = supply.current();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _metadataURI);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    //check total supply
    modifier mintCompliance() {
        require(supply.current() + 1 <= maxSupply, "Max supply exceeded!");
        _;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, uint2str(tokenId)));
    }

    // =============================================================================
    // Admin Functions
    // =============================================================================

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setWhitelistCost(uint256 _cost) public onlyOwner {
        whitelist_cost = _cost;
    }

    function setPublicCost(uint256 _cost) public onlyOwner {
        public_cost = _cost;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setAllowList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = numAllowedToMint;
        }
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // =============================================================================
    // Internal Functions
    // =============================================================================

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
