// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {AMM} from "./AMM.sol";
import {IFactory} from "../interfaces/IFactory.sol";

contract AMMFactory is IFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    uint256 private salt;

    event PairCreatedCREATE(
        address indexed token0,
        address indexed token1,
        address indexed pair,
        uint256 pairCount
    );

    event PairCreatedCREATE2(
        address indexed token0,
        address indexed token1,
        address indexed pair,
        uint256 pairCount
    );

    error IdenticalTokens();
    error PairExists();
    error InvalidTokenAddress();

    function createPairCREATE(address _token0, address _token1) external returns (address pair){
        if (_token0 == address(0) || _token1 == address(0)) {
            revert InvalidTokenAddress();
        }
        if (_token0 == _token1) {
            revert IdenticalTokens();
        }

        if (_token0 > _token1) {
            (_token0, _token1) = (_token1, _token0);
        }

        if (getPair[_token0][_token1] != address(0)) {
            revert PairExists();
        }

        pair = address(new AMM(_token0, _token1, "AMM-LP", "ALP"));

        getPair[_token0][_token1] = pair;
        allPairs.push(pair);

        emit PairCreatedCREATE(_token0, _token1, pair, allPairs.length);
    }

    function createPairCREATE2(address _token0, address _token1) external returns (address pair){
        if (_token0 == address(0) || _token1 == address(0)) {
            revert InvalidTokenAddress();
        }
        if (_token0 == _token1) {
            revert IdenticalTokens();
        }

        if (_token0 > _token1) {
            (_token0, _token1) = (_token1, _token0);
        }

        if (getPair[_token0][_token1] != address(0)) {
            revert PairExists();
        }

        salt++;

        pair = address(new AMM{salt: bytes32(salt)}(_token0, _token1, "AMM-LP", "ALP"));

        getPair[_token0][_token1] = pair;
        allPairs.push(pair);

        emit PairCreatedCREATE2(_token0, _token1, pair, allPairs.length);
    }

    function predictAddress(address _token0, address _token1) external view returns (address predicted){
        if (_token0 > _token1) {
            (_token0, _token1) = (_token1, _token0);
        }

        uint256 nextSalt = salt + 1;
        bytes memory bytecode = type(AMM).creationCode;
        bytes memory constructorArgs = abi.encode(_token0, _token1, "AMM-LP", "ALP");
        bytes memory fullBytecode = abi.encodePacked(bytecode, constructorArgs);

        bytes32 bytecodeHash = keccak256(fullBytecode);
        
        predicted = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            bytes32(nextSalt),
                            bytecodeHash
                        )
                    )
                )
            )
        );
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}

