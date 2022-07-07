// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Test.sol';
import '../src/SimpleToken.sol';

contract SimpleTokenTest is Test {
  uint256 initialSupply = 1_000_000 ether;
  SimpleToken token = new SimpleToken('token', 'tkn', initialSupply);

  function setUp() public {}

  function testBalance() public {
    assertEq(token.balanceOf(address(this)), initialSupply);
  }
}
