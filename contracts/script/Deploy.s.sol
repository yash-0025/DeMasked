// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DeMaskedToken.sol";
import "../src/DeMasked.sol";
import "../src/TokenPurchase.sol";
import "../src/MinimalForwarder.sol";


contract Deploy is Script {
    function run() external {
        // string memory deployerPrivateKeyHX = string.concat("0x", vm.envString("PRIVATE_KEY"));
        // uint256 deployerPrivateKey = vm.parseUint(deployerPrivateKeyHX);
        
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        MinimalForwarder forwarder = new MinimalForwarder();
        forwarder.initialize();
        console.log("Forwarder deployed Address ::", address(forwarder));

        DeMaskedToken token = new DeMaskedToken();
        console.log("DeMasked Token Contract is deployed on this Address ::", address(token));
        token.initialize(deployer);

        DeMasked demasked = new DeMasked();
        console.log("DeMasked Contract is deployed on this Address ::", address(demasked));
        demasked.initialize(address(token),address(forwarder), deployer);

        TokenPurchase purchase = new TokenPurchase();
        console.log("Token Purchase contract is deployed on this Address ::", address(purchase));
        purchase.initialize(address(token), deployer);
        token.mint(address(purchase), 1000000 * 10**18);

        vm.stopBroadcast();

    }
}