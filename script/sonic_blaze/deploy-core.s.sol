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

/**
 * Deployment
 * 
 * == Return ==
proxyAdmin: address 0xc7E7802814Abf6A302C6fAe01Ab9f7773F7583F7
factoryImpl: contract VaultFactory 0x6C1F5aEF283488944AAdafc109Ca2e8e5b59Cdf3
proxy: contract TransparentUpgradeableProxy 0xE640B1aD57FDadf8aa60d715A455b40Eb374d90b

== Logs ==
  VaultFactoryImpl ----> 0x6C1F5aEF283488944AAdafc109Ca2e8e5b59Cdf3
  Admin Proxy 0xc7E7802814Abf6A302C6fAe01Ab9f7773F7583F7
  VaultFactory Proxy ----> 0xE640B1aD57FDadf8aa60d715A455b40Eb374d90b
 * 
 * @title 
 * 
 * @author 
 * @notice 
 */

contract CoreDeployer is Script {
    // address ADMIN = 0x4A3723B6e427Ecbd90f2848d6dF9381A676a02b9;
    address WNATIVE = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;

    // address internal constant PRICE_LENS = 0x2443e5165DB8a8A7cff5d66Cb9861806332aCE4D;

    address wnative;

    function run() public returns (address proxyAdmin, VaultFactory factoryImpl, TransparentUpgradeableProxy proxy) {
        // WE DEPLOY HERE ONLY A DUMMY FOR LATER USE

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));
        vm.createSelectFork("sonic_blaze");

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

        /*
        VaultFactory factoryProxy = VaultFactory(address(proxy));

        vm.broadcast(deployer);
        Strategy strategy = new Strategy(IVaultFactory(address(proxy)));
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

        factoryProxy.setVaultImplementation(
            IVaultFactory.VaultType.Oracle,
            address(oracleRewardVault));

        factoryProxy.setStrategyImplementation(
            IVaultFactory.StrategyType.Default,
            address(strategy));
        
        factoryProxy.setPriceLens(IPriceLens(PRICE_LENS));
        vm.stopBroadcast(); */
    }
}

contract Upgrade is Script {
    address WNATIVE = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address PROXY_ADMIN_ADDRESS = 0xc7E7802814Abf6A302C6fAe01Ab9f7773F7583F7;
    address VAULT_FACTORY_PROXY = 0xE640B1aD57FDadf8aa60d715A455b40Eb374d90b;

    function run() public {
        vm.createSelectFork("sonic_blaze");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));

        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_ADDRESS);

        vm.broadcast(deployer);
        VaultFactory impl = new VaultFactory(WNATIVE);

        vm.broadcast(deployer);
        proxyAdmin.upgrade(TransparentUpgradeableProxy(payable(VAULT_FACTORY_PROXY)), address(impl));
    }
}

contract SetImplementaiton is Script {
    address PRICE_LENS = 0x96F4DF3E7ee90479d3A3cFe4f9557389DFB1C54b;
    address VAULT_FACTORY_PROXY = 0xE640B1aD57FDadf8aa60d715A455b40Eb374d90b;

    function run() public {
        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));
        vm.createSelectFork("sonic_blaze");

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
    address VAULT_FACTORY_PROXY = 0xE640B1aD57FDadf8aa60d715A455b40Eb374d90b;

    function run() public {
        vm.createSelectFork("sonic_blaze");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));

        vm.startBroadcast(deployer);

        ILBPair pair = ILBPair(0x5A2251254224Eb5eA9b459c6922C887e3E4054F7);
        (, uint256 oracleLength, , , ) = pair.getOracleParameters();
        if (oracleLength < 4) {
            pair.increaseOracleLength(4);
        }

        ILBPair pair2 = ILBPair(0x1C66bdc08346AE6B3c98d700B94d391c7B333a1d);
        (, oracleLength, , , ) = pair2.getOracleParameters();
        if (oracleLength < 4) {
            pair2.increaseOracleLength(4);
        }

        VaultFactory factory = VaultFactory(VAULT_FACTORY_PROXY);

        address[] memory pairs = new address[](2);
        pairs[0] = address(pair);
        pairs[1] = address(pair2);

        factory.setPairWhitelist(pairs, true);

        vm.stopBroadcast();
    }
}

contract UpgradeSetImpAndCreateVault is Script {
    address WNATIVE = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
    address VAULT_FACTORY_PROXY = 0xE640B1aD57FDadf8aa60d715A455b40Eb374d90b;
    address PROXY_ADMIN_ADDRESS = 0xc7E7802814Abf6A302C6fAe01Ab9f7773F7583F7;
    address PRICE_LENS = 0x96F4DF3E7ee90479d3A3cFe4f9557389DFB1C54b;
    function run() public {
        vm.createSelectFork("sonic_blaze");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));

        ProxyAdmin proxyAdmin = ProxyAdmin(PROXY_ADMIN_ADDRESS);

        vm.broadcast(deployer);
        VaultFactory impl = new VaultFactory(WNATIVE);

        vm.broadcast(deployer);
        proxyAdmin.upgrade(TransparentUpgradeableProxy(payable(VAULT_FACTORY_PROXY)), address(impl));

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

        VaultFactory factoryProxy = VaultFactory(VAULT_FACTORY_PROXY);

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

        // uint256 creationFee = factoryProxy.getCreationFee();
        // vm.broadcast(deployer);
        // factoryProxy.createMarketMakerOracleVault{value: creationFee}(
        //     ILBPair(0x5A2251254224Eb5eA9b459c6922C887e3E4054F7), 0.1e4);
    }
}   

