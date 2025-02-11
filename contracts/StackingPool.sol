// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./lib/Errors.sol";

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

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        owner = msg.sender; 
    }
    function swap(address _from, uint256 _amount) external {
        if (_from != tokenA && _from != tokenB) revert();
        
        address _to = (_from == tokenA) ? tokenB : tokenA;
        uint256 amountOut = (_from == tokenA) ? _amount * 3 : _amount * 2;
        
        IERC20 tokenFrom = IERC20(_from);
        IERC20 tokenTo = IERC20(_to);
        
        if (tokenFrom.balanceOf(msg.sender) < _amount) revert Errors.InsufficientBalance(_from, msg.sender, _amount);
        if (tokenTo.balanceOf(address(this)) < amountOut) revert Errors.InsufficientBalance(_to, address(this), amountOut);
        
        tokenFrom.safeTransferFrom(msg.sender, address(this), _amount);
        tokenTo.safeTransfer(msg.sender, amountOut);
        
        swappers[msg.sender].numberOfSwaps++;

        Events.Swaped(_from, msg.sender, _amount);
    }

    function stake(address _token, uint256 _amount) external {
        if (_token != tokenA && _token != tokenB) revert();

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        LP storage lp = liquidityProviders[msg.sender][_token];
        lp.amount += _amount;
        lp.numberOfStakes++;

        Events.Staked(_token, msg.sender, _amount);
    }

    function withdrawStake(address _token, uint256 _amount) external {
        LP storage lp = liquidityProviders[msg.sender][_token];
        if (lp.amount < _amount) revert Errors.InsufficientBalance(_token, msg.sender, _amount);
        
        lp.amount -= _amount;
        IERC20(_token).safeTransfer(msg.sender, _amount);

        Events.Withdrawn(_token, msg.sender);
    }
}
