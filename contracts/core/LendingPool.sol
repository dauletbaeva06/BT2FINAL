// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../libraries/MathUtils.sol";

/**
 * @title LendingPool
 * @dev Реализует паттерны: Access Control, Reentrancy Guard, Checks-Effects-Interactions.
 */
contract LendingPool is Ownable, ReentrancyGuard {
    using MathUtils for uint256;

    mapping(address => uint256) public userBalances;
    uint256 public totalLiquidity;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    // В конструкторе передаем msg.sender для инициализации Ownable
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Депозит токенов в пул.
     * Демонстрирует паттерн Checks-Effects-Interactions.
     */
    function deposit(address token, uint256 amount) external nonReentrant {
        // 1. Checks (Проверки)
        require(amount > 0, "LendingPool: Amount must be > 0");
        require(token != address(0), "LendingPool: Invalid token address");

        // 2. Effects (Изменение внутреннего состояния)
        userBalances[msg.sender] += amount;
        totalLiquidity += amount;

        // 3. Interactions (Внешние вызовы)
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "LendingPool: Transfer failed");

        emit Deposited(msg.sender, amount);
    }

    /**
     * @notice Снятие токенов.
     * Защищено ReentrancyGuard.
     */
    function withdraw(address token, uint256 amount) external nonReentrant {
        // 1. Checks
        require(userBalances[msg.sender] >= amount, "LendingPool: Insufficient balance");

        // 2. Effects
        userBalances[msg.sender] -= amount;
        totalLiquidity -= amount;

        // 3. Interactions
        bool success = IERC20(token).transfer(msg.sender, amount);
        require(success, "LendingPool: Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    // Пример функции под управлением администратора (Access Control)
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        require(IERC20(token).transfer(owner(), amount), "Transfer failed");
    }
}