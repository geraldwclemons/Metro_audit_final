// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";

import {BaseVault} from "./BaseVault.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IOracleVault} from "./interfaces/IOracleVault.sol";
import {IVaultFactory} from "./interfaces/IVaultFactory.sol";
import {IAggregatorV3} from "./interfaces/IAggregatorV3.sol";

/**
 * @title Liquidity Book Oracle Vault contract
 * @author Trader Joe
 * @notice This contract is used to interact with the Liquidity Book Pair contract.
 * The two tokens of the pair has to have an oracle.
 * The oracle is used to get the price of the token X in token Y.
 * The price is used to value the balance of the strategy and mint shares accordingly.
 * The immutable data should be encoded as follow:
 * - 0x00: 20 bytes: The address of the LB pair.
 * - 0x14: 20 bytes: The address of the token X.
 * - 0x28: 20 bytes: The address of the token Y.
 * - 0x3C: 1 bytes: The decimals of the token X.
 * - 0x3D: 1 bytes: The decimals of the token Y.
 * - 0x3E: 20 bytes: The address of the oracle of the token X.
 * - 0x52: 20 bytes: The address of the oracle of the token Y.
 */
contract OracleVault is BaseVault, IOracleVault {
    using Uint256x256Math for uint256;

    uint8 private constant _PRICE_OFFSET = 128;

    /// @notice Grace period time after sequencer is up
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    /// @notice Sequencer Uptime Feed
    IAggregatorV3 private _sequencerUptimeFeed;

    /// @notice Oracle min price
    uint256 private _oracleMinPrice;

    /// @notice Oracle max price
    uint256 private _oracleMaxPrice;

    /// @notice Oracle heartbeat for datafeedX, e.g. 24 hours
    uint24 private _dataFeedHeartbeatX;

    /// @notice Oracle heartbeat for datafeedY, e.g. 24 hours
    uint24 private _dataFeedHeartbeatY;

    /// @notice Whether TWAP price checking is enabled
    bool private _twapPriceCheckEnabled;

    /// @notice TWAP interval for price checking
    uint40 private _twapInterval;

    /// @notice Maximum allowed deviation between spot and TWAP price e.g. 5% (in percentage)
    uint256 private _deviationThreshold;

    /**
     * @dev Constructor of the contract.
     * @param factory Address of the factory.
     */
    constructor(IVaultFactory factory) BaseVault(factory) {}

    /**
     * @dev Returns the address of the oracle of the token X.
     * @return oracleX The address of the oracle of the token X.
     */
    function getOracleX()
        external
        pure
        override
        returns (IAggregatorV3 oracleX)
    {
        return _dataFeedX();
    }

    /**
     * @dev Returns the address of the oracle of the token Y.
     * @return oracleY The address of the oracle of the token Y.
     */
    function getOracleY()
        external
        pure
        override
        returns (IAggregatorV3 oracleY)
    {
        return _dataFeedY();
    }


    /**
     * @dev Returns the price of token X in token Y, in 128.128 binary fixed point format.
     * @return price The price of token X in token Y in 128.128 binary fixed point format.
     */
    function getPrice() external view override returns (uint256 price) {
        return _getPrice();
    }


    /**
     * @dev Returns the oracle parameters.
     * @return minPrice The minimum price of token X in token Y.
     * @return maxPrice The maximum price of token X in token Y.
     * @return heartbeatX The heartbeat for data feed X.
     * @return heartbeatY The heartbeat for data feed Y.
     * @return deviationThreshold The deviation threshold.
     * @return twapPriceCheckEnabled Whether TWAP price checking is enabled.
     * @return twapInterval The TWAP interval.
     */
    function getOracleParameters() external view returns (
                uint256 minPrice, 
                uint256 maxPrice, 
                uint256 heartbeatX, 
                uint256 heartbeatY,
                uint256 deviationThreshold,
                bool twapPriceCheckEnabled,
                uint40 twapInterval
                ) {
        return (_oracleMinPrice, _oracleMaxPrice, _dataFeedHeartbeatX, _dataFeedHeartbeatY, 
        _deviationThreshold, _twapPriceCheckEnabled, _twapInterval);
    }

    /**
     * @dev Sets the sequencer uptime feed. Can only be called by the factory.
     * @param sequencerUptimeFeed The sequencer uptime feed.
     */
    function setSequenzerUptimeFeed(
        IAggregatorV3 sequencerUptimeFeed
    ) external override onlyFactory {
        _sequencerUptimeFeed = sequencerUptimeFeed;
    }

    /**
     * @dev Sets the min and max price of the oracle
     * @param minPrice  min price
     * @param maxPrice  max price
     */
    function setMinMaxPrice(
        uint256 minPrice,
        uint256 maxPrice
    ) external override onlyFactory {
        if (minPrice > maxPrice) revert OracleVault__InvalidPrice();
        _oracleMinPrice = minPrice;
        _oracleMaxPrice = maxPrice;
    }


    /**
     * @dev Sets the data feed heartbeat for data feed X and Y.
     * @param heartbeatX The heartbeat for data feed X.
     * @param heartbeatY The heartbeat for data feed Y.
     */
    function setDatafeedHeartbeat(
        uint24 heartbeatX,
        uint24 heartbeatY
    ) external override onlyFactory {
        _dataFeedHeartbeatX = heartbeatX;
        _dataFeedHeartbeatY = heartbeatY;
    }

    /**
     * @dev Enables or disables TWAP price checking. Can only be called by the factory.
     * @param enabled Whether to enable TWAP price checking
     */
    function enableTWAPPriceCheck(bool enabled) external override onlyFactory {
        _twapPriceCheckEnabled = enabled;
    }

    /**
     * @dev Updates the TWAP interval for price checking. Can only be called by the factory.
     * @param interval The TWAP interval in seconds
     */
    function setTwapInterval(uint40 interval) external override onlyFactory {
        if (interval == 0) revert OracleVault__InvalidInterval();
        _twapInterval = interval;
    }

    /**
     * @dev Sets the maximum allowed price deviation threshold. Can only be called by the factory.
     * @param threshold The maximum allowed deviation in percentage
     */
    function setDeviationThreshold(uint256 threshold) external override onlyFactory {
        _deviationThreshold = threshold;
    }

    /**
     * @dev Returns the data feed of the token X.
     * @return dataFeedX The data feed of the token X.
     */
    function _dataFeedX() internal pure returns (IAggregatorV3 dataFeedX) {
        return IAggregatorV3(_getArgAddress(62));
    }

    /**
     * @dev Returns the data feed of the token Y.
     * @return dataFeedY The data feed of the token Y.
     */
    function _dataFeedY() internal pure returns (IAggregatorV3 dataFeedY) {
        return IAggregatorV3(_getArgAddress(82));
    }

    /**
     * @dev Returns the price of a token using its oracle.
     * @param dataFeed The data feed of the token.
     * @return uintPrice The oracle latest answer.
     */
    function _getOraclePrice(
        IAggregatorV3 dataFeed
    ) internal view returns (uint256 uintPrice) {
        _checkSequenzerUp();

        (, int256 price, , uint256 updatedAt, ) = dataFeed.latestRoundData();

        uint24 heartbeat = dataFeed == _dataFeedX()
            ? _dataFeedHeartbeatX
            : _dataFeedHeartbeatY;

        if (updatedAt == 0 || updatedAt + heartbeat < block.timestamp) {
            revert OracleVault__StalePrice();
        }

        if (
            uint256(price) < _oracleMinPrice || uint256(price) > _oracleMaxPrice
        ) {
            revert OracleVault__InvalidPrice();
        }

        uintPrice = uint256(price);
    }

    function _checkSequenzerUp() internal view {
        if (address(_sequencerUptimeFeed) == address(0)) {
            return;
        }

        // prettier-ignore
        (
            /*uint80 roundID*/,
            int256 answer,
            uint256 startedAt,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = _sequencerUptimeFeed.latestRoundData();

        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert OracleVault__SequencerDown();
        }

        uint256 timeSinceUp = block.timestamp - startedAt;
        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert OracleVault__GracePeriodNotOver();
        }
    }

    /**
     * @dev Returns the price of token X in token Y.
     * WARNING: Both oracles needs to return the same decimals and use the same quote currency.
     * @return price The price of token X in token Y.
     */
    function _getPrice() internal view returns (uint256 price) {
        uint256 scaledPriceX = _getOraclePrice(_dataFeedX()) *
            10 ** _decimalsY();
        uint256 scaledPriceY = _getOraclePrice(_dataFeedY()) *
            10 ** _decimalsX();

        // Essentially does `price = (priceX / 1eDecimalsX) / (priceY / 1eDecimalsY)`
        // with 128.128 binary fixed point arithmetic.
        price = scaledPriceX.shiftDivRoundDown(_PRICE_OFFSET, scaledPriceY);

        if (price == 0) revert OracleVault__InvalidPrice();
    }

    /**
     * @dev Returns the shares that will be minted when depositing `expectedAmountX` of token X and
     * `expectedAmountY` of token Y. The effective amounts will never be greater than the input amounts.
     * @param strategy The strategy to deposit to.
     * @param amountX The amount of token X to deposit.
     * @param amountY The amount of token Y to deposit.
     * @return shares The amount of shares that will be minted.
     * @return effectiveX The effective amount of token X that will be deposited.
     * @return effectiveY The effective amount of token Y that will be deposited.
     */
    function _previewShares(
        IStrategy strategy,
        uint256 amountX,
        uint256 amountY
    )
        internal
        view
        override
        returns (uint256 shares, uint256 effectiveX, uint256 effectiveY)
    {
        if (amountX == 0 && amountY == 0) return (0, 0, 0);

        // the price is in quoteToken
        uint256 price = _getPrice();

        // check if the price is within the allowed deviation
        _checkPrice(price);

        uint256 totalShares = totalSupply();

        uint256 valueInY = _getValueInY(price, amountX, amountY);

        if (totalShares == 0) {
            return (valueInY * _SHARES_PRECISION, amountX, amountY);
        }

        (uint256 totalX, uint256 totalY) = _getBalances(strategy);
        uint256 totalValueInY = _getValueInY(price, totalX, totalY);

        shares = valueInY.mulDivRoundDown(totalShares, totalValueInY);

        return (shares, amountX, amountY);
    }

    function _checkPrice(uint256 spotPriceInY) internal view {
        if (!_twapPriceCheckEnabled) return;

        uint40 twapStart = uint40(block.timestamp - _twapInterval);
        uint40 twapEnd = uint40(block.timestamp);

        if (twapEnd <= twapStart) revert OracleVault__InvalidTimestamps();

        // Fetch cumulative bin IDs at the specified timestamps
        (uint64 cumulativeId1, , ) = _pair().getOracleSampleAt(twapStart);
        (uint64 cumulativeId2, , ) = _pair().getOracleSampleAt(twapEnd);

        // Calculate the time difference
        uint40 timeElapsed = twapEnd - twapStart;

        // Compute the TWAP bin ID
        uint256 twapBinId = (cumulativeId2 - cumulativeId1) / timeElapsed;

        // Returns priceInY in 128.128 fixed-point format
        uint256 twapPriceInY = _pair().getPriceFromId(uint24(twapBinId));

        // both prices are in tokenY, check deviation
        if (
            spotPriceInY > (twapPriceInY * (100 + _deviationThreshold)) / 100 ||
            spotPriceInY < (twapPriceInY * (100 - _deviationThreshold)) / 100
        ) {
            revert OracleVault__PriceDeviation();
        }
    }

    /**
     * @dev Returns the value of amounts in token Y.
     * @param price The price of token X in token Y.
     * @param amountX The amount of token X.
     * @param amountY The amount of token Y.
     * @return valueInY The value of amounts in token Y.
     */
    function _getValueInY(
        uint256 price,
        uint256 amountX,
        uint256 amountY
    ) internal pure returns (uint256 valueInY) {
        uint256 amountXInY = price.mulShiftRoundDown(amountX, _PRICE_OFFSET);
        return amountXInY + amountY;
    }

    function _updatePool() internal virtual override {
        // nothing
    }

    function _modifyUser(
        address user,
        int256 amount
    ) internal virtual override {
        // nothing
    }

    function _beforeEmergencyMode() internal virtual override {
        // nothing
    }

}
