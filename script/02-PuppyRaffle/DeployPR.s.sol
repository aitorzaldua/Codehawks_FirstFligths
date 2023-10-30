// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {Script} from "forge-std/Script.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";

contract DeployPR is Script {
    address feeAddress = address(99);

    // Constructor variables:
    uint256 entranceFee = 1e18;
    uint256 duration = 1 days;

    function run() external returns (PuppyRaffle) {
        vm.startBroadcast(feeAddress);
        PuppyRaffle puppyRaffle = new PuppyRaffle(entranceFee, feeAddress, duration);
        vm.stopBroadcast();

        return (puppyRaffle);
    }
}
