// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract ArtAuction is AccessControl, ERC721URIStorage, ReentrancyGuard {
    using Address for address payable;

    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");
    bytes32 public constant BIDDER_ROLE = keccak256("BIDDER_ROLE");

    struct RoyaltyInfo {
        address artist;
        uint96 royaltyPercentage; // Reduced size from uint256 to uint96, large enough for storing percentage values
    }

    struct Auction {
        uint256 tokenId;
        address payable seller;
        uint256 highestBid;
        address payable highestBidder;
        uint256 startTime;
        uint256 endTime;
        bool active;
        uint256 minimumIncrement;
    }

    uint256 private _tokenIds;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public pendingReturns;
    mapping(uint256 => RoyaltyInfo) private _royalties; 

    event AuctionStarted(uint256 tokenId, uint256 startingPrice, uint256 startTime, uint256 endTime);
    event BidPlaced(uint256 tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 amount);
    event BidWithdrawn(uint256 tokenId, address bidder, uint256 amount);

    constructor() ERC721("ArtAuctionNFT", "AANFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ARTIST_ROLE, msg.sender);
        _setupRole(BIDDER_ROLE, msg.sender);
    }

    function mintToken(string memory tokenURI, uint96 royaltyPercentage) public onlyRole(ARTIST_ROLE) returns (uint256) {
        require(royaltyPercentage <= 100, "Royalty cannot exceed 100%");

        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        _royalties[newTokenId] = RoyaltyInfo(msg.sender, royaltyPercentage);

        return newTokenId;
    }

    function startAuction(uint256 tokenId, uint256 startingPrice, uint256 duration, uint256 minimumIncrement) public onlyRole(ARTIST_ROLE) {
        require(_exists(tokenId), "Token does not exist.");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner.");
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;

        auctions[tokenId] = Auction({
            tokenId: tokenId,
            seller: payable(msg.sender),
            highestBid: startingPrice,
            highestBidder: payable(address(0)),
            startTime: startTime,
            endTime: endTime,
            active: true,
            minimumIncrement: minimumIncrement
        });

        emit AuctionStarted(tokenId, startingPrice, startTime, endTime);
    }

    function endAuction(uint256 tokenId) public {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp > auction.endTime || msg.sender == auction.seller, "Auction cannot be ended yet.");
        require(auction.active, "Auction is not active.");

        auction.active = false;
        if (auction.highestBidder != address(0)) {
            uint256 royaltyAmount = (auction.highestBid * _royalties[tokenId].royaltyPercentage) / 100;
            uint256 sellerAmount = auction.highestBid - royaltyAmount;

            _royalties[tokenId].artist.sendValue(royaltyAmount);

            auction.seller.sendValue(sellerAmount);

            _safeTransfer(auction.seller, auction.highestBidder, tokenId, "");
        } else {
            // This returns the token back to the seller if no bids were received
            _safeTransfer(address(this), auction.seller, tokenId, "");
        }

        emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);
    }

    function grantArtistRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ARTIST_ROLE, account);
    }

    function revokeArtistRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ARTIST_ROLE, account);
    }

    function grantBidderRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(BIDDER_ROLE, account);
    }

    function revokeBidderRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(BIDDER_ROLE, account);
    }
}