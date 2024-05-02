// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DigitalArtNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event NFTCreated(uint256 indexed tokenId, string tokenURI, address owner);
    event NFTBurned(uint256 indexed tokenId);
    event MetadataURIUpdated(uint256 indexed tokenId, string newMetadataURI);

    mapping(uint256 => address) private _cachedOwners;

    constructor() ERC721("DigitalArtNFT", "DANFT") {}

    function mintNFT(address recipient, string memory metadataURI)
        public onlyOwner
        returns (uint256)
    {
        require(recipient != address(0), "Recipient address cannot be zero.");
        require(bytes(metadataURI).length > 0, "MetadataURI cannot be empty.");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadataURI);
        _cachedOwners[newItemId] = recipient; // Cache owner upon minting

        emit NFTCreated(newItemId, metadataURI, recipient);
        return newItemId;
    }

    function transferNFT(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        require(to != address(0), "Transfer to the zero address");

        _transfer(from, to, tokenId);
        _cachedOwners[tokenId] = to; // Update cached owner upon transfer
    }

    function burnNFT(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist.");
        require(_isApprovedOrOwner(_msgSender(), tokenId) || owner() == _msgSender(), "Caller is not owner nor approved or contract owner");
        
        _burn(tokenId);
        delete _cachedOwners[tokenId]; // Remove cached ownership upon burning
        emit NFTBurned(tokenId);
    }

    function updateMetadataURI(uint256 tokenId, string memory newMetadataURI) public {
        require(_exists(tokenId), "Token does not exist.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        require(bytes(newMetadataURI).length > 0, "New metadata URI cannot be empty.");
        
        _setTokenURI(tokenId, newMetadataURI);
        emit MetadataURIUpdated(tokenId, newMetadataURI);
    }

    function queryOwnership(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Query for nonexistent token");
        return _cachedOwners[tokenId]; // Return cached owner
    }
}