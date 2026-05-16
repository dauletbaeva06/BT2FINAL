// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import "forge-std/Test.sol";
import {AccessControlManager} from "../../contracts/access/AccessControlManager.sol";

contract AccessControlManagerTest is Test {
    AccessControlManager acm;
    address admin = address(0x1);
    address user1 = address(0x2);
    address user2 = address(0x3);

    function setUp() public {
        acm = new AccessControlManager(admin);
    }

    function test_Constructor_GrantsDefaultAdminRole() public {
        assertTrue(acm.hasRole(acm.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_GrantRole_Success() public {
        vm.prank(admin);
        acm.grantRole(acm.GOVERNOR_ROLE(), user1);
        assertTrue(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
    }

    function test_GrantRole_NonAdminReverts() public {
        vm.prank(user1);
        vm.expectRevert();
        acm.grantRole(acm.GOVERNOR_ROLE(), user2);
    }

    function test_RevokeRole_Success() public {
        vm.prank(admin);
        acm.grantRole(acm.GOVERNOR_ROLE(), user1);
        assertTrue(acm.hasRole(acm.GOVERNOR_ROLE(), user1));

        vm.prank(admin);
        acm.revokeRole(acm.GOVERNOR_ROLE(), user1);
        assertFalse(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
    }

    function test_RevokeRole_NonAdminReverts() public {
        vm.prank(admin);
        acm.grantRole(acm.GOVERNOR_ROLE(), user1);

        vm.prank(user2);
        vm.expectRevert();
        acm.revokeRole(acm.GOVERNOR_ROLE(), user1);
    }

    function test_HasRole_GovernorRole() public {
        vm.prank(admin);
        acm.grantRole(acm.GOVERNOR_ROLE(), user1);
        assertTrue(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
    }

    function test_HasRole_TimelockAdminRole() public {
        vm.prank(admin);
        acm.grantRole(acm.TIMELOCK_ADMIN_ROLE(), user1);
        assertTrue(acm.hasRole(acm.TIMELOCK_ADMIN_ROLE(), user1));
    }

    function test_HasRole_ProposerRole() public {
        vm.prank(admin);
        acm.grantRole(acm.PROPOSER_ROLE(), user1);
        assertTrue(acm.hasRole(acm.PROPOSER_ROLE(), user1));
    }

    function test_HasRole_ExecutorRole() public {
        vm.prank(admin);
        acm.grantRole(acm.EXECUTOR_ROLE(), user1);
        assertTrue(acm.hasRole(acm.EXECUTOR_ROLE(), user1));
    }

    function test_HasRole_FeeManagerRole() public {
        vm.prank(admin);
        acm.grantRole(acm.FEE_MANAGER_ROLE(), user1);
        assertTrue(acm.hasRole(acm.FEE_MANAGER_ROLE(), user1));
    }

    function test_HasRole_EmergencyRole() public {
        vm.prank(admin);
        acm.grantRole(acm.EMERGENCY_ROLE(), user1);
        assertTrue(acm.hasRole(acm.EMERGENCY_ROLE(), user1));
    }

    function test_HasRole_NonExistent_ReturnsFalse() public {
        assertFalse(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
    }

    function test_MultipleRoles_SameUser() public {
        vm.prank(admin);
        acm.grantRole(acm.GOVERNOR_ROLE(), user1);
        vm.prank(admin);
        acm.grantRole(acm.PROPOSER_ROLE(), user1);

        assertTrue(acm.hasRole(acm.GOVERNOR_ROLE(), user1));
        assertTrue(acm.hasRole(acm.PROPOSER_ROLE(), user1));
    }
}
