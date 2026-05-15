// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import {AMMFactory} from "../../contracts/core/AMMFactory.sol";

contract AMMFactoryTest is Test {
    AMMFactory factory;
    address t0 = address(0x1);
    address t1 = address(0x2);

    function setUp() public {
        factory = new AMMFactory();
    }

    function test_CreatePair_Success() public {
        address pair = factory.createPairCREATE(t0, t1);
        assertNotEq(pair, address(0));
        assertEq(factory.allPairsLength(), 1);
    }

    function test_PredictAddress_Match() public {
        address predicted = factory.predictAddress(t0, t1);
        address actual = factory.createPairCREATE2(t0, t1);
        assertEq(predicted, actual, "Address prediction failed");
    }

    function test_Revert_IdenticalTokens() public {
        vm.expectRevert(AMMFactory.IdenticalTokens.selector);
        factory.createPairCREATE(t0, t0);
    }
}