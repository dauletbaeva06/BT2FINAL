// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {AMMV2} from "../../contracts/core/AMMV2.sol";
import {TestToken} from "../../contracts/tokens/TestToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract AMMV2Test is Test {
    AMMV2 amm;
    TestToken token0;
    TestToken token1;

    address owner = address(this);
    address user = address(0x456);

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

        token0.mint(owner, 10000e18);
        token1.mint(owner, 10000e18);
        token0.approve(address(amm), type(uint256).max);
        token1.approve(address(amm), type(uint256).max);
    }

    function test_Initialize_SetTokens() public {
        assertEq(address(amm.token0()), address(token0));
        assertEq(address(amm.token1()), address(token1));
    }

    function test_Initialize_FlashLoanEnabled() public {
       assertEq(amm.flashLoanEnabled() ? 1 : 0, 1);
    }

    function test_Initialize_FlashLoanFee() public {
        assertEq(amm.flashLoanFee(), 5);
    }

    function test_AddLiquidity_InitialLiquidity() public {
        uint256 lpTokens = amm.addLiquidity(1000e18, 1000e18, 0);
        assertGt(lpTokens, 0);
        assertEq(amm.reserve0(), 1000e18);
        assertEq(amm.reserve1(), 1000e18);
    }

    function test_AddLiquidity_SecondProvider() public {
        amm.addLiquidity(1000e18, 1000e18, 0);
        uint256 lpTokens = amm.addLiquidity(500e18, 500e18, 0);
        assertGt(lpTokens, 0);
    }

    function test_RemoveLiquidity_Success() public {
        uint256 lpMinted = amm.addLiquidity(1000e18, 1000e18, 0);
        (uint256 amount0, uint256 amount1) = amm.removeLiquidity(lpMinted, 0, 0);
        assertEq(amount0, 1000e18);
        assertEq(amount1, 1000e18);
    }

    function test_GetReserves() public {
        amm.addLiquidity(1000e18, 1000e18, 0);
        (uint256 r0, uint256 r1) = amm.getReserves();
        assertEq(r0, 1000e18);
        assertEq(r1, 1000e18);
    }

    function test_GetPrice() public {
        amm.addLiquidity(1000e18, 1000e18, 0);
        uint256 price = amm.getPrice();
        assertEq(price, 1e18);
    }

    function test_GetK() public {
        amm.addLiquidity(1000e18, 1000e18, 0);
        uint256 k = amm.getK();
        assertEq(k, 1000e18 * 1000e18);
    }
}