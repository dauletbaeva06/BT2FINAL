// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

library Constants {
    uint256 public constant SWAP_FEE_BPS = 3;
    uint256 public constant BPS_DENOMINATOR = 1000;

    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    uint256 public constant MAX_RESERVE = type(uint128).max;
}
