## [Low - Gas Saving] ++i Costs Less Gas Than i++, Especially When It's Used In For-loops

### Severity

QA - Gas Saving

### Date Modified

Oct 30th, 2023

### Vulnerability Details

There is a 5 gas cost difference between ++i and i++ in favour of the former. The contract uses i++ in these functions:

`enterRaffle()` , i++ but also j++

`getActivePlayerIndex()`

`_isActivePlayer()`

### Impact

Gas Saving

### Tools Used

Foundry, manual

### Recommendations

Replace all i++ and j++ with ++i and ++j
