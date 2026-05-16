// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import {AMMV2} from "../../contracts/core/AMMV2.sol";
import {TestToken} from "../../contracts/tokens/TestToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AMMProxyFuzzTest is Test {
    AMMV2 amm;
    TestToken token0;
    TestToken token1;

    address owner = address(this);
    address user = address(0x789);

    function setUp() public {
        token0 = new TestToken("Token0", "T0", 18);
        token1 = new TestToken("Token1", "T1", 18);

        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }

        AMMV2 implementation = new AMMV2();
        bytes memory data = abi.encodeWithSelector(
            AMMV2.initialize.selector,
            address(token0),
            address(token1),
            "LP Token",
            "LPT"
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), data);
        amm = AMMV2(address(proxy));

        token0.mint(owner, 50000e18);
        token1.mint(owner, 50000e18);
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);

        amm.addLiquidity(10000e18, 10000e18, 0);
    }

    function testFuzz_RemoveLiquidityWithdrawsCorrectAmounts(uint256 lpAmount) public {
        uint256 totalSupply = amm.totalSupply();
        lpAmount = bound(lpAmount, 1, totalSupply - 1);

        (uint256 amount0, uint256 amount1) = amm.removeLiquidity(lpAmount, 0, 0);

        assertGt(amount0, 0);
        assertGt(amount1, 0);
    }

    function testFuzz_PriceUpdatesWithReserves(uint256 swapAmount) public {
        swapAmount = bound(swapAmount, 1e10, 100e18);
        
        uint256 priceBefore = amm.getPrice();
        
        token0.mint(user, swapAmount);
        vm.prank(user);
        token0.approve(address(amm), swapAmount);
        vm.prank(user);
        amm.swapToken0ForToken1(swapAmount, 0);
        
        uint256 priceAfter = amm.getPrice();
        assertGt(priceAfter, priceBefore, "Price should increase after token0 input");
    }

    function testFuzz_KInvariantApproximation(uint256 addAmt) public {
        addAmt = bound(addAmt, 1e18, 100e18);
        
        uint256 kBefore = amm.getK();
        
        amm.addLiquidity(addAmt, addAmt, 0);
        
        uint256 kAfter = amm.getK();
        assertGe(kAfter, kBefore, "K should increase or stay same after liquidity addition");
    }

    function testFuzz_SwapWithinBounds(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e10, 100e18);
        
        (uint256 r0Before, uint256 r1Before) = amm.getReserves();
        
        token0.mint(user, amountIn);
        vm.prank(user);
        token0.approve(address(amm), amountIn);
        vm.prank(user);
        uint256 amountOut = amm.swapToken0ForToken1(amountIn, 0);
        
        (uint256 r0After, uint256 r1After) = amm.getReserves();
        
        assertEq(r0After, r0Before + amountIn);
        assertEq(r1After, r1Before - amountOut);
    }
}
