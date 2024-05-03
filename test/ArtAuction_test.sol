pragma solidity ^0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ArtAuction.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract TestArtAuction is ERC721Holder {
    ArtAuction artAuction;
    uint public initialBalance = 10 ether;

    function beforeEach() public {
        if (address(artAuction) == address(0)) {
            artAuction = new ArtAuction();
        }
    }

    function testMintingAndListingArt() public {
        artAuction.createTokenAndAuction("ArtTokenURI", 1 ether);
        Assert.equal(artAuction.ownerOf(1), address(this), "Owner of minted NFT should be this contract.");
        (, uint startingBid, , bool isActive) = artAuction.artAuctions(1);
        Assert.equal(startingBid, 1 ether, "Auction's starting bid should be 1 ether.");
        Assert.isTrue(isActive, "Auction should be active.");
    }

    function testBiddingOnArt() public {
        address bidder = address(0x123);
        artAuction.createTokenAndAuction("ArtTokenURI2", 1 ether);
        artAuction.placeBid{value: 2 ether}(1);
        artAuction.placeBid{value: 3 ether}(1);
        (, , uint highestBid,) = artAuction.artAuctions(1);
        Assert.equal(highestBid, 3 ether, "Highest bid should be 3 ether.");
    }

    function testAuctionConclusion() public payable {
        artAuction.createTokenAndAuction("ArtTokenURI3", 1 ether);
        artAuction.placeBid{value: 2 ether}(1);
        artAuction.simulateAuctionEnd(1);
        artAuction.concludeAuction(1);
        (, , , bool isActive) = artAuction.artAuctions(1);
        Assert.isFalse(isActive, "Auction should be concluded.");
        uint balanceAfter = address(this).balance;
        Assert.isAtLeast(balanceAfter, 8 ether, "Seller should receive the payment.");
    }

    receive() external payable {}
}