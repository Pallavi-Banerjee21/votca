Here are some guidelines to compile under AIX

## Getting buildutil ##

Getting the buildutil from hg
```
cd $HOME
mkdir -p votca/src
cd votca/src
hg clone https://code.google.com/p/votca/ buildutil
ln -s buildutil/build.sh build
```

## Create confmakeinst ##
Now we create a script called `confmakeinst`, which sets some AIX specific variables and builds votca
```
#! /bin/sh -e

export CC="xlc_r -q64"
export CXX="xlC_r -q64"
export F77="xlf_r -q64"
export MPICC="mpcc_r -q64"
export AR="ar -X64"

export OBJECT_MODE=64
export FFLAGS="-O3 -qtune=pwr6 -qhot -qstrict"
export CFLAGS="-O2 -qcpluscmt -qtune=pwr6 -qhot -qstrict -g"
#-qhalt=w -qmaxerr=1"
export CXXFLAGS="-O2 -qtune=pwr6 -qhot -qstrict -qrtti -g"
#-qhalt=w -qmaxerr=1"
export LDFLAGS="-g -qdfp -lxlf90 -lm -lessl -lblas"

module load cmake/2.8.3
module load mercurial
#defines FFTW_HOME
module load fftw/3.2.2
#defines GSL_LIBDIR and GSL_INCDIR
module load gsl/1.14
#defines GMXLDLIB
#. /u/system/Power/app/gromacs/gromacs-4.5.3/bin/GMXRC.bash
module load gromacs

prefix=$HOME/votca

./build -j9 -du --prefix $prefix \
  -DGSL_INCLUDE_DIR="$GSL_INCDIR" -DGSL_LIBRARY="$GSL_LIBDIR/libgsl.a" -DGSLCBLAS_LIBRARY="$GSL_LIBDIR/libgslcblas.a;/usr/lib/libm.a" \
  -DFFTW3_INCLUDE_DIR="$FFTW_HOME/include" -DFFTW3_LIBRARY="$FFTW_HOME/lib/libfftw3.a" \
  -DEXPAT_INCLUDE_DIR="/opt/freeware/include" -DEXPAT_LIBRARY="/opt/freeware/lib/libexpat.a" \
  -DVOTCA_TOOLS_INCLUDE_DIR="$prefix/include" -DVOTCA_TOOLS_LIBRARY="$prefix/lib/libvotca_tools.so" \
  -DGMX_DOUBLE=ON -DGROMACS_INCLUDE_DIR="$GMXLDLIB/../include" -DGROMACS_LIBRARY="$GMXLDLIB/libgmx_d.a;/usr/local/lib/liblapack-essl_O3_qstrict.a;/usr/lib/libm.a" \
  -DBoost_INCLUDE_DIR=/u/system/Power6/libs/boost_1.48.0/include  \
  -DWITH_SQLITE3=OFF "$@"
```

In most cases you will have to change the `XXX_INCLUDE_DIR` and `XXX_LIBRARY` defines in the build command line, please refer to your supercomputer documentation.

## Do it ##
Everything is ready to compile:
```
chmod 755 confmakeinst
./confmakeinst -c tools csg
```
In this example we clean (-c) the target installation directory and compile tools and csg and afterwards.

You might have to adjust your LIBPATH as follows:
```
bash: export LIBPATH=/opt/freeware/lib:$LIBPATH 
```
or
```
*csh: setenv LIBPATH/opt/freeware/lib:$LIBPATH
```