// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import "../contracts/tokens/TestToken.sol";

contract DeployTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        TestToken tokenA = new TestToken("Gold Token", "GLD", 1_000_000);
        
        TestToken tokenB = new TestToken("Silver Token", "SLV", 1_000_000);

        vm.stopBroadcast();

        console.log("--- Tokens Deployed ---");
        console.log("Token A (GLD) Address:", address(tokenA));
        console.log("Token B (SLV) Address:", address(tokenB));
        console.log("-----------------------");
        console.log("Save these addresses! You will need them for AMM deployment.");
    }
}