// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IStrategy} from "./IStrategy.sol";
import {IBaseVault} from "./IBaseVault.sol";
import {IAggregatorV3} from "./IAggregatorV3.sol";

/**
 * @title Oracle Vault Interface
 * @author Trader Joe
 * @notice Interface used to interact with Liquidity Book Oracle Vaults
 */
interface IOracleVault is IBaseVault {
    
    error OracleVault__InvalidPrice();
    error OracleVault__StalePrice();

    error OracleVault__SequencerDown();
    error OracleVault__GracePeriodNotOver();
    error OracleVault__PriceDeviation();
    error OracleVault__InvalidInterval();
    error OracleVault__InvalidTimestamps();

    function getOracleX() external pure returns (IAggregatorV3 oracleX);

    function getOracleY() external pure returns (IAggregatorV3 oracleY);

    function getPrice() external view returns (uint256 price);

    function getOracleParameters() external view returns (
        uint256 minPrice, 
        uint256 maxPrice, 
        uint256 heartbeatX, 
        uint256 heartbeatY,
        uint256 deviationThreshold,
        bool twapPriceCheckEnabled,
        uint40 twapInterval
    );

    function setSequenzerUptimeFeed(IAggregatorV3 sequencerUptimeFeed) external;

    function setMinMaxPrice(uint256 minPrice, uint256 maxPrice) external;

    function setDatafeedHeartbeat(uint24 heartbeatX, uint24 heartbeatY) external;

    function enableTWAPPriceCheck(bool enabled) external;

    function setTwapInterval(uint40 interval) external;

    function setDeviationThreshold(uint256 threshold) external;
}
