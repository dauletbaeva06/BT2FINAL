// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import "../contracts/core/AMMFactory.sol";

contract DeployFactory is Script {
    function run() external {
        vm.startBroadcast();
        AMMFactory factory = new AMMFactory();
        vm.stopBroadcast();

        console.log("--- Factory Deployed ---");
        console.log("Factory Address:", address(factory));
    }
}