// SPDX-License-Identifier:MIT
pragma solidity ^0.8.20;

/// @title :: ERC 2771
/// @notice :: It is an Ethereum standard that enables meta transaction called gasless transactions. It allows users to interact with smart contracts without paying gas fees directly. Instead a relayer or forwarder pays the gas fees on behalf of the user
/*  
Components

1. User sign the transaction but didn't pay any gas
2. Relayer :: It is also known as Forwarder . It pays gas fees and sbumits the transaction to the blockchain.
3. Recipient Contract :: The smart contract that processes the transaction
*/

/* 
Flow of transaction
1. User signs transaction off-chain  with required information or data.
2. User sends signed transaction to a relayer
3. Relayer verifie the signature and wraps the original transaction in a forwarder contract .
4. Forwarder contract calls the recipient contract with originam msg.sender [user] address and original data.
5. Recipient contract processes the transaction as if the user sent it directly
*/

import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ForwarderUpgradeable.sol";

contract MinimalForwarder is ERC2771ForwarderUpgradeable {
    function initialize() public initializer {
        __ERC2771Forwarder_init("MinimalForwarder");
    }
}
