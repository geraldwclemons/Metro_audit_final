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

    function run() public  {
        
        vm.createSelectFork("sonic");

        address operator = vm.rememberKey(vm.envUint("SONIC_VAULT_OPERATOR_PRIVATE_KEY"));

        VaultFactory factory = VaultFactory(Addresses.VAULT_FACTORY_PROXY);

        address newOperator = 0x67b5A6779787350c49A02627cd7F7C321dFd593b;



        // factory.setOperator(BaseVault(payable(0x005941470c9fa95616c877b70b9e9841c2abd351)).getStrategy(), newOperator);
    }
}







