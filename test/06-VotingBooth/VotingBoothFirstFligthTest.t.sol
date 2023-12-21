// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VotingBooth} from "../src/VotingBooth.sol";
import {Test, console} from "forge-std/Test.sol";

contract VotingBoothFirstFligthTest is Test {
    ////////////////////
    //  VARS & CONST //
    //////////////////

    // 1. Monto total del deployer (este contrato).
    uint256 constant ETH_REWARD = 20e18;

    // 2. Array con los votantes autorizados.
    address[] voters;

    ////////////////////////
    //  USERS & ACCOUNTS ///
    ////////////////////////
    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");
    address USER3 = makeAddr("user3");
    address USER4 = makeAddr("user4");
    address USER5 = makeAddr("user5");
    address USER6 = makeAddr("user6");
    address USER7 = makeAddr("user7");
    address USER8 = makeAddr("user8");
    address USER9 = makeAddr("user9");
    address USER10 = makeAddr("user10");

    //////////////////////
    ///  CONTRACTS     ///
    //////////////////////

    VotingBooth booth;

    ///////////////////
    /// DEPLOY ////////
    //////////////////

    function setUp() public virtual {
        // El contrato incluye un pago a los votantes positivos.
        // Se añade al deployer (este contrato) una cantidad para que
        // pueda hacer frente a esos pagos
        deal(address(this), ETH_REWARD);

        // El contrato solicita como parametro de deploy
        // un array de votantes autorizados.
        voters.push(USER1);
        voters.push(USER2);
        voters.push(USER3);
        voters.push(USER3);
        voters.push(USER5);

        // Deploy
        booth = new VotingBooth{value: ETH_REWARD}(voters);

        // Verificar el deploy
        // 1. El contrato dispone de fondos
        assert(address(booth).balance == ETH_REWARD);
        // 2. isActive() => retorna si s_votingComplete = false/true
        assert(booth.isActive());
        // 3. Comprobar la lista de votantes
        assert(booth.getTotalAllowedVoters() == voters.length);
        // 4. Comprobar el deployer
        assert(booth.getCreator() == address(this));
    }

    // required to receive refund if proposal fails
    receive() external payable {}

    /////////////////////
    ///  UNIT TESTS   ///
    ////////////////////

    function testLogs_Addresses() external view {
        console.log("user1:    ", USER1);
        console.log("deploter: ", address(this));
        console.log("contract: ", address(booth));
        console.log("balance:  ", address(booth).balance / 1e18);
    }

    function testWorks_VoteUser1() external {
        vm.prank(USER1);
        booth.vote(true);

        assertEq(voters.length, 5);
        assertEq(booth.isActive(), true);
        assertEq(booth.s_totalCurrentVotes(), 1);
        assertEq((booth.s_totalCurrentVotes() * 100 / booth.s_totalAllowedVoters()), 20);
    }

    function testFail_VoteUser10() external {
        vm.prank(USER10);
        booth.vote(true);
    }

    function testFail_VoteUser1_vote2Times() external {
        vm.startPrank(USER1);
        booth.vote(true);
        booth.vote(true);
        vm.stopPrank();
    }

    //////////////////
    /// INVARIANT   //
    ////////////////

    /*
     * invariants para vote():
     * s_votersFor.length + s_votersAgainst.length < s_votingComplete.length
     * s_votersFor.length + s_votersAgainst.length == s_totalCurrentVotes.length
     * If booth.isActive() = true => booth.balance > 0
     *
     */
    function test_fuzz(bool _vote) external {}
}
