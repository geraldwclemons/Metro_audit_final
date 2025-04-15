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
import "./config/Addresses.sol";
contract CoreDeployer is Script {
    // address ADMIN = 0x4A3723B6e427Ecbd90f2848d6dF9381A676a02b9;
    address WNATIVE = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;

    // address internal constant PRICE_LENS = 0x2443e5165DB8a8A7cff5d66Cb9861806332aCE4D;

    address wnative;

    function run() public returns (address proxyAdmin, VaultFactory factoryImpl, TransparentUpgradeableProxy proxy) {
        // WE DEPLOY HERE ONLY A DUMMY FOR LATER USE

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));
        vm.createSelectFork("sonic");

        vm.broadcast(deployer);
        factoryImpl = new VaultFactory(WNATIVE);

        console.log("VaultFactoryImpl ---->", address(factoryImpl));

        vm.broadcast(deployer);
        proxyAdmin = address(new ProxyAdmin());

        console.log("Admin Proxy", proxyAdmin);

        // This version of proxy does not deploy a proxy admin
        vm.broadcast(deployer);
        proxy = new TransparentUpgradeableProxy(
            address(factoryImpl),
            proxyAdmin,
            abi.encodeWithSelector(VaultFactory.initialize4.selector, deployer, 4 ether)
        );

        console.log("VaultFactory Proxy ---->", address(proxy));

        require(proxyAdmin == ProxyHelper.getAdminAddress(address(proxy)), "Admin address mismatch");
    }
}

contract Upgrade is Script {
    address WNATIVE = Addresses.WNATIVE;
    address VAULT_FACTORY_PROXY = Addresses.VAULT_FACTORY_PROXY;

    function run() public {
        vm.createSelectFork("sonic");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));

        ProxyAdmin proxyAdmin = ProxyAdmin(Addresses.PROXY_ADMIN_MAINNET);
        VaultFactory factoryProxy = VaultFactory(address(VAULT_FACTORY_PROXY));

        vm.startBroadcast(deployer);
        VaultFactory impl = new VaultFactory(WNATIVE);

        proxyAdmin.upgradeAndCall(
            TransparentUpgradeableProxy(payable(VAULT_FACTORY_PROXY)), address(impl), 
                abi.encodeWithSelector(VaultFactory.initialize4.selector, deployer, 400 ether));

        factoryProxy.setDefaultOperator(Addresses.DEFAULT_OPERATOR);
        factoryProxy.setFeeRecipient(Addresses.FEE_RECIPIENT);

        vm.stopBroadcast();
    }
}

contract SetImplementaiton is Script {
    address PRICE_LENS = Addresses.PRICE_LENS;
    address VAULT_FACTORY_PROXY = Addresses.VAULT_FACTORY_PROXY;

    function run() public {
        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));
        vm.createSelectFork("sonic");

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




contract CreateVault is Script {
    address VAULT_FACTORY_PROXY = 0xfc7f189ACeF2Dd11e3bCB32C43807A5c15EC4FF2;

    function run() public {
        vm.createSelectFork("sonic");

        address deployer = vm.rememberKey(vm.envUint("DEV2_PRIVATE_KEY"));

        VaultFactory factory = VaultFactory(VAULT_FACTORY_PROXY);

        uint256 creationFee = factory.getCreationFee();

        vm.broadcast(deployer);
        factory.createMarketMakerOracleVault{value: creationFee}(ILBPair(0x8d7bD0dA2F2172027C1FeFc335a1594238C76A20), 0.1e4);
    }
}

contract WhitelistLbPairs is Script {
    address VAULT_FACTORY_PROXY = Addresses.VAULT_FACTORY_PROXY;

    address[] pairs = [
        // 0x5015643B8dB50A1cB779A3e134176237d14ca67a
        // 0x18536F666624C3Fb1C1266FE015C6e7828A09228
        // 0x56B404073C990E828691aF936bcfFf710f6c97A1
        0xdD93c63fFC4B4a85daaec86a4752D616E03a3015,
        0xEbcCE8b534A35E93c7Cf25f3FfF2F8202F9f0655,
        0x6ea10f2bd54520c5EA9a988F34a07b89A2C1B441,
        0x3987a13D675c66570bC28c955685a9bcA2dCF26e,
        0x74717286ECb77Bfad051e3Db5Ec6433f2A6A1B9b
    ];

    function run() public {
        vm.createSelectFork("sonic");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));


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

contract SetOwner is Script {
   

    function run() public {
        vm.createSelectFork("sonic");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));

        VaultFactory factory = VaultFactory(Addresses.VAULT_FACTORY_PROXY);
        ProxyAdmin proxyAdmin = ProxyAdmin(Addresses.PROXY_ADMIN_MAINNET);
        vm.startBroadcast(deployer);

        proxyAdmin.transferOwnership(Addresses.SAFE_DEV_WALLET);
        factory.transferOwnership(Addresses.SAFE_DEV_WALLET);
        vm.stopBroadcast();

        console.log("Owner set to", factory.pendingOwner());
        console.log("ProxyAdmin owner set to", proxyAdmin.owner());
    }
}

contract WithdrawRange is Script {

    function run() public {
        vm.createSelectFork("sonic");

        address operator = vm.rememberKey(vm.envUint("SONIC_VAULT_OPERATOR_PRIVATE_KEY"));
        
        Strategy strategy = Strategy(0x3A26a5C3Ca6303eB41E974b9bcDc8461B9F165BB);
        OracleRewardVault vault = OracleRewardVault(payable(strategy.getVault()));

        (uint24 lower, uint24 upper) = strategy.getRange();
        console.log("Lower", lower);
        console.log("Upper", upper);

        vm.startBroadcast(operator);
        // strategy.emergencyWidthdrawRange(8374446, 8374447);
        //strategy.emergencyWidthdrawRange(8374443, 8374444);


        // vault.submitShutdown();

        // strategy.emergencyWidthdrawRange(8374445, 8374445);
        // vault.submitShutdown();
        vm.stopBroadcast();
    }
}

