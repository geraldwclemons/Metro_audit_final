// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {Uint256x256Math} from "joe-v2/libraries/math/Uint256x256Math.sol";

import {OracleVault} from "./OracleVault.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IOracleRewardVault} from "./interfaces/IOracleRewardVault.sol";
import {IVaultFactory} from "./interfaces/IVaultFactory.sol";
import {IAggregatorV3} from "./interfaces/IAggregatorV3.sol";
import {IERC20} from "./interfaces/IHooksRewarder.sol";

import {TokenHelper} from "./libraries/TokenHelper.sol";
import {Precision} from "./libraries/Precision.sol";
/**
 * @title Liquidity Book Oracle Reward Vault contract
 * @author BlueLabs
 * @notice This contract is used to interact with the Liquidity Book Pair contract.
 *
 * This is a slightly modified version of the original source code, in order to receive rewards for LB Hook Farms.
 *
 * WARNING: You should not add this erc20 token to a MasterChef contract when this vault is acting on LBPairs with LB Hook farm rewards.
 * In this case LB Hook rewards will stay in MasterChef and are not claimable by the user.
 * We also don't recommend to use the vault shares for trading e.g. on a DEX.
 *
 * WARNING 2: Rewards will be claimed on transfer, so if you transfer to a contract, make sure the contract can handle the rewards.
 *
 * How it works:
 *  - The strategy detects if lb pair has a farm hook with lb rewards
 *  - acctTokenPerShare is increased when strategety sends reward tokens to the vault (this happens on rebalance)
 *  - user pending rewards: user balance * accTokenPerShare - rewardDebt
 *  - claim rewards: user balance * accTokenPerShare - rewardDebt
 *
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
contract OracleRewardVault is OracleVault, IOracleRewardVault {
    using Uint256x256Math for uint256;
    using Precision for uint256;

    uint256 private constant PRECISION = 1e12;

    /// @notice Grace period time after sequencer is up
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    /// @notice Accumulated reward per share
    uint256 private _accRewardsPerShare;

    /// @notice Accumulated reward per share for extra rewards
    uint256 private _extraRewardsPerShare;

    /// @notice Last reward balance
    uint256 private _lastRewardBalance;

    /// @notice Last extra reward balance
    uint256 private _lastExtraRewardBalance;

    /// @notice Tracks total supply of shares from users (without vauls e.g. on queueWithawal)
    uint256 private _shareTotalSupply;

    /// @notice User data
    mapping(address => User) public _users;




    /**
     * @dev Constructor of the contract.
     * @param factory Address of the factory.
     */
    constructor(IVaultFactory factory) OracleVault(factory) {}


    /**
     * @dev Returns the last reward balance and the last extra reward balance.
     * @return lastRewardBalance The last reward balance.
     * @return lastExtraRewardBalance The last extra reward balance.
     */
    function getLastRewardBalances() external view returns (
        uint256 lastRewardBalance, 
        uint256 lastExtraRewardBalance
    ) {
        return (_lastRewardBalance, _lastExtraRewardBalance);
    }

    function getUserInfo(address user) external view override returns (User memory) {
        return _users[user];
    }

    /**
     * @dev Returns pending rewards for user
     * @param user user
     * @return rewards rewards
     * @return extraRewards extra rewards
     */
    function getPendingRewards(address user) external view override returns (uint256 rewards, uint256 extraRewards) {
        User storage userData = _users[user];

        // calculate rewards (if there is no lb hook rewarders this will be always 0)
        uint256 accRewardsPerShare = _accRewardsPerShare;
        uint256 rewardBalance = TokenHelper.safeBalanceOf(getStrategy().getRewardToken(), address(this));
        uint256 lastRewardBalance = _lastRewardBalance;

        if (lastRewardBalance != rewardBalance && _shareTotalSupply > 0) {
            uint256 rewardDiff = rewardBalance - lastRewardBalance;
            accRewardsPerShare = accRewardsPerShare + rewardDiff.shiftPrecision() / _shareTotalSupply;
        }
        rewards =
            userData.amount > 0 ? (userData.amount * accRewardsPerShare).unshiftPrecision() - userData.rewardDebt : 0;

        // calculate extra rewards (if there is no lb hook rewarders this will be always 0)
        uint256 accExtraRewardsPerShare = _extraRewardsPerShare;
        uint256 extraRewardBalance = TokenHelper.safeBalanceOf(getStrategy().getExtraRewardToken(), address(this));
        uint256 lastExtraRewardBalance = _lastExtraRewardBalance;

        if (lastExtraRewardBalance != extraRewardBalance && _shareTotalSupply > 0) {
            uint256 extraRewardDiff = extraRewardBalance - lastExtraRewardBalance;
            accExtraRewardsPerShare = accExtraRewardsPerShare + extraRewardDiff.shiftPrecision() / _shareTotalSupply;
        }
        extraRewards = userData.amount > 0
            ? (userData.amount * accExtraRewardsPerShare).unshiftPrecision() - userData.extraRewardDebt
            : 0;
    }


    function _updatePool() internal override {
        if (address(getStrategy()) == address(0)) {
            return;
        }

        if (getStrategy().hasRewards()) {
            uint256 accRewardsPerShare = _accRewardsPerShare;
            uint256 rewardBalance = TokenHelper.safeBalanceOf(getStrategy().getRewardToken(), address(this));
            uint256 lastRewardBalance = _lastRewardBalance;

            // recompute accRewardsPerShare if not up to date
            if (lastRewardBalance != rewardBalance && _shareTotalSupply > 0) {
                uint256 accruedReward = rewardBalance - lastRewardBalance;
                uint256 calcAccRewardsPerShare =
                    accRewardsPerShare + ((accruedReward.shiftPrecision()) / _shareTotalSupply);

                _accRewardsPerShare = calcAccRewardsPerShare;
                _lastRewardBalance = rewardBalance;

                emit PoolUpdated(block.timestamp, calcAccRewardsPerShare);
            }
        }

        // checki if extra rewards
        // make sure the extra reward token is not the same as the reward token
        if (getStrategy().hasExtraRewards() && getStrategy().getExtraRewardToken() != getStrategy().getRewardToken()) {
            uint256 accExtraRewardsPerShare = _extraRewardsPerShare;
            uint256 extraRewardBalance = TokenHelper.safeBalanceOf(getStrategy().getExtraRewardToken(), address(this));
            uint256 lastExtraRewardBalance = _lastExtraRewardBalance;

            // recompute accRewardsPerShare if not up to date
            if (lastExtraRewardBalance == extraRewardBalance || _shareTotalSupply == 0) {
                return;
            }

            uint256 accruedExtraReward = extraRewardBalance - lastExtraRewardBalance;
            uint256 calcAccExtraRewardsPerShare =
                accExtraRewardsPerShare + ((accruedExtraReward.shiftPrecision()) / _shareTotalSupply);

            _extraRewardsPerShare = calcAccExtraRewardsPerShare;
            _lastExtraRewardBalance = extraRewardBalance;

            emit PoolUpdated(block.timestamp, calcAccExtraRewardsPerShare);
        }
    }

    /**
     * @dev will be called on base vault deposit and withdrawal
     * Update pool must be is called before.
     * @param user user
     * @param amount amount
     */
    function _modifyUser(address user, int256 amount) internal virtual override {
        User storage userData = _users[user];

        uint256 uAmount = uint256(amount < 0 ? -amount : amount); // cast to uint256

        // we claim rewards on deposit, withdrawal and harvest
        if (amount > 0) {
            // deposit
            _harvest(user);

            userData.amount = userData.amount + uAmount;

            _shareTotalSupply = _shareTotalSupply + uAmount;

            _updateUserDebt(userData);
        } else if (amount < 0) {
            // withdrawal

            _harvest(user);

            userData.amount = userData.amount - uAmount;

            _shareTotalSupply = _shareTotalSupply - uAmount;

            _updateUserDebt(userData);
        } else {
            // harvest
            _harvest(user);
            _updateUserDebt(userData);
        }
    }

    function _updateUserDebt(User storage userData) internal {
        userData.rewardDebt = (userData.amount * _accRewardsPerShare).unshiftPrecision(); // / PRECISION;
        userData.extraRewardDebt = (userData.amount * _extraRewardsPerShare).unshiftPrecision(); // / PRECISION;
    }


    function _harvest(address user) internal {
        if (address(getStrategy()) == address(0)) {
            return;
        }

        User storage userData = _users[user];
        uint256 pending = ((userData.amount * _accRewardsPerShare).unshiftPrecision()) - userData.rewardDebt;
        uint256 extraPending = ((userData.amount * _extraRewardsPerShare).unshiftPrecision()) - userData.extraRewardDebt;

        _safeRewardTransfer(getStrategy().getRewardToken(), user, pending, false);
        _safeRewardTransfer(getStrategy().getExtraRewardToken(), user, extraPending, true);
    }

    function _safeRewardTransfer(IERC20 token, address to, uint256 amount, bool isExtra) internal {
        if (amount == 0) return;

        uint256 balance = TokenHelper.safeBalanceOf(token, address(this));

        uint256 rewardPayout = amount;

        if (amount > balance) {
            rewardPayout = balance;
        }

        if (isExtra) {
            _lastExtraRewardBalance = _lastExtraRewardBalance - rewardPayout;
        } else {
            _lastRewardBalance = _lastRewardBalance - rewardPayout;
        }

        // transfer token
        TokenHelper.safeTransfer(token, to, rewardPayout);
    }

    /**
     * @dev Claim rewards of the sender.
     */
    function claim() external override nonReentrant {
        _updatePool();
        _modifyUser(msg.sender, 0);
    }

    /**
     * @dev claim rewards of sender before transfering it to recipient
     */
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (!_isIgnored(recipient) && !_isIgnored(sender)) {
            _updatePool();
            _modifyUser(sender, -int256(amount));
            _modifyUser(recipient, int256(amount));
        }
        super._transfer(sender, recipient, amount);
    }

    /**
     * Check if address is ingored for rewards (e.g strategy, or other addresses)
     * @param _address address
     */
    function _isIgnored(address _address) internal view returns (bool) {
        if (_address == address(getStrategy())) {
            return true;
        }
        return getFactory().isTransferIgnored(_address);
    }

    function _beforeEmergencyMode() internal virtual override {
        // nothing
    }
}
