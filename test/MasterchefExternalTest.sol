// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import '../src/SimpleToken.sol';
import '../src/MasterchefExternalRewards.sol';

contract MasterchefTest is Test {
  SimpleToken stakeToken;
  SimpleToken rewardToken;
  MasterchefExternalRewards mc;

  address alice = vm.addr(1);
  address bob = vm.addr(2);

  uint256 initialSupply = 1_000_000 ether;
  uint256 rewardAmount = initialSupply / 10;
  uint256 distributionAmount = initialSupply / 2;
  uint256 rewardDuration = 7 days;
  uint256 precision = 1e18;
  uint256 errorMargin = 0.0001e18;

  function setUp() public {
    stakeToken = new SimpleToken('stakeToken', 'stkn', initialSupply);
    rewardToken = new SimpleToken('rewardToken', 'rtkn', initialSupply);
    mc = new MasterchefExternalRewards(address(rewardToken), rewardDuration);
    distributeTokens();
  }

  function testBalances() public {
    assertEq(stakeToken.balanceOf(alice), distributionAmount);
    assertEq(stakeToken.balanceOf(bob), distributionAmount);
    assertEq(rewardToken.balanceOf(address(this)), initialSupply);
  }

  function testDeposit() public {
    setupMasterchef();
    deposit(alice, distributionAmount, 0);
    (uint256 aliceDeposit, ) = mc.userInfo(0, alice);
    assertEq(aliceDeposit, distributionAmount);
  }

  function testSingleRewardAccrue() public {
    uint256 period = 1 days;
    setupMasterchef();
    deposit(alice, distributionAmount, 0);
    vm.warp(block.timestamp + period);
    uint256 rewardRate = (rewardAmount * precision) / rewardDuration;
    assertApproxEqRel(mc.pendingReward(0, alice), (rewardRate * period) / precision, errorMargin);
  }

  function testRewardDepleted() public {
    setupMasterchef();
    deposit(alice, distributionAmount, 0);
    vm.warp(block.timestamp + rewardDuration);
    vm.startPrank(alice);
    mc.withdraw(0, 0);
    assertApproxEqRel(rewardToken.balanceOf(alice), rewardAmount, errorMargin);
    vm.warp(block.timestamp + rewardDuration * 2);
    mc.withdraw(0, distributionAmount);
    assertEq(stakeToken.balanceOf(alice), distributionAmount);
    vm.stopPrank();
  }

  function testAddingRewardsAfterDepletion() public {
    setupMasterchef();
    deposit(alice, distributionAmount, 0);
    vm.warp(block.timestamp + rewardDuration * 2);
    vm.prank(alice);
    mc.withdraw(0, 0);
    assertApproxEqRel(rewardToken.balanceOf(alice), rewardAmount, errorMargin);
    mc.updateRewards(rewardAmount);
    vm.warp(block.timestamp + rewardDuration);
    assertApproxEqRel(mc.pendingReward(0, alice), rewardAmount, errorMargin);
  }

  function deposit(
    address user,
    uint256 amount,
    uint256 pool
  ) internal {
    vm.prank(user);
    mc.deposit(pool, amount);
  }

  function distributeTokens() internal {
    stakeToken.transfer(alice, distributionAmount);
    stakeToken.transfer(bob, distributionAmount);
  }

  function setupMasterchef() internal {
    rewardToken.approve(address(mc), type(uint256).max);
    vm.prank(alice);
    stakeToken.approve(address(mc), type(uint256).max);
    vm.prank(bob);
    stakeToken.approve(address(mc), type(uint256).max);
    mc.setRewardDistributor(address(this));
    mc.add(1, address(stakeToken));
    mc.updateRewards(rewardAmount);
  }
}
