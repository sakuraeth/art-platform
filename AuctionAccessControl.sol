// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ArtAuction is AccessControl, ERC721URIStorage, ReentrancyGuard {
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");
    bytes32 public constant BIDDER_ROLE = keccak256("BIDDER_ROLE");

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

    event AuctionStarted(uint256 tokenId, uint256 startingPrice, uint256 startTime, uint256 endTime);
    event BidPlaced(uint256 tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 amount);
    event BidWithdrawn(uint256 tokenId, address bidder, uint256 amount);

    constructor() ERC721("ArtAuctionNFT", "AANFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ARTIST_ROLE, msg.sender);
        _setupRole(BIDDER_ROLE, msg.sender);
    }

    function mintToken(string memory tokenURI) public onlyRole(ARTIST_ROLE) returns (uint256) {
        _tokenIds++;
        uint256 newTokenId = _tokenIds;
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        return newTokenId;
    }

    // Start an auction with a time limit and a minimum bid increment
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

    // Place a bid on the auction
    function placeBid(uint256 tokenId) public payable onlyRole(BIDDER_ROLE) nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp >= auction.startTime && block.timestamp <= auction.endTime, "Auction not in progress.");
        require(auction.active, "Auction is not active.");
        require(msg.value >= auction.highestBid + auction.minimumIncrement, "Bid too low.");

        if (auction.highestBidder != address(0)) {
            // Allow previous highest bidder to withdraw
            pendingReturns[tokenId][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = payable(msg.sender);

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    function withdrawBid(uint256 tokenId) public {
        uint256 amount = pendingReturns[tokenId][msg.sender];
        require(amount > 0, "No amount to withdraw");
        
        pendingReturns[tokenId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit BidWithdrawn(tokenId, msg.sender, amount);
    }

    // End the auction and transfer the token to the winner
    function endAuction(uint256 tokenId) public {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp > auction.endTime || msg.sender == auction.seller, "Auction cannot be ended yet.");
        require(auction.active, "Auction is not active.");

        auction.active = false;
        if (auction.highestBidder != address(0)) {
            _transfer(auction.seller, auction.highestBidder, tokenId);
            auction.seller.transfer(auction.highestBid);
        } else {
            // Auction ended without bids; return NFT to seller
            _transfer(address(this), auction.seller, tokenId);
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