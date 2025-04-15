// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";
import "openzeppelin/proxy/transparent/ProxyAdmin.sol";
import "../helper.sol";

import "src/VaultFactory.sol";
import "src/interfaces/IVaultFactory.sol";

import "src/Strategy.sol";
import "src/SimpleVault.sol";
import "src/OracleRewardVault.sol";
import "src/libraries/Constants.sol";
import "./config/Addresses.sol";

contract Debug is Script {
    function run() public {
        vm.createSelectFork("sonic");
          OracleRewardVault vault = OracleRewardVault(payable(0xf1E28E380Ac635EFAc9f62D214828223154363F9));
        //Strategy strategy = Strategy(payable(address(vault.getStrategy())));


        address user = 0x290E00950f744A914cd61Ad51f58e37c0b8AC945;

        {
        console.log();
        console.log("== All was good until block", 14715880);
        vm.createSelectFork("sonic", 14715880);
        uint256 sharesBeforeFirstWithdraw = vault.totalSupply();

        (uint256 amountX, uint256 amountY) = vault.getBalances();
        console.log("Balance X before first withdraw", amountX);
        console.log("Balance Y before first withdraw", amountY);

        console.log("Total Shares before first withdraw", sharesBeforeFirstWithdraw);

        uint256 userShares = vault.balanceOf(user);
        console.log("User Shares before first withdraw", userShares);

        (uint256 amountXBeforeFirst, uint256 amountYBeforeFirst) = vault.previewAmounts(userShares);
        console.log("User Amount X before first withdraw", amountXBeforeFirst);
        console.log("User Amount Y before first withdraw", amountYBeforeFirst);


        uint256 queuedShares = vault.getCurrentTotalQueuedWithdrawal();
        console.log("Queued Shares", queuedShares);
        }


      {
        // withdrawFromRange happend 14715881
        console.log("==:1");
        console.log("== Second withdrawFromRange Block", 14715881);
        vm.createSelectFork("sonic", 14715881);
        uint256 sharesAfterFirstWithdraw = vault.totalSupply();
    
        (uint256 amountXAfter, uint256 amountYAfter) = vault.getBalances();
        console.log("Balance X after first withdraw", amountXAfter);
        console.log("Balance Y after first withdraw", amountYAfter);

        console.log("Total Shares after first withdraw", sharesAfterFirstWithdraw);
        

        uint256 userSharesAfterFirstWithdraw = vault.balanceOf(user);
        console.log("User Shares after first withdraw", userSharesAfterFirstWithdraw);

        (uint256 amountXAfterFirst, uint256 amountYAfterFirst) = vault.previewAmounts(userSharesAfterFirstWithdraw);
        console.log("User Amount X after first withdraw", amountXAfterFirst);
        console.log("User Amount Y after first withdraw", amountYAfterFirst);

        uint256 queuedSharesAfterFirstWithdraw = vault.getCurrentTotalQueuedWithdrawal();
        console.log("Queued Shares after first withdraw", queuedSharesAfterFirstWithdraw);
      }



     {
        // second withdrawFromRange happend 14715904
        console.log("==:2");
        vm.createSelectFork("sonic", 14715904);
        uint256 sharesAfterSecondWithdraw = vault.totalSupply();

        (uint256 amountXAfterSecond, uint256 amountYAfterSecond) = vault.getBalances();
        console.log("Balance X after second withdraw", amountXAfterSecond);
        console.log("Balance Y after second withdraw", amountYAfterSecond);

        console.log("Total Shares after second withdraw", sharesAfterSecondWithdraw);

        uint256 userSharesAfterSecondWithdraw = vault.balanceOf(user);
        console.log("User Shares after second withdraw", userSharesAfterSecondWithdraw);

        (uint256 userAmountXAfterSecond, uint256 userAmountYAfterSecond) = vault.previewAmounts(userSharesAfterSecondWithdraw);
        console.log("User Amount X after second withdraw", userAmountXAfterSecond);
        console.log("User Amount Y after second withdraw", userAmountYAfterSecond);

        uint256 queuedSharesAfterSecondWithdraw = vault.getCurrentTotalQueuedWithdrawal();
        console.log("Queued Shares after second withdraw", queuedSharesAfterSecondWithdraw);

    }


    {
        // third withdrawFromRange happend 14715974
        console.log("==:3");
        console.log("== Third withdrawFromRange Block", 14715974);
        vm.createSelectFork("sonic", 14715974);
        uint256 sharesAfterThirdWithdraw = vault.totalSupply();

        (uint256 amountXAfterThird, uint256 amountYAfterThird) = vault.getBalances();
        console.log("Balance X after third withdraw", amountXAfterThird);
        console.log("Balance Y after third withdraw", amountYAfterThird);

        console.log("Total Shares after third withdraw", sharesAfterThirdWithdraw);

        uint256 userSharesAfterThirdWithdraw = vault.balanceOf(user);
        console.log("User Shares after third withdraw", userSharesAfterThirdWithdraw);

        (uint256 userAmountXAfterThird, uint256 userAmountYAfterThird) = vault.previewAmounts(userSharesAfterThirdWithdraw);
        console.log("User Amount X after third withdraw", userAmountXAfterThird);
        console.log("User Amount Y after third withdraw", userAmountYAfterThird);

        uint256 queuedSharesAfterFirstWithdraw = vault.getCurrentTotalQueuedWithdrawal();
        console.log("Queued Shares after first withdraw", queuedSharesAfterFirstWithdraw);
        
    }

            
    }
}

