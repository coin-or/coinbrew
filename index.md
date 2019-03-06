# COIN-OR build and install helper

This script resembles a package manager that installs COIN-OR projects
with its dependencies from source.
It fetches the source from GitHub, builds the code, and installs the
binaries, libraries, and header files.


## Download

`coinbrew` consists of a single bash script. To use it, download the file


   [https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew](https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew)


to your system and make sure that it is executable.


## Usage: Interactive mode

Run `coinbrew` without arguments.

## Usage: Batch mode

### Fetch source

To get the source of a project with all its depencencies, use
```
/path/to/coinbrew fetch --main-proj=<ProjectName>
```

For example,
```
/path/to/coinbrew fetch --main-proj=Cbc
```


### Build source

```
/path/to/coinbrew build --main-proj=<ProjectName>
```

For example,
```
/path/to/coinbrew build --main-proj=Cbc --quiet --test
```


### Install executables, libraries, and header files

```
/path/to/coinbrew install --main-proj=<ProjectName>
```
