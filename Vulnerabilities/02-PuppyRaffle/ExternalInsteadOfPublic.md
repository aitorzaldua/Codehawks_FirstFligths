## [Gas Saving - functions as external] Consider declaring functions as external rather than public

### Severity

Low Risk (Gas Saving)

### Date Modified

Oct 28th, 2023

### Vulnerability Details

For all functions declared as `public`, the input parameters are automatically copied into memory, and this costs gas. If your function is only called externally, you must mark it with `external` visibility. The parameters of external functions are not copied into memory, but read directly from the calldata. This small optimisation can save a lot of gas if the input parameters of the function are huge.

The functions affected are:

`enterRaffle()`

`refund()`

`tokenURI()`

### Impact

Just gas saving.

### Tools Used

N/A

### Recommendations

Change the visibility to external
