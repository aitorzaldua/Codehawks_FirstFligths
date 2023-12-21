// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {VotingBooth} from "../src/VotingBooth.sol";
import {Test, console2} from "forge-std/Test.sol";
import {_CheatCodes} from "./mocks/CheatCodes.t.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract VotingBoothTest is Test {
    // eth reward
    uint256 constant ETH_REWARD = 10e18;

    // allowed voters
    address[] voters;

    // contracts required for test
    VotingBooth booth;

    _CheatCodes cheatCodes = _CheatCodes(HEVM_ADDRESS);

    function setUp() public virtual {
        // deal this contract the proposal reward
        deal(address(this), ETH_REWARD);

        // setup the allowed list of voters
        voters.push(address(0x1));
        voters.push(address(0x2));
        voters.push(address(0x3));
        voters.push(address(0x4));
        voters.push(address(0x5));
        voters.push(address(0x6));
        voters.push(address(0x7));
        voters.push(address(0x8));
        voters.push(address(0x9));
        // voters.push(address(0x10));
        // voters.push(address(0x11));

        // setup contract to be tested
        booth = new VotingBooth{value: ETH_REWARD}(voters);

        // verify setup
        //
        // proposal has rewards
        assert(address(booth).balance == ETH_REWARD);
        // proposal is active
        assert(booth.isActive());
        // proposal has correct number of allowed voters
        assert(booth.getTotalAllowedVoters() == voters.length);
        // this contract is the creator
        assert(booth.getCreator() == address(this));

        targetContract(address(booth));
    }

    // required to receive refund if proposal fails
    receive() external payable {}

    function test_console2() external view {
        console2.log("balance: ", address(booth).balance);
    }

    function invariant_testBalanceGreaterThanZero() external view {
        // uint256 votersLength = voters.length;
        // for (i = 0; i < voters.length; ++i) {}

        if (!booth.isActive()) {
            assert(address(booth).balance == 0);
        }
    }

    function testVotePassesAndMoneyIsSent() public {
        vm.prank(address(0x1));
        booth.vote(false);

        vm.prank(address(0x2));
        booth.vote(true);

        vm.prank(address(0x3));
        booth.vote(true);

        assert(!booth.isActive() && address(booth).balance == 0);
    }

    function testMoneyNotSentTillVotePasses() public {
        vm.prank(address(0x1));
        booth.vote(true);

        vm.prank(address(0x2));
        booth.vote(true);

        assert(booth.isActive() && address(booth).balance > 0);
    }

    function testIfPeopleVoteAgainstItBecomesInactiveAndMoneySentToOwner() public {
        uint256 startingAmount = address(this).balance;

        vm.prank(address(0x1));
        booth.vote(false);

        vm.prank(address(0x2));
        booth.vote(false);

        vm.prank(address(0x3));
        booth.vote(false);

        assert(!booth.isActive());
        assert(address(this).balance >= startingAmount);
    }

    //////////////////
    // scenes ///////
    /////////////////

    /*
     * 1. true, true, true
     * 2. false, false, false
     * 3. false, true, true -> FAIL
     * 4. true, false, true
     * 5. false, false, tue
     */

    function test_uno() public {
        console2.log("initial balance creator: ", address(this).balance);
        console2.log("initial balance booth:   ", address(booth).balance);
        console2.log("initial balance 0x1 :    ", address(0x1).balance);
        console2.log("initial balance 0x2:     ", address(0x2).balance);
        console2.log("initial balance 0x3:     ", address(0x3).balance);
        console2.log("initial Is active =>     ", booth.isActive());

        vm.prank(address(0x1));
        booth.vote(false);

        vm.prank(address(0x2));
        booth.vote(true);

        vm.prank(address(0x3));
        booth.vote(true);

        console2.log("****AFTER EXECUTION***");
        console2.log("final balance creator:   ", address(this).balance);
        console2.log("final balance booth:     ", address(booth).balance);
        console2.log("final balance 0x1 :      ", address(0x1).balance);
        console2.log("final balance 0x2:       ", address(0x2).balance);
        console2.log("final balance 0x3:       ", address(0x3).balance);
        console2.log("final Is active =>       ", booth.isActive());

        // assert(!booth.isActive() && address(booth).balance == 0);
    }

    function test_dos() public {
        // Voters initial balance = 0
        console2.log("initial balance creator: ", address(this).balance);
        console2.log("initial balance booth:   ", address(booth).balance);
        console2.log("initial Is active =>     ", booth.isActive());

        // 5 votes: 2 x false + 3 x true => Approved!!
        vm.prank(address(0x1));
        booth.vote(false);
        vm.prank(address(0x2));
        booth.vote(false);
        vm.prank(address(0x3));
        booth.vote(true);
        vm.prank(address(0x4));
        booth.vote(true);
        vm.prank(address(0x5));
        booth.vote(true);

        // What happened?
        console2.log("****AFTER EXECUTION***");
        console2.log("final balance creator:   ", address(this).balance);
        console2.log("final balance booth:     ", address(booth).balance);
        console2.log("final balance 0x1 :      ", address(0x1).balance);
        console2.log("final balance 0x2:       ", address(0x2).balance);
        console2.log("final balance 0x3:       ", address(0x3).balance);
        console2.log("final balance 0x4:       ", address(0x4).balance);
        console2.log("final balance 0x5:       ", address(0x5).balance);
        console2.log("final Is active =>       ", booth.isActive());

        // Expected behaivor
        assert(!booth.isActive() && address(booth).balance == 0);
    }

    function test_tres() public {
        console2.log("initial balance creator: ", address(this).balance);
        console2.log("initial balance booth:   ", address(booth).balance);
        console2.log("initial balance 0x1 :    ", address(0x1).balance);
        console2.log("initial balance 0x2:     ", address(0x2).balance);
        console2.log("initial balance 0x3:     ", address(0x3).balance);
        console2.log("initial Is active =>     ", booth.isActive());

        vm.prank(address(0x1));
        booth.vote(false);

        vm.prank(address(0x2));
        booth.vote(true);

        vm.prank(address(0x3));
        booth.vote(true);

        console2.log("****AFTER EXECUTION***");
        console2.log("final balance creator:   ", address(this).balance);
        console2.log("final balance booth:     ", address(booth).balance);
        console2.log("final balance 0x1 :      ", address(0x1).balance);
        console2.log("final balance 0x2:       ", address(0x2).balance);
        console2.log("final balance 0x3:       ", address(0x3).balance);
        console2.log("final Is active =>       ", booth.isActive());

        // assert(!booth.isActive() && address(booth).balance == 0);
    }

    function test_cuatro() public {
        console2.log("initial balance creator: ", address(this).balance);
        console2.log("initial balance booth:   ", address(booth).balance);
        console2.log("initial balance 0x1 :    ", address(0x1).balance);
        console2.log("initial balance 0x2:     ", address(0x2).balance);
        console2.log("initial balance 0x3:     ", address(0x3).balance);
        console2.log("initial Is active =>     ", booth.isActive());

        vm.prank(address(0x1));
        booth.vote(false);

        vm.prank(address(0x2));
        booth.vote(true);

        vm.prank(address(0x3));
        booth.vote(true);

        console2.log("****AFTER EXECUTION***");
        console2.log("final balance creator:   ", address(this).balance);
        console2.log("final balance booth:     ", address(booth).balance);
        console2.log("final balance 0x1 :      ", address(0x1).balance);
        console2.log("final balance 0x2:       ", address(0x2).balance);
        console2.log("final balance 0x3:       ", address(0x3).balance);
        console2.log("final Is active =>       ", booth.isActive());

        // assert(!booth.isActive() && address(booth).balance == 0);
    }

    function test_cinco() public {
        console2.log("initial balance creator: ", address(this).balance);
        console2.log("initial balance booth:   ", address(booth).balance);
        console2.log("initial balance 0x1 :    ", address(0x1).balance);
        console2.log("initial balance 0x2:     ", address(0x2).balance);
        console2.log("initial balance 0x3:     ", address(0x3).balance);
        console2.log("initial Is active =>     ", booth.isActive());

        vm.prank(address(0x1));
        booth.vote(false);

        vm.prank(address(0x2));
        booth.vote(true);

        vm.prank(address(0x3));
        booth.vote(true);

        console2.log("****AFTER EXECUTION***");
        console2.log("final balance creator:   ", address(this).balance);
        console2.log("final balance booth:     ", address(booth).balance);
        console2.log("final balance 0x1 :      ", address(0x1).balance);
        console2.log("final balance 0x2:       ", address(0x2).balance);
        console2.log("final balance 0x3:       ", address(0x3).balance);
        console2.log("final Is active =>       ", booth.isActive());

        // assert(!booth.isActive() && address(booth).balance == 0);
    }
}
