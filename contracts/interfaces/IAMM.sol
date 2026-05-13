// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAMM {
    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 lpTokens);

    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut);
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 lpTokens);
    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1);
}