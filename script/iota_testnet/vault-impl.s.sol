// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";
import "../helper.sol";

import "src/VaultFactory.sol";
import "src/interfaces/IVaultFactory.sol";

import "src/Strategy.sol";
import "src/SimpleVault.sol";
import "src/OracleRewardVault.sol";
import "src/libraries/Constants.sol";

contract UpgradeVaultImpl is Script {
    address ADMIN = 0x7F76D5b3a33A87061b5184Ae9BD301d6b7333185;

    address VAULT_FACTORY_PROXY = 0xfc7f189ACeF2Dd11e3bCB32C43807A5c15EC4FF2;

    bool _deployStrategy = true;

    function run() public returns (OracleRewardVault vault) {
        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));

        vm.createSelectFork("iota_testnet");

        VaultFactory factory = VaultFactory(VAULT_FACTORY_PROXY);

        vm.broadcast(deployer);
        vault = new OracleRewardVault(IVaultFactory(VAULT_FACTORY_PROXY));
        console.log("OracleVault ---->", address(vault));

        vm.broadcast(deployer);
        factory.setVaultImplementation(IVaultFactory.VaultType.Oracle, address(vault));

        if (_deployStrategy) {
            vm.broadcast(deployer);
            Strategy strategy = new Strategy(IVaultFactory(address(factory)), Constants.IOTA_MAX_RANGE);
            console.log("Strategy ---->", address(strategy));

            vm.broadcast(deployer);
            factory.setStrategyImplementation(IVaultFactory.StrategyType.Default, address(strategy));
        }
    }
}

contract SetEmergencyWithdraw is Script {
    address ADMIN = 0x7F76D5b3a33A87061b5184Ae9BD301d6b7333185;

    address VAULT_FACTORY_PROXY = 0xfc7f189ACeF2Dd11e3bCB32C43807A5c15EC4FF2;

    // address VAULT_ADDRESS = 0xE2b5f5BBeA31E75B8BB06AC28857FF590019682C;
    address VAULT_ADDRESS = 0xE2b5f5BBeA31E75B8BB06AC28857FF590019682C;

    address[] vaults = [
        // 0x0D895676A4bCd4647E0D900b017d35C7039DE728
        0x1d5edE2019943F8aE03271BCfa4C1Be3BE183771,
        0x37267ed5a09fD5493f724f02974C68fF44420a3e,
        0x72b98f8466dC15ce5C10D20b491FE7446B9e4742,
        0xda9091E91eC0f2a6B564246a418a19B314e3C1D3
    ];

    function run() public {
        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));

        vm.createSelectFork("iota_testnet");

        VaultFactory factory = VaultFactory(VAULT_FACTORY_PROXY);

        for (uint256 i = 0; i < vaults.length; i++) {
            vm.broadcast(deployer);
            factory.setEmergencyMode(OracleRewardVault(payable(vaults[i])));
        }

        // OracleRewardVault oracleRewardVault = OracleRewardVault(payable(VAULT_ADDRESS));

        //vm.broadcast(deployer);
        // factory.setEmergencyMode(oracleRewardVault);
    }
}
