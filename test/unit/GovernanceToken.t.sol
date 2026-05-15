// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/governance/GovernanceToken.sol";

contract GovernanceTokenTest is Test {
    GovernanceToken public token;
    address public owner = address(0x123);
    address public user1 = address(0x456);
    address public user2 = address(0x789);

    function setUp() public {
        vm.prank(owner);
        token = new GovernanceToken(owner);
    }

    function test_InitialSupply() public view {
        assertEq(token.totalSupply(), 1_000_000 * 10 ** 18);
        assertEq(token.balanceOf(owner), 1_000_000 * 10 ** 18);
    }

    function test_Mint() public {
        vm.prank(owner);
        token.mint(user1, 1000 * 10 ** 18);
        assertEq(token.balanceOf(user1), 1000 * 10 ** 18);
    }

    function test_Burn() public {
        vm.prank(owner);
        token.burn(owner, 1000 * 10 ** 18);
        assertEq(token.balanceOf(owner), 999_000 * 10 ** 18);
    }

    function test_NonMinterCannotMint() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, 1000 * 10 ** 18);
    }

    function test_Delegation() public {
        vm.prank(owner);
        token.delegate(user1);
        assertEq(token.delegates(owner), user1);
    }

    function test_VotingPower() public {
        vm.prank(owner);
        token.delegate(user1);
        uint256 votes = token.getVotes(user1);
        assertEq(votes, 1_000_000 * 10 ** 18);
    }

    function test_TokenMetadata() public view {
        assertEq(token.name(), "Governance Token");
        assertEq(token.symbol(), "GOV");
        assertEq(token.decimals(), 18);
    }

    function test_ApproveAndAllowance() public {
        vm.prank(owner);
        token.approve(user1, 500e18);
        assertEq(token.allowance(owner, user1), 500e18);
    }

    function test_TransferSuccess() public {
        vm.prank(owner);
        token.transfer(user1, 1000e18);
        assertEq(token.balanceOf(user1), 1000e18);
        assertEq(token.balanceOf(owner), 999_000e18);
    }

    function test_Revert_TransferInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 1e18);
    }

    function test_TransferUpdatesVotes() public {
        vm.prank(owner);
        token.delegate(owner);
        uint256 initialVotes = token.getVotes(owner);

        vm.prank(owner);
        token.transfer(user1, 200_000e18);

        assertEq(token.getVotes(owner), initialVotes - 200_000e18);
    }

    function test_DelegateToZeroAddress() public {
        vm.prank(owner);
        token.delegate(address(0));
        assertEq(token.delegates(owner), address(0));
    }

    function test_NumCheckpoints() public {
        vm.prank(owner);
        token.delegate(user1); // Первый чекпоинт
        
        uint256 nCheckpoints = token.numCheckpoints(user1);
        assertEq(nCheckpoints, 1);
    }

    function test_VotesAfterMultipleTransfers() public {
        vm.prank(owner);
        token.delegate(owner);
        
        vm.prank(owner);
        token.transfer(user1, 100e18);
        
        vm.prank(owner);
        token.transfer(user2, 100e18);
        
        assertEq(token.getVotes(owner), 999_800e18);
    }


    function test_TransferOwnership() public {
        vm.prank(owner);
        token.transferOwnership(user1);
        assertEq(token.owner(), user1);
    }

    function test_RenounceOwnership() public {
        vm.prank(owner);
        token.renounceOwnership();
        assertEq(token.owner(), address(0));
    }

    function test_Revert_NonOwnerCannotMint() public {
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, 1000 * 10 ** 18);
    }


    function test_BalanceOfNewUserIsZero() public view {
        assertEq(token.balanceOf(address(0xdeadbeef)), 0);
    }

    function test_BurnFromUserByOwner() public {
        vm.prank(owner);
        token.mint(user1, 500e18);
        
        vm.prank(owner);
        token.burn(user1, 200e18);
        
        assertEq(token.balanceOf(user1), 300e18);
    }

    function test_TotalSupplyAfterBurn() public {
        uint256 supplyBefore = token.totalSupply();
        vm.prank(owner);
        token.burn(owner, 100_000e18);
        assertEq(token.totalSupply(), supplyBefore - 100_000e18);
    }

    function test_Name() public view { assertEq(token.name(), "Governance Token"); }
    function test_Symbol() public view { assertEq(token.symbol(), "GOV"); }
    function test_Decimals() public view { assertEq(token.decimals(), 18); }

    function test_MultipleMints() public {
        vm.startPrank(owner);
        for(uint i=1; i<11; i++) {
            token.mint(address(uint160(i)), 100);
            assertEq(token.balanceOf(address(uint160(i))), 100);
        }
        vm.stopPrank();
    }

    function test_ApproveAllowance() public {
        vm.prank(owner);
        token.approve(user1, 1000);
        assertEq(token.allowance(owner, user1), 1000);
    }

    function test_TransferFromSuccess() public {
        vm.prank(owner);
        token.approve(address(this), 500);
        token.transferFrom(owner, user1, 500);
        assertEq(token.balanceOf(user1), 500);
    }
}