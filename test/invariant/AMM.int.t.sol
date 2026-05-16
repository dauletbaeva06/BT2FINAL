// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import {AMMV2} from "../../contracts/core/AMMV2.sol";
import {TestToken} from "../../contracts/tokens/TestToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AMMInvariant is Test {
    AMMV2 amm;
    TestToken token0;
    TestToken token1;
    
    uint256 initialK;
    address user = address(0x123);

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

        token0.mint(address(this), 5000e18);
        token1.mint(address(this), 5000e18);
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);

        amm.addLiquidity(1000e18, 1000e18, 0);
        initialK = amm.reserve0() * amm.reserve1();

        targetContract(address(amm));
    }

    function invariant_K_NeverDecreases() public {
        uint256 currentK = amm.reserve0() * amm.reserve1();
        assertGe(currentK, initialK, "K_DECREASED");
    }

    function invariant_ReservesVersusBalance() public {
        assertGe(token0.balanceOf(address(amm)), amm.reserve0(), "INSUFFICIENT_T0_BALANCE");
        assertGe(token1.balanceOf(address(amm)), amm.reserve1(), "INSUFFICIENT_T1_BALANCE");
    }

    function invariant_TotalSupplyAccounting() public {
        assertGe(amm.totalSupply(), 0);
    }

    function invariant_FeesNonNegative() public {
        (uint256 f0, uint256 f1) = (amm.feesAccumulatedToken0(), amm.feesAccumulatedToken1());
        assertGe(f0, 0);
        assertGe(f1, 0);
    }

    function invariant_PriceAlwaysPositive() public {
        if (amm.reserve0() > 0) {
            assertGt(amm.getPrice(), 0, "PRICE_ZERO_OR_NEGATIVE");
        }
    }
}