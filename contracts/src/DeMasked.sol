// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@opezeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "./DeMaskedToken.sol";

contract DeMasked is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable,  ERC2771ContextUpgradeable  {

    DeMaskedToken public dmtToken;

    struct User {
        string username;
        bool isRegistered;
        address[] friends;
        uint256 postCount;
        address[] pendingFriendRequests;
    }

    struct Post {
        address author;
        string content;
        string imageCID;
        uint256 timestamp;
    }

    struct Message {
        address sender;
        address receiver;
        string content;
        uint256 timestamp;
    }


    mapping(address => User) public users;
    mapping(address => mapping(address => bool)) public isFriend;
    mapping(address => mapping(address => bool)) public hasPendingRequest;
    mapping(string => address) public usernameToAddress;
    mapping(uint256 => Post) public posts;
    mapping(address => mapping(address => Message[])) public messages;


    address[] public registeredUsers;
    uint256 public postCounter;
    uint256 public constant POST_COST = 10 * 10**18;
    uint256 public constant MESSAGE_COST = 2 * 10**18;
    uint256 public constant FRIEND_REQUEST_COST = 5 * 10**18;
    uint256 public constant GAS_FEE = 1 * 10**18;

/*  EIP712 Type Hashes
     This bytes32 constant are part of EIP712 standard for structured data signing
     It defines structure of message that users will sign off-chain , which can later be verified on chain

     Components
     EIP712_DOMAIN_TYPEHASH :: It defines the domain separator [mostly helps in preventing cross-chain/ cross-contract replay attacks]


     1. User sign messages without sending a transaction
     2. The contract later verifies the signed messages to execute actions 
     3. It ensures a signature meant for one contract/chain can't be reused again.

    Working 
    1. TypesHashes is defined as compile-time constants to save gas and also they define the structure of signed data.
    2. DOMAIN_SEPARATOR compute which identifies the contract and the chain and prevents a signature of one contract from ethereum to being used on another contract on polygon.
    3. User signs structured data off-chain using wallets like metamask which shows data in a human readable format and signature is tied to DOMAIN_SEPARATOR
    4. AT last on chain verification takes place where the signed digest is reconstructed and the using ecrecover the signer's address is recovered and final check happens which checks the address matches with the user address or not.
*/


    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name, string version, uint256 chainId, address verifyingContract)");

    bytes32 private constant REGISTER_TYPEHASH = keccak256("Register(string username)");

    bytes32 private constant POST_TYPEHASH = keccak256("CreatePost(string content, string imageCID)");

    bytes32 private constant FRIEND_REQUEST_TYPEHASH = keccak256("SendFriendRequest(address friend)");

    bytes32 private constant MESSAGE_TYPEHASH = keccak256("SendMessage(address receiver, string content)");

    bytes32 private DOMAIN_SEPARATOR;


    // ------------------------ EVENTS -------------------------------
    event UserRegistered(address indexed user, string username);
    event PostCreated(address indexed author, uint256 indexed postId, string content, string imageCID);
    event FriendRequestSent(address indexed  sender, address indexed receiver);
    event FriendRequestAccepted(address indexed sender, address indexed receiver);
    event FriendRemoved(address indexed user, address indexed friend);
    event MessageSent(address indexed sender, address indexed receiver, string content);





}