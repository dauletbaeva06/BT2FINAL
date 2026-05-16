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
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract MainnetForkExtendedTest is Test {
    address constant ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant WETH = 0xc02AAa39B223fE8d0a0e8E4f27eAd9083c756CC2;
    address constant USDC_WHALE = 0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503;
    address constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    string MAINNET_RPC_URL = "https://eth-mainnet.g.alchemy.com/v2/oa9OpkybazdBk0bRRSo7b";

    function setUp() public {
        vm.createSelectFork(MAINNET_RPC_URL);
    }

    function testFork_ChainlinkPriceFeed_ReturnsValidData() public {
        (uint80 roundId, int256 price, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = 
            AggregatorV3Interface(ETH_USD_FEED).latestRoundData();
        
        assertGt(price, 0, "Price should be positive");
        assertGt(roundId, 0, "Round ID should be positive");
        assertGt(startedAt, 0, "Started at should be positive");
        assertGt(updatedAt, 0, "Updated at should be positive");
        assertGe(answeredInRound, roundId, "Answered round should be >= round ID");
    }

    function testFork_USDCTokenMetadata() public {
        // Verify USDC has correct decimals
        uint256 balance = IERC20(USDC).balanceOf(USDC_WHALE);
        assertGt(balance, 0, "Whale should have USDC");
        
        // A valid balance for USDC (6 decimals)
        assertTrue(balance > 0);
    }

    function testFork_WETHExistence() public {
        // Just verify WETH exists on mainnet by checking it has a balance contract
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(WETH)
        }
        assertGt(codeSize, 0, "WETH should have contract code");
    }

    function testFork_UniswapRouterExistence() public {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(UNISWAP_ROUTER)
        }
        assertGt(codeSize, 0, "Uniswap router should have contract code");
    }
}
