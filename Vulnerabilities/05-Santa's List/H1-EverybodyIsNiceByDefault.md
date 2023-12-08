## [H1] No need to be on the list to collect gifts

### Severity

High Risk

### Date Modified

Dec 4th, 2023

### Summary

Enums use indexes to set the value of a variable and have index 0 as the default value. In this case, index 0 is "NICE", so every user has "NICE" (index 0) as the default value in the enum.

If we run the `collectPresent()` function, every user will have a present because all users have index 0 (NICE) by default.

The same problem occurs with the `getNaughtyOrNiceOnce()` and `getNaughtyOrNiceTwice()` functions.

### Vulnerability Details (PoC)

For these functions, we do not need to add users to the lists:

```
function test_myList() public {
    assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.NICE));
    assertEq(uint256(santasList.getNaughtyOrNiceTwice(user)), uint256(SantasList.Status.NICE));
}
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_myList
[⠢] Compiling...
[⠔] Compiling 1 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.29s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_myList() (gas: 13504)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 2.21ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

And, unfortunately, for `collectPresent()`:

```
function test_everyBodyIsNice() external {
    vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);
    vm.startPrank(user);
    santasList.collectPresent();
    assertEq(santasList.balanceOf(user), 1);
    vm.stopPrank();
}
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_everyBodyIsNice
[⠢] Compiling...
[⠔] Compiling 1 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.29s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_everyBodyIsNice() (gas: 109817)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.90ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2023-11-Santas-List git:(main) ✗
```

### Impact

Anyone not marked EXTRA_NICE, NAUGHTY, NOT_CHECKED_TWICE is NICE by default and will receive a gift.

### Tools Used

Manual, foundry

### Recommendations

Add the option NOT_LISTED as index 0 in the Enum.

```
enum Status {
        NOT_LISTED,
        NICE,
        EXTRA_NICE,
        NAUGHTY,
        NOT_CHECKED_TWICE
    }
```

If we run again `test_everyBodyIsNice`:

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_everyBodyIsNice
[⠢] Compiling...
[⠔] Compiling 2 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.34s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[FAIL. Reason: SantasList__NotNice()] test_everyBodyIsNice() (gas: 18711)
Test result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 2.01ms

Ran 1 test suites: 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/unit/SantasListTest.t.sol:SantasListTest
[FAIL. Reason: SantasList__NotNice()] test_everyBodyIsNice() (gas: 18711)

Encountered a total of 1 failing tests, 0 tests succeeded
➜  2023-11-Santas-List git:(main) ✗
```

Fail as should be. Now, we add the user in both lists as NICE:

```
function test_NotEveryBodyIsNice() external {
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
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_NotEveryBodyIsNice
[⠢] Compiling...
[⠔] Compiling 1 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.33s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_NotEveryBodyIsNice() (gas: 158957)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.91ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2023-11-Santas-List git:(main) ✗

```

And works perfect.
