// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import '../src/SimpleToken.sol';
import '../src/MasterchefExternalRewards.sol';

contract MasterchefTest is Test {
  uint256 initialSupply = 1_000_000 ether;
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
  }

  function initialSetup() internal {
    uint256 rewardAmount = initialSupply / 10;

    stakeToken.approve(address(mc), type(uint256).max);
    rewardToken.approve(address(mc), type(uint256).max);
    mc.setRewardDistributor(address(this));
    mc.add(1, address(stakeToken), true);
    mc.updateRewards(rewardAmount);
  }
}
