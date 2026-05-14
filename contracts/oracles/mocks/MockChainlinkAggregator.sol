// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

contract MockChainlinkAggregator {
    int256 public latestAnswer;
    uint256 public latestTimestamp;
    uint80 public latestRoundId;

    constructor(int256 _initialPrice) {
        latestAnswer = _initialPrice;
        latestTimestamp = block.timestamp;
        latestRoundId = 1;
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 timestamp,
            uint80 answeredInRound
        )
    {
        return (latestRoundId, latestAnswer, block.timestamp, latestTimestamp, latestRoundId);
    }

    function setPrice(int256 _newPrice) external {
        latestAnswer = _newPrice;
        latestTimestamp = block.timestamp;
        latestRoundId++;
    }

    function setStale(uint256 _timeAgo) external {
        unchecked {
            latestTimestamp = block.timestamp - _timeAgo;
        }
    }
}