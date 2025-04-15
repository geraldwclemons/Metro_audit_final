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

contract SetOperator is Script {
    address ADMIN = 0x7F76D5b3a33A87061b5184Ae9BD301d6b7333185;

    address VAULT_FACTORY_PROXY = 0xfc7f189ACeF2Dd11e3bCB32C43807A5c15EC4FF2;

    address VAULT_ADDRESS = 0xE6e9a98F0CD6f89a872943d4f7c1Fe8faECAdf77;

    address NEW_OPERATOR = 0x7F76D5b3a33A87061b5184Ae9BD301d6b7333185;

    function run() public {
        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));

        vm.createSelectFork("iota_testnet");

        VaultFactory factory = VaultFactory(VAULT_FACTORY_PROXY);

        OracleRewardVault oracleRewardVault = OracleRewardVault(payable(VAULT_ADDRESS));
        IStrategy strategy = oracleRewardVault.getStrategy();

        console.log("Current default operator", factory.getDefaultOperator());
        console.log("Current vault operator", strategy.getOperator());

        vm.broadcast(deployer);
        factory.setOperator(strategy, NEW_OPERATOR);

        require(0 == factory.getVaultsByMarketMaker(0xdeD212B8BAb662B98f49e757CbB409BB7808dc10).length, "1::length");
        require(1 == factory.getVaultsByMarketMaker(0x7F76D5b3a33A87061b5184Ae9BD301d6b7333185).length, "2::length");

        IVaultFactory.MakerVault[] memory makerVaults = factory.getMarketMakerVaults();
        for (uint256 i = 0; i < makerVaults.length; i++) {
            console.log("Vault %s: %s", makerVaults[i].vault, makerVaults[i].operator);
        }
    }
}
