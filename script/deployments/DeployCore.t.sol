// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/core/AMM.sol";
import "../contracts/core/LendingPool.sol";
import "../contracts/vault/YieldVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployCore is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address ethUsdPriceFeed = 0xD3062148e759914E040172e218CC9A2e83Dcc33A;

        LendingPool lendingPool = new LendingPool();

        address wethAddress = 0x4200000000000000000000000000000000000006; 
        YieldVault vault = new YieldVault(
            IERC20(wethAddress),
            ethUsdPriceFeed
        );

        address usdcAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
        AMM amm = new AMM(wethAddress, usdcAddress);

        vm.stopBroadcast();

        console.log("LendingPool deployed at:", address(lendingPool));
        console.log("YieldVault deployed at:", address(vault));
        console.log("AMM deployed at:", address(amm));
    }
}