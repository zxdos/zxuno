# Authors

2021 Ivan Tatarinov <ivan-tat@ya.ru>

# Contributors

No one yet.

# License

This document is under [GNU FDL-1.3 or later](https://spdx.org/licenses/GFDL-1.3-or-later.html) license.  
SJAsmPlus Z80 Assembler is distributed under [zlib](https://spdx.org/licenses/Zlib.html) license.  
z88dk is distributed under [Clarified Artistic](https://spdx.org/licenses/ClArtistic.html) license.

# 1. General information

The structure of `sdk` folder:

Directory | Description
----|----
`bin` | Compiled binaries of tools.
`include` | Header files (`.def`, `.h` etc.) to be included in other sources (assembler, C, etc.).
`src` | The source code of local and downloadable tools. See Makefiles for details.

## 1.1. Copyright and licensing information for files

We try to follow [REUSE recommendations](https://reuse.software/tutorial/) on how to easely specify copyright and licensing information to our files.
So we added this information to each source file we used according to [SPDX specification](https://spdx.dev/specifications/).
Check it out by using this [reuse-tool](https://github.com/fsfe/reuse-tool).

# 2. Using SDK in GNU environment on Linux, FreeBSD etc.

## 2.1. Prepare a build environment

### 2.1.1. On a Debian-based system (Ubuntu etc.)

Open terminal and type:

```
# apt install -y build-essential git
```

to install `build-essential` and `git` packages.

**NOTE**: here the first symbol "#" means that the following command must be run as *root* or using `sudo` utility.

Additional packages for targets:

Target | Packages
----|----
`sjasmplus` | cmake libboost-all-dev libxml2-dev
`z88dk` | dos2unix libboost-all-dev texinfo texi2html libxml2-dev subversion bison flex zlib1g-dev m4

To use cross-compilation for Windows platform install *mingw-w64* package.

### 2.1.2. Clone repository

Choose a directory for project and type:

```bash
git clone git://github.com/zxdos/zxuno.git zxuno
```

Now `zxuno` sub-directory is the ZX-Uno project's root directory and all actions we'll make inside it.

## 2.2. Build tools

Go to the project's root directory, enter `sdk` sub-directory and type one of the following commands:

Command | Description
----|----
`make` | Build and install all tools from sources
`make <TARGET>` | Build and install only the TARGET from sources
`make BUILD=<BUILD>` | Cross-build and install all tools from sources for Windows platform
`make BUILD=<BUILD> <TARGET>` | Cross-build and install only the TARGET from sources for Windows platform

where:

Value of `TARGET` | Origin | Description
----|----|----
`sjasmplus` | downloaded | SJAsmPlus Z80 Assembler
`z88dk` | downloaded | z88dk
`zx7b` | `src/zx7b` | zx7b
`tools` | `src/tools` | tools

Value of `BUILD` | Target system
----|----
`mingw32` | Windows with i686 architecture (32-bits)
`mingw64` | Windows with AMD64 architecture (64-bits)

Compiled binaries are installed into `bin` sub-directory.

Example:

```bash
make BUILD=mingw64 tools
```

Then you may use `strip` tool to strip debug information from file and thus shrink file's size. Example:

```bash
strip bin/*.exe
```

For more options see [`Makefile`](Makefile).

## 2.3. Clean tools

Go to the project's root directory, enter `sdk` sub-directory and type one of the following commands:

Command | Description
----|----
`make uninstall` | remove installed binaries
`make clean` | clean after compilation from sources
`make distclean` | acts like `clean` but also remove temporary and downloaded files
`make BUILD=<BUILD> uninstall` | remove installed binaries for Windows platform
`make BUILD=<BUILD> clean` | clean after compilation from sources for Windows platform
`make BUILD=<BUILD> distclean` | acts like `clean` for Windows platform but also remove temporary and downloaded files

Value of `BUILD` is described in [2.2](#22-build-tools).

For more options see [`Makefile`](Makefile).

## 2.4. Tools usage

These tools are supposed to be used mainly in Makefiles and Bash scripts invoked from Makefiles.

### 2.4.1. In Makefiles

To use these tools in a Makefile just include `common.mk` file at the beginning of one like this:

```make
include ../sdk/common.mk
```

Remember to specify correct relative path to it.

This will set `ZXSDK` environment variable (on first inclusion only) and update your `PATH` environment variable to point to SDK's tools.
These changes are actual for current invocation of `make` utility and all child processes.

### 2.4.2. In Bash scripts

Bash scripts are supposed to be invoked from Makefiles where the correct environment is already prepared by `make` utility so nothing must be done for such scripts.

In other cases you must source `setenv.sh` file in a Bash script like this:

```bash
source ../sdk/setenv.sh
```

or

```bash
. ../sdk/setenv.sh
```

Remember to specify correct relative path to it.

This has the same behavior as the inclusion of `common.mk` file in a Makefile.

# 3. Using SDK in GNU environment on Windows

## 3.1. Prepare a build environment

### 3.1.1. Setup Cygwin

Download and run [Cygwin](https://cygwin.com/) GUI installer for Windows, either [32 bit](https://cygwin.com/setup-x86.exe) or [64 bit](https://cygwin.com/setup-x86_64.exe) version. See [Chapter 2. Setting Up Cygwin](https://cygwin.com/cygwin-ug-net/setup-net.html) for more information.

Install the following packages in Cygwin:

Target | Dependencies
----|----
all targets | bash git make wget unzip p7zip
`sjasmplus` | gcc-g++ cmake libboost-devel
`z88dk` | mingw64-i686-gcc-core mingw64-i686-libxml2 patch
`zx7b` | gcc-core
`tools` | gcc-core

**HINT**: you can install *Midnight Commander* (`mc` package). It will help you to navigate through filesystem.

To open Cygwin terminal just click on it's icon on desktop. This will open a Bash shell in a GNU environment.

### 3.1.2. Clone repository

The cloning is described in [2.1.2](#212-clone-repository).

## 3.2. Build tools

Go to the project's root directory, enter `sdk` sub-directory and type one of the following commands:

Command | Description
----|----
`make` | **Quick setup** of all tools (download precompiled binaries and install them)
`make <TARGET>` | **Qucik setup** of the TARGET only
`make FORCEBUILD=1` | Build and install all tools from sources
`make FORCEBUILD=1 <TARGET>` | Build and install only the TARGET from sources

where:

Value of `TARGET` | Sources origin | Binaries origin (**Quick setup**) | Build from sources
----|----|----|----
`sjasmplus` | downloaded | downloaded (**yes**) | available
`z88dk` | downloaded | downloaded (**yes**) | available
`zx7b` | local | precompiled locally (**no**) | available
`tools` | local | precompiled locally (**no**) | available

Then you may use `strip` tool to strip debug information from file and thus shrink file's size. Example:

```bash
strip bin/*.exe
```

For more options see [`Makefile`](Makefile).

## 3.3. Clean tools

Go to the project's root directory, enter `sdk` sub-directory and type one of the following commands:

Command | Description
----|----
`make FORCECLEAN=1 uninstall` | remove installed binaries from SDK after quick setup
`make FORCECLEAN=1 clean` | clean sources from downloaded binaries after quick setup
`make FORCECLEAN=1 distclean` | acts as forced `clean` but also removes temporary and downloaded files
`make FORCEBUILD=1 FORCECLEAN=1 uninstall` | remove all installed binaries from SDK
`make FORCEBUILD=1 FORCECLEAN=1 clean` | clean SDK after compilation from sources
`make FORCEBUILD=1 FORCECLEAN=1 distclean` | acts as forced `clean` after compilation from sources but also removes temporary and downloaded files

For more options see [`Makefile`](Makefile).

## 3.4. Tools usage

### 3.4.1. In Makefiles

The usage is similar to one for GNU on Linux, FreeBSD etc.
See [2.4.1](#241-in-makefiles).

### 3.4.2. In Bash scripts

The usage is similar to one for GNU on Linux, FreeBSD etc.
See [2.4.2](#242-in-bash-scripts).

# 4. Using SDK on Windows without GNU environment

## 4.1. Prepare a build environment

You should manually download precompiled binaries of SJAsmPlus and Z88DK from Internet and put them in their sub-directories as described in [`src/Makefile`](src/Makefile).

## 4.2. In batch scripts

To use these tools in a batch script just call `setenv.bat` file at the beginning of one like this:

```batch
call ..\sdk\setenv.bat
```

Remember to specify correct relative path to it.

This will set `ZXSDK` environment variable (on first call only) and update your `PATH` environment variable to point to SDK's tools.
These changes are actual for current invocation of command shell and all child processes.

# References

* [REUSE SOFTWARE](https://reuse.software/) - a set of recommendations to make licensing your Free Software projects easier
* [The Software Package Data Exchange (SPDX)](https://spdx.dev/) - An open standard for communicating software bill of material information, including components, licenses, copyrights, and security references
* [GNU Operating System](https://www.gnu.org/)
* [GNU Standards](http://savannah.gnu.org/projects/gnustandards) - GNU coding and package maintenance standards ([package](https://pkgs.org/download/gnu-standards))
* [GNU Core Utilities](https://www.gnu.org/software/coreutils/) ([package](https://pkgs.org/download/coreutils))
* [GNU Bash](https://www.gnu.org/software/bash/) - GNU Bourne Again SHell ([package](https://pkgs.org/download/bash))
* [GNU Compiler Collection](https://www.gnu.org/software/gcc/) ([package](https://pkgs.org/download/gcc))
* [GNU Make](https://www.gnu.org/software/make/) - utility for directing compilation ([package](https://pkgs.org/download/make))
* [Cygwin](https://cygwin.com/) - a large collection of GNU and Open Source tools which provide functionality similar to a Linux distribution on Windows
* [MSYS2](https://www.msys2.org/) - a collection of tools and libraries providing you with an easy-to-use environment for building, installing and running native Windows software
* [MinGW](https://osdn.net/projects/mingw/) - Minimalist GNU for Windows
* [MinGW-w64](http://mingw-w64.org/doku.php) - an advancement of the original mingw.org project, created to support the GCC compiler on Windows systems
* [cmd](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/cmd) - command interpreter in Windows
* [Windows commands](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/windows-commands)
* [SJAsmPlus](https://github.com/sjasmplus/sjasmplus) - Z80 Assembler
* [Z88DK](https://github.com/z88dk/z88dk) - The Development Kit for Z80 Computers
* [Open Source FPGA Foundation Formed to Accelerate Widespread Adoption of Programmable Logic](https://osfpga.org/osfpga-foundation-launched/) - news article (April 8, 2021)
* [Open-Source FPGA Foundation](https://osfpga.org/) - main site
* [Related Projects of Open Source FPGA Foundation](https://github.com/os-fpga/open-source-fpga-resource) - page on GitHub
