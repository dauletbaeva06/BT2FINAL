// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import {GovernanceToken} from "../../contracts/governance/GovernanceToken.sol";

contract GovernanceFuzzTest is Test {
    GovernanceToken govToken;

    address owner = address(this);
    address user = address(0x1337);

    function setUp() public {
        govToken = new GovernanceToken(owner);
    }

    function testFuzz_VotingPower(uint256 amount) public {
        amount = bound(amount, 1, 1_000_000e18);
        govToken.mint(user, amount);
        
        vm.prank(user);
        govToken.delegate(user);
        
        assertEq(govToken.getVotes(user), amount);
    }

    function testFuzz_TransferUpdatesVotes(uint256 transferAmt) public {
        uint256 initial = 1000e18;
        govToken.mint(user, initial);
        transferAmt = bound(transferAmt, 0, initial);
        
        vm.startPrank(user);
        govToken.delegate(user);
        govToken.transfer(address(0x3), transferAmt);
        vm.stopPrank();
        
        assertEq(govToken.getVotes(user), initial - transferAmt);
    }

    function testFuzz_TotalSupply(uint256 mintAmt, uint256 burnAmt) public {
        mintAmt = bound(mintAmt, 1e18, 1e28);
        burnAmt = bound(burnAmt, 0, mintAmt);
        
        vm.prank(owner);
        govToken.mint(user, mintAmt);
        
        vm.prank(owner);
        govToken.burn(user, burnAmt);
        
        uint256 initialSupply = 1_000_000 * 10**18;
        assertEq(govToken.totalSupply(), initialSupply + mintAmt - burnAmt);
    }
}