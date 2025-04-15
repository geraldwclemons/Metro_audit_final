// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import {IOracleVault} from "./IOracleVault.sol";

/**
 * @title Oracle Reard Vault Interface
 * @author BlueLabs
 * @notice Interface used to interact with Liquidity Book Oracle Vaults
 */
interface IOracleRewardVault is IOracleVault {

    struct User {
        uint256 amount;
        uint256 rewardDebt;
        uint256 extraRewardDebt;
    }

    event PoolUpdated(uint256 indexed timestamp, uint256 indexed accRewardShare);

    function getLastRewardBalances() external view returns (uint256 lastRewardBalance, uint256 lastExtraRewardBalance);

    function getUserInfo(address user) external view returns (User memory);

    function getPendingRewards(address _user)
        external
        view
        returns (uint256 pendingRewards, uint256 pendingExtraRewards);


    function claim() external;


}
