// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import "../src/Strategy.sol";

contract Rebalancer is Script {
    function run() public {
        Strategy strategy = Strategy(0x0a3137fea1Cd910242A2ebF2A0290D988aDa2137);

        uint256[] memory desiredL = new uint256[](11);
        desiredL[0] = 10000;
        desiredL[1] = 10000;
        desiredL[2] = 10000;
        desiredL[3] = 10000;
        desiredL[4] = 10000;
        desiredL[5] = 10000;
        desiredL[6] = 10000;
        desiredL[7] = 10000;
        desiredL[8] = 10000;
        desiredL[9] = 10000;
        desiredL[10] = 10000;

        // vm.broadcast();
        // strategy.rebalance(
        //      8371470,
        //     8371480,
        //     8371475,
        //     10,
        //     desiredL,
        //     1 ether,
        //     1 ether
        // );
    }
}
