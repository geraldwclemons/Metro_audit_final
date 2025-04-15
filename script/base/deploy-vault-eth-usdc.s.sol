// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

import "joe-v2/interfaces/ILBPair.sol";

import "../../src/VaultFactory.sol";
import "../../src/utils/OracleLensAggregator.sol";

contract ProdVaultEthUsdcDeployer is Script {
    address AMDIN = 0xdeD212B8BAb662B98f49e757CbB409BB7808dc10;

    address PAIR_OPTIMISM = 0x8E27E25D9DABc96f89A0eDc99e35D6e2a10b4fA0; // eth-usdc

    address PRICE_LENS_OPTIMISM = 0x2D52467D074B3590760831af816046471a81bf3a;
    address VAULT_FACTORY_OPTIMISM = 0xd47885EDA0A0b4ec79E5C37379e8D2e1d0B39017;

    address OPERATOR = 0xcaD3477b8D2569c849298E82D10046eD422AC258;

    uint16 AUM_FEE = 400; // 4%

    address tokenX;
    address tokenY;
    address pair;
    address vaultFactory;
    address priceLens;

    function run() public {
        if (block.chainid == 8453) {
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
