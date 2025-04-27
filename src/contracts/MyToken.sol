// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Staking logic
    mapping(address => uint256) public stakingBalance; // User's staking balance
    mapping(address => uint256) public stakingTimestamp; // Last staking time
    mapping(address => uint256) public rewards; // Rewards for each user

    uint256 public constant REWARD_INTERVAL = 3600 seconds; // Time for rewards to accumulate (example: 1 hour)
    uint256 public constant LOCK_PERIOD = 600 seconds; // Lock period before unstaking (10 minutes)

    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, initialSupply);
    }

    // Function to mint tokens
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Staking function: Allows users to stake tokens
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance to stake");

        // Transfer the tokens to the contract for staking
        _transfer(msg.sender, address(this), amount);

        // Update staking balance and staking timestamp
        stakingBalance[msg.sender] += amount;

        // Set the staking timestamp when tokens are first staked
        if (stakingTimestamp[msg.sender] == 0) {
            stakingTimestamp[msg.sender] = block.timestamp;
        }
    }

    // Unstaking function: Allows users to unstake tokens
    function unstake(uint256 amount) external {
        require(amount > 0, "Cannot unstake 0 tokens");
        require(stakingBalance[msg.sender] >= amount, "Insufficient staked balance");

        // Check if lock period has passed
        require(block.timestamp >= stakingTimestamp[msg.sender] + LOCK_PERIOD, "Tokens are locked");

        // Transfer the unstaked tokens back to the user
        _transfer(address(this), msg.sender, amount);

        // Update staking balance
        stakingBalance[msg.sender] -= amount;
    }

    // Function to calculate rewards
    function calculateRewards(address account) public view returns (uint256) {
        uint256 stakedDuration = block.timestamp - stakingTimestamp[account];
        uint256 reward = (stakingBalance[account] * stakedDuration) / REWARD_INTERVAL;

        return reward;
    }

    // Function to claim rewards
    function claimReward() external {
        uint256 reward = calculateRewards(msg.sender);
        require(reward > 0, "No rewards available");

        // Reset staking timestamp after claiming rewards
        stakingTimestamp[msg.sender] = block.timestamp;

        // Mint the reward tokens
        _mint(msg.sender, reward);
        rewards[msg.sender] += reward;
    }
}
