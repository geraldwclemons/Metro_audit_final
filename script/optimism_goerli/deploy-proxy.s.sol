// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

contract ProxyDeployer is Script {
    address AMDIN = 0xdeD212B8BAb662B98f49e757CbB409BB7808dc10;

    function run() public {
        vm.broadcast();
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        console.log("ProxyAdmin ---->", address(proxyAdmin));
    }
}
