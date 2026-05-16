// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {AccessControlManager} from "../../contracts/access/AccessControlManager.sol";

contract AccessControlManagerTest is Test {
    AccessControlManager public acm;
    address public admin = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        vm.startPrank(admin);
        acm = new AccessControlManager(admin);
        vm.stopPrank();
    }

    function test_Constructor_GrantsDefaultAdminRole() public view {
        assertTrue(acm.hasRole(acm.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_GrantRole_Success() public {
        vm.startPrank(admin);
        acm.grantRole(acm.GOVERNOR_ROLE(), user1);
        vm.stopPrank();
        
        assertTrue(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
    }



    function test_RevokeRole_Success() public {
        vm.startPrank(admin);
        acm.grantRole(acm.GOVERNOR_ROLE(), user1);
        assertTrue(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
        
        acm.revokeRole(acm.GOVERNOR_ROLE(), user1);
        vm.stopPrank();
        
        assertFalse(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
    }


    function test_HasRole_GovernorRole() public {
        vm.startPrank(admin);
        acm.grantRole(acm.GOVERNOR_ROLE(), user1);
        vm.stopPrank();
        
        assertTrue(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
    }

    function test_HasRole_TimelockAdminRole() public {
        vm.startPrank(admin);
        acm.grantRole(acm.TIMELOCK_ADMIN_ROLE(), user1);
        vm.stopPrank();
        
        assertTrue(acm.hasRole(acm.TIMELOCK_ADMIN_ROLE(), user1));
    }

    function test_HasRole_ProposerRole() public {
        vm.startPrank(admin);
        acm.grantRole(acm.PROPOSER_ROLE(), user1);
        vm.stopPrank();
        
        assertTrue(acm.hasRole(acm.PROPOSER_ROLE(), user1));
    }

    function test_HasRole_ExecutorRole() public {
        vm.startPrank(admin);
        acm.grantRole(acm.EXECUTOR_ROLE(), user1);
        vm.stopPrank();
        
        assertTrue(acm.hasRole(acm.EXECUTOR_ROLE(), user1));
    }

    function test_HasRole_FeeManagerRole() public {
        vm.startPrank(admin);
        acm.grantRole(acm.FEE_MANAGER_ROLE(), user1);
        vm.stopPrank();
        
        assertTrue(acm.hasRole(acm.FEE_MANAGER_ROLE(), user1));
    }

    function test_HasRole_EmergencyRole() public {
        vm.startPrank(admin);
        acm.grantRole(acm.EMERGENCY_ROLE(), user1);
        vm.stopPrank();
        
        assertTrue(acm.hasRole(acm.EMERGENCY_ROLE(), user1));
    }

    function test_HasRole_NonExistent_ReturnsFalse() public view {
        assertFalse(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
    }

    function test_MultipleRoles_SameUser() public {
        vm.startPrank(admin);
        acm.grantRole(acm.GOVERNOR_ROLE(), user1);
        acm.grantRole(acm.PROPOSER_ROLE(), user1);
        vm.stopPrank();

        assertTrue(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
        assertTrue(acm.hasRole(acm.PROPOSER_ROLE(), user1));
    }
}