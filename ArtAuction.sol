pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ArtAuctionPlatform is ReentrancyGuard {
    using SafeMath for uint256;

    IERC721 public nftTokenContract;

    struct AuctionDetails {
        address owner;
        uint256 startingBid;
        uint256 topBid;
        address topBidder;
        uint256 closingTime;
        bool isCompleted;
    }

    mapping(uint256 => AuctionDetails) public tokenAuctions;

    mapping(uint256 => mapping(address => uint256)) public participantBids;

    event AuctionInitiated(uint256 indexed tokenID, address owner, uint256 startingBid, uint256 closingTime);
    event BidSubmitted(uint256 indexed tokenID, address bidder, uint256 amount);
    event AuctionFinalized(uint256 indexed tokenID, address winningBidder, uint256 winningBidAmount);
    event FundsClaimed(address claimant, uint256 amount);

    constructor(IERC721 _nftTokenContract) {
        nftTokenContract = _nftTokenContract;
    }

    function initiateAuction(uint256 tokenID, uint256 minimumBid, uint256 auctionDuration) external {
        ensureTokenOwnership(tokenID);
        transferNftToContract(msg.sender, tokenID);
        setupAuction(tokenID, msg.sender, minimumBid, auctionDuration);
    }

    function submitBid(uint256 tokenID) external payable nonReentrant {
        ensureValidBidConditions(tokenID);
        updateAuctionAfterBid(tokenID, msg.value, msg.sender);
    }

    function finalizeAuction(uint256 tokenID) external {
        ensureAuctionCompletionConditions(tokenID);
        concludeAuction(tokenID);
    }

    function claimFunds(uint256 tokenID) external nonReentrant {
        withdrawBidderFunds(tokenID, msg.sender);
    }

    function ensureTokenOwnership(uint256 tokenID) internal view {
        require(nftTokenContract.ownerOf(tokenID) == msg.sender, "Auction can only be initiated by token owner.");
    }

    function transferNftToContract(address from, uint256 tokenID) internal {
        nftTokenContract.transferFrom(from, address(this), tokenID);
    }

    function setupAuction(uint256 tokenID, address owner, uint256 minimumBid, uint256 durationInSeconds) internal {
        require(tokenAuctions[tokenID].closingTime == 0, "Auction for token already exists.");
        uint256 closingTime = block.timestamp.add(durationInSeconds);

        tokenAuctions[tokenID] = AuctionDetails({
            owner: owner,
            startingBid: minimumBid,
            topBid: 0,
            topBidder: address(0),
            closingTime: closingTime,
            isCompleted: false
        });

        emit AuctionInitiated(tokenID, owner, minimumBid, closingTime);
    }

    function ensureValidBidConditions(uint256 tokenID) internal view {
        AuctionDetails storage auction = tokenAuctions[tokenID];
        require(block.timestamp < auction.closingTime, "Cannot bid, auction has concluded.");
        require(msg.value > auction.topBid && msg.value >= auction.startingBid, "Bid must be higher than current top bid and meet or exceed starting bid.");
    }

    function updateAuctionAfterBid(uint256 tokenID, uint256 bidAmount, address bidder) internal {
        AuctionDetails storage auction = tokenAuctions[tokenID];
        if (auction.topBidder != address(0)) {
            participantBids[tokenID][auction.topBidder] += auction.topBid;
        }

        auction.topBid = bidAmount;
        auction.topBidder = bidder;

        emit BidSubmitted(tokenID, bidder, bidAmount);
    }

    function ensureAuctionCompletionConditions(uint256 tokenID) internal view {
        AuctionDetails storage auction = tokenAuctions[tokenID];
        require(block.timestamp >= auction.closingTime, "Auction is still active.");
        require(!auction.isCompleted, "Auction has already been finalized.");
    }

    function concludeAuction(uint256 tokenID) internal {
        AuctionDetails storage auction = tokenAuctions[tokenID];
        auction.isCompleted = true;

        if (auction.topBidder != address(0)) {
            nftTokenContract.transferFrom(address(this), auction.topBidder, tokenID);
            payable(auction.owner).transfer(auction.topBid);
        } else {
            nftTokenContract.transferFrom(address(this), auction.owner, tokenID);
        }

        emit AuctionFinalized(tokenID, auction.topBidder, auction.topBid);
    }

    function withdrawBidderFunds(uint256 tokenID, address bidder) internal {
        uint256 amountToClaim = participantBids[tokenID][bidder];
        require(amountToClaim > 0, "You have no funds to claim.");
        participantBids[tokenID][bidder] = 0;
        payable(bidder).transfer(amountToClaim);

        emit FundsClaimed(bidder, amountToClaim);
    }
}