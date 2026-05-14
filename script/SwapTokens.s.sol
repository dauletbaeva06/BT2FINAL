// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/core/AMMV2.sol"; 

contract SwapTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address pairAddr = 0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968;
        
        vm.startBroadcast(deployerPrivateKey);

        AMMV2 pair = AMMV2(pairAddr);
        IERC20 token0 = IERC20(pair.token0()); 

        uint256 amountIn = 10 * 1e18; 
        uint256 minAmountOut = 0;

        token0.approve(pairAddr, amountIn);

        pair.swapToken0ForToken1(amountIn, minAmountOut);

        vm.stopBroadcast();

        (uint256 res0, uint256 res1) = pair.getReserves();
        console.log("--- Swap Success! ---");
        console.log("New Reserve GLD (token0):", res0 / 1e18);
        console.log("New Reserve SLV (token1):", res1 / 1e18);
        
        uint256 price = pair.getPrice();
        console.log("Current Price (SLV per 1 GLD):", price);
    }
}