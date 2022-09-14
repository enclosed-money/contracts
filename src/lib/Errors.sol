// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Errors library
 * @notice Defines the custom errors used across the protocol
 */
library Errors {
    /// @dev Given deposit amount is too small
    error ValueTooSmall();

    /// @dev Given deposit amount is too large
    error ValueTooLarge();
}
