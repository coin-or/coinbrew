# Download

Download this file:

   [https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew](https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew)


Save it on your system and make sure it is executable.


# Usage: Interactive mode

Run `coinbrew` without arguments.

# Usage: Batch mode

## Fetch source

To get the source of a project with all its depencencies, use
```
/path/to/coinbrew fetch --main-proj=<ProjectName>
```

For example,
```
/path/to/coinbrew fetch --main-proj=Cbc
```


## Build source

```
/path/to/coinbrew build --main-proj=<ProjectName>
```

For example,
```
/path/to/coinbrew build --main-proj=Cbc --quiet --test
```


## Install executables, libraries, and header files

```
/path/to/coinbrew install --main-proj=<ProjectName>
```