contract GetShares is Script {

    function run() public {
        // get all shares and preview amounts for all users
        vm.createSelectFork("sonic", 14622782);

        OracleRewardVault vault = OracleRewardVault(payable(0xf1E28E380Ac635EFAc9f62D214828223154363F9));

        uint256 shares = vault.totalSupply();

        address[] memory users = getUsers();
        console.log("User,Shares,Amount X,Amount Y");
        for (uint256 i = 0; i < users.length; i++) {
            uint256 userShares = vault.balanceOf(users[i]);
            (uint256 amountX, uint256 amountY) = vault.previewAmounts(userShares);         
            string memory result = string(abi.encodePacked(
                toHexString(users[i]), 
                ",",
                toString(userShares),
                ",",
                toString(amountX),
                ",",
                toString(amountY)
            ));
            console.log(result);
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        bytes memory buffer = new bytes(42);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint160(addr) / (2**(8*(19 - i)))));
            buffer[2+i*2] = bytes1(uint8(b) / 16 >= 10 ? uint8(b) / 16 + 87 : uint8(b) / 16 + 48);
            buffer[3+i*2] = bytes1(uint8(b) % 16 >= 10 ? uint8(b) % 16 + 87 : uint8(b) % 16 + 48);
        }
        return string(buffer);
    }

    function getUsers() public pure returns (address[] memory) {
        address[] memory users = new address[](26);
        users[0] = 0x0C759509dE69C23F4fd35BdE9148A34743586fF8;
        users[1] = 0x0F977101dB0eb9256B82034e7e80d6e48E6F7a9D;
        users[2] = 0x2850a72F6D4D1EF010fdB7F3cA4bd32bDde905A2;
        users[3] = 0x290E00950f744A914cd61Ad51f58e37c0b8AC945;
        users[4] = 0x3EDB7d5b494cCB9bb84D11CA25F320Af2bb15f40;
        users[5] = 0x4533E03d983Fae04741131C5f7cB35F1b32A1ACD;
        users[6] = 0x47630c744c4F9CC8bE8Da6Af09D688Cc43dE2323;
        users[7] = 0x61125f52cee83Ed5D7A6Cd14598D34974B11865e;
        users[8] = 0x68aeDee7DC9da33A1E7D32a6637361E409c40519;
        users[9] = 0x7E45AC061cA96B3995cD6730A0211816fBd5F77e;
        users[10] = 0x86e4C00C5A7e7FB456D2A5f75fcb68998004BD87;
        users[11] = 0x87D7fe60456922915560F2DBBbA4cd19E97649f0;
        users[12] = 0x888A555349c75353213c9610fEE87587fD6f8a6A;
        users[13] = 0x91799239fBF7dc87E74dD657ed9d8B98Ea34F989;
        users[14] = 0x9B5683703ca24EC7d346A69353F3C51B55D8f8dc;
        users[15] = 0x9Ba52bc4e63965FF9D6EaB7ec68Fd4213823c99E;
        users[16] = 0xa100Fa6fAda1be2041A20BA80c11e8F370c9306b;
        users[17] = 0xa32A1e271691C0d1b3b73a260757802270A4E21e;
        users[18] = 0xB4Bd807C9cDde19AE1498c7b7006713268E25997;
        users[19] = 0xB5Cda7504C4E5881Ef6404fd6f45da7b1E79e821;
        users[20] = 0xc4c4C064fFF824dAeaCD76BdC0D2656FaD17CE44;
        users[21] = 0xC5659B1ddcf5f5C0d9E006FfA6D57f58e9ba51cB;
        users[22] = 0xD881878265FcAE4D4985cF023279D950451AA880;
        users[23] = 0xDD21BE69bADB67067b9cea9227cC701551A545c6;
        users[24] = 0xF0009f5F6731FBd11Bf9bFFf0D1Ea6D790Bec101;
        users[25] = 0xF2842c6fc18F3070d3186664f45e06E1Ce873663;
        return users;
    }
}