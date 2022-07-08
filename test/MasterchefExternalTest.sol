// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import '../src/SimpleToken.sol';
import '../src/MasterchefExternalRewards.sol';

contract MasterchefTest is Test {
  uint256 initialSupply = 1_000_000 ether;
  uint256 rewardAmount = initialSupply / 10;
  SimpleToken stakeToken = new SimpleToken('stakeToken', 'stkn', initialSupply);
  SimpleToken rewardToken = new SimpleToken('rewardToken', 'rtkn', initialSupply);
  MasterchefExternalRewards mc = new MasterchefExternalRewards(address(rewardToken), 1 weeks);

  function setUp() public {}

  function testBalances() public {
    assertEq(stakeToken.balanceOf(address(this)), initialSupply);
    assertEq(rewardToken.balanceOf(address(this)), initialSupply);
  }

  function testScenario01() public {
    initialSetup();
    console.log(block.timestamp);
    vm.warp(block.timestamp + 8 days);
    console.log(block.timestamp);
    uint256 expectedReward = mc.pendingReward(0, address(this));
    uint256 rewardInBalance = rewardToken.balanceOf(address(this));
    console.log('Pending Rewards: ', expectedReward / 1e18);
    mc.withdraw(0, 0);
    assertEq(rewardToken.balanceOf(address(this)), expectedReward + rewardInBalance);
    mc.updateRewards(rewardAmount);
    vm.warp(block.timestamp + 5 days);
    console.log('Pending Rewards: ', mc.pendingReward(0, address(this)) / 1e18);
  }

  function initialSetup() internal {
    stakeToken.approve(address(mc), type(uint256).max);
    rewardToken.approve(address(mc), type(uint256).max);
    mc.setRewardDistributor(address(this));
    mc.add(1, address(stakeToken));
    mc.updateRewards(rewardAmount);
    mc.deposit(0, stakeToken.balanceOf(address(this)));
  }
}
