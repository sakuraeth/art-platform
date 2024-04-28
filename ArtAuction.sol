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
        require(nftContract.ownerOf(tokenId) == msg.sender, "You must own the NFT to auction it.");
        require(auctions[tokenId].endTime == 0, "Auction already exists.");

        nftContract.transferFrom(msg.sender, address(this), tokenId);

        uint256 endTime = block.timestamp.add(duration);
        auctions[tokenId] = Auction({
            seller: msg.sender,
            minBid: minBid,
            highestBid: 0,
            highestBidder: address(0),
            endTime: endTime,
            ended: false
        });

        emit AuctionStarted(tokenId, msg.sender, minBid, endTime);
    }

    function placeBid(uint256 tokenId) external payable nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp < auction.endTime, "Auction already ended.");
        require(msg.value > auction.highestBid && msg.value >= auction.minBid, "Bid not high enough.");

        if (auction.highestBidder != address(0)) {
            bids[tokenId][auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        
        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    function endAuction(uint256 tokenId) external {
        Auction storage auction = auctions[tokenId];
        require(block.timestamp >= auction.endTime, "Auction not yet ended.");
        require(!auction.ended, "Auction already ended.");

        auction.ended = true;
        if (auction.highestBidder != address(0)) {
            nftContract.transferFrom(address(this), auction.highestBidder, tokenId);
            payable(auction.seller).transfer(auction.highestBid);
        } else {
            nftContract.transferFrom(address(this), auction.seller, tokenId);
        }

        emit AuctionEnded(tokenId, auction.highestBidder, auction.highestBid);
    }

    function withdrawFunds(uint256 tokenId) external nonReentrant {
        uint256 amount = bids[tokenId][msg.sender];
        require(amount > 0, "No funds to withdraw.");

        bids[tokenId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit FundsWithdrawn(msg.sender, amount);
    }
}