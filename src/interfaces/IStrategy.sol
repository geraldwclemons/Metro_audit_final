// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IERC20Upgradeable} from "openzeppelin-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {ILBPair} from "joe-v2/interfaces/ILBPair.sol";

import {IOneInchRouter} from "./IOneInchRouter.sol";
import {IVaultFactory} from "./IVaultFactory.sol";
import {IERC20} from "./IHooksRewarder.sol";

/**
 * @title Strategy Interface
 * @author Trader Joe
 * @notice Interface used to interact with Liquidity Book Vaults' Strategies
 */
interface IStrategy {
    error Strategy__OnlyFactory();
    error Strategy__OnlyVault();
    error Strategy__OnlyOperators();
    error Strategy__OnlyDefaultOperator();
    error Strategy__ZeroAmounts();
    error Strategy__InvalidAmount();
    error Strategy__InvalidToken();
    error Strategy__InvalidReceiver();
    error Strategy__InvalidRange();
    error Strategy__InvalidFee();
    error Strategy__ActiveIdSlippage();
    error Strategy__RangeAlreadySet();
    error Strategy__RangeTooWide();
    error Strategy__InvalidLength();

    event OperatorSet(address operator);

    event AumFeeCollected(
        address indexed sender, uint256 totalBalanceX, uint256 totalBalanceY, uint256 feeX, uint256 feeY
    );

    event AumAnnualFeeSet(uint256 fee);

    event PendingAumAnnualFeeSet(uint256 fee);

    event PendingAumAnnualFeeReset();

    event RangeSet(uint24 low, uint24 upper);

    function getFactory() external view returns (IVaultFactory);

    function getVault() external pure returns (address);

    function getPair() external pure returns (ILBPair);

    function getTokenX() external pure returns (IERC20Upgradeable);

    function getTokenY() external pure returns (IERC20Upgradeable);

    function getRange() external view returns (uint24 low, uint24 upper);

    function getAumAnnualFee() external view returns (uint256 aumAnnualFee);

    function getLastRebalance() external view returns (uint256 lastRebalance);

    function getPendingAumAnnualFee() external view returns (bool isSet, uint256 pendingAumAnnualFee);

    function getRewardToken() external view returns (IERC20);

    function getExtraRewardToken() external view returns (IERC20);

    function hasRewards() external view returns (bool);

    function hasExtraRewards() external view returns (bool);

    function getOperator() external view returns (address);

    function getBalances() external view returns (uint256 amountX, uint256 amountY);

    function getIdleBalances() external view returns (uint256 amountX, uint256 amountY);

    function getMaxRange() external view returns (uint256);

    function initialize() external;

    function withdrawAll() external;

    function rebalance(
        uint24 newLower,
        uint24 newUpper,
        uint24 desiredActiveId,
        uint24 slippageActiveId,
        uint256 amountX,
        uint256 amountY,
        bytes calldata distributions
    ) external;

    function setOperator(address operator) external;

    function setPendingAumAnnualFee(uint16 pendingAumAnnualFee) external;

    function resetPendingAumAnnualFee() external;
}
