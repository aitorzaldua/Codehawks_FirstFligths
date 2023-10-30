## [LOW - Gas Saving] Set variables as immutables

### Severity

LOW - Gas Saving

### Date Modified

Oct 30th, 2023

### Summary

To Set the variables which value will no change during the contract helps to sabe a lot of gas

### Vulnerability Details

In Solidity, variables which are not intended to be updated should be constant or immutable.

The Solidity compiler does not reserve a storage slot for constant or immutable variables and instead replaces every occurrence of these variables with their assigned value in the contract’s bytecode so we do not need to do SLOAD operations to access these variables.

Variables affected:

`raffleDuration`

`raffleStartTime`

### Impact

Just Gas saving

### Tools Used

Foundry, manual

### Recommendations

Set `raffleDuration` and `raffleStartTime` as immutables.
