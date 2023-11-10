// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @audit Is not possible to store passwords so we change
 * @audit all the idea to store just data.
 */

contract DataStore is Ownable {
    error DataStore__NotOwner();

    string private s_data;

    event SetNewData();

    constructor(string memory _initialData) {
        s_data = _initialData;
    }

    /*
     * @notice This function allows only the owner to set a new data.
     * @param newData The new data to set.
     */
    function setData(string memory newData) external onlyOwner {
        s_data = newData;
        emit SetNewData();
    }

    /*
     * @notice This allows only the owner to retrieve the data.
     */
    function getData() external view returns (string memory) onlyOwner {
        return s_data;
}
