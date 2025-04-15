// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

import "joe-v2/interfaces/ILBPair.sol";

import "../../src/VaultFactory.sol";
import "../../src/utils/OracleLensAggregator.sol";

contract VaultDeployer is Script {
    address AMDIN = 0xdeD212B8BAb662B98f49e757CbB409BB7808dc10;

    address PAIR_FANTOM = 0x511d22cF8f99d966bbF80FF42c5A5191a09d488b; // ftm-usdc

    address PRICE_LENS_FANTOM = 0x769078c6Bd2D8913523Cd32450D7fB946dD40dfA;
    address VAULT_FACTORY_FANTOM = 0x08d520AFEb367E66E28A9E0f503Ecd209b589Af6;

    address tokenX;
    address tokenY;
    address pair;
    address vaultFactory;
    address priceLens;

    function run() public {
        if (block.chainid == 250) {
            pair = PAIR_FANTOM;
            priceLens = PRICE_LENS_FANTOM;
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

        VaultFactory factory = VaultFactory(VAULT_FACTORY_FANTOM);

        vm.broadcast();
        (address vault, address strategy) = factory.createOracleVaultAndDefaultStrategy(lbPair, oracleX, oracleY);

        console.log("Vault created ---->", vault);
        console.log("Strategy created ---->", strategy);
    }
}
