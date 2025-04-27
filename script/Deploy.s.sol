// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/contracts/MyToken.sol";
import "../src/contracts/MyNFT.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy MyToken Implementation
        MyToken token = new MyToken(1_000_000 ether);
        token.grantRole(token.MINTER_ROLE(), msg.sender);
        console.log("MyToken deployed at:", address(token));

        // Deploy MyNFT Implementation
        MyNFT nft = new MyNFT();
        nft.grantRole(nft.MINTER_ROLE(), msg.sender);
        console.log("MyNFT deployed at:", address(nft));
        console.log("Deployed block number:", block.number);

        // Stop broadcasting
        vm.stopBroadcast();
    }
}

// Run to deploy -> forge script script/Deploy.s.sol --rpc-url SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
// Or use the script -> chmod +x ./script/deploy_to_sepolia.sh -> ./script/deploy_to_sepolia.sh
