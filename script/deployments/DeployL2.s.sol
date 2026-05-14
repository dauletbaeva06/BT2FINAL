// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import "../../contracts/core/AMM.sol";
import "../../contracts/core/AMMFactory.sol";
import "../../contracts/governance/GovernanceToken.sol";

contract DeployL2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        GovernanceToken token = new GovernanceToken(deployer);

        AMMFactory factory = new AMMFactory();

        vm.stopBroadcast();

        console.log("GovernanceToken deployed at:", address(token));
        console.log("AMMFactory deployed at:", address(factory));
    }
}