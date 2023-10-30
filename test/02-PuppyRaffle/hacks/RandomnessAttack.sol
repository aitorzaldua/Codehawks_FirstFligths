// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import {console} from "forge-std/Test.sol";

interface IPuppyRaffle {
    function selectWinner() external;
}

contract RandomnessAttack {
    IPuppyRaffle puppyRaffle;

    address owner;
    address[] public players;

    modifier onlyOwner() {
        require(msg.sender == owner, "only Owner");
        _;
    }

    constructor(address _puppyRaffle) {
        owner = msg.sender;
        puppyRaffle = IPuppyRaffle(_puppyRaffle);
    }

    function attack() external view onlyOwner {
        uint256 winnerIndex = players.length;

        console.log("winnerIndex: ", winnerIndex);
    }

    receive() external payable {
        (bool success,) = owner.call{value: msg.value}("");
        require(success);
    }
}
