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

    constructor() ERC721("DigitalArtNFT", "DANFT") {}

    function mintNFT(address recipient, string memory metadataURI)
        public
        onlyOwner
        returns (uint256)
    {
        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current(); 
        _mint(recipient, newItemId); 
        _setTokenURI(newItemId, metadataURI); 

        emit NFTCreated(newItemId, metadataURI, recipient);
        return newItemId; 
    }

    function transferNFT(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    
    function burnNFT(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId) || owner() == _msgSender(), "Caller is not owner nor approved or contract owner");
        _burn(tokenId);
        emit NFTBurned(tokenId);
    }

    function updateMetadataURI(uint256 tokenId, string memory newMetadataURI) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        _setTokenURI(tokenId, newMetadataURI);
        emit MetadataURIUpdated(tokenId, newMetadataURI);
    }

    function queryOwnership(uint256 tokenId) public view returns (address owner) {
        owner = ownerOf(tokenId);
        return owner;
    }
}