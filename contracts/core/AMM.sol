// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAMM.sol";

contract AMM is IAMM, ERC20, ReentrancyGuard {
    address public token0;
    address public token1;
    uint256 public reserve0;
    uint256 public reserve1;

    constructor(address _token0, address _token1) ERC20("AMM LP Token", "LP-AMM") {
        token0 = _token0;
        token1 = _token1;
    }

    // Реализация функции addLiquidity (которую мы писали ранее)
    function addLiquidity(uint256 amount0, uint256 amount1) 
        external 
        override 
        nonReentrant 
        returns (uint256 lpTokens) 
    {
        require(amount0 > 0 && amount1 > 0, "Amounts must be > 0");
        lpTokens = amount0 + amount1; 
        reserve0 += amount0;
        reserve1 += amount1;
        _mint(msg.sender, lpTokens);
        return lpTokens;
    }

    // НОВОЕ: Реализация getReserves (требование интерфейса)
    function getReserves() external view override returns (uint256 _reserve0, uint256 _reserve1) {
        return (reserve0, reserve1);
    }

    // НОВОЕ: Реализация swap (требование интерфейса)
    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut) 
        external 
        override 
        nonReentrant 
        returns (uint256 amountOut) 
    {
        require(tokenIn == token0 || tokenIn == token1, "Invalid token");
        require(amountIn > 0, "Amount must be > 0");
        
        // Базовая заглушка логики свопа для компиляции
        amountOut = amountIn; 
        require(amountOut >= minAmountOut, "Slippage too high");
        
        return amountOut;
    }
}