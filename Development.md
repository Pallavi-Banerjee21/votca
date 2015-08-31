# Introduction #

This pages summarizes a few hints how to get started with developing your own votca code. If you are just interested in writing your own analysis tool, you can use an existing votca installation. Examples for small tools can be found in the csgapps repository. They offer a good starting point to get an idea how to use the analysis library.

If you start digging deeper into the code and want to modify libtools or libcsg, we highly recommend to use an IDE. For most of the tools and libraries, there are existing netbeans projects.

# Setting up netbeans #
Before importing single projects into Netbeans, make sure that build.sh successfully finishes on your system. build.sh will (among others) invoke cmake and thereby create needed header files.
You may now set the GROMACS flags (needed to specify the version) and start Netbeans.


## Compiler and Linker flags ##
Important is to specify the GROMACS path in CPPFLAGS and LDFLAGS. Also, interfaces of the different GROMACS versions are not compatible and flags to select which version is installed have to be set (e.g. -DGMX=45).

The following snippet is a script to start Netbeans and setup a few flags which are essential:
```
#!/bin/bash
export LDFLAGS="-L/sw/linux/gromacs/4.5/shared/latest/lib"
export CPPFLAGS="-I/sw/linux/gromacs/4.5/shared/latest/include -DGMX=45"

/sw/linux/netbeans-6.9/bin/netbeans
```

Please do not change these settings in the netbeans projects and commit since they are system and platform dependent.