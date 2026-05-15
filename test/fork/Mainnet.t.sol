// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MainnetForkTest is Test {
    address constant ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_WHALE = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;

    string MAINNET_RPC_URL = "https://eth-mainnet.g.alchemy.com/v2/oa9OpkybazdBk0bRRSo7b";

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL);
    }

    function testFork_ChainlinkPrice() public {
        (,int price,,,) = AggregatorV3Interface(ETH_USD_FEED).latestRoundData();
        
        assertGt(price, 0, "Chainlink price should be positive");
        uint256 ethPrice = uint256(price) / 1e8;
        console.log("Current ETH Price on Mainnet: $%s", ethPrice);
    }

    function testFork_WhaleBalance() public {
        uint256 balance = IERC20(USDC).balanceOf(USDC_WHALE);
        assertGt(balance, 0, "Whale should have positive USDC balance");
    }

    function testFork_SimulateTransfer() public {
        uint256 amount = 100 * 1e6; // 100 USDC (6 decimals)
        
        uint256 initialBalance = IERC20(USDC).balanceOf(address(this));
        
        vm.prank(USDC_WHALE);
        IERC20(USDC).transfer(address(this), amount);
        
        assertEq(IERC20(USDC).balanceOf(address(this)), initialBalance + amount);
        console.log("Successfully 'borrowed' 100 USDC from a whale!");
    }
}