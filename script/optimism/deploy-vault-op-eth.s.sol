// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

import "joe-v2/interfaces/ILBPair.sol";

import "../../src/VaultFactory.sol";
import "../../src/utils/OracleLensAggregator.sol";

contract ProdVaultOpEthDeployer is Script {
    address AMDIN = 0xdeD212B8BAb662B98f49e757CbB409BB7808dc10;

    address PAIR_OPTIMISM = 0x24f4d29dfa81EEB6B22F94a962b87DfA769D2492; // op-eth

    address PRICE_LENS_OPTIMISM = 0x9fbDf5e760394964F8C71fFF4Ff5CeA5B325237c;
    address VAULT_FACTORY_OPTIMISM = 0x8Cce20D17aB9C6F60574e678ca96711D907fD08c;

    address OPERATOR = 0xcaD3477b8D2569c849298E82D10046eD422AC258;

    uint16 AUM_FEE = 400; // 4%

    address tokenX;
    address tokenY;
    address pair;
    address vaultFactory;
    address priceLens;

    function run() public {
        if (block.chainid == 10) {
            pair = PAIR_OPTIMISM;
            priceLens = PRICE_LENS_OPTIMISM;
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

        VaultFactory factory = VaultFactory(VAULT_FACTORY_OPTIMISM);

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
