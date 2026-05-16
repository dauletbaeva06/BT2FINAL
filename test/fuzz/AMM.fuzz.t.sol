// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import {AMMV2} from "../../contracts/core/AMMV2.sol";
import {TestToken} from "../../contracts/tokens/TestToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AMMFuzzTest is Test {
    AMMV2 amm;
    TestToken token0;
    TestToken token1;

    address public owner = address(this);
    address public user = address(0x456);

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

        token0.mint(owner, 1000e18);
        token1.mint(owner, 1000e18);
    
        token0.approve(address(amm), 1000e18);
        token1.approve(address(amm), 1000e18);

        amm.addLiquidity(100e18, 100e18, 0);
        targetContract(address(amm));
        }

    function _addLiquidity(uint256 amt0, uint256 amt1) internal {
        vm.startPrank(owner);
        token0.approve(address(amm), amt0);
        token1.approve(address(amm), amt1);
        amm.addLiquidity(amt0, amt1, 0);
        vm.stopPrank();
    }

    function testFuzz_Swap(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e10, 10e18);
        
        token0.mint(user, amountIn);
        
        vm.startPrank(user);
        token0.approve(address(amm), amountIn);
        amm.swapToken0ForToken1(amountIn, 0);
        vm.stopPrank();
    }

    function testFuzz_SlippageRevert(uint256 amountIn, uint256 minOut) public {
        _addLiquidity(100e18, 100e18);
        amountIn = bound(amountIn, 1e10, 10e18);
        minOut = bound(minOut, 50e18, 100e18); // Higher than possible output
        
        token0.mint(user, amountIn);
        vm.startPrank(user);
        token0.approve(address(amm), amountIn);
        
        vm.expectRevert(); 
        amm.swapToken0ForToken1(amountIn, minOut);
        vm.stopPrank();
    }

    function testFuzz_AddLiquidityProportions(uint256 amt0, uint256 amt1) public {
        amt0 = bound(amt0, 1e18, 10000e18);
        amt1 = bound(amt1, 1e18, 10000e18);
        
        token0.mint(user, amt0);
        token1.mint(user, amt1);

        vm.startPrank(user);
        token0.approve(address(amm), amt0);
        token1.approve(address(amm), amt1);
        
        amm.addLiquidity(amt0, amt1, 0);
        vm.stopPrank();
    }

    function testFuzz_FlashLoanFee(uint256 loanAmount) public {
        loanAmount = bound(loanAmount, 1e18, 500e18);
        token0.mint(address(this), 1000e18 + loanAmount + 10e18);
        token1.mint(address(this), 1000e18 + 1000e18);

        token0.approve(address(amm), 1000e18 + loanAmount + 10e18);
        token1.approve(address(amm), 1000e18 + 1000e18);
        amm.addLiquidity(1000e18, 1000e18, 0);
        
        uint256 expectedFee = (loanAmount * amm.flashLoanFee()) / 10000;
        assertGt(expectedFee + loanAmount, loanAmount);
    }
}