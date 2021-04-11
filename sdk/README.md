# Authors

2021 Ivan Tatarinov <ivan-tat@ya.ru>

# Contributors

No one yet.

# License

This document is under [GNU FDL-1.3 or later](http://www.gnu.org/licenses/fdl-1.3.html) license.

# 1. General information

The source code of all tools is in `src` directory. All compiled binaries are placed in `bin` directory.

## 1.1. Copyright and licensing information for files

We try to follow [REUSE recommendations](https://reuse.software/tutorial/) on how to easely specify copyright and licensing information to our files.
So we added this information to each source file we used according to [SPDX specification](https://spdx.dev/specifications/).
Check it out by using this [reuse-tool](https://github.com/fsfe/reuse-tool).

# 2. Using SDK in GNU environment on Linux, FreeBSD etc.

## 2.1. Build tools

To build all tools type:

```bash
make
```

To build only **sjasmplus** type:

```bash
make bin/sjasmplus
```

## 2.2. Clean tools

To clean everything type:

```bash
make clean
```

## 2.3. Tools usage

These tools are supposed to be used mainly in Makefiles and Bash scripts invoked from Makefiles.

### 2.3.1. In Makefiles

To use these tools in a Makefile just include `common.mk` file at the beginning of one like this:

```make
include ../sdk/common.mk
```

Remember to specify correct relative path to it.

This will set "ZXUNOSDK" environment variable (on first inclusion only) and update your "PATH" environment variable to point to SDK's tools.
These changes are actual for current invocation of "make" utility and all child processes.

### 2.3.2. In Bash scripts

Bash scripts are supposed to be invoked from Makefiles where the correct environment is already prepared by "make" utility so nothing must be done for such scripts.

In other cases you must source `setvars.sh` file in a Bash script like this:

```bash
source ../sdk/setvars.sh
```

or

```bash
. ../sdk/setvars.sh
```

Remember to specify correct relative path to it.

This has the same behavior as the inclusion of `common.mk` file in a Makefile.

# 3. Using SDK in GNU environment on Windows

**NOTE**: compilation of the following tools:

* sjasmplus

on Windows platform is disabled right now because of presence of precompiled binaries of them in repository. They are not deleted when cleaning.

## 3.1. Build tools

To build all tools type:

```bash
make
```

To build only **sjasmplus** type:

```
make bin/sjasmplus.exe
```

## 3.2. Clean tools

To clean everything type:

```bash
make clean
```

## 3.3. Tools usage

### 3.3.1. In Makefiles

The usage is similar to one for GNU/Linux, FreeBSD etc. See [2.3.1](#231-in-makefiles).

### 3.3.2. In Bash scripts

The usage is similar to one for GNU/Linux, FreeBSD etc. See [2.3.2](#232-in-bash-scripts).

# 4. Using SDK on Windows without GNU environment

## 4.1. In batch scripts

To use these tools in a batch script just call `setvars.bat` file at the beginning of one like this:

```batch
call ..\sdk\setvars.bat
```

Remember to specify correct relative path to it.

This will set "ZXUNOSDK" environment variable (on first call only) and update your "PATH" environment variable to point to SDK's tools.
These changes are actual for current invocation of command shell and all child processes.
