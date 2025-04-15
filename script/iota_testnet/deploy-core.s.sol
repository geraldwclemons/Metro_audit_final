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

contract CoreDeployer is Script {
    address ADMIN = 0x7F76D5b3a33A87061b5184Ae9BD301d6b7333185;
    address WNATIVE = 0xB2E0DfC4820cc55829C71529598530E177968613;

    address internal constant PRICE_LENS = 0x2443e5165DB8a8A7cff5d66Cb9861806332aCE4D;

    address wnative;

    function run() public returns (address proxyAdmin, VaultFactory factoryImpl, TransparentUpgradeableProxy proxy) {
        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));

        if (block.chainid == 1075) {
            wnative = WNATIVE;
        }

        vm.broadcast(deployer);
        factoryImpl = new VaultFactory(wnative);

        console.log("VaultFactoryImpl ---->", address(factoryImpl));

        vm.broadcast(deployer);
        proxyAdmin = address(new ProxyAdmin());

        console.log("Admin Proxy", proxyAdmin);

        // This version of proxy does not deploy a proxy admin
        vm.broadcast(deployer);
        proxy = new TransparentUpgradeableProxy(
            address(factoryImpl), proxyAdmin, abi.encodeWithSelector(VaultFactory.initialize2.selector, deployer)
        );

        console.log("VaultFactory Proxy ---->", address(proxy));

        require(proxyAdmin == ProxyHelper.getAdminAddress(address(proxy)), "Admin address mismatch");

        VaultFactory factoryProxy = VaultFactory(address(proxy));

        vm.broadcast(deployer);
        Strategy strategy = new Strategy(IVaultFactory(address(proxy)), Constants.DEFAULT_MAX_RANGE);
        console.log("Strategy ---->", address(strategy));

        vm.broadcast(deployer);
        SimpleVault simpleVault = new SimpleVault(IVaultFactory(address(proxy)));
        console.log("SimpleVault ---->", address(simpleVault));

        vm.broadcast(deployer);
        OracleRewardVault oracleRewardVault = new OracleRewardVault(IVaultFactory(address(proxy)));
        console.log("OracleVault ---->", address(oracleRewardVault));

        console.log("Set implementation");

        console.log("Factory owner", factoryProxy.owner());

        vm.startBroadcast(deployer);
        // factoryProxy.setVaultImplementation(
        //     IVaultFactory.VaultType.Simple,
        //     address(simpleVault));

        factoryProxy.setVaultImplementation(IVaultFactory.VaultType.Oracle, address(oracleRewardVault));

        factoryProxy.setStrategyImplementation(IVaultFactory.StrategyType.Default, address(strategy));

        factoryProxy.setPriceLens(IPriceLens(PRICE_LENS));
        vm.stopBroadcast();
    }
}

contract Upgrade is Script {
    address WNATIVE = 0xB2E0DfC4820cc55829C71529598530E177968613;
    address PROXY_ADMIN_ADDRESS = 0xBe1Bf27eEfE2004dd10daD96cECDE85D4C779B74;
    address VAULT_FACTORY_PROXY = 0xfc7f189ACeF2Dd11e3bCB32C43807A5c15EC4FF2;

    function run() public {
        vm.createSelectFork("iota_testnet");

        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));

        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_ADDRESS);

        vm.broadcast(deployer);
        VaultFactory impl = new VaultFactory(WNATIVE);

        vm.broadcast(deployer);
        proxyAdmin.upgrade(TransparentUpgradeableProxy(payable(VAULT_FACTORY_PROXY)), address(impl));
    }
}

contract SetImplementaiton is Script {
    address PRICE_LENS = 0x2443e5165DB8a8A7cff5d66Cb9861806332aCE4D;
    address VAULT_FACTORY_PROXY = 0xfc7f189ACeF2Dd11e3bCB32C43807A5c15EC4FF2;

    function run() public {
        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));
        vm.createSelectFork("iota_testnet");

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

    function run() public {
        vm.createSelectFork("sonic_blaze");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        ILBPair pair = ILBPair(0x8d7bD0dA2F2172027C1FeFc335a1594238C76A20);

        vm.stopBroadcast();
    }
}


contract Deposit is Script {
    address VAULT = 0x09043c0819C8CD8CfCa85637a8D5d4E4CA35416e;

    function run() public {
        vm.createSelectFork("iota_testnet");

        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));

        IOracleRewardVault vault = IOracleRewardVault(VAULT);

        vm.broadcast(deployer);
        vault.depositNative{value: 1e18}(1e6, 1e18, 0);
    }

}

contract CreateVault is Script {
    address VAULT_FACTORY_PROXY = 0xfc7f189ACeF2Dd11e3bCB32C43807A5c15EC4FF2;

    function run() public {
        vm.createSelectFork("iota_testnet");

        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));

        VaultFactory factory = VaultFactory(VAULT_FACTORY_PROXY);

        uint256 creationFee = factory.getCreationFee();

        vm.broadcast(deployer);
        factory.createMarketMakerOracleVault{value: creationFee}(ILBPair(0x8d7bD0dA2F2172027C1FeFc335a1594238C76A20), 0.1e4);
    }
}
