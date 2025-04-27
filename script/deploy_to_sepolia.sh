#!/bin/bash

# Script to deploy a Solidity contract using Forge
# Prompts for private key and RPC URL interactively

# Ensure Foundry is installed
if ! command -v forge &> /dev/null; then
    echo "Error: Forge is not installed. Please install Foundry first."
    echo "Run: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    exit 1
fi

# Prompt for private key (hidden input)
echo "Enter your private key (input will be hidden):"
read -s PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: Private key cannot be empty."
    exit 1
fi

# Prompt for RPC URL
echo "Enter RPC URL (e.g., SEPOLIA_RPC_URL):"
read RPC_URL
if [ -z "$RPC_URL" ]; then
    echo "Error: RPC URL cannot be empty."
    exit 1
fi

# Step 1: Compile the contract
echo "Compiling the contract..."
forge build
if [ $? -ne 0 ]; then
    echo "Error: Compilation failed."
    exit 1
fi

# Step 2: Deploy MyToken and MyNFT contracts
echo "Deploying MyToken and MyNFT contracts..."
DEPLOY_OUTPUT=$(forge script script/Deploy.s.sol \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --broadcast)

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo "MyToken and MyNFT deployment successful!"
else
    echo "Error: Deployment failed. Check your RPC URL, private key, or network status."
    exit 1
fi

# Extract deployed contract addresses and block number
MYTOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "MyToken deployed at:" | awk '{print $5}')
MYNFT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "MyNFT deployed at:" | awk '{print $5}')
BLOCK_NUMBER=$(echo "$DEPLOY_OUTPUT" | grep "Deployed block number:" | awk '{print $4}')

# Validate extraction
if [ -z "$MYTOKEN_ADDRESS" ] || [ -z "$MYNFT_ADDRESS" ] || [ -z "$BLOCK_NUMBER" ]; then
    echo "Error: Could not extract contract addresses or block number from output."
    echo "Output: $DEPLOY_OUTPUT"
    exit 1
fi

# Step 3: Output deployed addresses and block number
echo
echo "------------ R E S U L T S ------------"
echo
echo "MyToken Contract Address: $MYTOKEN_ADDRESS"
echo "MyNFT Contract Address: $MYNFT_ADDRESS"
echo "Deployed Block Number: $BLOCK_NUMBER"

