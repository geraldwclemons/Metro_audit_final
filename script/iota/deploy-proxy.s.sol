// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

contract ProxyDeployer is Script {
    address AMDIN = 0x7F76D5b3a33A87061b5184Ae9BD301d6b7333185;

    function run() public {
        vm.broadcast();
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        console.log("ProxyAdmin ---->", address(proxyAdmin));
    }
}
