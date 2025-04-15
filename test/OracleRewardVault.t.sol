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

// this is a fork test
contract OracleRewardVaultTest is Test {
    address internal constant WNATIVE = 0x6e47f8d48a01b44DF3fFF35d258A10A3AEdC114c;
    address internal constant USDCe = 0xFbDa5F676cB37624f28265A144A48B0d6e87d3b6;
    address internal constant IOTA_USDC_E_PAIR = 0xa86d3169d5cccdC224637aDAd34F4F1Be174000C; // iota mainnet

    address internal constant PRICE_LENS = 0x1C608813e4B62c685A6C546E338F268924d4996d;

    address internal constant LUM = 0x34a85ddc4E30818e44e6f4A8ee39d8CBA9A60fB3;

    address max = makeAddr("maxmaker");
    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address treasury = makeAddr("treasury");

    VaultFactory _factory;

    function setUp() public {
        vm.createSelectFork("iota");

        // deploy new
        _factory = VaultFactory(
            address(
                new TransparentUpgradeableProxy(
                    address(new VaultFactory(address(WNATIVE))),
                    address(1),
                    abi.encodeWithSelector(VaultFactory.initialize3.selector, address(this))
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
        pairs[0] = IOTA_USDC_E_PAIR;
        _factory.setPairWhitelist(pairs, true);
    }

    function testCreationFeeSetter() public {
        assertEq(_factory.getDefaultOperator(), address(this), "default operator should be this contract");

        assertEq(_factory.getCreationFee(), 75 ether);

        assertEq(_factory.getDefaultMarketMakerAumFee(), 0.1e4);
    }

    function testCreateMarketMakerVault() public {

        // vm.expectRevert(IVaultFactory.VaultFactory__TwapInvalidOracleSize.selector);
        hoax(max, 75 ether);
        (address vault, address strategy) =
            _factory.createMarketMakerOracleVault{value: 75 ether}(ILBPair(IOTA_USDC_E_PAIR), 0.1e4);

        (, uint256 oracleLength, , , ) = ILBPair(IOTA_USDC_E_PAIR).getOracleParameters();
        if (oracleLength < 1) {
            ILBPair(IOTA_USDC_E_PAIR).increaseOracleLength(1);
        }

        // now create vault again
        hoax(max, 75 ether);
        (vault, strategy) =
            _factory.createMarketMakerOracleVault{value: 75 ether}(ILBPair(IOTA_USDC_E_PAIR), 0.1e4);

        address[] memory vaults = _factory.getVaultsByMarketMaker(max);

        assertEq(vault, vaults[1], "vault should be created");
        assertEq(address(IOracleVault(vault).getStrategy()), strategy, "strategy should be created");
    }

    function testRebalanceSingleSide() public {
        (, uint256 oracleLength, , , ) = ILBPair(IOTA_USDC_E_PAIR).getOracleParameters();
        if (oracleLength < 3) {
            ILBPair(IOTA_USDC_E_PAIR).increaseOracleLength(3);
        }

        skip(2 minutes);

        hoax(max, 75 ether);
        (address vault, address strategy) =
            _factory.createMarketMakerOracleVault{value: 75 ether}(ILBPair(IOTA_USDC_E_PAIR), 0.1e4);

        IERC20Upgradeable tokenX = IBaseVault(vault).getTokenX();
        IERC20Upgradeable tokenY = IBaseVault(vault).getTokenY();

        uint256 amountX = 10 * 10 ** IERC20MetadataUpgradeable(address(tokenX)).decimals(); // wnative
        uint256 amountY = 0; // 10 ** IERC20MetadataUpgradeable(address(tokenY)).decimals();

        // bob deposits

        deal(bob, amountX); // deal with erc20 is not working on iota evm

        vm.startPrank(bob);
        IWNative(WNATIVE).deposit{value: amountX}();

        tokenX.approve(vault, amountX);
        (uint256 shares,,) = IBaseVault(vault).deposit(amountX, amountY, 0);

        vm.stopPrank();

        assertGt(shares, 0, "shares should be minted");

        (bool isSet, uint256 pendingAumFee) = IStrategy(strategy).getPendingAumAnnualFee();
        assertTrue(isSet);
        assertEq(pendingAumFee, 1000);

        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);

        // time travel
        skip(10 minutes);

        vm.prank(max);
        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);

        // check aum fee
        assertGe(tokenX.balanceOf(max), 18000005764564); // max is the operator

        // check rewards on vault
        assertLt(0, IStrategy(strategy).getRewardToken().balanceOf(vault), "rewards should be claimed");

        vm.prank(bob);
        IOracleVault(vault).queueWithdrawal(shares, bob);

        skip(1 minutes);

        _rebalanceReset(max, strategy);

        vm.prank(bob);
        IOracleVault(vault).redeemQueuedWithdrawal(0, bob);
    }

    function testDepositRebalanceWithdraw() public {
        // increase oracle so we can do a twap price check
        (, uint256 oracleLength, , , ) = ILBPair(IOTA_USDC_E_PAIR).getOracleParameters();
        if (oracleLength < 3) {
            ILBPair(IOTA_USDC_E_PAIR).increaseOracleLength(3);
        }

        skip(2 minutes);

        hoax(max, 75 ether);
        (address vault, address strategy) =
            _factory.createMarketMakerOracleVault{value: 75 ether}(ILBPair(IOTA_USDC_E_PAIR), 0.1e4);

        OracleRewardVault rewardVault = OracleRewardVault(payable(vault));

        IERC20Upgradeable tokenX = rewardVault.getTokenX();
        IERC20Upgradeable tokenY = rewardVault.getTokenY();

        uint256 amountX = 10 * 10 ** IERC20MetadataUpgradeable(address(tokenX)).decimals(); // wnative
        uint256 amountY = 0;

        // bob deposits
        deal(bob, amountX); // deal with erc20 is not working on iota evm

        vm.startPrank(bob);
        IWNative(WNATIVE).deposit{value: amountX}();

        tokenX.approve(vault, amountX);
        (uint256 shares,,) = rewardVault.deposit(amountX, amountY, 0);
        vm.stopPrank();

        console.log("::1 shares");
        (uint256 pending,) = rewardVault.getPendingRewards(bob);
        assertEq(0, pending, "::1 pending rewards should be 0");

        // rebalance
        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);

        // time travel
        skip(10 minutes);

        // rebalance again, this will harvest rewards
        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);

        console.log("::2");
        (pending,) = rewardVault.getPendingRewards(bob);
        assertGt(pending, 0, "::2 pending rewards should be greater than 0");

        deal(bob, amountX); // deal with erc20 is not working on iota evm
        vm.startPrank(bob);
        IWNative(WNATIVE).deposit{value: amountX}();

        tokenX.approve(vault, amountX);
        (uint256 shares2,,) = rewardVault.deposit(amountX, amountY, 0);
        vm.stopPrank();

        skip(10 minutes);
        console.log("::3");
        (pending,) = rewardVault.getPendingRewards(bob);

        assertEq(pending, 0, "::3 pending rewards should be than 0, we did harvest on deposit before");

        skip(10 minutes);
        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);

        vm.prank(bob);
        rewardVault.claim();

        assertGt(Strategy(strategy).getRewardToken().balanceOf(bob), 0, "claimed rewards should be greater than 0");

        skip(20 minutes);
        console.log("::4");
        // no rebalance, pending rewards should be 0
        (pending,) = rewardVault.getPendingRewards(bob);
        assertEq(pending, 0, "::4 pending rewards should be 0");

        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);
        (pending,) = rewardVault.getPendingRewards(bob);
        assertGt(pending, 0, "::5 pending rewards should be 0");

        console.log("::1 BOB VAULT SHARES", IERC20(vault).balanceOf(bob));

        assertEq(IERC20(vault).balanceOf(bob), shares + shares2, "::1 shares should be the same");

        // withdrawal only a part
        vm.startPrank(bob);
        rewardVault.queueWithdrawal(2e6, bob);
        vm.stopPrank();

        IOracleRewardVault.User memory user = rewardVault.getUserInfo(bob);

        console.log("::2 BOB VAULT SHARES", IERC20(vault).balanceOf(bob));
        assertEq(IERC20(vault).balanceOf(bob), user.amount, "::2 shares and user.amount should be the same");

        console.log("Bobs Address", bob);
        vm.startPrank(bob);
        rewardVault.queueWithdrawal(IERC20(vault).balanceOf(bob), bob);
        vm.stopPrank();

        assertGt(
            Strategy(strategy).getRewardToken().balanceOf(bob),
            0,
            "::6 claimed rewards should be greater than 0 after withdrawal"
        );

        _rebalanceReset(max, strategy);

        vm.prank(bob);
        rewardVault.redeemQueuedWithdrawalNative(0, bob);
    }

    function testEmergencyWithdraw() public {
        // increase oracle so we can do a twap price check
        (, uint256 oracleLength, , , ) = ILBPair(IOTA_USDC_E_PAIR).getOracleParameters();
        if (oracleLength < 3) {
            ILBPair(IOTA_USDC_E_PAIR).increaseOracleLength(3);
        }
        skip(2 minutes);

        hoax(max, 75 ether);
        (address vault, address strategy) =
            _factory.createMarketMakerOracleVault{value: 75 ether}(ILBPair(IOTA_USDC_E_PAIR), 0.1e4);

        OracleRewardVault rewardVault = OracleRewardVault(payable(vault));

        IERC20Upgradeable tokenX = rewardVault.getTokenX();
        IERC20Upgradeable tokenY = rewardVault.getTokenY();

        uint256 amountX = 10 * 10 ** IERC20MetadataUpgradeable(address(tokenX)).decimals(); // wnative
        uint256 amountY = 0;

        // bob deposits
        deal(bob, amountX); // deal with erc20 is not working on iota evm

        vm.startPrank(bob);
        IWNative(WNATIVE).deposit{value: amountX}();

        tokenX.approve(vault, amountX);
        (uint256 shares,,) = rewardVault.deposit(amountX, amountY, 0);
        vm.stopPrank();

        // rebalance
        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);

        // time travel
        skip(10 minutes);

        // set to emergency mode
        _factory.setEmergencyMode(rewardVault);

        // bob goes out
        vm.startPrank(bob);
        rewardVault.emergencyWithdraw();
        vm.stopPrank();

        assertEq(0, IERC20(vault).balanceOf(bob), "bob should have 0 shares");
    }

    function testClaimRewards() public {
        ERC20Mock tokenX = new ERC20Mock("WIOTA", "WIOTA", 18);
        ERC20Mock tokenY = new ERC20Mock("USDC", "USDC", 6);

        ILBPair pair = ILBPair(address(new LBPairMock(tokenX, tokenY)));

        ERC20Mock rewardToken = new ERC20Mock("LUM", "LUM", 18);
        ERC20Mock extraRewardToken = new ERC20Mock("SEA", "SEA", 18);

        VaultFactory localFactory = VaultFactory(
            address(
                new TransparentUpgradeableProxy(
                    address(new VaultFactory(address(tokenX))),
                    address(1),
                    abi.encodeWithSelector(VaultFactory.initialize2.selector, address(this))
                )
            )
        );

        // whitelist pair
        address[] memory pairs = new address[](1);
        pairs[0] = address(pair);
        localFactory.setPairWhitelist(pairs, true);

        OracleRewardVault oracleRewardVault = new OracleRewardVault(localFactory);
        localFactory.setVaultImplementation(IVaultFactory.VaultType.Oracle, address(oracleRewardVault));

        localFactory.setStrategyImplementation(IVaultFactory.StrategyType.Default, address(new StrategyMock()));

        localFactory.setPriceLens(IPriceLens(new PriceLensMock()));
        localFactory.setFeeRecipient(treasury);

        hoax(max, 75 ether);
        (address vault, address strategy) = localFactory.createMarketMakerOracleVault{value: 75 ether}(pair, 0.1e4);

        // have to set it manuelly cause this is a clone
        StrategyMock(strategy).setOperator(max);
        StrategyMock(strategy).setRewardToken(rewardToken);
        StrategyMock(strategy).setExtraRewardToken(extraRewardToken);
        StrategyMock(strategy).setTokenX(tokenX);
        StrategyMock(strategy).setTokenY(tokenY);

        OracleRewardVault rewardVault = OracleRewardVault(payable(vault));

        // disable twap price check
        vm.prank(address(localFactory));
        rewardVault.enableTWAPPriceCheck(false);

        // mint token
        tokenX.mint(bob, 10e18);
        tokenY.mint(bob, 12e6);

        vm.startPrank(bob);
        tokenX.approve(vault, 10e18);
        tokenY.approve(vault, 12e6);

        (uint256 shares,,) = rewardVault.deposit(10e18, 12e6, 0);
        vm.stopPrank();

        (uint256 pending, uint256 extra) = rewardVault.getPendingRewards(bob);
        assertEq(0, pending, "pending rewards should be 0");

        // mint rewardtokens
        rewardToken.mint(vault, 20e18);
        (pending, extra) = rewardVault.getPendingRewards(bob);

        assertEq(19999999999999999999, pending);
        assertEq(0, extra);

        // claim rewards
        vm.prank(bob);
        rewardVault.claim();

        assertEq(19999999999999999999, rewardToken.balanceOf(bob));

        // deposit again
        tokenX.mint(bob, 10e18);
        tokenY.mint(bob, 12e6);

        vm.startPrank(bob);
        tokenX.approve(vault, 10e18);
        tokenY.approve(vault, 12e6);

        (shares,,) = rewardVault.deposit(1e18, 4e6, 0);
        vm.stopPrank();
    }

    function testTransfer() public {
        // increase oracle so we can do a twap price check
        (, uint256 oracleLength, , , ) = ILBPair(IOTA_USDC_E_PAIR).getOracleParameters();
        if (oracleLength < 3) {
            ILBPair(IOTA_USDC_E_PAIR).increaseOracleLength(3);
        }

        skip(2 minutes);

        hoax(max, 75 ether);
        (address vault, address strategy) =
            _factory.createMarketMakerOracleVault{value: 75 ether}(ILBPair(IOTA_USDC_E_PAIR), 0.1e4);

        OracleRewardVault rewardVault = OracleRewardVault(payable(vault));

        IERC20Upgradeable tokenX = rewardVault.getTokenX();
        IERC20Upgradeable tokenY = rewardVault.getTokenY();

        uint256 amountX = 10 * 10 ** IERC20MetadataUpgradeable(address(tokenX)).decimals(); // wnative
        uint256 amountY = 0;

        // bob deposits
        deal(bob, amountX); // deal with erc20 is not working on iota evm

        vm.startPrank(bob);
        IWNative(WNATIVE).deposit{value: amountX}();

        tokenX.approve(vault, amountX);
        (uint256 shares,,) = rewardVault.deposit(amountX, amountY, 0);
        vm.stopPrank();

        console.log("::1 shares");
        (uint256 pending,) = rewardVault.getPendingRewards(bob);
        assertEq(0, pending, "::1 pending rewards should be 0");

        // rebalance
        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);

        // time travel
        skip(10 minutes);

        // rebalance again, this will harvest rewards
        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);

        //send to alice
        vm.startPrank(bob);
        IERC20Upgradeable(vault).transfer(alice, shares);
        vm.stopPrank();

        (pending,) = rewardVault.getPendingRewards(bob);
        assertEq(pending, 0, "::2 bob pending rewards should be 0");

        assertGt(
            Strategy(strategy).getRewardToken().balanceOf(bob), 0, "::3 bob claimed rewards should be greater than 0"
        );

        (pending,) = rewardVault.getPendingRewards(alice);
        assertEq(pending, 0, "::3 alice pending rewards be 0");

        skip(10 minutes);

        _rebalanceSingleSide(max, IOTA_USDC_E_PAIR, strategy);

        (pending,) = rewardVault.getPendingRewards(bob);
        assertEq(pending, 0, "::4 bob pending rewards should be 0");

        (pending,) = rewardVault.getPendingRewards(alice);
        assertGt(pending, 0, "::5 alice pending rewards greater than 0");

        vm.startPrank(alice);
        rewardVault.claim();
        vm.stopPrank();

        assertGt(
            Strategy(strategy).getRewardToken().balanceOf(alice),
            0,
            "::6 alice claimed rewards should be greater than 0"
        );
    }

    function _rebalanceSingleSide(address vaultManager, address pair, address strategy) internal {
        uint256 activeId = ILBPair(pair).getActiveId();

        bytes memory distributions = abi.encodePacked(uint64(0.5e18), uint64(0.5e18));

        vm.prank(vaultManager);
        IStrategy(strategy).rebalance(
            uint24(activeId) + 1, uint24(activeId) + 1, uint24(activeId) + 1, 1, 1e18, 0, distributions
        );
    }

    function _rebalanceReset(address vaultManager, address strategy) internal {
        bytes memory distributions = bytes("0");
        vm.prank(vaultManager);
        IStrategy(strategy).rebalance(0, 0, 0, 0, 0, 0, distributions);
    }
}

