## [H1] FFi is enabled and running commands on auditors' computers

### Severity

High Risk

### Date Modified

Dec 6th, 2023

### Summary

Foreign Function Interface, aka ffi, is a cheat code that executes commands in our computer as if it were the owner. You should never run this type of test without knowing what is happening.

In this case, at the very moment we run `make` we run every test so, by default, we will be pwned!

### Vulnerability Details (PoC)

After run `clone` and `make`:

```
➜  2023-11-Santas-List git:(main) ✗ ls -la
total 112
drwxr-xr-x  17 aitor  staff    544 Dec  6 09:46 .
drwxr-xr-x  16 aitor  staff    512 Dec  6 09:45 ..
drwxr-xr-x  14 aitor  staff    448 Dec  6 09:45 .git
drwxr-xr-x   3 aitor  staff     96 Dec  6 09:45 .github
-rw-r--r--   1 aitor  staff    173 Dec  6 09:45 .gitignore
-rw-r--r--   1 aitor  staff    341 Dec  6 09:45 .gitmodules
-rw-r--r--   1 aitor  staff   1133 Dec  6 09:45 Makefile
-rw-r--r--   1 aitor  staff  33603 Dec  6 09:45 README.md
drwxr-xr-x   3 aitor  staff     96 Dec  6 09:46 cache
-rw-r--r--   1 aitor  staff    543 Dec  6 09:45 foundry.toml
drwxr-xr-x   5 aitor  staff    160 Dec  6 09:45 img
drwxr-xr-x   5 aitor  staff    160 Dec  6 09:45 lib
drwxr-xr-x  38 aitor  staff   1216 Dec  6 09:46 out
-rw-r--r--   1 aitor  staff    389 Dec  6 09:45 slither.config.json
drwxr-xr-x   5 aitor  staff    160 Dec  6 09:45 src
drwxr-xr-x   4 aitor  staff    128 Dec  6 09:45 test
-rw-r--r--   1 aitor  staff      0 Dec  6 09:46 youve-been-pwned
➜  2023-11-Santas-List git:(main) ✗
```

:-( ups.

### Impact

In this case, the elves were just being naughty, but a malicious developer could use this kind of test to control or destroy our computer.

### Tools Used

Manual, foundry

### Recommendations

Always check all code distributed by a customer, especially the tests. Then, if you find something suspicious, you can "comment" it and ask the developers for an explanation.

```
/*
* What is that???

function testPwned() public {
    string[] memory cmds = new string[](2);
    cmds[0] = "touch";
    cmds[1] = string.concat("youve-been-pwned");
    cheatCodes.ffi(cmds);
}
*/
```
