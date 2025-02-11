// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library Errors {
    error InsufficientBalance(address token, address caller, uint256 requested);
}                               