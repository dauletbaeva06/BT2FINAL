// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";

contract ChainlinkPriceFeed {
    AggregatorV3Interface public priceFeed;
    uint256 public stalenessThreshold;

    error StalePrice();
    error InvalidRoundData();
    error ZeroAddress();

    event PriceUpdated(int256 price, uint256 timestamp);
    event StalenessThresholdUpdated(uint256 newThreshold);

    constructor(address _priceFeed, uint256 _stalenessThreshold) {
        if (_priceFeed == address(0)) revert ZeroAddress();
        priceFeed = AggregatorV3Interface(_priceFeed);
        stalenessThreshold = _stalenessThreshold;
    }

    function getLatestPrice() public view returns (int256 price, uint256 updatedAt) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 timestamp, uint80 answeredInRound) = priceFeed.latestRoundData();

        if (answer <= 0) revert InvalidRoundData();
        if (timestamp == 0) revert InvalidRoundData();
        if (timestamp > block.timestamp) revert StalePrice();
        if (block.timestamp - timestamp > stalenessThreshold) revert StalePrice();
        if (answeredInRound < roundId) revert InvalidRoundData();

        return (answer, timestamp);
    }

    function getPriceInUsd(uint256 amountInToken, uint8 tokenDecimals) external view returns (uint256) {
        (int256 price, ) = getLatestPrice();
        return (amountInToken * uint256(price) * 1e18) / (10 ** tokenDecimals) / 1e8;
    }

    function setStalenessThreshold(uint256 _newThreshold) external {
        stalenessThreshold = _newThreshold;
        emit StalenessThresholdUpdated(_newThreshold);
    }
}