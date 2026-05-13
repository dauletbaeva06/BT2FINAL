// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AMM.sol";

contract PairFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        (address t0, address t1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[t0][t1] == address(0), "Factory: PAIR_EXISTS");

        bytes32 salt = keccak256(abi.encodePacked(t0, t1));
        pair = address(new AMM{salt: salt}(t0, t1));

        getPair[t0][t1] = pair;
        getPair[t1][t0] = pair;
        allPairs.push(pair);
    }
}