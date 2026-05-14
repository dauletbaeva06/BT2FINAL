// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import "../contracts/core/AMMFactory.sol";

contract CreatePair is Script {
    function run() external {
        address factoryAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        address tokenA = 0x9b4393C60f2408de53F04d93aD178ffBAF25b202;
        address tokenB = 0x20cf99233e5B16Fba6B0E7bA70768d6EDe75789D;

        vm.startBroadcast();

        AMMFactory factory = AMMFactory(factoryAddr);
        
        address pair = factory.createPairCREATE2(tokenA, tokenB);

        vm.stopBroadcast();

        console.log("--- Pair Created Successfully ---");
        console.log("Pair Address:", pair);
    }
}