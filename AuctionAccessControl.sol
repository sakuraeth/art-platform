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
        uint256 startingPrice;
        bool active;
    }

    uint256 private _tokenIds;
    mapping(uint256 => Auction) public auctions;  

    event NewAuction(uint256 tokenId, uint256 startingPrice);
    event BidPlaced(uint256 tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 amount);

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

    function startAuction(uint256 tokenId, uint256 startingPrice) public onlyRole(ARTIST_ROLE) {
        require(_exists(tokenId), "Token does not exist.");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the token owner.");

        auctions[tokenId] = Auction({
            tokenId: tokenId,
            seller: payable(msg.sender),
            startingPrice: startingPrice,
            active: true
        });

        emit NewAuction(tokenId, startingPrice);
    }

    function placeBid(uint256 tokenId) public payable onlyRole(BIDDER_ROLE) nonReentrant {
        Auction storage auction = auctions[tokenId];
        require(auction.active, "Auction is not active.");
        require(msg.value >= auction.startingPrice, "Bid price is too low.");

        if (auction.startingPrice > 0) {
            auction.seller.transfer(msg.value);
        }

        auction.seller = payable(msg.sender); 
        auction.startingPrice = msg.value;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    function endAuction(uint256 tokenId) public {
        Auction storage auction = auctions[tokenId];
        require(auction.active, "Auction is not active.");
        require(auction.seller == msg.sender, "Only the seller can end the auction.");

        auction.active = false;
        _transfer(address(this), msg.sender, tokenId);
        auction.seller.transfer(auction.startingPrice);

        emit AuctionEnded(tokenId, msg.sender, auction.startingPrice);
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