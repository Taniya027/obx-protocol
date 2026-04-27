// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/OBXToken.sol";
import "../src/OBXVesting.sol";

contract OBXTest is Test {
    OBXToken token;
    address owner = address(this);
    address rewards = address(0xABC);
    uint256 start;

    function setUp() public {
        start = block.timestamp;
        token = new OBXToken(
            rewards, address(0x1), address(0x2), address(0x3), 
            address(0x4), address(0x5), address(0x6), address(0x7), 
            address(0x8), start
        );
    }

    function testInitialSupply() public {
    uint256 supply = token.totalSupply();
    assertEq(supply, 1_000_000_000 * 1e18);
}

function testVestingDeployment() public { 
    address vestingAddr = token.vestings("rewards");
    assertTrue(vestingAddr != address(0));
}
}