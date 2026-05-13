// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library MathUtils {
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        require(denominator > 0, "MathUtils: division by zero");
        result = (x * y) / denominator;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}