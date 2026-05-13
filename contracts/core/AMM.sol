// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IAMM} from "../interfaces/IAMM.sol";
import {Math} from "../libraries/Math.sol";
import {Constants} from "../libraries/Constants.sol";

contract AMM is ERC20, ReentrancyGuard, IAMM {
    using SafeERC20 for IERC20;

    IERC20 public token0;
    IERC20 public token1;
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public feesAccumulatedToken0;
    uint256 public feesAccumulatedToken1;

    event LiquidityAdded(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 lpTokensMinted,
        uint256 timestamp
    );

    event LiquidityRemoved(
        address indexed provider,
        uint256 amount0,
        uint256 amount1,
        uint256 lpTokensBurned,
        uint256 timestamp
    );

    event Swap(
        address indexed trader,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee,
        uint256 timestamp
    );

    event FeesWithdrawn(
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 timestamp
    );

    error InvalidTokenAddress();
    error InvalidReserves();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();
    error ZeroAmount();
    error IdenticalTokens();
    error PoolNotInitialized();
    error InvalidSlippage();


    constructor(
        address _token0,
        address _token1,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        if (_token0 == address(0) || _token1 == address(0)) {
            revert InvalidTokenAddress();
        }
        if (_token0 == _token1) {
            revert IdenticalTokens();
        }

        if (_token0 > _token1) {
            (_token0, _token1) = (_token1, _token0);
        }

        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function addLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _minLPTokens
    ) external nonReentrant returns (uint256 lpTokensMinted) {
        if (_amount0 == 0 || _amount1 == 0) {
            revert ZeroAmount();
        }

        uint256 totalSupply = totalSupply();

        if (totalSupply == 0) {
            lpTokensMinted = Math.sqrt(_amount0 * _amount1);

            if (lpTokensMinted < Constants.MINIMUM_LIQUIDITY) {
                revert InsufficientLiquidity();
            }
        } else {
            uint256 lpTokensForAmount0 = (_amount0 * totalSupply) / reserve0;
            uint256 lpTokensForAmount1 = (_amount1 * totalSupply) / reserve1;

            lpTokensMinted = lpTokensForAmount0 < lpTokensForAmount1
                ? lpTokensForAmount0
                : lpTokensForAmount1;
        }

        if (lpTokensMinted < _minLPTokens) {
            revert InvalidSlippage();
        }

        reserve0 += _amount0;
        reserve1 += _amount1;

        _mint(msg.sender, lpTokensMinted);

        token0.safeTransferFrom(msg.sender, address(this), _amount0);
        token1.safeTransferFrom(msg.sender, address(this), _amount1);

        emit LiquidityAdded(msg.sender, _amount0, _amount1, lpTokensMinted, block.timestamp);
    }

    function removeLiquidity(
        uint256 _lpTokens,
        uint256 _minAmount0,
        uint256 _minAmount1
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        if (_lpTokens == 0) {
            revert ZeroAmount();
        }

        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            revert InsufficientLiquidity();
        }

        amount0 = (_lpTokens * reserve0) / totalSupply;
        amount1 = (_lpTokens * reserve1) / totalSupply;

        if (amount0 < _minAmount0 || amount1 < _minAmount1) {
            revert InvalidSlippage();
        }

        reserve0 -= amount0;
        reserve1 -= amount1;

        _burn(msg.sender, _lpTokens);

        token0.safeTransfer(msg.sender, amount0);
        token1.safeTransfer(msg.sender, amount1);

        emit LiquidityRemoved(msg.sender, amount0, amount1, _lpTokens, block.timestamp);
    }

    function swapToken0ForToken1(uint256 _amountIn, uint256 _minAmountOut)
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        if (_amountIn == 0) {
            revert ZeroAmount();
        }
        if (reserve0 == 0 || reserve1 == 0) {
            revert PoolNotInitialized();
        }

        uint256 fee = (_amountIn * Constants.SWAP_FEE_BPS) / Constants.BPS_DENOMINATOR;
        uint256 amountInAfterFee = _amountIn - fee;

        amountOut = _getAmountOut(amountInAfterFee, reserve0, reserve1);

        if (amountOut == 0) {
            revert InsufficientOutputAmount();
        }
        if (amountOut < _minAmountOut) {
            revert InvalidSlippage();
        }

        reserve0 += _amountIn;
        reserve1 -= amountOut;
        feesAccumulatedToken0 += fee;

        token0.safeTransferFrom(msg.sender, address(this), _amountIn);
        token1.safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, address(token0), address(token1), _amountIn, amountOut, fee, block.timestamp);
    }

    function swapToken1ForToken0(uint256 _amountIn, uint256 _minAmountOut)
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        if (_amountIn == 0) {
            revert ZeroAmount();
        }
        if (reserve0 == 0 || reserve1 == 0) {
            revert PoolNotInitialized();
        }

        uint256 fee = (_amountIn * Constants.SWAP_FEE_BPS) / Constants.BPS_DENOMINATOR;
        uint256 amountInAfterFee = _amountIn - fee;

        amountOut = _getAmountOut(amountInAfterFee, reserve1, reserve0);

        if (amountOut == 0) {
            revert InsufficientOutputAmount();
        }
        if (amountOut < _minAmountOut) {
            revert InvalidSlippage();
        }

        reserve1 += _amountIn;
        reserve0 -= amountOut;
        feesAccumulatedToken1 += fee;

        token1.safeTransferFrom(msg.sender, address(this), _amountIn);
        token0.safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, address(token1), address(token0), _amountIn, amountOut, fee, block.timestamp);
    }

    function withdrawFees(address _recipient) external returns (uint256 amount0, uint256 amount1) {
        if (_recipient == address(0)) {
            revert InvalidTokenAddress();
        }

        amount0 = feesAccumulatedToken0;
        amount1 = feesAccumulatedToken1;

        feesAccumulatedToken0 = 0;
        feesAccumulatedToken1 = 0;

        if (amount0 > 0) {
            token0.safeTransfer(_recipient, amount0);
        }
        if (amount1 > 0) {
            token1.safeTransfer(_recipient, amount1);
        }

        emit FeesWithdrawn(_recipient, amount0, amount1, block.timestamp);
    }

    function getAmountOut(uint256 _amountIn, uint256 _reserveIn, uint256 _reserveOut)
        external
        pure
        returns (uint256)
    {
        if (_amountIn == 0) revert ZeroAmount();
        return _getAmountOut(_amountIn, _reserveIn, _reserveOut);
    }

    function getPrice() external view returns (uint256) {
        if (reserve0 == 0) revert InvalidReserves();
        return (reserve1 * 1e18) / reserve0;
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    function getK() external view returns (uint256) {
        return reserve0 * reserve1;
    }

    function _getAmountOut(
        uint256 _amountIn,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (_amountIn == 0 || _reserveIn == 0 || _reserveOut == 0) {
            return 0;
        }

        uint256 numerator = _amountIn * _reserveOut;
        uint256 denominator = _reserveIn + _amountIn;
        amountOut = numerator / denominator;
    }
}
