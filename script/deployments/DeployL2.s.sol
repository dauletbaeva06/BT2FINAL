// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

import "../../contracts/core/AMM.sol";
import "../../contracts/core/AMMFactory.sol";
import "../../contracts/governance/GovernanceToken.sol";
import "../../contracts/oracles/mocks/MockERC20.sol";

contract DeployL2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        GovernanceToken govToken = new GovernanceToken(deployer);

        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");

        AMMFactory factory = new AMMFactory();

        address pairAddress =
            factory.createPairCREATE(address(tokenA), address(tokenB));

        AMM pair = AMM(pairAddress);

        tokenA.approve(address(pair), 1000 ether);
        tokenB.approve(address(pair), 1000 ether);

        pair.addLiquidity(
            1000 ether,
            1000 ether,
            1
        );

        vm.stopBroadcast();

        console.log("GovernanceToken deployed at:", address(govToken));
        console.log("TokenA deployed at:", address(tokenA));
        console.log("TokenB deployed at:", address(tokenB));
        console.log("AMMFactory deployed at:", address(factory));
        console.log("AMM Pair deployed at:", pairAddress);
    }
}