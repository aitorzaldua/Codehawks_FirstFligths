## [Low - Gas Saving] Repeated access to the loop break condition

### Severity

QA - Gas Saving

### Date Modified

Oct 30th, 2023

### Vulnerability Details

There are a few functions that have a loop that checks the length of an array on each iteration:

`enterRaffle()`

`getActivePlayerIndex()`

`_isActivePlayer()`

In these cases, the length of the array is continuously accessed on each iteration, which involves a reading on the corresponding mapping. To avoid the constant access to the storage, it is recommended to store the length in a variable and use it in the loop.

### Impact

Just gas saving

### Tools Used

Foundry, manual.

### Recommendations

Store the length of the arrays in memory before the loop and use that variable instead of accessing the array length on every iteration.
