// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArtPlatform {
    function buyItem(uint256 id) public {
        uint256 price = itemPrices[id];
        if (msg.sender.balance < price) {
            revert InsufficientBalance({available: msg.sender.balance, required: price});
        }
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
    }

    function balanceOf(address owner) internal view returns (uint256) {
    }
}