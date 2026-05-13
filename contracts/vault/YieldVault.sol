// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/AggregatorV3Interface.sol";


contract YieldVault is ERC4626, Ownable, ReentrancyGuard, Pausable {
    
    AggregatorV3Interface public immutable priceFeed;

    constructor(
        IERC20 _asset,
        address _priceFeed
    ) 
        ERC4626(_asset) 
        ERC20("Yield Bearing Token", "yTKN") 
        Ownable(msg.sender)
    {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function emergencyPause() external onlyOwner {
        _pause();
    }

    function resume() external onlyOwner {
        _unpause();
    }

    function deposit(uint256 assets, address receiver) 
        public 
        override 
        whenNotPaused 
        nonReentrant 
        returns (uint256) 
    {
        return super.deposit(assets, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner) 
        public 
        override 
        whenNotPaused 
        nonReentrant 
        returns (uint256) 
    {
        return super.withdraw(assets, receiver, owner);
    }

    function getAssetPrice() public view returns (int256) {
        ( , int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function totalAssets() public view override returns (uint256) {
        return super.totalAssets();
    }
}