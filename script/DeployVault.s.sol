// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Script.sol";
import {YieldVault} from "../contracts/core/YieldVault.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployVault is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        address assetToken = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
        address ammPool = 0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968;

        vm.startBroadcast(deployerPrivateKey);

        YieldVault vaultImplementation = new YieldVault();

        bytes memory initData = abi.encodeWithSelector(
            YieldVault.initialize.selector,
            IERC20(assetToken),
            ammPool,
            "Yield Vaulted Gold",
            "yGLD"
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(vaultImplementation),
            initData
        );

        console.log("YieldVault Implementation deployed at:", address(vaultImplementation));
        console.log("YieldVault Proxy (Interact with this) deployed at:", address(proxy));

        vm.stopBroadcast();
    }
}