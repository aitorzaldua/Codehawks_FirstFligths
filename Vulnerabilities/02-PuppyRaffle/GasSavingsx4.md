## [Low] Gas Savings x 4

### Severity

QA - Gas Saving

### Date Modified

Oct 30th, 2023

### Summary

FYI, here are 4 ways to save gas and improve code quality:

1. Repeated access to the loop break condition
2. Consider declaring functions as external rather than public
3. ++i Costs Less Gas Than i++, Especially When It's Used In For-loops
4. Set variables as immutables

### Vulnerability Details

- Repeated access to the loop break condition:

There are a few functions that have a loop that checks the length of an array on each iteration:

`enterRaffle()`

`getActivePlayerIndex()`

`_isActivePlayer()`

In these cases, the length of the array is continuously accessed on each iteration, which involves a reading on the corresponding mapping. To avoid the constant access to the storage, it is recommended to store the length in a variable and use it in the loop.

- Consider declaring functions as external rather than public:

For all functions declared as `public`, the input parameters are automatically copied into memory, and this costs gas. If your function is only called externally, you must mark it with `external` visibility. The parameters of external functions are not copied into memory, but read directly from the calldata. This small optimisation can save a lot of gas if the input parameters of the function are huge.

The functions affected are:

`enterRaffle()`

`refund()`

`tokenURI()`

- ++i Costs Less Gas Than i++, Especially When It's Used In For-loops:

There is a 5 gas cost difference between ++i and i++ in favour of the former. The contract uses i++ in these functions:

`enterRaffle()` , i++ but also j++

`getActivePlayerIndex()`

`_isActivePlayer()`

- Set variables as immutables:

In Solidity, variables which are not intended to be updated should be constant or immutable.

The Solidity compiler does not reserve a storage slot for constant or immutable variables and instead replaces every occurrence of these variables with their assigned value in the contract’s bytecode so we do not need to do SLOAD operations to access these variables.

Variables affected:

`raffleDuration`

`raffleStartTime`

### Impact

Gas Saving

### Tools Used

Manual, Foundry

### Recommendations

1. Store the length of the arrays in memory before the loop and use that variable instead of accessing the array length on every iteration.
2. Change the visibility to external.
3. Replace all i++ and j++ with ++i and ++j.
4. Set `raffleDuration` and `raffleStartTime` as immutables.
