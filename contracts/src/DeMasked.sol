// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import "./DeMaskedToken.sol";

contract DeMasked is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ERC2771ContextUpgradeable {

    DeMaskedToken public dmtToken;
    address private _trustedForwarder;

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

     Digest
     It is the final hash that represent a signed message in a standardized format it is what users actually sign offchain and that;s what contract verify on-chain
     EIP712 Preamble :: 
     \x19 = Byte prefix indicating an intended validator which prevents misuse of signature
    \x01 = Version byte for EIP-712 structured data
    It ensures signature cannot be confused with raw Ethereum transaction or other signing schemes

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


    constructor() {
        _disableInitializers();
    }

    function initialize(address _dmtToken, address forwarder,address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();

        dmtToken = DeMaskedToken(_dmtToken);
        _trustedForwarder = forwarder;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes("DeMasked")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }



    function register(string memory _username, bytes memory _signature ) external nonReentrant {
        address sender = _msgSender();
        require(!users[sender].isRegistered, "User Already Registered");
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(usernameToAddress[_username] == address(0), "Username already taken");
        require(dmtToken.balanceOf(sender) >= GAS_FEE, "Insufficient DMT for gas fees");

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(REGISTER_TYPEHASH, keccak256(bytes(_username))))
    ));

    require(_verifySignature(digest, _signature, sender), "Invalid signature");
    dmtToken.transferFrom(sender, owner(), GAS_FEE);

    users[sender] = User({
        username: _username,
        isRegistered: true,
        friends: new address[](0),
        postCount: 0,
        pendingFriendRequests: new address[](0)
    });
    usernameToAddress[_username] = sender;
    registeredUsers.push(sender);

    emit UserRegistered(sender, _username);
    }


    function sendFriendRequest(address _friend, bytes memory _signature) external nonReentrant {
        address sender = _msgSender();
        require(users[sender].isRegistered, "User not registered");
        require(users[_friend].isRegistered, "Friend is not registered");
        require(_friend != sender, "Cannot send friend request to self");
        require(!isFriend[sender][_friend], "You both are already Friends");
        require(!hasPendingRequest[sender][_friend], "Request Already sent");
        require(dmtToken.balanceOf(sender) >= (FRIEND_REQUEST_COST + GAS_FEE), "Insufficient DeMasked Token");

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR,keccak256(abi.encode(FRIEND_REQUEST_TYPEHASH, _friend))));

        require(_verifySignature(digest, _signature, sender), "Invalid Signature");

        dmtToken.transferFrom(sender, address(this), FRIEND_REQUEST_COST);
        dmtToken.transferFrom(sender, owner(), GAS_FEE);
        hasPendingRequest[sender][_friend] = true;
        users[_friend].pendingFriendRequests.push(sender);

        emit FriendRequestSent(sender, _friend);
    }


    function acceptFriendRequest(address _sender) external nonReentrant {
        address receiver =_msgSender();
        require(users[receiver].isRegistered, "User not Registered");
        require(hasPendingRequest[_sender][receiver], "No Pending Request");
        require(!isFriend[receiver][_sender], "Already Friends");
        require(dmtToken.balanceOf(receiver) >= GAS_FEE, "Insufficient DeMasked Token for gas fees");

        dmtToken.transferFrom(receiver, owner(), GAS_FEE);
        isFriend[receiver][_sender] = true;
        isFriend[_sender][receiver] = true;
        hasPendingRequest[_sender][receiver] = false;

        address[] storage requests = users[receiver].pendingFriendRequests;
        for(uint256 i=0; i<requests.length; i++) {
            if(requests[i] == _sender) {
                requests[i] = requests[requests.length - 1];
                requests.pop();
                break;
            }
        }
        users[receiver].friends.push(_sender);
        users[_sender].friends.push(receiver);

        emit FriendRequestAccepted(_sender, receiver);
        
    }

    function createPost(string memory _content, string memory _imageCID, bytes memory _signature) external nonReentrant {
        address sender = _msgSender();
        require(users[sender].isRegistered, "User not registered");
        require(dmtToken.balanceOf(sender) >= (POST_COST + GAS_FEE), "Insufficient DeMasked Tokens");
        require(bytes(_content).length > 0 || bytes(_imageCID).length > 0, "Nothing to post , Image or any text content is required");

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(POST_TYPEHASH,keccak256(bytes(_content)),
        keccak256(bytes(_imageCID))))
        ));

        require(_verifySignature(digest, _signature, sender), "Invalid signature");

        dmtToken.transferFrom(sender, address(this), POST_COST);
        dmtToken.transferFrom(sender, owner(), GAS_FEE);
        postCounter++;
        posts[postCounter] = Post({
            author:sender,
            content: _content,
            imageCID:_imageCID,
            timestamp: block.timestamp
        });
        users[sender].postCount++;
        emit PostCreated(sender, postCounter, _content, _imageCID);
    }


    function sendMessage(address _receiver, string memory _content, bytes memory _signature) external nonReentrant {
        address sender = _msgSender();
        require(users[sender].isRegistered, "User not registered");
        require(users[_receiver].isRegistered, "Friend not registered");
        require(isFriend[sender][_receiver], "Not Friends");
        require(dmtToken.balanceOf(sender) >= (MESSAGE_COST + GAS_FEE), "Insufficient DeMasked Token");
        require(bytes(_content).length > 0, "Message cannot be empty");

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(MESSAGE_TYPEHASH, _receiver, keccak256(bytes(_content))))
        ));
        require(_verifySignature(digest, _signature, sender), "Invalid signature");

        dmtToken.transferFrom(sender, address(this), MESSAGE_COST);
        dmtToken.transferFrom(sender, owner(), GAS_FEE);
        messages[sender][_receiver].push(Message({
            sender: sender,
            receiver: _receiver,
            content: _content,
            timestamp: block.timestamp
        }));

        emit MessageSent(sender, _receiver, _content);
    }

    function removeFriend(address _friend) external nonReentrant {
        address sender =_msgSender();
        require(users[sender].isRegistered, "User not registered");
        require(isFriend[sender][_friend], "Not Friends");
        require(dmtToken.balanceOf(sender) >= GAS_FEE, "Insufficient DeMasked tokens for GAs fees");

        dmtToken.transferFrom(sender, owner(), GAS_FEE);
        isFriend[sender][_friend] = false;
        isFriend[_friend][sender] = false;

        address[] storage senderFriends = users[sender].friends;
        for(uint256 i=0; i<senderFriends.length; i++) {
            if(senderFriends[i] == _friend){
                senderFriends[i] = senderFriends[senderFriends.length - 1];
                senderFriends.pop();
                break;
            }
        }

        address[] storage friendFriends = users[_friend].friends;
        for(uint256 i=0; i<friendFriends.length; i++) {
            if(friendFriends[i] == sender) {
                friendFriends[i] = friendFriends[friendFriends.length - 1];
                friendFriends.pop();
                break;
            }
        }

        emit FriendRemoved(sender, _friend);
    }

    function searchUsers(string memory _query) external view returns (address[] memory) {
        address[] memory matches = new address[](registeredUsers.length);
        uint256 count = 0;
        address addr;

        try this.parseAddress(_query) returns (address tempAddr) {
            addr = tempAddr;
            if(users[addr].isRegistered) {
                matches[count] = addr;
                count++;
            }
        } catch {
            // Search by username
            for(uint256 i = 0; i < registeredUsers.length; i++) {
                if(keccak256(abi.encodePacked(users[registeredUsers[i]].username)) == keccak256(abi.encodePacked(_query))) {
                    matches[count] = registeredUsers[i];
                    count++;
                }
            }
        }

        address[] memory result = new address[](count);
        for(uint256 i=0; i<count; i++) {
            result[i] = matches[i];
        }
        return result;
    }

    //  ------------------------ HELPER FUNCTIONS -----------------------------

    function _contextSuffixLength()
    internal
    view
    override(ContextUpgradeable, ERC2771ContextUpgradeable)
    returns (uint256)
{
    return ERC2771ContextUpgradeable._contextSuffixLength();
}

