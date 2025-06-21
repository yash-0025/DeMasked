// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.20;

    import "forge-std/Test.sol";
    import "../src/DeMaskedToken.sol";

    contract DeMaskedTokenTest is Test {
        DeMaskedToken token;
        address owner = address(0x1);
        address user = address(0x2);

        function setUp() public {
            vm.prank(owner);
            token = new DeMaskedToken();
            token.initialize(owner);
        }

        function testInitialize() public {
            assertEq(token.name(), "DeMaskedToken");
            assertEq(token.symbol(), "DMT");
            assertEq(token.balanceOf(owner), 1000000 * 10 ** 18);
        }

        function testMint() public {
            vm.prank(owner);
            token.mint(user, 1000 * 10 ** 18);
            assertEq(token.balanceOf(user), 1000 * 10 ** 18);
        }
    }