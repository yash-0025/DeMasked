// // SPDX-License-Identifier: MIT
//     pragma solidity ^0.8.20;

//     import "forge-std/Test.sol";
//     import "../src/DeMasked.sol";
//     import "../src/DeMaskedToken.sol";
//     import "../src/MinimalForwarder.sol";

//     contract DeMaskedTest is Test {
//         DeMasked demasked;
//         DeMaskedToken token;
//         MinimalForwarder forwarder;
//         address owner = address(0x1);
//         address user1 = address(0x2);
//         address user2 = address(0x3);

//         function setUp() public {
//             vm.startPrank(owner);
//             forwarder = new MinimalForwarder();
//             token = new DeMaskedToken();
//             token.initialize(owner);
//             demasked = new DeMasked();
//             demasked.initialize(address(token), address(forwarder), owner);
//             token.mint(user1, 1000 * 10 ** 18);
//             token.mint(user2, 1000 * 10 ** 18);
//             vm.stopPrank();
//         }

//         function testRegisterUser() public {
//             vm.startPrank(user1);
//             token.approve(address(demasked), 1 * 10 ** 18);
//             bytes memory signature = signRegister("User1", user1);
//             demasked.register("User1", signature);
//             (string memory username, bool isRegistered,,,) = demasked.users(user1);
//             assertEq(username, "User1");
//             assertTrue(isRegistered);
//             assertEq(demasked.usernameToAddress("User1"), user1);
//             vm.stopPrank();
//         }

//         function testFailRegisterDuplicateUsername() public {
//             vm.startPrank(user1);
//             token.approve(address(demasked), 1 * 10 ** 18);
//             demasked.register("User1", signRegister("User1", user1));
//             vm.stopPrank();
//             vm.startPrank(user2);
//             token.approve(address(demasked), 1 * 10 ** 18);
//             vm.expectRevert("Username already taken");
//             demasked.register("User1", signRegister("User1", user2));
//             vm.stopPrank();
//         }

//         function testCreateTextOnlyPost() public {
//             vm.startPrank(user1);
//             token.approve(address(demasked), 11 * 10 ** 18);
//             demasked.register("User1", signRegister("User1", user1));
//             demasked.createPost("Hello, world!", "", signPost("Hello, world!", "", user1));
//             (, , , uint256 postCount,) = demasked.users(user1);
//             assertEq(postCount, 1);
//             (address author, string memory content, string memory imageCID,) = demasked.getPost(1);
//             assertEq(author, user1);
//             assertEq(content, "Hello, world!");
//             assertEq(imageCID, "");
//             vm.stopPrank();
//         }

//         function testCreatePostWithImage() public {
//             vm.startPrank(user1);
//             token.approve(address(demasked), 11 * 10 ** 18);
//             demasked.register("User1", signRegister("User1", user1));
//             demasked.createPost("Hello with image!", "QmTestCID", signPost("Hello with image!", "QmTestCID", user1));
//             (, , , uint256 postCount,) = demasked.users(user1);
//             assertEq(postCount, 1);
//             (address author, string memory content, string memory imageCID,) = demasked.getPost(1);
//             assertEq(author, user1);
//             assertEq(content, "Hello with image!");
//             assertEq(imageCID, "QmTestCID");
//             vm.stopPrank();
//         }

//         function testSendFriendRequest() public {
//             vm.startPrank(user1);
//             token.approve(address(demasked), 1 * 10 ** 18);
//             demasked.register("User1", signRegister("User1", user1));
//             vm.stopPrank();
//             vm.startPrank(user2);
//             token.approve(address(demasked), 3 * 10 ** 18);
//             demasked.register("User2", signRegister("User2", user2));
//             demasked.sendFriendRequest(user1, signFriendRequest(user1, user2));
//             assertTrue(demasked.hasPendingRequest(user2, user1));
//             vm.stopPrank();
//         }

//         function testSendMessage() public {
//             vm.startPrank(user1);
//             token.approve(address(demasked), 1 * 10 ** 18);
//             demasked.register("User1", signRegister("User1", user1));
//             vm.stopPrank();
//             vm.startPrank(user2);
//             token.approve(address(demasked), 8 * 10 ** 18);
//             demasked.register("User2", signRegister("User2", user2));
//             demasked.sendFriendRequest(user1, signFriendRequest(user1, user2));
//             vm.stopPrank();
//             vm.prank(user1);
//             token.approve(address(demasked), 1 * 10 ** 18);
//             demasked.acceptFriendRequest(user2);
//             vm.startPrank(user2);
//             demasked.sendMessage(user1, "Hi!", signMessage(user1, "Hi!", user2));
//             DeMasked.Message[] memory msgs = demasked.getMessages(user2, user1);
//             assertEq(msgs.length, 1);
//             assertEq(msgs[0].content, "Hi!");
//             vm.stopPrank();
//         }

//         function signRegister(string memory username, address signer) private returns (bytes memory) {
//             bytes32 digest = keccak256(abi.encodePacked(
//                 "\x19\x01",
//                 keccak256(abi.encode(
//                     keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
//                     keccak256(bytes("DeMasked")),
//                     keccak256(bytes("1")),
//                     block.chainid,
//                     address(demasked)
//                 )),
//                 keccak256(abi.encode(
//                     keccak256("Register(string username)"),
//                     keccak256(bytes(username))
//                 ))
//             ));
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), digest);
//             return abi.encodePacked(r, s, v);
//         }

//         function signPost(string memory content, string memory imageCID, address signer) private returns (bytes memory) {
//             bytes32 digest = keccak256(abi.encodePacked(
//                 "\x19\x01",
//                 keccak256(abi.encode(
//                     keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
//                     keccak256(bytes("DeMasked")),
//                     keccak256(bytes("1")),
//                     block.chainid,
//                     address(demasked)
//                 )),
//                 keccak256(abi.encode(
//                     keccak256("CreatePost(string content,string imageCID)"),
//                     keccak256(bytes(content)),
//                     keccak256(bytes(imageCID))
//                 ))
//             ));
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), digest);
//             return abi.encodePacked(r, s, v);
//         }

//         function signFriendRequest(address friend, address signer) private returns (bytes memory) {
//             bytes32 digest = keccak256(abi.encodePacked(
//                 "\x19\x01",
//                 keccak256(abi.encode(
//                     keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
//                     keccak256(bytes("DeMasked")),
//                     keccak256(bytes("1")),
//                     block.chainid,
//                     address(demasked)
//                 )),
//                 keccak256(abi.encode(
//                     keccak256("SendFriendRequest(address friend)"),
//                     friend
//                 ))
//             ));
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), digest);
//             return abi.encodePacked(r, s, v);
//         }

//         function signMessage(address receiver, string memory content, address signer) private returns (bytes memory) {
//             bytes32 digest = keccak256(abi.encodePacked(
//                 "\x19\x01",
//                 keccak256(abi.encode(
//                     keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
//                     keccak256(bytes("DeMasked")),
//                     keccak256(bytes("1")),
//                     block.chainid,
//                     address(demasked)
//                 )),
//                 keccak256(abi.encode(
//                     keccak256("SendMessage(address receiver,string content)"),
//                     receiver,
//                     keccak256(bytes(content))
//                 ))
//             ));
//             (uint8 v, bytes32 r, bytes32 s) = vm.sign(uint256(uint160(signer)), digest);
//             return abi.encodePacked(r, s, v);
//         }
//     }