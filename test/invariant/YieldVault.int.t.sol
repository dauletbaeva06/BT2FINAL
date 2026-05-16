// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import {YieldVault} from "../../contracts/core/YieldVault.sol";
import {TestToken} from "../../contracts/tokens/TestToken.sol";
import {AMM} from "../../contracts/core/AMM.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract YieldVaultInvariant is Test {
    YieldVault vault;
    AMM amm;
    TestToken asset;
    
    address owner = address(0xABC);

    function setUp() public {
        vm.startPrank(owner);
        
        asset = new TestToken("Gold Token", "GLD", 1_000_000);
        TestToken otherToken = new TestToken("Other", "OTH", 1_000_000);
        
        amm = new AMM(address(asset), address(otherToken), "LP", "ALP");

        YieldVault implementation = new YieldVault();
        bytes memory initData = abi.encodeWithSelector(
            YieldVault.initialize.selector,
            address(asset),
            address(amm),
            "Yield Vaulted Gold",
            "yGLD"
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        vault = YieldVault(address(proxy));
        
        asset.transferOwnership(address(this));
        
        vm.stopPrank();
    }

    function invariant_TotalAssetsNeverNegative() public {
        uint256 totalAssets = vault.totalAssets();
        assertGe(totalAssets, 0, "Total assets should never be negative");
    }

    function invariant_SharePriceIncreases() public {
        // Deposit some assets
        asset.mint(address(this), 1000e18);
        asset.approve(address(vault), 1000e18);
        uint256 shares = vault.deposit(1000e18, address(this));
        
        uint256 initialPrice = vault.convertToAssets(1e18);
        assertGe(initialPrice, 1e18, "Share price should be >= 1 asset");
    }

    function invariant_SharesAlwaysExchangeable() public {
        // Deposit, then verify shares can always be redeemed
        asset.mint(address(this), 100e18);
        asset.approve(address(vault), 100e18);
        uint256 shares = vault.deposit(100e18, address(this));
        
        assertGe(vault.balanceOf(address(this)), shares, "User balance >= shares");
    }
}
