// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";

import "joe-v2/interfaces/ILBPair.sol";

import "../../src/VaultFactory.sol";
import "../../src/interfaces/IStrategy.sol";
import "../../src/interfaces/IOracleVault.sol";

contract OperatorSetter is Script {
    address AMDIN = 0xdeD212B8BAb662B98f49e757CbB409BB7808dc10;

    address VAULT_FACTORY_FANTOM = 0x08d520AFEb367E66E28A9E0f503Ecd209b589Af6;

    address OPERATOR = 0xcaD3477b8D2569c849298E82D10046eD422AC258;

    uint16 AUM_FEE = 400; // 4%

    function run() public {
        VaultFactory factory = VaultFactory(VAULT_FACTORY_FANTOM);

        address vault1 = 0x2ea7babF44796090eE42Feb8678B38b84D20b697;
        address strategy1 = 0xe4355ac00294414C2FF21701c8c914298b0Bd793;

        vm.broadcast();
        factory.setOperator(IStrategy(strategy1), OPERATOR);

        vm.broadcast();
        factory.setPendingAumAnnualFee(IOracleVault(vault1), AUM_FEE);

        address vault2 = 0xE13D1a668C7d7F90AB9181Aa624A2522F7b8b19E;
        address strategy2 = 0xB0512eF572Bc6f57f18baA6D6d78a4A786eF51D5;

        vm.broadcast();
        factory.setOperator(IStrategy(strategy2), OPERATOR);

        vm.broadcast();
        factory.setPendingAumAnnualFee(IOracleVault(vault2), AUM_FEE);
    }
}
