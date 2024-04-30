pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ArtAuction is ReentrancyGuard {
    using SafeMath for uint256;

    IERC721 public nftContract;

    struct Auction {
        address seller;
        uint256 minBid;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool ended;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public bids;

    event AuctionStarted(uint256 indexed tokenId, address seller, uint256 minBid, uint256 endTime);
    event BidPlaced(uint256 indexed tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address winner, uint256 amount);
    event FundsWithdrawn(address withdrawer, uint256 amount);

    constructor(IERC721 _nftContract) {
        nftContract = _nftContract;
    }

    function startAuction(uint256 tokenId, uint256 minBid, uint256 duration) external {
        _validateOwnership(tokenId);
        _transferNftToContract(msg.sender, tokenId);
        _initiateAuction(tokenId, msg.sender, minBid, duration);
    }

    function placeBid(uint256 tokenId) external payable nonReentrant {
        _validateBidConditions(tokenId);
        _updateAuctionState(tokenId, msg.value, msg.sender);
    }

    function endAuction(uint256 tokenId) external {
        _validateAuctionEndConditions(tokenId);
        _concludeAuction(tokenId);
    }

    function withdrawFunds(uint256 tokenId) external nonReentrant {
        _withdrawBidFunds(tokenId, msg.sender);
    }

    // Internal helper functions to refactor complex logic
    function _validateOwnership(uint256 tokenId) internal view {
        require(nftContract.ownerOf(tokenId) == msg.sender, "You must own the NFT to auction it.");
    }

    function _transferNftToContract(address from, uint256 tokenId) internal {
        nftContract.transferFrom(from, address(this), tokenId);
    }

    function _initiateAuction(uint256 tokenId, address seller, uint256 minBid, uint256 duration) internal {
        require(auctions[tokenId].endTime == 0, "Auction already exists.");
        uint256 endTime = block.timestamp.add(duration);
        auctions[tokenId] = Auction({
            seller: seller,
            minBid: minBid,
            highestBid: 0,
            highestBidder: address(0),
            endTime: endTime,
            ended: false
        });

        emit AuctionStarted(tokenId, seller, minBid, endTime);
    }

    function _validateBidConditions(uint256 tokenId) internal view {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp < auction.endTime, "Auction already ended.");
        require(msg.value > auction.highestBid && msg.value >= auction.minBid, "Bid not high enough.");
    }

    function _updateAuctionState(uint256 tokenId, uint256 bidAmount, address bidder) internal {
        Auction storage auction = auctions[tokenId];
        if (auction.highestBidder != address(0)) {
            bids[tokenId][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = bidAmount;
        auction.highestBidder = bidder;
        
        emit BidPlaced(tokenId, bidder, bidAmount);
    }

    function _validateAuctionEndConditions(uint256 tokenId) internal view {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp >= auction.endTime, "Auction not yet ended.");
        require(!auction.ended, "Auction already ended.");
    }

    function _concludeAuction(uint256 tokenId) internal {
        Auction storage auction = auctions[tokenId];
        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            nftContract.transferFrom(address(this), auction.highestBidder, tokenId);
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            nftContract.transferFrom(address(this), auction.seller, tokenId);
        }

        emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);
    }

    function _withdrawBidFunds(uint256 tokenId, address bidder) internal {
        uint256 amount = bids[tokenId][bidder];
        require(amount > 0, "No funds to withdraw.");
        bids[tokenId][bidder] = 0;
        payable(bidder).transfer(amount);
        emit FundsWithdrawn(bidder, amount);
    }
}