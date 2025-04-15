// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

import "joe-v2/interfaces/ILBPair.sol";

import "../../src/VaultFactory.sol";
import "../../src/utils/OracleLensAggregator.sol";

contract VaultOpEthDeployer is Script {
    address AMDIN = 0xdeD212B8BAb662B98f49e757CbB409BB7808dc10;

    address PAIR_OPTIMISM_TESTNET = 0x6d8aB7Df45AC13722B726434bfc37e5C53710768; // op-eth

    address PRICE_LENS_OPTIMISM_TESTNET = 0x97e792198443482385c3BD7Eb16d11D0462ec10b;
    address VAULT_FACTORY_OPTIMISM_TESTNET = 0x6e6577Ae563D28c6FD0b5d1F2f32361339deB09e;

    address OPERATOR = 0xcaD3477b8D2569c849298E82D10046eD422AC258;

    uint16 AUM_FEE = 400; // 4%

    address tokenX;
    address tokenY;
    address pair;
    address vaultFactory;
    address priceLens;

    function run() public {
        if (block.chainid == 420) {
            pair = PAIR_OPTIMISM_TESTNET;
            priceLens = PRICE_LENS_OPTIMISM_TESTNET;
        } else {
            revert("wrong chain");
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

        VaultFactory factory = VaultFactory(VAULT_FACTORY_OPTIMISM_TESTNET);

        vm.broadcast();
        (address vault, address strategy) = factory.createOracleVaultAndDefaultStrategy(lbPair, oracleX, oracleY);

        console.log("Vault created ---->", vault);
        console.log("Strategy created ---->", strategy);

        // set operator and aum fee
        vm.broadcast();
        factory.setOperator(IStrategy(strategy), OPERATOR);

        vm.broadcast();
        factory.setPendingAumAnnualFee(IOracleVault(vault), AUM_FEE);
    }
}
