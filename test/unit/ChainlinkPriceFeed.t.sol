// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../contracts/oracles/ChainlinkPriceFeed.sol";
import "../../contracts/oracles/mocks/MockChainlinkAggregator.sol";

contract ChainlinkPriceFeedTest is Test {
    ChainlinkPriceFeed public priceFeed;
    MockChainlinkAggregator public mockAggregator;
    uint256 public constant STALENESS_THRESHOLD = 3600; // 1 hour

    function setUp() public {
        mockAggregator = new MockChainlinkAggregator(2000e8); // $2000
        priceFeed = new ChainlinkPriceFeed(
            address(mockAggregator),
            STALENESS_THRESHOLD
        );
    }

    function test_GetLatestPrice() public view {
        (int256 price, uint256 timestamp) = priceFeed.getLatestPrice();
        assertEq(price, 2000e8);
        assertTrue(timestamp > 0);
    }

    function test_StalePriceReverts() public {
        mockAggregator.setStale(STALENESS_THRESHOLD + 1);
        vm.expectRevert(ChainlinkPriceFeed.StalePrice.selector);
        priceFeed.getLatestPrice();
    }

    function test_GetPriceInUsd() public view {
        uint256 usdValue = priceFeed.getPriceInUsd(1e18, 18);
        assertEq(usdValue, 2000e18);
    }

    function test_ZeroAddressReverts() public {
        vm.expectRevert(ChainlinkPriceFeed.ZeroAddress.selector);
        new ChainlinkPriceFeed(address(0), STALENESS_THRESHOLD);
    }
}