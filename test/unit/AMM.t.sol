// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {AMM} from "../../contracts/core/AMM.sol";
import {TestToken} from "../../contracts/tokens/TestToken.sol";

contract AMMTest is Test {
    AMM amm;
    TestToken token0;
    TestToken token1;
    
    address owner = address(1);
    address user = address(2);

    function setUp() public {
        vm.startPrank(owner);
        token0 = new TestToken("Token0", "T0", 1_000_000e18);
        token1 = new TestToken("Token1", "T1", 1_000_000e18);
        
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }

        amm = new AMM(address(token0), address(token1), "LP Token", "LPT");
        
        token0.transfer(user, 10000e18);
        token1.transfer(user, 10000e18);
        vm.stopPrank();
    }

    function test_Revert_RemoveLiquidity_ZeroAmount() public {
        vm.prank(user);
        vm.expectRevert(AMM.ZeroAmount.selector);
        amm.removeLiquidity(0, 0, 0);
    }

    function test_Revert_AddLiquidity_InvalidSlippage() public {
        vm.startPrank(user);
        token0.approve(address(amm), 100e18);
        token1.approve(address(amm), 100e18);
        
        vm.expectRevert(AMM.InvalidSlippage.selector);
        amm.addLiquidity(100e18, 100e18, 200e18);
        vm.stopPrank();
    }

    function test_Revert_Swap_InvalidSlippage() public {
        _initialLiquidity();

        vm.startPrank(user);
        uint256 amountIn = 10e18;
        token0.approve(address(amm), amountIn);
        
        vm.expectRevert(AMM.InvalidSlippage.selector);
        amm.swapToken0ForToken1(amountIn, 100e18);
        vm.stopPrank();
    }

    function test_Revert_WithdrawFees_NotOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user));
        amm.withdrawFees(user);
    }

    function test_Revert_WithdrawFees_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(AMM.InvalidTokenAddress.selector);
        amm.withdrawFees(address(0));
    }

    function test_GetPrice_UpdateAfterSwap() public {
        _initialLiquidity();
        uint256 priceBefore = amm.getPrice();
    
        vm.startPrank(user);
        token0.approve(address(amm), 500e18);
        amm.swapToken0ForToken1(500e18, 0);
        vm.stopPrank();
    
        uint256 priceAfter = amm.getPrice();
    
        assertLt(priceAfter, priceBefore, "Price should decrease after adding supply of token0");
    }

    function _initialLiquidity() internal {
        vm.startPrank(user);
        token0.approve(address(amm), 1000e18);
        token1.approve(address(amm), 1000e18);
        amm.addLiquidity(1000e18, 1000e18, 0);
        vm.stopPrank();
    }

    function test_SwapToken1ForToken0_Success() public {
        _initialLiquidity();
        vm.startPrank(user);
        token1.approve(address(amm), 10e18);
        uint256 amountOut = amm.swapToken1ForToken0(10e18, 0);
        assertGt(amountOut, 0);
        vm.stopPrank();
    }

    function testFuzz_AddLiquidity(uint256 amount) public {
        amount = bound(amount, 1e18, 1000e18);
        vm.startPrank(owner);
        token0.mint(user, amount);
        token1.mint(user, amount);
        vm.stopPrank();

        vm.startPrank(user);
        token0.approve(address(amm), amount);
        token1.approve(address(amm), amount);
        uint256 lp = amm.addLiquidity(amount, amount, 0);
        assertGt(lp, 0);
        vm.stopPrank();
    }

    function test_Revert_Constructor_SameTokens() public {
        vm.expectRevert(AMM.IdenticalTokens.selector);
        new AMM(address(token0), address(token0), "LP", "LP");
    }
    
    function test_Revert_Constructor_ZeroAddress() public {
        vm.expectRevert(AMM.InvalidTokenAddress.selector);
        new AMM(address(0), address(token1), "LP", "LP");
    }
}