// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";
import {IERC20, ILBPair} from "joe-v2/interfaces/ILBPair.sol";
import "../src/BaseVault.sol";
import "../src/VaultFactory.sol";
import "../src/SimpleVault.sol";
import "../src/OracleRewardVault.sol";
import "../src/Strategy.sol";

import {ERC20Mock} from "./mocks/ERC20.sol";

// this is a fork test for OracleRewardVault
// You can use this as base for a PoC
contract PoCTest is Test {


    address internal constant WNATIVE = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38; // sonic mainnet
    address internal constant USDCe = 0x29219dd400f2Bf60E5a23d13Be72B486D4038894; // sonic mainnet
    address internal constant S_USDC_E_PAIR = 0x56B404073C990E828691aF936bcfFf710f6c97A1; // sonic mainnet

    address internal constant PRICE_LENS = 0x189F3FAEE49F744b76dC0B2549a20146E836aa37; // sonic mainnet

    address internal constant REWARD_TOKEN = 0x71E99522EaD5E21CF57F1f542Dc4ad2E841F7321; // metro
    address internal constant EXTRA_REWARD_TOKEN = 0x8A3b1cd8d0DEcF649262e56EcE6B339E59f350db; // mgem

    address max = makeAddr("maxmaker");
    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address treasury = makeAddr("treasury");

    address admin = makeAddr("admin"); // factory admin

    VaultFactory _factory;

    function setUp() public {
        vm.createSelectFork("sonic");

        // deploy new
        _factory = VaultFactory(
            address(
                new TransparentUpgradeableProxy(
                    address(new VaultFactory(address(WNATIVE))),
                    address(admin),
                    abi.encodeWithSelector(VaultFactory.initialize4.selector, address(this), 50 ether)
                )
            )
        );

        _factory.setFeeRecipient(treasury);

        OracleRewardVault oracleRewardVault = new OracleRewardVault(_factory);

        _factory.setVaultImplementation(IVaultFactory.VaultType.Oracle, address(oracleRewardVault));

        _factory.setStrategyImplementation(IVaultFactory.StrategyType.Default, address(new Strategy(_factory, 51)));

        _factory.setPriceLens(IPriceLens(PRICE_LENS));

        // whitelist pairs
        address[] memory pairs = new address[](1);
        pairs[0] = S_USDC_E_PAIR;
        _factory.setPairWhitelist(pairs, true);
    }

    function testCreationFeeSetter() public {
        assertEq(_factory.getDefaultOperator(), address(this), "default operator should be this contract");

        assertEq(_factory.getCreationFee(), 50 ether);

        assertEq(_factory.getDefaultMarketMakerAumFee(), 0.1e4);
    }

    function testCreateMarketMakerVault() public {

        // vm.expectRevert(IVaultFactory.VaultFactory__TwapInvalidOracleSize.selector);
        hoax(max, 50 ether);
        (address vault, address strategy) =
            _factory.createMarketMakerOracleVault{value: 50 ether}(ILBPair(S_USDC_E_PAIR), 0.1e4);

        (, uint256 oracleLength, , , ) = ILBPair(S_USDC_E_PAIR).getOracleParameters();
        if (oracleLength < 1) {
            ILBPair(S_USDC_E_PAIR).increaseOracleLength(1);
        }

        // now create vault again
        hoax(max, 50 ether);
        (vault, strategy) =
            _factory.createMarketMakerOracleVault{value: 50 ether}(ILBPair(S_USDC_E_PAIR), 0.1e4);

        address[] memory vaults = _factory.getVaultsByMarketMaker(max);

        assertEq(vault, vaults[1], "vault should be created");
        assertEq(address(IOracleVault(vault).getStrategy()), strategy, "strategy should be created");
    }




}