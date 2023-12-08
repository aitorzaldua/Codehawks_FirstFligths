## [H1] Incorrect price in sanataTokes.sol´s burn() function

### Severity

High Risk

### Date Modified

Dec 6th, 2023

### Summary

As per documentation: "buyPresent: A function that trades 2e18 of SantaToken for an NFT", but unfortunately the developers made a mistake and set the trade to 1e18 santaTokens.

```
function burn(address to) external {
    if (msg.sender != i_santasList) {
        revert SantaToken__NotSantasList();
    }
    _burn(to, 1e18);
}
```

### Vulnerability Details (PoC)

We just need a very simple test:

```
function test_buyPresentWith1e18SantaToken() external executeCollectPresent {
    // 1. After collectPresent user has just 1e18 santaToken:
    assertEq(santasList.balanceOf(user), 1);
    assertEq(santaToken.balanceOf(user), 1e18);

    // 2. user can buy a present using only 1e18 santaTokens:
    vm.prank(user);
    santasList.buyPresent(mate);
    assertEq(santasList.balanceOf(mate), 1);
    assertEq(santaToken.balanceOf(user), 0);
    }
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_buyPresentWith1e18SantaToken
[⠢] Compiling...
[⠔] Compiling 1 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.29s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_buyPresentWith1e18SantaToken() (gas: 213043)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 4.63ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2023-11-Santas-List git:(main) ✗
```

### Impact

The protocol will collect half of the expected SantaTokens, which is a major problem if they have other commitments such as distributing funds, paying feeds, etc... the protocol could go bankrupt.

### Tools Used

Manual, foundry

### Recommendations

Set the correct price in the SantaToken.sol function:

```
function burn(address from) external {
        if (msg.sender != i_santasList) {
            revert SantaToken__NotSantasList();
        }
        _burn(from, 2e18);
    }
```

The previous test will fail:

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_buyPresentWith1e18SantaToken
[⠢] Compiling...
[⠔] Compiling 3 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.30s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[FAIL. Reason: panic: arithmetic underflow or overflow (0x11)] test_buyPresentWith1e18SantaToken() (gas: 194751)
Test result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 1.80ms

Ran 1 test suites: 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/unit/SantasListTest.t.sol:SantasListTest
[FAIL. Reason: panic: arithmetic underflow or overflow (0x11)] test_buyPresentWith1e18SantaToken() (gas: 194751)

Encountered a total of 1 failing tests, 0 tests succeeded
```

And a new test, that demand 2 tokens, will success:

```
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
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_buyPresentWith2e18SantaToken
[⠢] Compiling...
[⠔] Compiling 1 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.32s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_buyPresentWith2e18SantaToken() (gas: 242919)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.50ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2023-11-Santas-List git:(main) ✗
```
