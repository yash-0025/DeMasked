// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract DeMaskedToken is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    function initialize(address initialOwner) public initializer {
        __ERC20_init("DeMaskedToken", "DMT");
        __Ownable_init(initialOwner);
        _mint(initialOwner, 100000000 * 10 ** decimals() );
    }

    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to,amount);
    }
}
