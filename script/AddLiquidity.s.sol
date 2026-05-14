// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../contracts/core/AMMV2.sol"; 

contract AddLiquidity is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address pairAddr = 0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968;
        uint256 amount = 100 * 1e18; 

        vm.startBroadcast(deployerPrivateKey);

        AMMV2 pair = AMMV2(pairAddr);
        IERC20 token0 = IERC20(pair.token0());
        IERC20 token1 = IERC20(pair.token1());

        console.log("Deployer:", deployerAddress);
        console.log("Balance Token0:", token0.balanceOf(deployerAddress) / 1e18);
        console.log("Balance Token1:", token1.balanceOf(deployerAddress) / 1e18);

        token0.approve(pairAddr, amount);
        token1.approve(pairAddr, amount);

        pair.addLiquidity(amount, amount, 0);

        vm.stopBroadcast();

        (uint256 res0, uint256 res1) = pair.getReserves();
        console.log("--- Success! ---");
        console.log("Pool Reserve 0:", res0 / 1e18);
        console.log("Pool Reserve 1:", res1 / 1e18);
    }
}