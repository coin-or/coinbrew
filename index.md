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
  * A compiler toolchain (`gcc`, `cl`, etc.)

## Download

`coinbrew` consists of a single bash script. To use it, download the file

   [https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew](https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew)

to your system and make sure that it is executable.

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
coinbrew fetch <ProjectName|URL:branch> --no-prompt
```
For example,
```
coinbrew fetch Cbc:stable/2.10 --verbosity=2 --no-prompt
```
Note that this command can be run even if you have previously fetched another
project with overlapping dependencies. You can even fetch two projects that
require different versions of a common dependency. Each fetch command will
automatically check out the appropriate version of all dependent projects,
although this may fail if any of these projects have uncommitted local
changes. To build a fork, specify the URL, e.g.,
```
coinbrew fetch https://github.com/tkralphs/Cbc:stable/2.10 --verbosity=2 --no-prompt
```

### Build project from source

To build a project, do
```
coinbrew build <ProjectName> --no-prompt <configure_options>
```
For example,
```
coinbrew build Cbc --verbosity=2 --test --enable-debug --prefix=/usr/local
```
During the build process, each project will be "pre-installed" within the
build directory. Permanent installation to another location is done using the
`install` command (see below), but it is important to note that the prefix
must be specified at build time.

Any option valid for a project's `configure` script can be specified as
arguments to `coinbrew` and will be passed through. To see what arguments are
available for configuration, do
```
coinbrew Cbc --configure-help
```

### Install executables, libraries, and header files

After building with an installation prefix specified, the project may be
installed using the command
```
coinbrew install <ProjectName>
```
## Help

To get help, do
```
coinbrew --help
```
The output is preproduced here for convenience.
```
Welcome to the COIN-OR fetch and build utility

For help, run script with --help.

Usage: coinbrew <command1> <command2> <name|URL:branch> --option option_par ...
       Run without arguments for interactive mode

Commands:

  fetch: Checkout source code for project and dependencies
    options: --svn (check out SVN projects with SVN)
             --git (check out all projects from git)
             --ssh (checkout git projects using ssh
             --skip='proj1 proj2' skip listed projects
             --no-third-party don't download third party source (getter-scripts)
             --skip-update Skip updating projects that are already checked out (useful if you have local changes)

  build: Configure, build, test (optional), and pre-install all projects
    options: --xxx=yyy (will be passed through to configure)
             --parallel-jobs=n build in parallel with maximum 'n' jobs
             --build-dir=\dir\to\build\in do a VPATH build (default: /home/tkral/coinbrew/build)
             --test run unit test of main project before install
             --test-all run unit tests of all projects before install
             --verbosity=i set verbosity level (1-4)
             --reconfigure re-run configure
             --prefix=\dir\to\install (where to install, default: /home/tkral/coinbrew/build)

  install: Install all projects in location specified by prefix (after build and test)

  uninstall: Uninstall all projects

General options:
  --debug: Turn on debugging output
  --no-prompt: Turn on non-interactive mode
  --help: Print help
```