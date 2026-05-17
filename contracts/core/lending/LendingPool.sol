// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract LendingPool is ReentrancyGuard, AccessControl {
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    
    struct Loan {
        uint256 collateralAmount;
        uint256 borrowAmount;
        uint256 lastInterestAccrual;
        uint256 interestRatePerSec;
        bool active;
    }
    
    mapping(address => mapping(address => Loan)) public loans;
    mapping(address => uint256) public interestRates;
    mapping(address => uint256) public ltvRatios;
    address public priceFeed;
    
    uint256 public constant LIQUIDATION_THRESHOLD = 8000;
    uint256 public constant LIQUIDATION_BONUS = 1050;
    
    event LoanCreated(address indexed user, address collateral, uint256 collatAmount, uint256 borrowAmount);
    event Liquidated(address indexed user, address collateral, address liquidator, uint256 seizedCollat, uint256 repaidDebt);
    
    constructor(address _priceFeed) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LIQUIDATOR_ROLE, msg.sender);
        priceFeed = _priceFeed;
    }
    
    function setInterestRate(address token, uint256 rate) external onlyRole(DEFAULT_ADMIN_ROLE) {
        interestRates[token] = rate;
    }
    
    function setLTV(address token, uint256 ltv) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(ltv <= 9000, "LTV too high");
        ltvRatios[token] = ltv;
    }
    
    function depositAndBorrow(
        address collateralToken,
        uint256 collateralAmount,
        address borrowToken,
        uint256 borrowAmount
    ) external nonReentrant {
        require(ltvRatios[collateralToken] > 0, "LTV not set");
        IERC20(collateralToken).transferFrom(msg.sender, address(this), collateralAmount);
        
        uint256 maxBorrow = (collateralAmount * ltvRatios[collateralToken]) / 10000;
        require(borrowAmount <= maxBorrow, "Exceeds max borrow");
        
        loans[msg.sender][collateralToken] = Loan({
            collateralAmount: collateralAmount,
            borrowAmount: borrowAmount,
            lastInterestAccrual: block.timestamp,
            interestRatePerSec: interestRates[collateralToken],
            active: true
        });
        
        IERC20(borrowToken).transfer(msg.sender, borrowAmount);
        emit LoanCreated(msg.sender, collateralToken, collateralAmount, borrowAmount);
    }
    
    function getHealthFactor(address user, address collateralToken) public view returns (uint256) {
        Loan memory loan = loans[user][collateralToken];
        if (!loan.active) return type(uint256).max;
        if (loan.borrowAmount == 0) return type(uint256).max;
        return (loan.collateralAmount * 10000) / (loan.borrowAmount * 10000 / LIQUIDATION_THRESHOLD);
    }
    
    function liquidate(address user, address collateralToken, address borrowToken) external nonReentrant onlyRole(LIQUIDATOR_ROLE) {
        Loan memory loan = loans[user][collateralToken];
        require(loan.active, "No active loan");
        require(getHealthFactor(user, collateralToken) < 10000, "Health factor too high");
        
        uint256 collateralToSeize = (loan.borrowAmount * LIQUIDATION_BONUS) / 10000;
        IERC20(collateralToken).transfer(msg.sender, collateralToSeize);
        loans[user][collateralToken].active = false;
        
        emit Liquidated(user, collateralToken, msg.sender, collateralToSeize, loan.borrowAmount);
    }
}
