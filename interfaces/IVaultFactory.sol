// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IAggregatorV3} from "./IAggregatorV3.sol";
import {IStrategy} from "./IStrategy.sol";
import {IBaseVault} from "./IBaseVault.sol";

/**
 * @title Vault Factory Interface
 * @author Trader Joe
 * @notice Interface used to interact with the Factory for Liquidity Book Vaults
 */
interface IVaultFactory {
    error VaultFactory__VaultImplementationNotSet(VaultType vType);
    error VaultFactory__StrategyImplementationNotSet(StrategyType sType);
    error VaultFactory__InvalidType();
    error VaultFactory__InvalidOraclePrice();
    error VaultFactory__InvalidStrategy();
    error VaultFactory__InvalidFeeRecipient();
    error VaultFactory__InvalidOwner();
    error VaultFactory__InvalidLength();
    error VaultFactory__InvalidDecimals();
    error VaultFactory__InvalidCreationFee();
    error VaultFactory__InvalidAumFee();
    error VaultFactory__TwapInvalidOracleSize();
    error VaultFactory__VaultNotWhitelisted();

    enum VaultType {
        None,
        Simple,
        Oracle
    }

    enum StrategyType {
        None,
        Default
    }

    struct RebalanceSetting {
        uint24 newLower;
        uint24 newUpper;
        uint24 desiredActiveId;
        uint24 slippageActiveId;
        uint256 amountX;
        uint256 amountY;
        bytes distributions;
    }

    struct MakerVault {
        address vault;
        address operator;
    }

    event VaultCreated(
        VaultType indexed vType,
        address indexed vault,
        ILBPair indexed lbPair,
        uint256 vaultIndex,
        address tokenX,
        address tokenY
    );

    event StrategyCreated(
        StrategyType indexed sType,
        address indexed strategy,
        address indexed vault,
        ILBPair lbPair,
        uint256 strategyIndex
    );

    event TransferIgnoreListSet(address[] addresses);

    event VaultImplementationSet(VaultType indexed vType, address indexed vaultImplementation);

    event StrategyImplementationSet(StrategyType indexed sType, address indexed strategyImplementation);

    event DefaultOperatorSet(address indexed sender, address indexed defaultOperator);

    event FeeRecipientSet(address indexed sender, address indexed feeRecipient);

    event RebalanceSettingSet(address indexed vault, address indexed user);

    event DeviationThresholdUpdated(address indexed vault, uint256 threshold);

    event PairWhitelistSet(address[] pairs, bool isWhitelisted);

    function getWNative() external view returns (address);

    function getVaultAt(VaultType vType, uint256 index) external view returns (address);

    function getVaultType(address vault) external view returns (VaultType);

    function getStrategyAt(StrategyType sType, uint256 index) external view returns (address);

    function getStrategyType(address strategy) external view returns (StrategyType);

    function getNumberOfVaults(VaultType vType) external view returns (uint256);

    function getNumberOfStrategies(StrategyType sType) external view returns (uint256);

    function getDefaultOperator() external view returns (address);

    function getFeeRecipient() external view returns (address);

    function getFeeRecipientByVault(address vault) external view returns (address);

    function getVaultImplementation(VaultType vType) external view returns (address);

    function getStrategyImplementation(StrategyType sType) external view returns (address);

    function isTransferIgnored(address _address) external view returns (bool);

    function getTransferIgnoreList() external view returns (address[] memory);

    function isPairWhitelisted(address pair) external view returns (bool);

    function batchRedeemQueuedWithdrawals(
        address[] calldata vaults,
        uint256[] calldata rounds,
        bool[] calldata withdrawNative
    ) external;

    function setVaultImplementation(VaultType vType, address vaultImplementation) external;

    function setStrategyImplementation(StrategyType sType, address strategyImplementation) external;

    function setDefaultOperator(address defaultOperator) external;

    function setOperator(IStrategy strategy, address operator) external;

    function setPendingAumAnnualFee(IBaseVault vault, uint16 pendingAumAnnualFee) external;

    function resetPendingAumAnnualFee(IBaseVault vault) external;

    function setFeeRecipient(address feeRecipient) external;

    function setDefaultSequencerUptimeFeed(IAggregatorV3 sequencerUptimeFeed) external;

    function setSequenzerUptimeFeed(address oracleVault, IAggregatorV3 sequencerUptimeFeed) external;

    function setTwapInterval(address oracleVault, uint40 interval) external;

    function enableTWAPPriceCheck(address oracleVault, bool enabled) external;

    function setMinMaxPrice(address oracleVault, uint256 minPrice, uint256 maxPrice) external;

    function setDatafeedHeartbeat(address oracleVault, uint24 dataFeedHeartbeatX, uint24 dataFeedHeartbeatY) external;

    function setPairWhitelist(address[] calldata pairs, bool isWhitelisted) external;

    function createOracleVaultAndDefaultStrategy(ILBPair lbPair, IAggregatorV3 dataFeedX, IAggregatorV3 dataFeedY)
        external
        returns (address vault, address strategy);

    function createSimpleVaultAndDefaultStrategy(ILBPair lbPair) external returns (address vault, address strategy);

    function createOracleVault(ILBPair lbPair, IAggregatorV3 dataFeedX, IAggregatorV3 dataFeedY)
        external
        returns (address vault);

    function createSimpleVault(ILBPair lbPair) external returns (address vault);

    function createDefaultStrategy(IBaseVault vault) external returns (address strategy);

    function linkVaultToStrategy(IBaseVault vault, address strategy) external;

    function setEmergencyMode(IBaseVault vault) external;

    function cancelShutdown(address oracleVault) external;

    function recoverERC20(IBaseVault vault, IERC20Upgradeable token, address recipient, uint256 amount) external;
    
    function setDeviationThreshold(address oracleVault, uint256 threshold) external;

    function setTransferIgnoreList(address[] calldata addresses) external;

}
