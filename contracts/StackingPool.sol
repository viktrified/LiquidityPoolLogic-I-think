// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StakingPool {
    using SafeERC20 for IERC20;

    address public immutable tokenA;
    address public immutable tokenB;
    address public immutable owner;

    struct Swapper {
        uint256 numberOfSwaps;
    }

    struct LP {
        uint256 amount;
        uint256 numberOfStakes;
    }

    mapping(address => Swapper) public swappers;
    mapping(address => mapping(address => LP)) public liquidityProviders;

    error InsufficientBalance(address token, address caller, uint256 requested);

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        owner = msg.sender;
    }

    function swapAToB(uint256 _amount) external {
        IERC20 token = IERC20(tokenA);
        if (token.balanceOf(msg.sender) < _amount) revert InsufficientBalance(tokenA, msg.sender, _amount);
        
        uint256 amountOut = _amount * 3;
        IERC20 tokenOut = IERC20(tokenB);
        if (tokenOut.balanceOf(address(this)) < amountOut) revert InsufficientBalance(tokenB, address(this), amountOut);

        token.safeTransferFrom(msg.sender, address(this), _amount);
        tokenOut.safeTransfer(msg.sender, amountOut);

        swappers[msg.sender].numberOfSwaps++;
    }

    function swapBToA(uint256 _amount) external {
        IERC20 token = IERC20(tokenB);
        if (token.balanceOf(msg.sender) < _amount) revert InsufficientBalance(tokenB, msg.sender, _amount);
        
        uint256 amountOut = _amount * 2;
        IERC20 tokenOut = IERC20(tokenA);
        if (tokenOut.balanceOf(address(this)) < amountOut) revert InsufficientBalance(tokenA, address(this), amountOut);

        token.safeTransferFrom(msg.sender, address(this), _amount);
        tokenOut.safeTransfer(msg.sender, amountOut);

        swappers[msg.sender].numberOfSwaps++;
    }

    function stake(address _token, uint256 _amount) external {
        if (_token != tokenA && _token != tokenB) revert();

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        LP storage lp = liquidityProviders[msg.sender][_token];
        lp.amount += _amount;
        lp.numberOfStakes++;
    }

    function withdrawStake(address _token, uint256 _amount) external {
        LP storage lp = liquidityProviders[msg.sender][_token];
        if (lp.amount < _amount) revert InsufficientBalance(_token, msg.sender, _amount);
        
        lp.amount -= _amount;
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}
