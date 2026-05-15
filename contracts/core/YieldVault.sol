// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAMM} from "../interfaces/IAMM.sol";

contract YieldVault is Initializable, ERC4626Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    
    IAMM public targetPool;
    uint256 public lastHarvest;

    event Harvested(uint256 amount0, uint256 amount1);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20 _asset,
        address _pool,
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC4626_init(_asset);
        __ERC20_init(_name, _symbol);
        __Ownable_init(msg.sender);
        
        targetPool = IAMM(_pool);
        lastHarvest = block.timestamp;
    }

    function harvest() external {
        (uint256 a0, uint256 a1) = targetPool.withdrawFees(address(this));
        
        lastHarvest = block.timestamp;
        emit Harvested(a0, a1);
    }

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}