// Ensure the caller is not the zero address.
require(msg.sender != address(0), "Caller is the zero address");

// Validate inputs for a function, e.g., minting an NFT
require(_tokenId > 0, "Invalid token ID");
require(!_exists(_tokenId), "Token already minted");

if (balanceOf(_owner) <= 0) {
    revert("Owner has no tokens");
}

// Solidity 0.8.x and later
uint256 c = a + b;
require(c >= a, "Uint256 addition overflow");

(bool success, ) = externalContract.call(abi.encodeWithSignature("functionName()"));
require(success, "External call failed");

error InsufficientBalance(uint256 available, uint256 required);

function buyItem(uint256 id) public {
    uint price = itemPrices[id];
    if (msg.sender.balance < price) {
        revert InsufficientBalance({available: msg.sender.balance, required: price});
    }
    // purchase logic
}