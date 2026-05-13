// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFactory {
    function createPairCREATE(address token0, address token1) external returns (address);
    function createPairCREATE2(address token0, address token1) external returns (address);
    function getPair(address token0, address token1) external view returns (address);
    function predictAddress(address token0, address token1) external view returns (address);
}