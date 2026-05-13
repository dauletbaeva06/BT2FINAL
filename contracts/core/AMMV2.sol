// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AMM} from "./AMM.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract AMMV2 is AMM, UUPSUpgradeable, Ownable {
    bool public flashLoanEnabled;
    uint256 public flashLoanFee; // in BPS (100 = 1%)

    event FlashLoan(address indexed receiver, uint256 amount0, uint256 amount1, uint256 fee);

    error FlashLoanNotEnabled();
    error InvalidFlashLoanReturn();

    function initializeV2() external onlyOwner {
        flashLoanEnabled = true;
        flashLoanFee = 5; // 0.5%
    }

    function flashLoan(
        address receiver,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external returns (bool) {

        if (!flashLoanEnabled) revert FlashLoanNotEnabled();
        if (amount0 == 0 && amount1 == 0) revert ZeroAmount();

        uint256 fee0 = (amount0 * flashLoanFee) / 10000;
        uint256 fee1 = (amount1 * flashLoanFee) / 10000;

        uint256 balanceBefore0 = token0.balanceOf(address(this));
        uint256 balanceBefore1 = token1.balanceOf(address(this));

        reserve0 -= amount0;
        reserve1 -= amount1;

        if (amount0 > 0) {
            token0.transfer(receiver, amount0);
        }
        if (amount1 > 0) {
            token1.transfer(receiver, amount1);
        }

        IFlashLoanReceiver(receiver).executeOperation(
            address(token0),
            address(token1),
            amount0,
            amount1,
            fee0,
            fee1,
            data
        );

        uint256 balanceAfter0 = token0.balanceOf(address(this));
        uint256 balanceAfter1 = token1.balanceOf(address(this));

        if (balanceAfter0 < balanceBefore0 + fee0) revert InvalidFlashLoanReturn();
        if (balanceAfter1 < balanceBefore1 + fee1) revert InvalidFlashLoanReturn();

        reserve0 += amount0;
        reserve1 += amount1;
        feesAccumulatedToken0 += fee0;
        feesAccumulatedToken1 += fee1;

        emit FlashLoan(receiver, amount0, amount1, fee0 + fee1);
        return true;
    }

    function setFlashLoanFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 1000, "Fee too high"); // Max 10%
        flashLoanFee = _newFee;
    }

    function setFlashLoanEnabled(bool _enabled) external onlyOwner {
        flashLoanEnabled = _enabled;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

interface IFlashLoanReceiver {
    function executeOperation(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}
