// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";
import "src/VaultFactory.sol";
import "src/interfaces/IVaultFactory.sol";

import "src/Strategy.sol";
import "src/SimpleVault.sol";
import "src/OracleVault.sol";
import "src/OracleRewardVault.sol";
import "src/libraries/Constants.sol";
import "./config/Addresses.sol"; 

contract CoreDeployer is Script {
    address ADMIN_PROXY = 0xa0229891BaC4777656f77Ca761E1fac8B9Cf8283;
    address ADMIN = 0x7F76D5b3a33A87061b5184Ae9BD301d6b7333185;
    address WNATIVE = 0x6e47f8d48a01b44DF3fFF35d258A10A3AEdC114c;

    address wnative;

    function run() public {
        if (block.chainid == 8822) {
            wnative = WNATIVE;
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


contract Upgrade is Script {
    address WNATIVE = Addresses.WNATIVE;
    address VAULT_FACTORY_PROXY = Addresses.VAULT_FACTORY_PROXY;

    function run() public {
        vm.createSelectFork("iota");

        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));

        ProxyAdmin proxyAdmin = ProxyAdmin(Addresses.PROXY_ADMIN_MAINNET);
        VaultFactory factoryProxy = VaultFactory(address(VAULT_FACTORY_PROXY));

        vm.startBroadcast(deployer);
        VaultFactory impl = new VaultFactory(WNATIVE);

        proxyAdmin.upgradeAndCall(
            TransparentUpgradeableProxy(payable(VAULT_FACTORY_PROXY)), address(impl), 
                abi.encodeWithSelector(VaultFactory.initialize4.selector, deployer, 1000 ether));
        
        factoryProxy.setDefaultOperator(Addresses.DEFAULT_OPERATOR);
        factoryProxy.setFeeRecipient(Addresses.FEE_RECIPIENT);

        vm.stopBroadcast();
    }
}

contract SetImplementaiton is Script {
    address PRICE_LENS = Addresses.PRICE_LENS;
    address VAULT_FACTORY_PROXY = Addresses.VAULT_FACTORY_PROXY;

    function run() public {
        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));
        vm.createSelectFork("iota");

        VaultFactory factoryProxy = VaultFactory(address(VAULT_FACTORY_PROXY));

        vm.broadcast(deployer);
        Strategy strategy = new Strategy(IVaultFactory(address(VAULT_FACTORY_PROXY)), Constants.DEFAULT_MAX_RANGE);
        console.log("Strategy ---->", address(strategy));

        vm.broadcast(deployer);
        SimpleVault simpleVault = new SimpleVault(IVaultFactory(address(VAULT_FACTORY_PROXY)));
        console.log("SimpleVault ---->", address(simpleVault));

        vm.broadcast(deployer);
        OracleRewardVault oracleRewardVault = new OracleRewardVault(IVaultFactory(address(VAULT_FACTORY_PROXY)));
        console.log("OracleVault ---->", address(oracleRewardVault));

        console.log("Set implementation");

        console.log("Factory owner", factoryProxy.owner());

        vm.startBroadcast(deployer);

        factoryProxy.setVaultImplementation(
            IVaultFactory.VaultType.Oracle,
            address(oracleRewardVault));

        factoryProxy.setStrategyImplementation(
            IVaultFactory.StrategyType.Default,
            address(strategy));
        
        factoryProxy.setPriceLens(IPriceLens(PRICE_LENS));
        vm.stopBroadcast();
    }

}

contract WhitelistLbPairs is Script {
    address VAULT_FACTORY_PROXY = Addresses.VAULT_FACTORY_PROXY;

    address[] pairs = [
        //0xa86d3169d5cccdC224637aDAd34F4F1Be174000C
        0xbac6c7808C453E988163283Eb71E876cB325A3EE,
        0xE919092CC7CBD2097ae3158f72Da484ac813b74b
    ];

    function run() public {
        vm.createSelectFork("iota");

        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));


        VaultFactory factory = VaultFactory(VAULT_FACTORY_PROXY);
        vm.startBroadcast(deployer);

        for (uint256 i = 0; i < pairs.length; i++) {
            ILBPair pair = ILBPair(pairs[i]);
            (, uint256 oracleLength, , , ) = pair.getOracleParameters();
            if (oracleLength < 4) {
                pair.increaseOracleLength(4);
            }
        }

        factory.setPairWhitelist(pairs, true);

        vm.stopBroadcast();
    }
}

