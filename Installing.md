Some Linux distribution provide a VOTCA package, but if your distribution is not listed below, follow the instructions under the _[From Source](Installing#From_Source.md)_ section.


# Fedora #
```
yum install votca-csg
```
The most recent version use:
```
yum install --enablerepo=updates-testing votca-csg

```

# OpenSuse #
Activate [Opensuse's education repository](https://build.opensuse.org/project/show/Education) and just install it:
```
zypper install votca-csg
```

# Gentoo #
```
emerge votca-csg
```
The most recent ebuilds can be found in the science overlay, which can be added by:
```
layman -a science
```

# Arch #
Votca package can be found in AUR (arch user repository):
https://aur.archlinux.org/packages/votca-csg/

# Debian #
```
sudo apt-get install votca-csg
```

# Ubuntu #
Votca is part of the universe repository. After activating it, just run:
```
sudo apt-get install votca-csg
```

# AIX #
AIX is the IBM operating system. For details see [compiling\_AIX](compiling_AIX.md)

# OSX #
OSX is the operating system running on Apple's machines. For details see [CompilingOSX](CompilingOSX.md)


# From Source #
Check the [dependencies](http://code.google.com/p/votca/wiki/Dependencies) first. Do **NOT** download anything yourself, this done by `build.sh` below.

When installing for the first time, run the following commands in bash:
```
prefix=WHERE/TO/INSTALL/VOTCA
mkdir -p ${prefix}/src
cd ${prefix}/src
wget http://votca.googlecode.com/hg/build.sh
chmod +x build.sh
./build.sh --prefix ${prefix} tools csg
```
Replace the _WHERE/TO/INSTALL/VOTCA_ with directory where you want to install votca, usually ${HOME}/votca is good choice.

This commands will:
  * Create a directory, where the sources are store (above `${prefix}/src`)
  * Go there
  * Download our build script
  * Make the build script executable
  * Run the build script to download all votca modules using mercurial

If you want to quickly build VOTCA in current directory and install it in your home just execute:
```
./build.sh --prefix ~/votca tools csg
```

If you don't have mercurial installed, run
```
./build.sh --prefix ${prefix} --latest tools csg
```
to download the latest tarballs instead.

## Minimal ##
If you just want an installation with the **absolute minimum** of dependencies, add the `--minimal` option to `build.sh`. Remember that this will also disable Gromacs support, which can be re-enabled by adding `-DWITH_GMX=ON` _after_ `--minimal`. The same can be done for fftw3 (`-DWITH_FFTW=ON`) and gsl (`-DWITH_GSL=ON`).

## Additional Options ##
It is possible to disable certain VOTCA functionality by adding the following options to the `build.sh` commandline (see [Dependencies](Dependencies.md) for details):
```
-DWITH_GMX=OFF
-DWITH_FFTW=OFF
-DWITH_GSL=OFF
```

It is also possible to specify path manually after ./build.sh (replace paths as necessary - here just an example what to look for):
```
-DGSL_INCLUDE_DIR=           ~/programs/gsl/include
-DGSL_LIBRARY=               ~/programs/gsl/lib/libgsl.so
-DCBLAS_LIBRARY=             ~/programs/gsl/lib/libgslcblas.so
-DFFTW3_INCLUDE_DIR=         ~/programs/fftw/include
-DFFTW3_LIBRARY=             ~/programs/fftw/lib/libfftw3.so
-DGROMACS_INCLUDE_DIR=           ~/programs/gromacs/include
-DGROMACS_LIBRARY=               ~/programs/gromacs/lib/libgmx.so
-DSQLITE_INCLUDE_DIR=        ~/programs/sqlite/include
-DSQLITE_LIBRARY=            ~/programs/sqlite/lib/libsqlite3.so
```

**Hint**: If you have specify multiple libraries use quotes to avoid problems with the special character `;` (which means end of command in all shells):
```
-DFFTW3_LIBRARY=             "/opt/fftw/lib/libfftw3.a;/usr/lib/libm.a"
```
## Update ##

To update later, it is enough to run:
```
cd ${prefix}/src
./build.sh --prefix ${prefix} --do-update tools csg
```

## Development Version ##
You can build the recent development version by adding the `--dev` option to `build.sh`:
```
./build.sh --prefix ${prefix} --dev tools csg
```


## Gromacs ##
`build.sh` can also build and install [gromacs](http://www.gromacs.org) for you
```
./build.sh --prefix ${prefix} gromacs
```

If installing gromacs manually (or using pre installed one) make sure it is installed as shared.

To build against a double precision version of gromacs (libgmx\_d) add
`-DGMX_DOUBLE=ON` to `build.sh`:
```
./build.sh --prefix ${prefix} -DGMX_DOUBLE=ON tools csg
```

## Manual Install ##
Manual download and build is **not** recommended, but it can be done.
  1. Checkout the source code
```
hg clone https://code.google.com/p/votca.tools/ tools
```
  1. Configure the source
```
cd tools
cmake -DCMAKE_INSTALL_PREFIX=/where/to/install .
```
  1. Build it
```
make
```
  1. Install it
```
make install
```
And now do the same thing for _csg_ by replacing _tools_ by _csg_ in the above commands.





> # Installing VOTCA 1.2.2 (on Rocks 6 Cluster) #

Make sure **gsl** and **cmake** are installed on the system.

**gsl**:
Installing by hand: Get a copy of gsl-1.15 from http://ftp.heanet.ie/mirrors/gnu/gsl/ and extract:

```
tar -xzvf gsl-.tar.gz 
./configure --enable-shared --prefix=/share/apps/gsl
make
make install 
```

Please note, we install to the folder /share/apps/ on our cluster, but it does not necessarily have to be it.

**cmake**
Next get a copy of cmake-2.8.8:

```
wget http://www.cmake.org/files/v2.8/cmake-2.8.8.tar.gz 
tar -xvf cmake-2.8.8.tar.gz 
cd cmake-2.8.8 
./configure --prefix=/share/apps/cmake
make 
make install
```

Add this directory to your path in .bashrc
```
export PATH=$PATH:/share/apps/cmake/bin
```

Also you (might) need to make sure the **expat** package is installed.

You will also of course need **Gromacs** and **fftw3** installed.

Now we can install VOTCA. Get a copy of the newest VOTCA from http://www.votca.org/download, then get build.sh and make sure it is executable:

```
tar -xzvf votca.tar.gz 
wget http://votca.googlecode.com/hg/build.sh 
chmod +x build.sh 
```

VOTCA (with all flags) should be installed like:

```
 ./build.sh -DWITH_SQLITE3=NO -DGSL_INCLUDE_DIR=/share/apps/gsl/include -DGSL_LIBRARY=/share/apps/gsl/lib/libgsl.so -DGSLCBLAS_LIBRARY=/share/apps/gsl/lib/libgslcblas.so -DFFTW3_INCLUDE_DIR=/share/apps/fftw3_d/include -DFFTW3_LIBRARY=/share/apps/fftw3_d/lib/libfftw3.so -DGROMACS_INCLUDE_DIR=/share/apps/gromacs/include -DGROMACS_LIBRARY=/share/apps/gromacs/lib/libgmx.so -DGROMACS_DEP_LIBARIES="/share/apps/gsl/lib/libgslcblas.so;/share/apps/gsl/lib/libgsl.so" --prefix /share/apps/votca tools csg
```

Then add the VOTCA install directory to the path. Add to your .bashrc file
```
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/share/apps/votca/lib:/usr/lib64/openmpi/lib/
export PATH=$PATH:/share/apps/votca/bin:share/apps/votca
```

Ta-da!