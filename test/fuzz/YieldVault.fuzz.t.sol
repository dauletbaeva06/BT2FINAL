// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import {YieldVault} from "../../contracts/core/YieldVault.sol";
import {TestToken} from "../../contracts/tokens/TestToken.sol";
import {AMM} from "../../contracts/core/AMM.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract YieldVaultFuzzTest is Test {
    YieldVault vault;
    AMM amm;
    TestToken asset;
    
    address owner = address(0xABC);
    address user = address(0xDEF);

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
        
        // Transfer ownership to test contract for minting
        asset.transferOwnership(address(this));
        
        vm.stopPrank();
    }

    function _userDeposit(uint256 amount) internal {
        asset.mint(user, amount);
        vm.startPrank(user);
        asset.approve(address(vault), amount);
        vault.deposit(amount, user);
        vm.stopPrank();
    }

    function testFuzz_VaultDeposit(uint256 amount) public {
        amount = bound(amount, 1e6, 1_000_000e18);
        asset.mint(user, amount);
        
        vm.startPrank(user);
        asset.approve(address(vault), amount);
        uint256 shares = vault.deposit(amount, user);
        
        assertEq(vault.balanceOf(user), shares);
        assertLe(vault.previewRedeem(shares), amount + 1); 
        vm.stopPrank();
    }

    function testFuzz_VaultRedeem(uint256 depositAmt, uint256 redeemPercent) public {
        depositAmt = bound(depositAmt, 1e18, 1000e18);
        redeemPercent = bound(redeemPercent, 1, 100);
        
        _userDeposit(depositAmt);
        uint256 userShares = vault.balanceOf(user);
        uint256 sharesToRedeem = (userShares * redeemPercent) / 100;
        
        if (sharesToRedeem > 0) {
            vm.prank(user);
            vault.redeem(sharesToRedeem, user, user);
            assertEq(vault.balanceOf(user), userShares - sharesToRedeem);
        }
    }

    function testFuzz_SharePrice(uint256 assetsInVault) public {
        _userDeposit(1e18);
        
        assetsInVault = bound(assetsInVault, 1e18, 10000e18);
        asset.mint(address(vault), assetsInVault);
        
        uint256 assetsForOneShare = vault.convertToAssets(1e18);
        assertGt(assetsForOneShare, 0, "Share price should be positive");
    }
}