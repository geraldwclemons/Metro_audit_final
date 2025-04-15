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

contract Upgrade is Script {
    address ADMIN_PROXY = 0x90F28Fe6963cE929d4cBc3480Df1169b92DD22B7;
    address ADMIN = 0x4A3723B6e427Ecbd90f2848d6dF9381A676a02b9;

    address WNATIVE = 0xceebE42DC2336f5483e026F68fe599cEc3E6f114;

    address VAULT_FACTORY_PROXY = 0xe77DA7F5B6927fD5E0e825B2B27aca526341069B;

    address PRICE_LENS = 0x39D966c1BaFe7D3F1F53dA4845805E15f7D6EE43;

    function run() public {
        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));
        vm.createSelectFork("sonic_testnet");

        ProxyAdmin proxyAdmin = ProxyAdmin(ADMIN_PROXY);

        vm.broadcast(deployer);
        VaultFactory impl = new VaultFactory(WNATIVE);

        vm.broadcast(deployer);
        proxyAdmin.upgradeAndCall(
            TransparentUpgradeableProxy(payable(VAULT_FACTORY_PROXY)),
            address(impl),
            abi.encodeWithSelector(VaultFactory.initialize4.selector, deployer, 0.01 ether)
        );

        // set vault and strategy

        VaultFactory factory = VaultFactory(VAULT_FACTORY_PROXY);
        vm.broadcast(deployer);
        OracleRewardVault vault = new OracleRewardVault(IVaultFactory(VAULT_FACTORY_PROXY));
        console.log("OracleVault Implementation --->", address(vault));

        vm.broadcast(deployer);
        factory.setVaultImplementation(IVaultFactory.VaultType.Oracle, address(vault));

        vm.broadcast(deployer);
        Strategy strategy = new Strategy(IVaultFactory(address(factory)), Constants.DEFAULT_MAX_RANGE);
        console.log("Strategy Implementation --->", address(strategy));

        vm.broadcast(deployer);
        factory.setStrategyImplementation(IVaultFactory.StrategyType.Default, address(strategy));

        vm.broadcast(deployer);
        factory.setPriceLens(IPriceLens(PRICE_LENS));
    }
}
