// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./DeMaskedToken.sol";


contract TokenPurchase is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    DeMaskedToken public dmtToken;
// @note :: Token Per ETH [For now 100000 DMT per 1 ETH]
    uint256 public tokenPrice;

    function initialize(address _dmtToken, address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        dmtToken = DeMaskedToken(_dmtToken);
        tokenPrice = 100000 * 10 ** 18;
    }

    function purchaseTokens() external payable nonReentrant {
        require(msg.value > 0, "Must  send ETH");
        uint256 tokenAmount =  msg.value * tokenPrice / 1 ether;
        require(dmtToken.balanceOf(address(this)) >= tokenAmount, "Insufficient Tokens");
        dmtToken.transfer(msg.sender, tokenAmount);
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}