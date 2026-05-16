// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {AMMV2} from "../../contracts/core/AMMV2.sol";
import {TestToken} from "../../contracts/tokens/TestToken.sol";
import {AMMProxy} from "../../contracts/upgrades/AMMProxy.sol";

contract AMMInvariant is Test {
    AMMV2 amm;
    TestToken token0;
    TestToken token1;
    address owner = address(this);

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
        AMMProxy proxy = new AMMProxy(address(implementation), data);
        amm = AMMV2(address(proxy));

        token0.mint(owner, 10000e18);
        token1.mint(owner, 10000e18);
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);

        amm.addLiquidity(1000e18, 1000e18, 0);
    }

    function test_Invariant_KNeverDecreases() public {
        uint256 kBefore = amm.reserve0() * amm.reserve1();
        amm.swapToken0ForToken1(100e18, 0);
        uint256 kAfter = amm.reserve0() * amm.reserve1();
        assertGe(kAfter, kBefore, "K decreased");
    }

    function test_Invariant_ReservesVsBalance() public {
        uint256 balance0 = token0.balanceOf(address(amm));
        uint256 reserve0 = amm.reserve0();
        assertGe(balance0, reserve0, "Token0 balance < reserve");
    }

    function test_Invariant_FeesNonNegative() public {
        (uint256 f0, uint256 f1) = (amm.feesAccumulatedToken0(), amm.feesAccumulatedToken1());
        assertGe(f0, 0, "Fee0 negative");
        assertGe(f1, 0, "Fee1 negative");
    }

    function test_Invariant_PricePositive() public {
        if (amm.reserve0() > 0) {
            uint256 price = amm.getPrice();
            assertGt(price, 0, "Price zero");
        }
    }

    function test_Invariant_TotalSupplyNonNegative() public {
        assertGe(amm.totalSupply(), 0, "Total supply negative");
    }
}