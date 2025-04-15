// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

import "src/VaultFactory.sol";
import "src/interfaces/IVaultFactory.sol";

import "src/Strategy.sol";
import "src/SimpleVault.sol";
import "src/OracleVault.sol";
import "src/libraries/Constants.sol";

contract CoreDeployer is Script {
    address ADMIN_PROXY = 0x2D52467D074B3590760831af816046471a81bf3a;
    address ADMIN = 0xdeD212B8BAb662B98f49e757CbB409BB7808dc10;
    address WETH_ZKEVM_TESTNET = 0x4671AcA0C1fe99fE6779606698E61783d4520a41;

    address wnative;

    function run() public {
        if (block.chainid == 1442) {
            wnative = WETH_ZKEVM_TESTNET;
        }

        vm.broadcast();
        VaultFactory factory = new VaultFactory(wnative);

        console.log("VaultFactory ---->", address(factory));

        vm.broadcast();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(factory), ADMIN_PROXY, "");

        console.log("VaultFactory Proxy ---->", address(proxy));

        VaultFactory factoryProxy = VaultFactory(address(proxy));

        vm.broadcast();
        factoryProxy.initialize(ADMIN);

        console.log("VaultFactory Proxy ---->", address(factoryProxy));

        vm.broadcast();
        Strategy strategy = new Strategy(IVaultFactory(address(proxy)), Constants.DEFAULT_MAX_RANGE);
        console.log("Strategy ---->", address(strategy));

        vm.broadcast();
        SimpleVault simpleVault = new SimpleVault(IVaultFactory(address(proxy)));
        console.log("SimpleVault ---->", address(simpleVault));

        vm.broadcast();
        OracleVault oracleVault = new OracleVault(IVaultFactory(address(proxy)));
        console.log("OracleVault ---->", address(oracleVault));

        console.log("Set implementation");

        vm.startBroadcast();
        factoryProxy.setVaultImplementation(IVaultFactory.VaultType.Simple, address(simpleVault));

        factoryProxy.setVaultImplementation(IVaultFactory.VaultType.Oracle, address(oracleVault));

        factoryProxy.setStrategyImplementation(IVaultFactory.StrategyType.Default, address(strategy));

        vm.stopBroadcast();
    }
}
