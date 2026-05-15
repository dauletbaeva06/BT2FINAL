// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

interface IAMM {
    function swapToken0ForToken1(uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut);
    function swapToken1ForToken0(uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut);
    function addLiquidity(uint256 amount0, uint256 amount1, uint256 minLPTokens) external returns (uint256 lpTokensMinted);
    function removeLiquidity(uint256 lpTokens, uint256 minAmount0, uint256 minAmount1) external returns (uint256 amount0, uint256 amount1);
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);
    function getK() external view returns (uint256);
    function getPrice() external view returns (uint256);
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256);
    function withdrawFees(address _recipient) external returns (uint256 amount0, uint256 amount1);
}