contract CreateVault is Script {
    address VAULT_FACTORY_PROXY = 0xE640B1aD57FDadf8aa60d715A455b40Eb374d90b;

    function run() public {
        vm.createSelectFork("sonic_blaze");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));

        VaultFactory factory = VaultFactory(VAULT_FACTORY_PROXY);

        uint256 creationFee = factory.getCreationFee();

        vm.broadcast(deployer);
        factory.createMarketMakerOracleVault{value: creationFee}(
            ILBPair(0x5A2251254224Eb5eA9b459c6922C887e3E4054F7), 0.1e4);
    }
}

contract Rebalance is Script {
    function run() public {
        vm.createSelectFork("sonic_blaze");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));

        //vm.startBroadcast(deployer);

        IOracleRewardVault vault = IOracleRewardVault(0xCA2FC0bf428a6199f1eB337917692d240e378138);

        IStrategy strategy = IStrategy(vault.getStrategy());

        console.log("strategy", address(strategy));

        console.log("hasRewards", strategy.hasRewards());

       (uint256 amount0, uint256 amount1) = vault.getBalances();

       console.log("amount0", amount0);
       console.log("amount1", amount1);

        vm.startBroadcast(deployer);
      strategy.rebalance(
        0, 0, 0, 0, 0, 0, new bytes(0)
      );
        vm.stopBroadcast();
    }
}


contract Deposit is Script {
    using Uint256x256Math for uint256;


    address VAULT = 0xF5A68FBEe353Ed9774Fe51170d3Fa78C28b8B7C5;

    function run() public {
        vm.createSelectFork("sonic_blaze");

        OracleRewardVault vault = OracleRewardVault(payable(VAULT));

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));


        console.log("price", _getPrice(vault));

        ILBPair pair =vault.getPair();
        uint24 activeId = pair.getActiveId();
        uint256 priceScaled = pair.getPriceFromId(activeId);

        uint8 decimalsX = IERC20MetadataUpgradeable(address(vault.getTokenX())).decimals();
        uint8 decimalsY = IERC20MetadataUpgradeable(address(vault.getTokenY())).decimals();
        // (priceScaled, uint256 precision) = (type(uint256).max / priceScaled, 10 ** (18 + decimalsY - decimalsX));

        uint256 price = priceScaled.mulShiftRoundDown(1e18, 128);

        console.log("price from ID", price);


        vm.startBroadcast(deployer);

        
        vault.depositNative{value: 1e18}(1e6, 1e18, 0);
        vm.stopBroadcast();
    }

    function _getPrice(IOracleVault vault) internal view returns (uint256 price) {
        uint8 decimalsX = IERC20MetadataUpgradeable(address(vault.getTokenX())).decimals();
        uint8 decimalsY = IERC20MetadataUpgradeable(address(vault.getTokenY())).decimals();

        (, int256 priceX, , , ) = vault.getOracleX().latestRoundData();
        uint256 scaledPriceX = uint256(priceX) * 10 ** decimalsX;

        (, int256 priceY, , , ) = vault.getOracleY().latestRoundData();
        uint256 scaledPriceY = uint256(priceY) * 10 ** decimalsY;

        // Essentially does `price = (priceX / 1eDecimalsX) / (priceY / 1eDecimalsY)`
        // with 128.128 binary fixed point arithmetic.
        price = scaledPriceX.shiftDivRoundDown(128, scaledPriceY);
    }
}

contract VaultBalances is Script {
    uint256 private constant _BASIS_POINTS = 1e4;
    uint256 private constant _SCALED_YEAR = 365 days * _BASIS_POINTS;
    uint256 private constant _SCALED_YEAR_SUB_ONE = _SCALED_YEAR - 1;
    function run() public {
        vm.createSelectFork("sonic_blaze");

        OracleRewardVault vault = OracleRewardVault(payable(0xF5A68FBEe353Ed9774Fe51170d3Fa78C28b8B7C5));

        (uint256 amount0, uint256 amount1) = vault.getBalances();

        console.log("aumAnnualFee", vault.getAumAnnualFee());

        console.log("amount0", amount0);
        console.log("amount1", amount1);

        uint256 duration = block.timestamp - IStrategy(vault.getStrategy()).getLastRebalance();
        duration = duration > 1 days ? 1 days : duration;

        uint256 feeX = (amount0 * vault.getAumAnnualFee() * duration + _SCALED_YEAR_SUB_ONE) / _SCALED_YEAR;
        uint256 feeY = (amount1 * vault.getAumAnnualFee() * duration + _SCALED_YEAR_SUB_ONE) / _SCALED_YEAR;

        console.log("feeX", feeX);
        console.log("feeY", feeY);

        console.log("amount0 - feeX", amount0 - feeX);
        console.log("amount1 - feeY", amount1 - feeY);


        console.log("Strategy", address(vault.getStrategy()));
    }
}

