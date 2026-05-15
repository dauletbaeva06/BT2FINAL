// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {YieldVault} from "../../contracts/core/YieldVault.sol";
import {AMM} from "../../contracts/core/AMM.sol";
import {TestToken} from "../../contracts/tokens/TestToken.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract YieldVaultTest is Test {
    YieldVault vault;
    AMM amm;
    TestToken asset;
    TestToken otherToken;
    
    address owner = address(1);
    address user = address(2);

    function setUp() public {
        vm.startPrank(owner);
        
        asset = new TestToken("Gold Token", "GLD", 1_000_000e18);
        otherToken = new TestToken("Other Token", "OTHR", 1_000_000e18);

        amm = new AMM(address(asset), address(otherToken), "LP", "LP");

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

        asset.transfer(user, 1000e18);
        vm.stopPrank();
    }

    function test_Deposit_CorrectShares() public {
        vm.startPrank(user);
        uint256 depositAmount = 100e18;
        asset.approve(address(vault), depositAmount);

        uint256 expectedShares = vault.previewDeposit(depositAmount);
        uint256 actualShares = vault.deposit(depositAmount, user);

        assertEq(actualShares, expectedShares);
        assertEq(vault.balanceOf(user), actualShares);
        assertEq(asset.balanceOf(address(vault)), depositAmount);
        vm.stopPrank();
    }

    function test_Withdraw_CorrectAssets() public {
        vm.startPrank(user);
        uint256 depositAmount = 100e18;
        asset.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);

        uint256 sharesToRedeem = vault.balanceOf(user);
        uint256 expectedAssets = vault.previewRedeem(sharesToRedeem);
        
        uint256 actualAssets = vault.redeem(sharesToRedeem, user, user);

        assertEq(actualAssets, expectedAssets);
        assertEq(vault.balanceOf(user), 0);
        assertEq(asset.balanceOf(user), 1000e18);
        vm.stopPrank();
    }

    function test_Revert_Deposit_ZeroAmount() public {
        vm.startPrank(user);
        uint256 shares = vault.deposit(0, user);
        assertEq(shares, 0, "Should yield 0 shares for 0 assets");
        vm.stopPrank();
    }

    function test_PreviewDeposit_MatchesActual() public {
        uint256 amount = 50e18;
        uint256 previewed = vault.previewDeposit(amount);
        vm.startPrank(user);
        asset.approve(address(vault), amount);
        uint256 actual = vault.deposit(amount, user);
        assertEq(previewed, actual);
        vm.stopPrank();
    }

    function test_Revert_Harvest_NotOwner() public {
        address nonOwner = address(0x999);
        vm.prank(nonOwner);
    
        vm.expectRevert(); 
        vault.harvest();
    }

    function test_MaxDeposit_IsTotalSupply() public {
        assertEq(vault.maxDeposit(user), type(uint256).max);
    }

    function test_Asset_Address() public {
        assertEq(vault.asset(), address(asset));
    }
}