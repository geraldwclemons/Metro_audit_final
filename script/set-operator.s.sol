// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";

import "../src/VaultFactory.sol";
import "../src/Strategy.sol";

contract SetOperator is Script {
    address AMDIN = 0xdeD212B8BAb662B98f49e757CbB409BB7808dc10;

    address STRATEGY_FANTOM_TESTNET = 0x28f01638aD635Ed001D76bdB1faA767bF60D7E06; // eth-btc strategy
    address VAULT_FACTORY_FANTOM_TESTNET = 0xc4e9E5aE18bf3078706B38b26a3fC5b31833BA10;
    address OPERATOR_FANTOM_TESTNET = 0xcaD3477b8D2569c849298E82D10046eD422AC258;

    address strategy;
    address vaultFactory;
    address operator;

    function run() public {
        if (block.chainid == 4002) {
            strategy = STRATEGY_FANTOM_TESTNET;
            vaultFactory = VAULT_FACTORY_FANTOM_TESTNET;
            operator = OPERATOR_FANTOM_TESTNET;
        }

        VaultFactory factoryProxy = VaultFactory(vaultFactory);

        vm.broadcast();
        factoryProxy.setOperator(Strategy(strategy), operator);
    }
}