function parseAddress(string memory _addr) public pure returns(address) {
        bytes memory addrBytes = bytes(_addr);
        require(addrBytes.length == 42, "Invalid address length"); // 0x + 40 hex chars
        require(addrBytes[0] == '0' && (addrBytes[1] == 'x' || addrBytes[1] == 'X'), "Invalid address format");
        
        uint160 result = 0;
        for(uint i = 2; i < 42; i++) {
            result *= 16;
            uint8 b = uint8(addrBytes[i]);
            if(b >= 48 && b <= 57) { // 0-9
                result += b - 48;
            } else if(b >= 65 && b <= 70) { // A-F
                result += b - 55;
            } else if(b >= 97 && b <= 102) { // a-f
                result += b - 87;
            } else {
                revert("Invalid hex character");
            }
        }
        return address(result);
    }

    function getUser(address _user) external view returns(User memory) {
        return users[_user];
    }

    function getPost(uint256 _postId) external view returns (Post memory) {
        return posts[_postId];
    }

    function getMessages(address _sender, address _receiver) external view returns(Message[] memory) {
        return messages[_sender][_receiver];
    }

    function _msgSender() internal view override(ContextUpgradeable,ERC2771ContextUpgradeable) returns(address){
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable,ERC2771ContextUpgradeable) returns(bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    function withdrawDMT() external onlyOwner {
        uint256 balance = dmtToken.balanceOf(address(this));
        dmtToken.transfer(owner(), balance);
    }
    /* 
    digest :: EIP712 hashed message 
    signature :: user's cryptographic signature (65-byte bytes)
    signer :: Address that supposedly created the sginature
    Returns true if signature is valid otherwise false

    Working
    Ethereum signature is 65 bytes long and structured as r,s,v
    r :: (32 bytes) - First part of the ECDSA signature
    s :: (32 bytes) - Second part of the ECDSA signature
    v :: (1 bytes) - Recovery identifier 

    ecrecover function is a precompiled contract in Ethereum that 
    takes digest and v,r,s and returns the ethereum address that signed the message
    */

    // function _verifySignature(bytes32 digest, bytes memory signature, address signer) private pure returns (bool) {
    //     address recovered = ecrecover(digest, uint8(signature[64]), bytes32(signature[0:32]), bytes32(signature[32:64]));
    //     return recovered == signer;
    // }


    function _verifySignature(bytes32 digest, bytes memory signature, address signer) private pure returns (bool) {
    require(signature.length == 65, "Invalid signature length");

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
        r := mload(add(signature, 32))
        s := mload(add(signature, 64))
        v := byte(0, mload(add(signature, 96)))
    }

    return ecrecover(digest, v, r, s) == signer;
}

}