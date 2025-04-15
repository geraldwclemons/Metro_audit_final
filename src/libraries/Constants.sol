// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title Constants Library
 * @dev A library that defines various constants used throughout the codebase.
 */
library Constants {
    uint256 internal constant ACC_PRECISION_BITS = 64;
    uint256 internal constant PRECISION = 1e18;

    // current max range for iota
    uint256 internal constant IOTA_MAX_RANGE = 151;

    // current max range for default (all other chains)
    uint256 internal constant DEFAULT_MAX_RANGE = 51; 
}
