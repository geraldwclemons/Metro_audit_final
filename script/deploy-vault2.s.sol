// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

import "joe-v2/interfaces/ILBPair.sol";

import "../src/VaultFactory.sol";
import "../src/utils/OracleLensAggregator.sol";

contract Vault2Deployer is Script {
    address AMDIN = 0xdeD212B8BAb662B98f49e757CbB409BB7808dc10;

    address PAIR_FANTOM_TESTNET = 0x95be17AddCF8Af907Baa07df28FfBE421ff5dc04; // eth-ftm

    address PRICE_LENS_FANTOM_TESTNET = 0xe81ea8e2C236aC7149bEB1Ba69f21c52fA11a1F8; // 0x56018054BEaC139D6B9cEf9973963DEE7Ed217c3;
    address VAULT_FACTORY_FANTOM_TESTNET = 0xc4e9E5aE18bf3078706B38b26a3fC5b31833BA10;

    address OPERATOR = 0xcaD3477b8D2569c849298E82D10046eD422AC258;

    address tokenX;
    address tokenY;
    address pair;
    address vaultFactory;
    address priceLens;

    function run() public {
        if (block.chainid == 4002) {
            pair = PAIR_FANTOM_TESTNET;
            priceLens = PRICE_LENS_FANTOM_TESTNET;
        }

        ILBPair lbPair = ILBPair(pair);

        tokenX = address(lbPair.getTokenX());
        tokenY = address(lbPair.getTokenY());

        vm.broadcast();
        OracleLensAggregator oracleX = new OracleLensAggregator(priceLens, tokenX);
        console.log("OracleX ---->", address(oracleX));

        vm.broadcast();
        OracleLensAggregator oracleY = new OracleLensAggregator(priceLens, tokenY);
        console.log("OracleY ---->", address(oracleY));

        VaultFactory factory = VaultFactory(VAULT_FACTORY_FANTOM_TESTNET);

        vm.broadcast();
        (address vault, address strategy) = factory.createOracleVaultAndDefaultStrategy(lbPair, oracleX, oracleY);

        console.log("Vault created ---->", vault);
        console.log("Strategy created ---->", strategy);

        vm.broadcast();
        factory.setOperator(IStrategy(strategy), OPERATOR);
    }
}
