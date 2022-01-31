# COIN-OR fetch, build, and install helper

This script works like a package manager to fetch, build, and install COIN-OR
projects, along with their dependencies, from their respective git
repositories. The projects are intalled in subdirectories at the same level as
the `coinbrew` script, which fetches the source from GitHub, builds the code,
and installs the binaries, libraries, and header files. It has many features
that are yet to be documented. It can probably do what you need even if it is
not mentioned here, so please feel free to ask questions!

## Quick start example

To use the latest version of coinbrew, simply download the `coinbrew` script from `master` and select the desired build target.
```
wget https://raw.githubusercontent.com/coin-or/coinbrew/master/coinbrew
./coinbrew build Cbc@stable/2.10
```

To use the legacy version, grab the v1.0 tag.
```
wget https://raw.githubusercontent.com/coin-or/coinbrew/v1.0/coinbrew
./coinbrew build Cbc@stable/2.10
```

## Documentation

Full documentation is at 

https://coin-or.github.io/coinbrew

Please also see the general documentation at

https://coin-or.github.io

for much more detailed information on setting up your platform to use coinbrew
and other useful information. 
