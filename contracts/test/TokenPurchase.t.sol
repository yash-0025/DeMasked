// // SPDX-License-License: MIT
//     pragma solidity ^0.8.20;

//     import "forge-std/Test.sol";
//     import "../src/TokenPurchase.sol";
//     import "../src/DeMaskedToken.sol";

//     contract TokenPurchaseTest is Test {
//         TokenPurchase purchase;
//         DeMaskedToken token;
//         address owner = address(0x1);
//         address user = address(0x2);

//         function setUp() public {
//             vm.startPrank(owner);
//             token = new DeMaskedToken();
//             token.initialize(owner);
//             purchase = new TokenPurchase();
//             purchase.initialize(address(token), owner);
//             token.mint(address(purchase), 1000000 * 10 ** 18);
//             vm.stopPrank();
//         }

//         function testPurchaseTokens() public {
//             vm.deal(user, 1 ether);
//             vm.prank(user);
//             purchase.purchaseTokens{value: 1 ether}();
//             assertEq(token.balanceOf(user), 1000 * 10 ** 18);
//         }
//     }