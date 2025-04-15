
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


contract Debug is Script {

    function run() public {
     vm.createSelectFork("sonic_blaze");

        address deployer = vm.rememberKey(vm.envUint("SONIC_PRIVATE_KEY"));


       OracleRewardVault vault = OracleRewardVault(payable(0x41C959c72429be3d8fAEd7057C96511F64EE50a0));

       Strategy strategy = Strategy(payable(address(vault.getStrategy())));

       console.log("Strategy", address(strategy));


    (uint24 lower, uint24 upper) = strategy.getRange();
    console.log("Lower", lower);
    console.log("Upper", upper);


       vm.startBroadcast(deployer);

       strategy.emergencyWidthdrawRange(lower, upper);

       vm.stopBroadcast();
    }
}
