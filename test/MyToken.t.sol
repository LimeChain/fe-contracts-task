// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/contracts/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public minter = address(0x3);

    function setUp() public {
        token = new MyToken(1_000_000 ether);
        token.grantRole(token.MINTER_ROLE(), minter);
    }

    function testNameAndSymbol() public view {
        assertEq(token.name(), "MyToken");
        assertEq(token.symbol(), "MTK");
    }

    function testInitialBalance() public view {
        assertEq(token.balanceOf(address(this)), 1_000_000 ether);
    }

    function testTransfer() public {
        token.transfer(alice, 100 ether);
        assertEq(token.balanceOf(alice), 100 ether);
    }

    function testApproveAndTransferFrom() public {
        token.approve(bob, 50 ether);
        vm.prank(bob);
        token.transferFrom(address(this), bob, 50 ether);
        assertEq(token.balanceOf(bob), 50 ether);
    }

    function testMintWithRole() public {
        vm.prank(minter);
        token.mint(alice, 500 ether);
        assertEq(token.balanceOf(alice), 500 ether);
    }

    function testTransferExceedsBalance() public {
        uint256 balance = token.balanceOf(address(this));
        vm.expectRevert();
        token.transfer(alice, balance + 1);
    }

    function testUnauthorizedMintReverts() public {
        vm.expectRevert();
        token.mint(alice, 100 ether);
    }

    function testStakeTokens() public {
        uint256 stakeAmount = 100 ether;
        vm.prank(minter);
        token.mint(alice, stakeAmount);
        uint256 initialBalance = token.balanceOf(alice);

        assertEq(initialBalance, stakeAmount);
        
        vm.prank(alice);
        token.stake(stakeAmount);

        assertEq(token.stakingBalance(alice), stakeAmount);
        assertEq(token.balanceOf(alice), initialBalance - stakeAmount);
    }

    function testUnstakeBeforeLockPeriod() public {
        uint256 stakeAmount = 100 ether;
        vm.prank(minter);
        token.mint(alice, stakeAmount);

        vm.prank(alice);
        token.stake(stakeAmount);

        vm.expectRevert("Tokens are locked");
        vm.prank(alice);
        token.unstake(stakeAmount);
    }

    function testUnstakeAfterLockPeriod() public {
        uint256 stakeAmount = 100 ether;
        vm.prank(minter);
        token.mint(alice, stakeAmount);

        vm.prank(alice);
        token.stake(stakeAmount);

        // Simulate passing time (lock period)
        uint256 timePassed = 10 minutes;
        vm.warp(block.timestamp + timePassed);

        uint256 initialBalance = token.balanceOf(alice);
        vm.prank(alice);
        token.unstake(50 ether);

        assertEq(token.stakingBalance(alice), 50 ether);
        assertEq(token.balanceOf(alice), initialBalance + 50 ether);
    }

    function testRewardCalculation() public {
        uint256 stakeAmount = 100 ether;
        vm.prank(minter);
        token.mint(alice, stakeAmount);

        vm.prank(alice);
        token.stake(stakeAmount);

        // Simulate passing time (e.g., 1 hour)
        uint256 timePassed = 1 hours;
        vm.warp(block.timestamp + timePassed);

        uint256 reward = token.calculateRewards(alice);
        assertGt(reward, 0);
    }

    function testClaimRewards() public {
        uint256 stakeAmount = 100 ether;
        vm.prank(minter);
        token.mint(alice, stakeAmount);

        vm.prank(alice);
        token.stake(stakeAmount);

        uint256 timestampBefore = token.stakingTimestamp(alice);

        uint256 timePassed = 1 hours;
        vm.warp(timestampBefore + timePassed);

        uint256 initialBalance = token.balanceOf(alice);
        uint256 reward = token.calculateRewards(alice);
        
        assertGt(reward, 0, "Reward should be greater than zero after sufficient time.");

        vm.prank(alice);
        token.claimReward();

        uint256 newBalance = token.balanceOf(alice);

        // Ensure the new balance is increased by the claimed reward
        assertEq(newBalance, initialBalance + reward);
    }
}
