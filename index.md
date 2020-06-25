# COIN-OR fetch, build, and install helper

This script works like a package manager to fetch, build, and install COIN-OR
projects, along with their dependencies, from their respective git
repositories. The projects are intalled in subdirectories at the same level as
the `coinbrew` script, which fetches the source from GitHub, builds the code,
and installs the binaries, libraries, and header files. It has many features
that are yet to be documented. It can probably do what you need even if it is
not mentioned here, so please feel free to ask questions!

## Requirements

THis script is a bash script and must be executed in a bash shell. Bash is
available on all major platforms. See [here](
https://coin-or.github.io/user_introduction.html#building-from-source) for
more detailed documentation on installing/using bash.  Other requirements
include the following commands.
  * `make`
  * `git`
  * `wget`
  * `tar`
  * `patch`
  * `dos2unix`
  * `pkg-config`
  * A C++ compiler (`g++`, `cl`, etc.)
  * Optional: A Fortran compiler (`gfortran`, `ifort`, etc.) is needed for some projects.
  
## Download

`coinbrew` consists of a single bash script. To use it, download the file

   [https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew](https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew)

to your system and make sure that it is executable (`chmod u+x coinbrew`).

## Usage: Interactive mode

If you run `coinbrew` without arguments, you will be guided through the
process of fetching and building interactively by prompts.

## Usage: Batch mode

### Fetch source of project

The fetch command serves several purposes. For projects that have yet to be
cloned, it clones the project from Github. For existing projects, it checks
out the appropriate version and gets any updates from Github. It is a good
idea to fetch before building, even for previously fetched projects.

The following assumes the `coinbrew` script is in your executable path. If
not, be sure to add the path to the executable in the commands below. To get
the most recent sources for a project, along with all its depencencies, use 
```
coinbrew fetch <ProjectName|URL@version>
```
Examples
```
coinbrew fetch Cbc                                    #get latest release
coinbrew fetch Cbc@2.10                               #get stable version 2.10
coinbrew fetch --ssh Cbc@2.10                         #get with ssh instead of https
coinbrew fetch https://github.com/tkralphs/Cbc@master #get fork
coinbrew fetch Cbc@master --skip-dependencies         #get project only
```
Note that this command can be run even if you have previously fetched another
project with overlapping dependencies or a different version of the same project.
You can even fetch two projects that require different versions of a common dependency. 
Each fetch command will automatically check out the appropriate versions of all dependent 
projects, although this may fail if any of these projects have uncommitted local
changes.

### Build and install project from source

To build a project that has already been fetched with the existing versions of all
dependent projects that are already checked out, do
```
coinbrew build <ProjectName> <coinbrew_options> <configure_options>
```
Examples
```
coinbrew build Cbc --tests none --enable-debug --prefix=/usr/local 
coinbrew build Cbc --verbosity 2 --parallel-jobs 4 --build-dir build-cbc -p
coinbrew build Cbc ADD_CXXFLAGS=-DFOO --prefix=/usr/local 
```
The build artifacts for each project will be generated in the `build`
directory by default (a different directory can be specified with
`--build-dir` or `-b`). Installation is done automatically at build time to
abother installation directory, specified with `--prefix` or `-p` (`dist/` by 
default). If you specify `-p` (after specifying a build directory) but provide 
no install directory, installation will be done to the build directory 
(convenient if you have multiple build directories). 
```
coinbrew build Cbc --build-dir build-cbc -p
```
If the install directory is not writable, the `install` command 
must be invoked via sudo and the user will be prompted for sudo authorization.
This is only done once just after launching the script so that the install
can be done unattended from then on. 

It is not necessary to fetch a project before building it. This will be done
automatically if the project does not exist. If the project does exist,
however, the fetch will not be done automatically. If it is desired to do an
update of the project source before building, this can be done with
```
coinbrew fetch build Cbc@master --tests main --enable-debug --prefix=/usr/local
```
Any option valid for a project's `configure` script can be specified as
arguments to `coinbrew` and will be passed through. To see what arguments are
available for configuration, do
```
coinbrew Cbc --configure-help
```

## Help

To get help, do
```
coinbrew --help
```
The output is preproduced here for convenience.
```
Usage: coinbrew <command> <name|URL@version> --option value ...
       Run without arguments for interactive mode

Commands:

  fetch: Clone repos of project and dependencies
    options: --ssh checkout git projects using ssh protocol rather than https
             --skip,-s <'proj1 proj2'> skip listed projects
             --no-third-party don't fetch third party source (run getter-scripts)
             --skip-update skip updating projects that are already checked out (useful if you have local changes)
             --skip-dependencies don't fetch dependencies, only main project
             --latest-release Fetch latest releases of projects
             --time check out project and all dependencies at a time stamp
             --auto-stash stash changes before switching versions (experimental)

  build: Configure, build, test (optional), and install all projects
    options: --configure-help (print help on build configuration
             --xxx=yyy (will be passed through to configure)
             VAR=xxx (will be passed through to configure)
             --parallel-jobs,-j <n> build in parallel with maximum 'n' jobs (default: 1)
             --build-dir,-b </dir/to/build/in> where to build (default: /mnt/c/Users/tkral/Documents/Projects/CoinUtils/build)
             --tests,-t <all|main|none> which tests to do before install (default: all)
             --verbosity,-v <1-4> set verbosity level (default: 1)
             --reconfigure re-run configure
             --prefix,-p </dir/to/install> where to install (default: /mnt/c/Users/tkral/Documents/Projects/CoinUtils/dist)
             --skip-dependencies don't build dependencies, only main project
             --no-third-party don't build third party projects
             --static build static executables on Linux and OS X
             --download-binary <'proj1 proj2'> list of binary packages to download
             --platform <string> string specifying platform (required for binaries)

  install: Install all projects in location specified by prefix. This is done
           done automatically after build, so probably not useful in general.

  uninstall: Uninstall all projects

  download: Download project binaries (experimental, limited projects supported)
    options: --platform <string> string specifying platform (required for binaries)
             --prefix,-p </dir/to/install> where to install (default: /mnt/c/Users/tkral/Documents/Projects/CoinUtils/dist)

General options:
  --debug,-d Turn on debugging output (this should be the first option specified)
  --no-prompt,-n Suppress interactive prompts
  --help,-h Print help
```