contract StrategyMock is Clone {
    IERC20 internal _rewardToken;
    IERC20 internal _extraRewardToken;
    address internal _operator;

    IERC20 _tokenX;
    IERC20 _tokenY;

    function getRewardToken() external view returns (IERC20) {
        return _rewardToken;
    }

    function getExtraRewardToken() external view returns (IERC20) {
        return _extraRewardToken;
    }

    function setTokenX(IERC20 tokenX) external {
        _tokenX = tokenX;
    }

    function setTokenY(IERC20 tokenY) external {
        _tokenY = tokenY;
    }

    function getBalances() external view returns (uint256 amountX, uint256 amountY) {
        amountX = _tokenX.balanceOf(address(this));
        amountY = _tokenY.balanceOf(address(this));
    }

    function getVault() external pure returns (address) {
        return _getArgAddress(0);
    }

    function getPair() external pure returns (ILBPair) {
        return ILBPair(_getArgAddress(20));
    }

    function getTokenX() external pure returns (IERC20Upgradeable tokenX) {
        tokenX = IERC20Upgradeable(_getArgAddress(40));
    }

    function getTokenY() external pure returns (IERC20Upgradeable tokenY) {
        tokenY = IERC20Upgradeable(_getArgAddress(60));
    }

    function hasRewards() external pure returns (bool) {
        return true;
    }

    function hasExtraRewards() external pure returns (bool) {
        return true;
    }

    function setPendingAumAnnualFee(uint16) external {}

    function setFeeRecipient(address) external {}

    function initialize() external {}

    function setOperator(address operator) external {
        _operator = operator;
    }

    function setRewardToken(IERC20 rewardToken) external {
        _rewardToken = rewardToken;
    }

    function setExtraRewardToken(IERC20 extraRewardToken) external {
        _extraRewardToken = extraRewardToken;
    }
}

contract LBPairMock {
    IERC20 internal _tokenX;
    IERC20 internal _tokenY;

    constructor(IERC20 tokenX, IERC20 tokenY) {
        _tokenX = tokenX;
        _tokenY = tokenY;
    }

    function getTokenX() external view returns (IERC20) {
        return _tokenX;
    }

    function getTokenY() external view returns (IERC20) {
        return _tokenY;
    }

    function increaseOracleLength(uint16 size) external pure {
        size;
    }

    function getOracleParameters() external pure returns (uint8, uint16, uint16, uint40, uint40) {
        return (1, 1, 1, 1, 1);
    }

    function getOracleSampleAt (uint40 lookupTimestamp)
        external
        pure
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed) {
        cumulativeId = 929229;
        cumulativeVolatility = 1;
        cumulativeBinCrossed = 1;
    }

    function getPriceFromId(uint24 id) external pure returns (uint256) {
        { id; }
        return 1e18;
    }
}

contract PriceLensMock is IPriceLens {
    function getTokenPriceNative(address) external pure override returns (uint256 price) {
        return 1e18;
    }
}
